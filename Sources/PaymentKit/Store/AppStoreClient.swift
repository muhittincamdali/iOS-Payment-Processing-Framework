#if canImport(StoreKit)
import Foundation
import StoreKit
#if os(visionOS)
import UIKit
#endif

/// The ``StoreClient`` that talks to the App Store through StoreKit 2.
///
/// In development it uses the StoreKit configuration file selected in the scheme; in
/// TestFlight and the App Store it uses the sandbox and production App Store.
public final class AppStoreClient: StoreClient {
    private let cache = StoreKitCache()

    public init() {}

    public func products(for ids: Set<String>) async throws -> [StoreProduct] {
        let products = try await Product.products(for: ids)
        await cache.remember(products)
        return products.compactMap(StoreProduct.init(product:))
    }

    public func purchase(_ productID: String, options: PurchaseOptions) async throws -> PurchaseResult {
        guard (1...PurchaseOptions.maximumQuantity).contains(options.quantity) else {
            throw StoreError.invalidQuantity(options.quantity)
        }
        let product: Product
        if let cached = await cache.product(productID) {
            product = cached
        } else if let loaded = try await Product.products(for: [productID]).first {
            await cache.remember([loaded])
            product = loaded
        } else {
            throw StoreError.productNotFound(productID)
        }

        var purchaseOptions: Set<Product.PurchaseOption> = []
        if let token = options.appAccountToken {
            purchaseOptions.insert(.appAccountToken(token))
        }
        if options.quantity > 1 {
            purchaseOptions.insert(.quantity(options.quantity))
        }

        switch try await Self.showPurchaseSheet(for: product, options: purchaseOptions) {
        case .success(let verification):
            return .completed(await event(from: verification, remember: true))
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            throw StoreError.storeKit("The App Store returned a purchase result this version does not know.")
        }
    }

    /// StoreKit's current entitlements, checked against the verified renewal status of each
    /// subscription in them.
    ///
    /// A subscription in its Billing Grace Period gets
    /// ``StoreTransaction/gracePeriodExpirationDate``; one whose status names the same transaction
    /// as in billing retry, expired or revoked is left out. A status that cannot be read or
    /// verified leaves StoreKit's list as it is.
    public func currentEntitlements() async -> [TransactionEvent] {
        var statuses: [String: [Product.SubscriptionInfo.Status]] = [:]
        var events: [TransactionEvent] = []
        for await result in Transaction.currentEntitlements {
            var gracePeriodEnd: Date?
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               let groupID = transaction.subscriptionGroupID {
                if statuses[groupID] == nil {
                    statuses[groupID] = (try? await Product.SubscriptionInfo.status(for: groupID)) ?? []
                }
                switch Self.renewalStanding(of: transaction, in: statuses[groupID] ?? []) {
                case .active: break
                case .gracePeriod(let end): gracePeriodEnd = end
                case .ended: continue
                }
            }
            events.append(await event(from: result, remember: false, gracePeriodEnd: gracePeriodEnd))
        }
        return events
    }

    private enum RenewalStanding {
        case active
        case gracePeriod(until: Date)
        case ended
    }

    /// What the verified status that names this transaction says about it.
    private static func renewalStanding(of transaction: Transaction, in statuses: [Product.SubscriptionInfo.Status]) -> RenewalStanding {
        for status in statuses {
            guard case .verified(let current) = status.transaction, current.id == transaction.id,
                  case .verified(let renewal) = status.renewalInfo
            else { continue }
            switch status.state {
            case .inGracePeriod:
                return renewal.gracePeriodExpirationDate.map { .gracePeriod(until: $0) } ?? .active
            case .inBillingRetryPeriod, .expired, .revoked:
                return .ended
            default:
                return .active
            }
        }
        return .active
    }

    public func unfinishedTransactions() async -> [TransactionEvent] {
        var events: [TransactionEvent] = []
        for await result in Transaction.unfinished {
            events.append(await event(from: result, remember: true))
        }
        return events
    }

