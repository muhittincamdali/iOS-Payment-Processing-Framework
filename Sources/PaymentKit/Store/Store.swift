import Foundation
import Observation

/// The in-app purchase model of an app: products, purchases and the entitlements they grant.
///
/// Create one `Store` when the app launches and call ``start()`` right away, so renewals,
/// refunds, Ask to Buy approvals and purchases from other devices are handled even when the
/// person never opens the store screen.
///
/// ```swift
/// @MainActor let store = Store(catalog: [
///     .autoRenewable("pro.monthly", unlocks: "pro"),
///     .nonConsumable("pro.lifetime", unlocks: "pro"),
///     .consumable("coins.100", credits: 100, to: "coins")
/// ])
///
/// // In a view:
/// if store.hasEntitlement("pro") { ProFeatures() }
/// Text("\(store.balance(of: "coins")) coins")
/// ```
///
/// Every transaction goes through the same steps: transactions StoreKit cannot verify are
/// rejected and never finished; verified ones are passed to `deliver` as a
/// ``TransactionChange``, credited to the ``ConsumableLedger`` when they are consumables with a
/// credit, finished only after both succeed, and then ``entitlements`` is recomputed.
///
/// Access is never accumulated: ``entitlements`` is always computed again from StoreKit's
/// current verified transactions, so a refund, a revocation, an expiry or an upgrade removes it.
/// A refund reaches `deliver` as ``TransactionChange/revoked(_:)``, never as a new grant.
@MainActor
@Observable
public final class Store {
    /// A closure that delivers what a transaction paid for: coins for a consumable, a call to
    /// your server with ``StoreTransaction/signedTransaction``. Throwing leaves the transaction
    /// unfinished, so the App Store sends it again on the next ``start()``.
    ///
    /// It runs at least once per transaction: StoreKit sends a transaction again when the app
    /// stops between `deliver` and `finish()`, so make it idempotent by transaction identifier
    /// (the receipt server in Examples does).
    public typealias Delivery = @Sendable (TransactionChange) async throws -> Void

    /// What happened to a purchase.
    public enum PurchaseOutcome: Hashable, Sendable {
        /// The App Store charged the person and the transaction was delivered and finished.
        case purchased(StoreTransaction)
        /// The purchase waits for approval; the transaction arrives through the updates
        /// ``start()`` listens to.
        case pending
        /// The person closed the purchase sheet.
        case cancelled
    }

    /// The products of the catalog that the App Store returned, in catalog order.
    public private(set) var products: [StoreProduct] = []
    /// The access the person has now, one entry per entitlement name.
    public private(set) var entitlements: [Entitlement] = []
    /// The product whose purchase sheet is showing, if any.
    public private(set) var purchasingProductID: String?
    /// The balances of consumables with a credit, such as `["coins": 300]`.
    public private(set) var balances: [String: Int64] = [:]
    /// The last error from loading, an update or a delivery, to show in the interface.
    public private(set) var lastError: StoreError?

    @ObservationIgnored private let catalog: [ProductDefinition]
    @ObservationIgnored private let credits: [String: ProductDefinition.Credit]
    @ObservationIgnored private let ledger: ConsumableLedger
    @ObservationIgnored private let client: any StoreClient
    @ObservationIgnored private let resolver: EntitlementResolver
    @ObservationIgnored private let deliver: Delivery?
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private var expiryTask: Task<Void, Never>?
    @ObservationIgnored private var inFlight: Set<TransactionKey> = []
    @ObservationIgnored private var handled = RecentSet<TransactionKey>(capacity: 1_000)
    /// Counts refreshes, so the result of an older refresh never replaces a newer one.
    @ObservationIgnored private var refreshGeneration: UInt64 = 0

