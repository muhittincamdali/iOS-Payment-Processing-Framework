import Foundation

/// A ``StoreClient`` that keeps products and transactions in memory, for unit tests and
/// SwiftUI previews.
///
/// It behaves like the App Store where ``Store`` can tell the difference: purchases create
/// transactions that stay unfinished until finished, auto-renewable subscriptions expire after
/// their period or at the end of a Billing Grace Period
/// (``startBillingGracePeriod(for:until:)``), refunds set a revocation date, and renewals,
/// refunds, Ask to Buy approvals and purchases on other devices arrive through
/// ``transactionUpdates()``, except the refund of a finished consumable, which StoreKit does not
/// send either. Only one listener receives the updates, as with one `Store`.
///
/// ```swift
/// let client = TestStoreClient(products: [.preview(id: "pro.monthly", kind: .autoRenewable)])
/// let store = Store(catalog: [.autoRenewable("pro.monthly", unlocks: "pro")], client: client)
/// await store.start()
/// try await store.purchase(store.products[0])
/// store.hasEntitlement("pro") // true
/// ```
public actor TestStoreClient: StoreClient {
    /// What the next purchase of a product does.
    public enum PurchaseBehavior: Hashable, Sendable {
        /// Charges and returns a verified transaction.
        case succeed
        /// Waits for approval, as with Ask to Buy; call ``approvePendingPurchase(of:)``.
        case pending
        /// The person closes the sheet.
        case cancel
        /// Returns a transaction whose signature StoreKit could not verify.
        case failVerification
        /// The App Store or the network fails with this message.
        case fail(String)
    }

    /// The error a `.fail` purchase or ``failSync(with:)`` throws.
    public struct Failure: Error, LocalizedError, Hashable, Sendable {
        public let message: String
        public var errorDescription: String? { message }
    }

    private let catalog: [String: StoreProduct]
    private let now: @Sendable () -> Date
    private var behaviors: [String: PurchaseBehavior] = [:]
    private var pendingOptions: [String: PurchaseOptions] = [:]
    private var nextID: UInt64 = 1_000
    private var syncError: Failure?
    /// Transactions whose signature does not verify; StoreKit reports them as unverified
    /// wherever they appear.
    private var unverifiedIDs: Set<UInt64> = []
    /// The end of the Billing Grace Period of a subscription's latest transaction, by
    /// transaction identifier.
    private var gracePeriodEnds: [UInt64: Date] = [:]
    private nonisolated let updates: AsyncStream<TransactionEvent>
    private nonisolated let continuation: AsyncStream<TransactionEvent>.Continuation

    /// Every transaction in the order it was created; refunds replace the refunded one.
    public private(set) var transactions: [StoreTransaction] = []
    /// Identifiers of transactions that were created and not finished yet.
    public private(set) var unfinishedTransactionIDs: [UInt64] = []
    /// Identifiers in the order ``finish(_:)`` received them.
    public private(set) var finishedTransactionIDs: [UInt64] = []
    /// How many purchase sheets were shown.
    public private(set) var purchaseCount = 0
    /// How many times ``sync()`` was called.
    public private(set) var syncCount = 0

    /// Creates a client that sells `products`.
    ///
    /// - Parameters:
    ///   - products: The products the client returns and lets you buy.
    ///   - now: The current time, used for purchase and expiration dates.
    public init(products: [StoreProduct], now: @escaping @Sendable () -> Date = { Date() }) {
        self.catalog = Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.now = now
        (updates, continuation) = AsyncStream.makeStream(of: TransactionEvent.self)
    }

    /// Sets what purchases of a product do from now on. The default is `.succeed`.
    public func setPurchaseBehavior(_ behavior: PurchaseBehavior, for productID: String) {
        behaviors[productID] = behavior
    }

    /// Makes the next ``sync()`` calls throw.
    public func failSync(with message: String?) {
        syncError = message.map(Failure.init(message:))
    }

    // MARK: StoreClient

    public func products(for ids: Set<String>) async throws -> [StoreProduct] {
        ids.compactMap { catalog[$0] }.sorted { $0.id < $1.id }
    }

    public func purchase(_ productID: String, options: PurchaseOptions) async throws -> PurchaseResult {
        guard catalog[productID] != nil else { throw StoreError.productNotFound(productID) }
        purchaseCount += 1
        switch behaviors[productID] ?? .succeed {
        case .succeed:
            return .completed(TransactionEvent(transaction: makeTransaction(productID, options: options), verification: .verified))
        case .pending:
            pendingOptions[productID] = options
            return .pending
        case .cancel:
            return .cancelled
        case .failVerification:
            let transaction = makeTransaction(productID, options: options)
            unverifiedIDs.insert(transaction.id)
            return .completed(event(for: transaction))
        case .fail(let message):
            throw Failure(message: message)
        }
    }

    public func currentEntitlements() async -> [TransactionEvent] {
        let date = now()
        var latest: [String: StoreTransaction] = [:]
        for var transaction in transactions where transaction.productKind != .consumable {
            guard transaction.revocationDate == nil, !transaction.isUpgraded else { continue }
            if transaction.productKind == .autoRenewable, (transaction.expirationDate ?? .distantPast) <= date {
                // StoreKit keeps listing a subscription in its Billing Grace Period.
                guard let end = gracePeriodEnds[transaction.id], end > date else { continue }
                transaction = transaction.inGracePeriod(until: end)
            }
            if let current = latest[transaction.productID], current.purchaseDate > transaction.purchaseDate { continue }
            latest[transaction.productID] = transaction
        }
        return latest.values.sorted { $0.id < $1.id }.map(event(for:))
    }

    public func unfinishedTransactions() async -> [TransactionEvent] {
        unfinishedTransactionIDs.compactMap { id in
            transactions.first { $0.id == id }.map(event(for:))
        }
    }

    public nonisolated func transactionUpdates() -> AsyncStream<TransactionEvent> {
        updates
    }

    public func finish(_ transaction: StoreTransaction) async {
        unfinishedTransactionIDs.removeAll { $0 == transaction.id }
        finishedTransactionIDs.append(transaction.id)
    }

    public func sync() async throws {
        syncCount += 1
        if let syncError { throw syncError }
    }

    // MARK: Simulating the App Store

    /// Approves a purchase that returned `.pending`, as a parent approving Ask to Buy.
    @discardableResult
    public func approvePendingPurchase(of productID: String) throws -> StoreTransaction {
        guard let options = pendingOptions.removeValue(forKey: productID) else { throw StoreError.productNotFound(productID) }
        return emit(makeTransaction(productID, options: options))
    }

    /// Records a purchase made on another device signed in to the same account.
    @discardableResult
    public func purchaseOnAnotherDevice(_ productID: String) throws -> StoreTransaction {
        guard catalog[productID] != nil else { throw StoreError.productNotFound(productID) }
        return emit(makeTransaction(productID, options: PurchaseOptions()))
    }

    /// Renews an auto-renewable subscription for one more period from now; this also ends a
    /// Billing Grace Period.
    @discardableResult
    public func renew(_ productID: String) throws -> StoreTransaction {
        guard let previous = transactions.last(where: { $0.productID == productID }) else { throw StoreError.productNotFound(productID) }
        gracePeriodEnds[previous.id] = nil
        return emit(makeTransaction(productID, options: PurchaseOptions(appAccountToken: previous.appAccountToken), originalID: previous.originalID))
    }

    /// Fails the next renewal of an auto-renewable subscription, as when the App Store cannot
    /// charge the person, and gives it a Billing Grace Period that ends at `end`.
    ///
    /// No transaction arrives. Once its period has ended, the latest transaction stays in
    /// ``currentEntitlements()`` with ``StoreTransaction/gracePeriodExpirationDate`` until `end`,
    /// as StoreKit lists a subscription in its grace period; ``renew(_:)`` ends it.
    public func startBillingGracePeriod(for productID: String, until end: Date) throws {
        guard let latest = transactions.last(where: { $0.productID == productID && $0.productKind == .autoRenewable }) else {
            throw StoreError.productNotFound(productID)
        }
        gracePeriodEnds[latest.id] = end
    }

    /// Refunds a transaction: it gets a revocation date and arrives again as an update. Use it
    /// for a family member's shared purchase too: StoreKit revokes it the same way when Family
    /// Sharing stops.
    ///
    /// The refund of a consumable that was already finished gets its revocation date in
    /// ``transactions`` but sends no update: StoreKit does not tell the app about it, and only
    /// your server learns of it, from a `REFUND` App Store Server Notification. A consumable
    /// refunded while it is still unfinished arrives as an update, as with StoreKit.
    @discardableResult
    public func refund(_ transactionID: UInt64) throws -> StoreTransaction {
        let isFinishedConsumable = transactions.contains { $0.id == transactionID && $0.productKind == .consumable }
            && !unfinishedTransactionIDs.contains(transactionID)
        return try replace(transactionID, sendingUpdate: !isFinishedConsumable) { $0.revoked(at: now()) }
    }

    /// Sends a transaction again as an update, as StoreKit can after a restore or when the app
    /// stopped before finishing it.
    @discardableResult
    public func redeliver(_ transactionID: UInt64) throws -> StoreTransaction {
        guard let transaction = transactions.first(where: { $0.id == transactionID }) else {
            throw StoreError.productNotFound(String(transactionID))
        }
        return emit(transaction)
    }

    /// Moves the person from the latest transaction of `oldProductID` to a new subscription of
    /// `newProductID` in the same group: the old transaction is marked upgraded and both arrive
    /// as updates.
    @discardableResult
    public func upgrade(from oldProductID: String, to newProductID: String) throws -> StoreTransaction {
        guard catalog[newProductID] != nil,
              let previous = transactions.last(where: { $0.productID == oldProductID && $0.revocationDate == nil })
        else { throw StoreError.productNotFound(newProductID) }
        try replace(previous.id) { $0.upgraded() }
        return emit(makeTransaction(newProductID, options: PurchaseOptions(appAccountToken: previous.appAccountToken), originalID: previous.originalID))
    }

    /// Records a purchase a family member made and shares through Family Sharing.
    @discardableResult
    public func shareFromFamily(_ productID: String) throws -> StoreTransaction {
        guard catalog[productID] != nil else { throw StoreError.productNotFound(productID) }
        return emit(makeTransaction(productID, options: PurchaseOptions(), isFamilyShared: true))
    }

    @discardableResult
    private func replace(
        _ transactionID: UInt64,
        sendingUpdate: Bool = true,
        _ change: (StoreTransaction) -> StoreTransaction
    ) throws -> StoreTransaction {
        guard let index = transactions.firstIndex(where: { $0.id == transactionID }) else {
            throw StoreError.productNotFound(String(transactionID))
        }
        let changed = change(transactions[index])
        transactions[index] = changed
        if sendingUpdate {
            continuation.yield(event(for: changed))
        }
        return changed
    }

    /// Sends a transaction update whose signature cannot be verified.
    public func sendUnverifiedUpdate(for productID: String) throws {
        guard catalog[productID] != nil else { throw StoreError.productNotFound(productID) }
        let transaction = makeTransaction(productID, options: PurchaseOptions())
        unverifiedIDs.insert(transaction.id)
        continuation.yield(event(for: transaction))
    }

    private func emit(_ transaction: StoreTransaction) -> StoreTransaction {
        continuation.yield(event(for: transaction))
        return transaction
    }

    private func event(for transaction: StoreTransaction) -> TransactionEvent {
        let verification: TransactionEvent.Verification = unverifiedIDs.contains(transaction.id) ? .unverified(reason: "invalidSignature") : .verified
        return TransactionEvent(transaction: transaction, verification: verification)
    }

    private func makeTransaction(_ productID: String, options: PurchaseOptions, originalID: UInt64? = nil, isFamilyShared: Bool = false) -> StoreTransaction {
        let product = catalog[productID]
        let kind = product?.kind ?? .consumable
        let date = now()
        let expiration = kind == .autoRenewable ? (product?.subscription?.period ?? SubscriptionPeriod(1, .month)).date(after: date) : nil
        nextID += 1
        let transaction = StoreTransaction(
            id: nextID,
            originalID: originalID,
            productID: productID,
            productKind: kind,
            purchaseDate: date,
            expirationDate: expiration,
            isFamilyShared: isFamilyShared,
            purchasedQuantity: options.quantity,
            environment: "Xcode",
            appAccountToken: options.appAccountToken
        )
        transactions.append(transaction)
        unfinishedTransactionIDs.append(transaction.id)
        return transaction
    }
}

