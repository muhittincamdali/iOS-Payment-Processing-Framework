import Foundation
@testable import PaymentKit

/// A clock tests move forward by hand.
final class ManualClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        self.current = start
    }

    var now: Date {
        lock.withLock { current }
    }

    func advance(by seconds: TimeInterval) {
        lock.withLock { current += seconds }
    }
}

/// Records what a store's `deliver` closure received, and can fail on demand.
final class DeliveryRecorder: @unchecked Sendable {
    struct Failure: Error, LocalizedError {
        var errorDescription: String? { "The wallet service is offline." }
    }

    private let lock = NSLock()
    private var received: [TransactionChange] = []
    private var failing = false

    var changes: [TransactionChange] {
        lock.withLock { received }
    }

    var transactions: [StoreTransaction] {
        changes.map(\.transaction)
    }

    func setFailing(_ value: Bool) {
        lock.withLock { failing = value }
    }

    func deliver(_ change: TransactionChange) throws {
        try lock.withLock {
            if failing { throw Failure() }
            received.append(change)
        }
    }
}

/// Waits until `condition` holds, for work that arrives through an `AsyncStream`.
@MainActor
func eventually(timeout: Duration = .seconds(5), _ condition: @MainActor () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while clock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await condition()
}

enum Fixtures {
    static let monthly = StoreProduct.preview(id: "pro.monthly", kind: .autoRenewable, price: "4.99")
    static let yearly = StoreProduct.preview(id: "pro.yearly", kind: .autoRenewable, price: "39.99", period: SubscriptionPeriod(1, .year))
    static let lifetime = StoreProduct.preview(id: "pro.lifetime", kind: .nonConsumable, price: "99.99")
    static let coins = StoreProduct.preview(id: "coins.100", kind: .consumable, price: "0.99")
    static let season = StoreProduct.preview(id: "season.pass", kind: .nonRenewable, price: "9.99")

    static let products = [monthly, yearly, lifetime, coins, season]

    static let catalog: [ProductDefinition] = [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        .consumable("coins.100", credits: 100, to: "coins"),
        .nonRenewing("season.pass", unlocks: "season", lasts: SubscriptionPeriod(3, .month))
    ]
}

/// A client that passes everything to a ``TestStoreClient`` but can stand in for an app that
/// stops before `finish()`, or hold one entitlements read until the test releases it.
actor InterposingClient: StoreClient {
    let base: TestStoreClient
    private var finishes = true
    private var holdNextRead = false
    private var held: CheckedContinuation<Void, Never>?

    init(_ base: TestStoreClient) {
        self.base = base
    }

    /// Makes `finish(_:)` do nothing, as if the app stopped right before it.
    func stopBeforeFinishing() {
        finishes = false
    }

    /// Makes the next `currentEntitlements()` read the transactions now and return them only
    /// after ``releaseHeldRead()``.
    func holdNextEntitlementsRead() {
        holdNextRead = true
    }

    var isHoldingRead: Bool { held != nil }

    func releaseHeldRead() {
        held?.resume()
        held = nil
    }

    func products(for ids: Set<String>) async throws -> [StoreProduct] { try await base.products(for: ids) }
    func purchase(_ productID: String, options: PurchaseOptions) async throws -> PurchaseResult { try await base.purchase(productID, options: options) }
    func unfinishedTransactions() async -> [TransactionEvent] { await base.unfinishedTransactions() }
    nonisolated func transactionUpdates() -> AsyncStream<TransactionEvent> { base.transactionUpdates() }
    func sync() async throws { try await base.sync() }

    func finish(_ transaction: StoreTransaction) async {
        if finishes { await base.finish(transaction) }
    }

    func currentEntitlements() async -> [TransactionEvent] {
        let snapshot = await base.currentEntitlements()
        if holdNextRead {
            holdNextRead = false
            await withCheckedContinuation { held = $0 }
        }
        return snapshot
    }
}

/// A small seeded generator (SplitMix64), so a failing random sequence can be replayed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

/// A file URL in a new temporary directory, removed by the caller.
func temporaryLedgerURL() -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "PaymentKitTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        .appending(path: "ledger.json")
}