    public func transactionUpdates() -> AsyncStream<TransactionEvent> {
        // Updates that do not fit are not lost: unfinished transactions come back through
        // unfinishedTransactions() on the next launch.
        AsyncStream(bufferingPolicy: .bufferingOldest(StoreKitCache.capacity)) { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    continuation.yield(await self.event(from: result, remember: true))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func finish(_ transaction: StoreTransaction) async {
        if let cached = await cache.takeTransaction(transaction.id) {
            await cached.finish()
            return
        }
        for await result in Transaction.unfinished where result.unsafePayloadValue.id == transaction.id {
            await result.unsafePayloadValue.finish()
        }
    }

    public func sync() async throws {
        try await AppStore.sync()
    }

    private func event(from result: VerificationResult<Transaction>, remember: Bool, gracePeriodEnd: Date? = nil) async -> TransactionEvent {
        let transaction = result.unsafePayloadValue
        if remember {
            await cache.remember(transaction)
        }
        let value = StoreTransaction(transaction, signedTransaction: result.jwsRepresentation, gracePeriodEnd: gracePeriodEnd)
        switch result {
        case .verified:
            return TransactionEvent(transaction: value, verification: .verified)
        case .unverified(_, let error):
            return TransactionEvent(transaction: value, verification: .unverified(reason: String(describing: error)))
        }
    }

    @MainActor
    private static func showPurchaseSheet(for product: Product, options: Set<Product.PurchaseOption>) async throws -> Product.PurchaseResult {
        #if os(visionOS)
        // visionOS needs a scene to show the purchase sheet in.
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive }
        guard let scene else { throw StoreError.storeKit("There is no active window to show the purchase in.") }
        return try await product.purchase(confirmIn: scene, options: options)
        #else
        return try await product.purchase(options: options)
        #endif
    }
}

/// StoreKit objects kept to purchase and finish by identifier. Bounded, so unverified
/// transactions that are never finished cannot grow it without limit.
actor StoreKitCache {
    static let capacity = 256

    private var products: [String: Product] = [:]
    private var transactions: [UInt64: Transaction] = [:]
    private var transactionOrder: [UInt64] = []

    func remember(_ loaded: [Product]) {
        for product in loaded {
            products[product.id] = product
        }
    }

    func product(_ id: String) -> Product? {
        products[id]
    }

    func remember(_ transaction: Transaction) {
        if transactions.updateValue(transaction, forKey: transaction.id) == nil {
            transactionOrder.append(transaction.id)
        }
        while transactionOrder.count > Self.capacity {
            transactions[transactionOrder.removeFirst()] = nil
        }
    }

    func takeTransaction(_ id: UInt64) -> Transaction? {
        guard let transaction = transactions.removeValue(forKey: id) else { return nil }
        transactionOrder.removeAll { $0 == id }
        return transaction
    }
}

extension StoreProduct {
    /// Converts a StoreKit product; returns `nil` when its price cannot be an exact ``Money``.
    init?(product: Product) {
        guard let currency = try? Currency(product.priceFormatStyle.currencyCode),
              let price = (try? Money(product.price, currency)) ?? (try? Money(rounding: product.price, currency))
        else { return nil }

        let kind: Kind
        switch product.type {
        case .consumable: kind = .consumable
        case .nonConsumable: kind = .nonConsumable
        case .autoRenewable: kind = .autoRenewable
        default: kind = .nonRenewable
        }

        self.init(
            id: product.id,
            kind: kind,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            price: price,
            subscription: product.subscription.map { info in
                Subscription(
                    groupID: info.subscriptionGroupID,
                    period: SubscriptionPeriod(info.subscriptionPeriod),
                    hasIntroductoryOffer: info.introductoryOffer != nil
                )
            },
            isFamilyShareable: product.isFamilyShareable
        )
    }
}

extension SubscriptionPeriod {
    init(_ period: Product.SubscriptionPeriod) {
        let unit: Unit = switch period.unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        @unknown default: .month
        }
        self.init(period.value, unit)
    }
}

extension StoreTransaction {
    init(_ transaction: Transaction, signedTransaction: String, gracePeriodEnd: Date? = nil) {
        let kind: StoreProduct.Kind
        switch transaction.productType {
        case .consumable: kind = .consumable
        case .nonConsumable: kind = .nonConsumable
        case .autoRenewable: kind = .autoRenewable
        default: kind = .nonRenewable
        }
        self.init(
            id: transaction.id,
            originalID: transaction.originalID,
            productID: transaction.productID,
            productKind: kind,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            gracePeriodExpirationDate: gracePeriodEnd,
            revocationDate: transaction.revocationDate,
            isUpgraded: transaction.isUpgraded,
            isFamilyShared: transaction.ownershipType == .familyShared,
            purchasedQuantity: transaction.purchasedQuantity,
            environment: transaction.environment.rawValue,
            appAccountToken: transaction.appAccountToken,
            signedTransaction: signedTransaction
        )
    }
}
#endif
