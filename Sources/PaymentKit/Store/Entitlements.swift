import Foundation

/// A product your app sells and the access it unlocks.
///
/// ```swift
/// let catalog: [ProductDefinition] = [
///     .autoRenewable("pro.monthly", unlocks: "pro"),
///     .autoRenewable("pro.yearly", unlocks: "pro"),
///     .nonConsumable("pro.lifetime", unlocks: "pro"),
///     .nonRenewing("season.pass", unlocks: "season", lasts: SubscriptionPeriod(3, .month)),
///     .consumable("coins.100")
/// ]
/// ```
public struct ProductDefinition: Hashable, Sendable {
    /// The product identifier from App Store Connect.
    public let id: String
    /// The entitlement the product grants, or `nil` for consumables.
    public let entitlement: String?
    /// How long a non-renewing subscription lasts after its purchase date.
    public let duration: SubscriptionPeriod?

    /// A consumable, such as coins; it unlocks nothing by itself. Deliver it in the
    /// `deliver` closure of ``Store``.
    public static func consumable(_ id: String) -> ProductDefinition {
        ProductDefinition(id: id, entitlement: nil, duration: nil)
    }

    /// A one-time purchase that unlocks `entitlement` for good.
    public static func nonConsumable(_ id: String, unlocks entitlement: String) -> ProductDefinition {
        ProductDefinition(id: id, entitlement: entitlement, duration: nil)
    }

    /// An auto-renewable subscription that unlocks `entitlement` until it expires.
    public static func autoRenewable(_ id: String, unlocks entitlement: String) -> ProductDefinition {
        ProductDefinition(id: id, entitlement: entitlement, duration: nil)
    }

    /// A non-renewing subscription. StoreKit reports no expiration date for these, so the
    /// access ends `duration` after the purchase date.
    public static func nonRenewing(_ id: String, unlocks entitlement: String, lasts duration: SubscriptionPeriod) -> ProductDefinition {
        ProductDefinition(id: id, entitlement: entitlement, duration: duration)
    }
}

/// Access the person has now, granted by a verified transaction.
public struct Entitlement: Identifiable, Hashable, Sendable {
    /// The entitlement name from ``ProductDefinition``, such as `"pro"`.
    public let name: String
    /// The product that grants it.
    public let productID: String
    /// The transaction that grants it.
    public let transactionID: UInt64
    /// When access ends; `nil` for a lifetime purchase.
    public let expirationDate: Date?
    /// Whether it comes from a family member through Family Sharing.
    public let isFamilyShared: Bool

    public var id: String { name }

    public init(name: String, productID: String, transactionID: UInt64, expirationDate: Date?, isFamilyShared: Bool) {
        self.name = name
        self.productID = productID
        self.transactionID = transactionID
        self.expirationDate = expirationDate
        self.isFamilyShared = isFamilyShared
    }
}

/// Decides which entitlements a set of transactions grants at a point in time.
///
/// The rules, applied to verified transactions only:
/// - refunded or revoked transactions grant nothing;
/// - a subscription that was upgraded grants nothing (the higher one does);
/// - auto-renewable subscriptions grant access until their expiration date;
/// - non-renewing subscriptions grant access for their ``ProductDefinition/duration`` after
///   the purchase date;
/// - non-consumables grant access with no end;
/// - consumables and products missing from the catalog grant nothing.
///
/// When several transactions grant the same entitlement, the one without an end wins, then
/// the one that ends last.
public struct EntitlementResolver: Sendable {
    private let definitions: [String: ProductDefinition]
    private let calendar: Calendar

    public init(catalog: [ProductDefinition], calendar: Calendar = Calendar(identifier: .gregorian)) {
        // The first definition of a product identifier wins.
        self.definitions = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.calendar = calendar
    }

    /// The entitlements active at `date`, sorted by name.
    public func entitlements(from events: [TransactionEvent], at date: Date) -> [Entitlement] {
        var best: [String: Entitlement] = [:]
        for event in events where event.isVerified {
            guard let entitlement = entitlement(for: event.transaction, at: date) else { continue }
            if let current = best[entitlement.name], !Self.isBetter(entitlement, than: current) { continue }
            best[entitlement.name] = entitlement
        }
        return best.values.sorted { $0.name < $1.name }
    }

    private func entitlement(for transaction: StoreTransaction, at date: Date) -> Entitlement? {
        guard let definition = definitions[transaction.productID], let name = definition.entitlement else { return nil }
        guard transaction.revocationDate == nil, !transaction.isUpgraded else { return nil }

        let expiration: Date?
        switch transaction.productKind {
        case .consumable:
            return nil
        case .nonConsumable:
            expiration = nil
        case .autoRenewable:
            guard let end = transaction.expirationDate else { return nil }
            expiration = end
        case .nonRenewable:
            guard let duration = definition.duration,
                  let end = duration.date(after: transaction.purchaseDate, calendar: calendar)
            else { return nil }
            expiration = end
        }
        if let expiration, expiration <= date { return nil }
        return Entitlement(
            name: name,
            productID: transaction.productID,
            transactionID: transaction.id,
            expirationDate: expiration,
            isFamilyShared: transaction.isFamilyShared
        )
    }

    private static func isBetter(_ candidate: Entitlement, than current: Entitlement) -> Bool {
        switch (candidate.expirationDate, current.expirationDate) {
        case (nil, nil): candidate.isFamilyShared == false && current.isFamilyShared
        case (nil, _): true
        case (_, nil): false
        case (let lhs?, let rhs?): lhs > rhs
        }
    }
}