    /// Creates a store that talks to `client`.
    ///
    /// - Parameters:
    ///   - catalog: The products the app sells and what they unlock.
    ///   - client: The App Store, or a ``TestStoreClient`` in tests and previews.
    ///   - ledger: Where the balances of consumables with a credit are kept. Tests and previews
    ///     pass `ConsumableLedger(fileURL: nil)`.
    ///   - now: The current time; tests pass a fixed clock.
    ///   - deliver: Called for each new verified transaction and each refund before it is
    ///     finished.
    public init(
        catalog: [ProductDefinition],
        client: any StoreClient,
        ledger: ConsumableLedger = .standard,
        now: @escaping @Sendable () -> Date = { Date() },
        deliver: Delivery? = nil
    ) {
        self.catalog = catalog
        self.credits = Dictionary(
            catalog.compactMap { definition in definition.credit.map { (definition.id, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        self.ledger = ledger
        self.client = client
        self.resolver = EntitlementResolver(catalog: catalog)
        self.now = now
        self.deliver = deliver
    }

    /// Starts listening for transaction updates, loads the products, delivers unfinished
    /// transactions and computes the entitlements. Calling it again does nothing.
    public func start() async {
        guard updatesTask == nil else { return }
        let updates = client.transactionUpdates()
        updatesTask = Task { [weak self] in
            for await event in updates {
                guard let self else { return }
                await self.handle(event)
            }
        }
        await loadProducts()
        if !credits.isEmpty {
            await loadBalances()
        }
        for event in await client.unfinishedTransactions() {
            await handle(event)
        }
        await refreshEntitlements()
    }

    /// Stops listening for transaction updates and expiry dates.
    public func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        expiryTask?.cancel()
        expiryTask = nil
    }

    /// Loads the catalog's products from the App Store again.
    public func loadProducts() async {
        do {
            let loaded = try await client.products(for: Set(catalog.map(\.id)))
            let order = Dictionary(catalog.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
            products = loaded.sorted { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }
        } catch {
            lastError = .storeKit(error.localizedDescription)
        }
    }

    /// The loaded product with the given identifier.
    public func product(withID id: String) -> StoreProduct? {
        products.first { $0.id == id }
    }

    /// Whether the person has the entitlement now.
    public func hasEntitlement(_ name: String) -> Bool {
        let date = now()
        return entitlements.contains { $0.name == name && ($0.expirationDate.map { $0 > date } ?? true) }
    }

    /// The balance of a consumable account, such as `"coins"`; 0 when it has none.
    public func balance(of account: String) -> Int64 {
        balances[account] ?? 0
    }

    /// Spends from a consumable balance.
    ///
    /// - Throws: ``ConsumableLedger/Failure/insufficientBalance(account:balance:requested:)``
    ///   when the balance is too low; nothing changes then.
    public func spend(_ amount: Int64, of account: String) async throws(ConsumableLedger.Failure) {
        try await ledger.spend(amount, of: account)
        balances = try await ledger.balances()
    }

    /// Shows the purchase sheet, then delivers and finishes the transaction.
    ///
    /// - Throws: ``StoreError/purchaseInProgress`` while another sheet is showing,
    ///   ``StoreError/productNotFound(_:)``, ``StoreError/invalidQuantity(_:)``,
    ///   ``StoreError/verificationFailed(productID:reason:)`` (nothing is granted), or
    ///   ``StoreError/storeKit(_:)`` when the App Store or the network fails, or
    ///   ``StoreError/deliveryFailed(transactionID:reason:)`` when `deliver` throws; the
    ///   transaction then stays unfinished and is delivered on the next ``start()``.
    @discardableResult
    public func purchase(_ product: StoreProduct, options: PurchaseOptions = PurchaseOptions()) async throws(StoreError) -> PurchaseOutcome {
        guard purchasingProductID == nil else { throw .purchaseInProgress }
        guard catalog.contains(where: { $0.id == product.id }) else { throw .productNotFound(product.id) }
        guard (1...PurchaseOptions.maximumQuantity).contains(options.quantity),
              options.quantity == 1 || product.kind == .consumable
        else { throw .invalidQuantity(options.quantity) }

        purchasingProductID = product.id
        defer { purchasingProductID = nil }

        let result: PurchaseResult
        do {
            result = try await client.purchase(product.id, options: options)
        } catch let error as StoreError {
            throw error
        } catch {
            throw .storeKit(error.localizedDescription)
        }

        switch result {
        case .cancelled:
            return .cancelled
        case .pending:
            return .pending
        case .completed(let event):
            if case .unverified(let reason) = event.verification {
                throw .verificationFailed(productID: event.transaction.productID, reason: reason)
            }
            do {
                try await process(event.transaction)
            } catch {
                throw .deliveryFailed(transactionID: event.transaction.id, reason: error.localizedDescription)
            }
            return .purchased(event.transaction)
        }
    }

    /// Asks the App Store for the person's purchases and recomputes the entitlements.
    ///
    /// Only call it from a Restore Purchases button: the App Store may ask the person to sign
    /// in. Purchases normally arrive by themselves through ``start()``.
    public func restorePurchases() async throws(StoreError) {
        do {
            try await client.sync()
        } catch {
            throw .storeKit(error.localizedDescription)
        }
        await refreshEntitlements()
    }

    /// Recomputes ``entitlements`` from the App Store's current entitlements.
    ///
    /// When refreshes overlap, the one that started last wins, so a list read before a refund
    /// cannot replace the list read after it.
    public func refreshEntitlements() async {
        refreshGeneration &+= 1
        let generation = refreshGeneration
        let events = await client.currentEntitlements()
        guard generation == refreshGeneration else { return }
        entitlements = resolver.entitlements(from: events, at: now())
        scheduleExpiryRefresh()
    }

    private func loadBalances() async {
        do {
            balances = try await ledger.balances()
        } catch {
            lastError = .ledger(error)
        }
    }

    // MARK: - Transactions

    private func handle(_ event: TransactionEvent) async {
        if case .unverified(let reason) = event.verification {
            lastError = .verificationFailed(productID: event.transaction.productID, reason: reason)
            return
        }
        do {
            try await process(event.transaction)
        } catch {
            lastError = .deliveryFailed(transactionID: event.transaction.id, reason: error.localizedDescription)
        }
    }

    /// Delivers, credits and finishes a verified transaction once, then recomputes the
    /// entitlements.
    private func process(_ transaction: StoreTransaction) async throws {
        let key = TransactionKey(transaction)
        guard !inFlight.contains(key) else { return }
        guard !handled.contains(key) else {
            // Delivered already; a repeat can still carry a new flag such as an upgrade.
            await refreshEntitlements()
            return
        }
        inFlight.insert(key)
        defer { inFlight.remove(key) }

        let change = TransactionChange(transaction)
        try await deliver?(change)
        try await applyCredit(of: change)
        await client.finish(transaction)
        handled.insert(key)
        await refreshEntitlements()
    }

    /// Credits a consumable purchase to the ledger, or takes a refunded one back.
    private func applyCredit(of change: TransactionChange) async throws {
        let transaction = change.transaction
        guard let credit = credits[transaction.productID] else { return }
        // purchasedQuantity is at most PurchaseOptions.maximumQuantity, so the conversion is exact.
        let (amount, overflow) = credit.amount.multipliedReportingOverflow(by: Int64(transaction.purchasedQuantity))
        guard !overflow else { throw ConsumableLedger.Failure.overflow(account: credit.account) }
        switch change {
        case .granted:
            try await ledger.credit(amount, to: credit.account, for: transaction.id)
        case .revoked:
            try await ledger.revoke(amount, from: credit.account, for: transaction.id)
        }
        balances = try await ledger.balances()
    }

    private func scheduleExpiryRefresh() {
        expiryTask?.cancel()
        expiryTask = nil
        guard let next = entitlements.compactMap(\.expirationDate).min() else { return }
        let delay = Self.refreshDelay(until: next, now: now())
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.refreshEntitlements()
        }
    }

    /// How long to wait before recomputing entitlements for an expiry at `date`: at least
    /// 1 second, at most 1 day, and 1 day for dates that are not finite.
    nonisolated static func refreshDelay(until date: Date, now: Date) -> Duration {
        let interval = date.timeIntervalSince(now)
        guard interval.isFinite else { return .seconds(86_400) }
        // Clamp before converting, so a far-future date cannot overflow Duration.
        let seconds = min(max(interval, 1), 86_400)
        return .milliseconds(Int64((seconds * 1_000).rounded(.up)))
    }
}

/// A transaction identifier plus whether it is revoked, so a refund of a delivered
/// transaction is delivered again.
struct TransactionKey: Hashable, Sendable {
    let id: UInt64
    let isRevoked: Bool

    init(_ transaction: StoreTransaction) {
        self.id = transaction.id
        self.isRevoked = transaction.revocationDate != nil
    }
}

/// A set that keeps only the most recently inserted `capacity` elements.
struct RecentSet<Element: Hashable> {
    private(set) var order: [Element] = []
    private var members: Set<Element> = []
    let capacity: Int

    init(capacity: Int) {
        self.capacity = max(capacity, 1)
    }

    func contains(_ element: Element) -> Bool {
        members.contains(element)
    }

    mutating func insert(_ element: Element) {
        guard members.insert(element).inserted else { return }
        order.append(element)
        if order.count > capacity {
            members.remove(order.removeFirst())
        }
    }

    var count: Int { members.count }
}

#if canImport(StoreKit)
extension Store {
    /// Creates a store that talks to the App Store through StoreKit 2.
    ///
    /// - Parameters:
    ///   - catalog: The products the app sells and what they unlock.
    ///   - deliver: Called for each new verified transaction and each refund before it is
    ///     finished.
    ///
    /// Balances of consumables with a credit are kept in ``ConsumableLedger/standard``.
    public convenience init(catalog: [ProductDefinition], deliver: Delivery? = nil) {
        self.init(catalog: catalog, client: AppStoreClient(), ledger: .standard, deliver: deliver)
    }
}
#endif
