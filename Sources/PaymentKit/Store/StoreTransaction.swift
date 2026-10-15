import Foundation

/// A purchase, renewal or refund from the App Store, as a value.
public struct StoreTransaction: Identifiable, Hashable, Sendable {
    /// The transaction identifier.
    public let id: UInt64
    /// The identifier of the first purchase; renewals and restores share it.
    public let originalID: UInt64
    public let productID: String
    public let productKind: StoreProduct.Kind
    public let purchaseDate: Date
    /// When a subscription period ends; `nil` for other products.
    public let expirationDate: Date?
    /// When the App Store refunded or revoked the purchase; access must end.
    public let revocationDate: Date?
    /// Whether the person moved to a higher subscription in the same group.
    public let isUpgraded: Bool
    /// Whether a family member bought it and Family Sharing shares it.
    public let isFamilyShared: Bool
    /// How many units of a consumable were bought, 1 to ``PurchaseOptions/maximumQuantity``.
    ///
    /// Values outside StoreKit's limit are clamped, so `coins * purchasedQuantity` cannot
    /// overflow on a malformed transaction.
    public let purchasedQuantity: Int
    /// `"Production"`, `"Sandbox"` or `"Xcode"`, as the App Store reports it.
    public let environment: String
    /// The UUID your app passed when purchasing, to link the purchase to an account.
    public let appAccountToken: UUID?
    /// The signed transaction (JWS) to send to your server, which verifies it with
    /// App Store Server Library before it grants anything.
    public let signedTransaction: String

    public init(
        id: UInt64,
        originalID: UInt64? = nil,
        productID: String,
        productKind: StoreProduct.Kind,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil,
        isUpgraded: Bool = false,
        isFamilyShared: Bool = false,
        purchasedQuantity: Int = 1,
        environment: String = "Xcode",
        appAccountToken: UUID? = nil,
        signedTransaction: String = ""
    ) {
        self.id = id
        self.originalID = originalID ?? id
        self.productID = productID
        self.productKind = productKind
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isUpgraded = isUpgraded
        self.isFamilyShared = isFamilyShared
        self.purchasedQuantity = min(max(purchasedQuantity, 1), PurchaseOptions.maximumQuantity)
        self.environment = environment
        self.appAccountToken = appAccountToken
        self.signedTransaction = signedTransaction
    }
}

/// A transaction together with the result of StoreKit's signature check.
public struct TransactionEvent: Hashable, Sendable {
    /// Whether StoreKit could verify the App Store's signature.
    public enum Verification: Hashable, Sendable {
        case verified
        /// The signature or device check failed; never grant content for it.
        case unverified(reason: String)
    }

    public let transaction: StoreTransaction
    public let verification: Verification

    public init(transaction: StoreTransaction, verification: Verification) {
        self.transaction = transaction
        self.verification = verification
    }

    public var isVerified: Bool { verification == .verified }
}