extension StoreProduct {
    /// A product for previews and tests, priced in US dollars.
    ///
    /// Auto-renewable products renew monthly unless `period` says otherwise.
    public static func preview(
        id: String,
        kind: Kind,
        displayName: String? = nil,
        price: String = "4.99",
        period: SubscriptionPeriod = SubscriptionPeriod(1, .month)
    ) -> StoreProduct {
        StoreProduct(
            id: id,
            kind: kind,
            displayName: displayName ?? id,
            displayPrice: "$\(price)",
            price: (try? Money(price, .usd)) ?? .zero(.usd),
            subscription: kind == .autoRenewable ? Subscription(groupID: "preview", period: period) : nil
        )
    }
}

extension StoreTransaction {
    func revoked(at date: Date) -> StoreTransaction {
        copy(revocationDate: date, isUpgraded: isUpgraded, gracePeriodExpirationDate: gracePeriodExpirationDate)
    }

    func upgraded() -> StoreTransaction {
        copy(revocationDate: revocationDate, isUpgraded: true, gracePeriodExpirationDate: gracePeriodExpirationDate)
    }

    func inGracePeriod(until end: Date) -> StoreTransaction {
        copy(revocationDate: revocationDate, isUpgraded: isUpgraded, gracePeriodExpirationDate: end)
    }

    private func copy(revocationDate: Date?, isUpgraded: Bool, gracePeriodExpirationDate: Date?) -> StoreTransaction {
        StoreTransaction(
            id: id, originalID: originalID, productID: productID, productKind: productKind,
            purchaseDate: purchaseDate, expirationDate: expirationDate,
            gracePeriodExpirationDate: gracePeriodExpirationDate, revocationDate: revocationDate,
            isUpgraded: isUpgraded, isFamilyShared: isFamilyShared, purchasedQuantity: purchasedQuantity,
            environment: environment, appAccountToken: appAccountToken, signedTransaction: signedTransaction
        )
    }
}
