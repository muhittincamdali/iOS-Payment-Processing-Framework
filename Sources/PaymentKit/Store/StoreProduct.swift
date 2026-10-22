import Foundation

/// A product from the App Store, as a value you can show, compare and test with.
public struct StoreProduct: Identifiable, Hashable, Sendable {
    /// The kind of in-app purchase.
    public enum Kind: String, Hashable, Sendable, Codable {
        /// Used up and bought again, such as coins.
        case consumable
        /// Bought once and kept, such as a lifetime unlock.
        case nonConsumable
        /// A subscription the App Store renews until it is cancelled.
        case autoRenewable
        /// A subscription with a fixed length that your app tracks.
        case nonRenewable
    }

    /// The product identifier from App Store Connect.
    public let id: String
    public let kind: Kind
    /// The localized name from App Store Connect.
    public let displayName: String
    /// The localized description from App Store Connect.
    public let description: String
    /// The price formatted for the person's storefront, for example `"$4.99"`.
    public let displayPrice: String
    /// The price as an exact amount in the storefront's currency.
    public let price: Money
    /// The subscription details, for ``Kind-swift.enum/autoRenewable`` products.
    public let subscription: Subscription?
    /// Whether Family Sharing can share the purchase.
    public let isFamilyShareable: Bool

    public init(
        id: String,
        kind: Kind,
        displayName: String,
        description: String = "",
        displayPrice: String? = nil,
        price: Money,
        subscription: Subscription? = nil,
        isFamilyShareable: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice ?? price.formatted()
        self.price = price
        self.subscription = subscription
        self.isFamilyShareable = isFamilyShareable
    }

    /// The subscription group and renewal period of an auto-renewable subscription.
    public struct Subscription: Hashable, Sendable {
        /// The subscription group identifier from App Store Connect.
        public let groupID: String
        /// How long one period lasts.
        public let period: SubscriptionPeriod
        /// Whether the person can redeem the introductory offer, when the product has one.
        public let hasIntroductoryOffer: Bool

        public init(groupID: String, period: SubscriptionPeriod, hasIntroductoryOffer: Bool = false) {
            self.groupID = groupID
            self.period = period
            self.hasIntroductoryOffer = hasIntroductoryOffer
        }
    }
}

/// A length of time in calendar units, such as 1 month or 3 days.
public struct SubscriptionPeriod: Hashable, Sendable, Codable, CustomStringConvertible {
    public enum Unit: String, Hashable, Sendable, Codable {
        case day, week, month, year
    }

    /// The largest number of units a period can have; App Store periods use at most 12.
    public static let maximumValue = 1_000

    public let value: Int
    public let unit: Unit

    /// Creates a period such as `SubscriptionPeriod(1, .month)`.
    ///
    /// The value is clamped to 1 through ``maximumValue``, so a period always moves a date
    /// forward and never overflows a calendar calculation.
    public init(_ value: Int, _ unit: Unit) {
        self.value = min(max(value, 1), Self.maximumValue)
        self.unit = unit
    }

    /// The date one period after `date`, or `nil` when the calendar cannot represent it.
    public func date(after date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date? {
        let component: Calendar.Component = switch unit {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
        return calendar.date(byAdding: component, value: value, to: date)
    }

    public var description: String {
        "\(value) \(unit.rawValue)\(value == 1 ? "" : "s")"
    }

    private enum CodingKeys: String, CodingKey {
        case value, unit
    }

    /// Decodes `{"value": 1, "unit": "month"}` and clamps the value like ``init(_:_:)``.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(try container.decode(Int.self, forKey: .value), try container.decode(Unit.self, forKey: .unit))
    }
}
