import Foundation

/// Balances bought with consumables, such as coins, credited exactly once per transaction.
///
/// ``Store`` uses a ledger for every consumable whose definition says what it credits:
///
/// ```swift
/// let store = Store(catalog: [.consumable("coins.100", credits: 100, to: "coins")])
/// store.balance(of: "coins")          // 100 × the quantity of each purchase
/// try await store.spend(30, of: "coins")
/// ```
///
/// The rules:
/// - a transaction credits its account once, however often StoreKit sends it (as an update, as
///   unfinished at launch, again after a crash before `finish()`);
/// - a refund takes the credit back once, even if the coins were spent; the balance can then go
///   below zero, and your app decides what that means (for example, no spending until it is
///   positive again);
/// - a refund that arrives before its purchase makes the purchase credit nothing;
/// - the balance and the list of handled transactions are written to disk together in one
///   atomic write, so a crash leaves either both changes or neither. If the write fails the
///   change is undone and the error is thrown, so the transaction stays unfinished.
///
/// The ledger lives on this device. For anything of value, your server, which sees App Store
/// Server Notifications, is the source of truth.
public actor ConsumableLedger {
    /// Why a ledger operation failed.
    public enum Failure: Error, Hashable, Sendable {
        /// The amount is zero or negative.
        case invalidAmount(Int64)
        /// The account name is empty or longer than ``ConsumableLedger/maximumAccountLength``.
        case invalidAccount(String)
        /// The balance would leave the range of `Int64`.
        case overflow(account: String)
        /// Spending more than the balance.
        case insufficientBalance(account: String, balance: Int64, requested: Int64)
        /// The file exists but cannot be read or is not a ledger; holds the reason.
        case unreadable(String)
        /// The file cannot be written; holds the reason.
        case unwritable(String)
    }

    /// How many handled transactions are remembered. Older ones are forgotten first; StoreKit
    /// does not send finished transactions again, so only recent ones can repeat.
    public static let capacity = 10_000
    /// The longest account name, in characters.
    public static let maximumAccountLength = 64
    /// The largest ledger file read, so a damaged file cannot exhaust memory.
    static let maximumFileSize = 4 * 1_024 * 1_024

    /// The ledger the StoreKit initializer of ``Store`` uses, stored in the app's Application
    /// Support directory.
    public static let standard = ConsumableLedger(fileURL: defaultFileURL())

    private let fileURL: URL?
    private var state: LedgerState?

    /// Creates a ledger stored at `fileURL`, or kept in memory when `fileURL` is `nil` (for tests
    /// and previews). The file is read on first use.
    public init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    /// The balance of every account that has one.
    public func balances() throws(Failure) -> [String: Int64] {
        try loaded().balances
    }

    /// Credits `amount` to `account` for a transaction, once.
    ///
    /// - Returns: `false` when the transaction was already credited or already refunded.
    @discardableResult
    public func credit(_ amount: Int64, to account: String, for transactionID: UInt64) throws(Failure) -> Bool {
        try Self.check(amount: amount, account: account)
        var next = try loaded()
        guard next.records[transactionID] == nil else { return false }
        let (sum, overflow) = next.balance(of: account).addingReportingOverflow(amount)
        guard !overflow else { throw .overflow(account: account) }
        next.balances[account] = sum
        next.remember(transactionID, LedgerState.Record(account: account, amount: amount, isRevoked: false))
        try save(next)
        return true
    }

    /// Takes back what a refunded transaction credited, once.
    ///
    /// - Returns: `false` when there was nothing to take back. A refund of a transaction the
    ///   ledger has not seen is remembered, so its purchase credits nothing later.
    @discardableResult
    public func revoke(_ amount: Int64, from account: String, for transactionID: UInt64) throws(Failure) -> Bool {
        try Self.check(amount: amount, account: account)
        var next = try loaded()
        if let record = next.records[transactionID] {
            guard !record.isRevoked else { return false }
            let (difference, overflow) = next.balance(of: record.account).subtractingReportingOverflow(record.amount)
            guard !overflow else { throw .overflow(account: record.account) }
            next.balances[record.account] = difference
            next.records[transactionID] = LedgerState.Record(account: record.account, amount: record.amount, isRevoked: true)
            try save(next)
            return true
        }
        next.remember(transactionID, LedgerState.Record(account: account, amount: amount, isRevoked: true))
        try save(next)
        return false
    }

    /// Spends `amount` from `account`.
    ///
    /// - Throws: ``Failure/insufficientBalance(account:balance:requested:)`` when the balance is
    ///   lower than `amount`; nothing changes then.
    public func spend(_ amount: Int64, of account: String) throws(Failure) {
        try Self.check(amount: amount, account: account)
        var next = try loaded()
        let balance = next.balance(of: account)
        guard balance >= amount else {
            throw .insufficientBalance(account: account, balance: balance, requested: amount)
        }
        next.balances[account] = balance - amount
        try save(next)
    }

    /// Whether the ledger has handled the transaction, as a credit or a refund.
    public func hasHandled(_ transactionID: UInt64) throws(Failure) -> Bool {
        try loaded().records[transactionID] != nil
    }

    // MARK: Storage

    private func loaded() throws(Failure) -> LedgerState {
        if let state { return state }
        let loaded = try Self.read(fileURL)
        state = loaded
        return loaded
    }

    /// Writes `next` and only then makes it the current state.
    private func save(_ next: LedgerState) throws(Failure) {
        if let fileURL {
            do {
                let data = try JSONEncoder().encode(next)
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                throw .unwritable(error.localizedDescription)
            }
        }
        state = next
    }

    static func read(_ fileURL: URL?) throws(Failure) -> LedgerState {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else { return LedgerState() }
        do {
            let size = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
            guard size <= maximumFileSize else { throw Failure.unreadable("The ledger file is larger than \(maximumFileSize) bytes.") }
            let state = try JSONDecoder().decode(LedgerState.self, from: Data(contentsOf: fileURL))
            try state.validate()
            return state
        } catch let failure as Failure {
            throw failure
        } catch {
            throw .unreadable(error.localizedDescription)
        }
    }

    private static func check(amount: Int64, account: String) throws(Failure) {
        guard amount > 0 else { throw .invalidAmount(amount) }
        guard isValid(account: account) else { throw .invalidAccount(account) }
    }

    static func isValid(account: String) -> Bool {
        !account.isEmpty && account.utf8.count <= maximumAccountLength * 4 && account.count <= maximumAccountLength
    }

    private static func defaultFileURL() -> URL {
        var directory = URL.applicationSupportDirectory
        if let bundleID = Bundle.main.bundleIdentifier {
            // Outside the sandbox, Application Support is shared by every app of the user.
            directory.append(path: bundleID, directoryHint: .isDirectory)
        }
        return directory.appending(path: "PaymentKit/consumables.json")
    }
}

