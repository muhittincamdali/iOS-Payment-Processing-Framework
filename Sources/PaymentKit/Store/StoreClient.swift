import Foundation

/// The App Store operations ``Store`` needs, so it can run against StoreKit in an app and
/// against ``TestStoreClient`` in tests and previews.
public protocol StoreClient: Sendable {
    /// Loads products from the App Store. Unknown identifiers are left out of the result.
    func products(for ids: Set<String>) async throws -> [StoreProduct]

    /// Shows the App Store purchase sheet for a product.
    func purchase(_ productID: String, options: PurchaseOptions) async throws -> PurchaseResult

    /// The latest transaction of every product the person currently owns or subscribes to.
    func currentEntitlements() async -> [TransactionEvent]

    /// Transactions that were never finished, for example because the app quit before the
    /// content was delivered.
    func unfinishedTransactions() async -> [TransactionEvent]

    /// Transactions that arrive outside a purchase call: renewals, refunds, Ask to Buy
    /// approvals and purchases on other devices.
    func transactionUpdates() -> AsyncStream<TransactionEvent>

    /// Tells the App Store the content was delivered, so the transaction is not sent again.
    func finish(_ transaction: StoreTransaction) async

    /// Asks the App Store for the person's purchases again; it may ask them to sign in.
    func sync() async throws
}

/// Options for one purchase.
public struct PurchaseOptions: Hashable, Sendable {
    /// The most units of a consumable one purchase can buy.
    public static let maximumQuantity = 10

    /// A UUID that links the purchase to your own account record, reported back in the
    /// transaction and in App Store Server Notifications.
    public var appAccountToken: UUID?
    /// How many units of a consumable to buy, 1 to ``maximumQuantity``.
    public var quantity: Int

    public init(appAccountToken: UUID? = nil, quantity: Int = 1) {
        self.appAccountToken = appAccountToken
        self.quantity = quantity
    }
}

/// What the purchase sheet returned.
public enum PurchaseResult: Hashable, Sendable {
    /// The App Store charged the person and returned a transaction.
    case completed(TransactionEvent)
    /// The purchase waits for approval (Ask to Buy) or for the person to act (for example,
    /// to update a payment method); the transaction arrives later through
    /// ``StoreClient/transactionUpdates()``.
    case pending
    /// The person closed the sheet.
    case cancelled
}

/// An error from ``Store``.
public enum StoreError: Error, Hashable, Sendable {
    /// The product identifier is not one the store loaded.
    case productNotFound(String)
    /// StoreKit could not verify the transaction's signature; nothing was granted.
    case verificationFailed(productID: String, reason: String)
    /// Another purchase is still showing; wait for it to finish.
    case purchaseInProgress
    /// The quantity is outside 1...``PurchaseOptions/maximumQuantity``, or above 1 for a
    /// product that is not a consumable.
    case invalidQuantity(Int)
    /// The `deliver` closure of ``Store`` threw; the transaction stays unfinished and is
    /// delivered again on the next ``Store/start()``. Holds the error's description.
    case deliveryFailed(transactionID: UInt64, reason: String)
    /// The App Store or the network failed; holds the system's description.
    case storeKit(String)
}

extension StoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .productNotFound(let id): "The product “\(id)” is not available."
        case .verificationFailed: "The App Store could not confirm this purchase, so nothing was unlocked."
        case .purchaseInProgress: "Another purchase is in progress."
        case .invalidQuantity(let quantity): "\(quantity) is not a quantity this product can be bought in."
        case .deliveryFailed: "The purchase went through but could not be delivered yet. It will be delivered the next time the app starts."
        case .storeKit(let description): description
        }
    }
}