extension ConsumableLedger.Failure: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidAmount(let amount): "\(amount) is not an amount that can be credited or spent."
        case .invalidAccount: "The balance name must have 1 to \(ConsumableLedger.maximumAccountLength) characters."
        case .overflow(let account): "The balance of “\(account)” is too large."
        case .insufficientBalance(let account, let balance, let requested): "Only \(balance) “\(account)” left, \(requested) needed."
        case .unreadable(let reason): "The saved balances cannot be read: \(reason)"
        case .unwritable(let reason): "The balances cannot be saved: \(reason)"
        }
    }
}

/// What a ``ConsumableLedger`` writes to disk.
struct LedgerState: Codable, Equatable, Sendable {
    struct Record: Codable, Equatable, Sendable {
        let account: String
        let amount: Int64
        let isRevoked: Bool
    }

    var balances: [String: Int64] = [:]
    var records: [UInt64: Record] = [:]
    /// Transaction identifiers, oldest first, to forget the oldest past the capacity.
    var order: [UInt64] = []

    func balance(of account: String) -> Int64 {
        balances[account] ?? 0
    }

    mutating func remember(_ transactionID: UInt64, _ record: Record) {
        if records.updateValue(record, forKey: transactionID) == nil {
            order.append(transactionID)
        }
        while order.count > ConsumableLedger.capacity {
            records[order.removeFirst()] = nil
        }
    }

    /// Rejects files whose parts disagree, so a damaged file is reported instead of trusted.
    func validate() throws(ConsumableLedger.Failure) {
        guard order.count == records.count, Set(order).count == order.count,
              order.allSatisfy({ records[$0] != nil }), order.count <= ConsumableLedger.capacity,
              balances.keys.allSatisfy(ConsumableLedger.isValid(account:)),
              records.values.allSatisfy({ $0.amount > 0 && ConsumableLedger.isValid(account: $0.account) })
        else { throw .unreadable("The ledger file is inconsistent.") }
    }
}
