import Foundation

/// An Apple Pay payment request built from ``Money`` values and checked before it reaches
/// PassKit.
///
/// PassKit takes amounts as `NSDecimalNumber` and a currency code as a string, and shows an
/// error sheet (or nothing) when they do not fit together. `ApplePayRequest` keeps every amount
/// in the request's currency, adds up the total exactly, and reports problems as an
/// ``ApplePayRequestError`` you can test.
///
/// ```swift
/// var request = ApplePayRequest(
///     merchantIdentifier: "merchant.com.example.shop",
///     merchantName: "Example Shop",
///     countryCode: "US",
///     currency: .usd,
///     items: [
///         ApplePaySummaryItem("Coffee beans", try Money("18.00", .usd)),
///         ApplePaySummaryItem("Discount", try Money("-2.00", .usd))
///     ]
/// )
/// request.shippingMethods = [
///     ApplePayShippingMethod(id: "standard", label: "Standard", detail: "3–5 days", amount: try Money("4.99", .usd))
/// ]
/// try request.total()   // 20.99 USD: items plus the first shipping method
/// ```
public struct ApplePayRequest: Hashable, Sendable {
    /// The most summary items or shipping methods a request can have.
    public static let maximumItems = 50
    /// The longest label, merchant name or shipping detail.
    public static let maximumLabelLength = 128

    /// Your merchant identifier from the Apple Developer website, such as
    /// `"merchant.com.example.shop"`.
    public var merchantIdentifier: String
    /// The business name shown on the total line, as Apple's guidelines require.
    public var merchantName: String
    /// The two-letter ISO 3166 code of the country where the payment is processed.
    public var countryCode: String
    /// The currency of every amount in the request.
    public var currency: Currency
    /// The lines above the total: products, tax, discounts (negative amounts).
    public var items: [ApplePaySummaryItem]
    /// The shipping choices; the first one is selected when the sheet opens.
    public var shippingMethods: [ApplePayShippingMethod] = []
    /// The networks you accept. Apple Pay only shows cards of these networks.
    public var supportedNetworks: [ApplePayNetwork] = [.visa, .masterCard, .amex, .discover]
    /// The payment processing protocols and card types you support.
    public var capabilities: ApplePayCapabilities = .threeDSecure
    /// The billing contact fields the person must provide.
    public var requiredBillingFields: Set<ApplePayContactField> = []
    /// The shipping contact fields the person must provide.
    public var requiredShippingFields: Set<ApplePayContactField> = []

    public init(
        merchantIdentifier: String,
        merchantName: String,
        countryCode: String,
        currency: Currency,
        items: [ApplePaySummaryItem]
    ) {
        self.merchantIdentifier = merchantIdentifier
        self.merchantName = merchantName
        self.countryCode = countryCode
        self.currency = currency
        self.items = items
    }

    /// The amount the person pays: the items plus the shipping method's amount.
    ///
    /// - Parameter shippingMethodID: The selected shipping method; `nil` uses the first one.
    /// - Throws: ``ApplePayRequestError/currencyMismatch(label:)``,
    ///   ``ApplePayRequestError/unknownShippingMethod(_:)`` or
    ///   ``ApplePayRequestError/amountOutOfRange``.
    public func total(shippingMethodID: String? = nil) throws(ApplePayRequestError) -> Money {
        var amounts = items.map { (label: $0.label, amount: $0.amount) }
        if let shipping = try shippingMethod(withID: shippingMethodID) {
            amounts.append((shipping.label, shipping.amount))
        }
        var total = Money.zero(currency)
        for line in amounts {
            guard line.amount.currency == currency else { throw .currencyMismatch(label: line.label) }
            do {
                total = try total.adding(line.amount)
            } catch {
                throw .amountOutOfRange
            }
        }
        return total
    }

    /// Checks everything PassKit would reject or show wrongly.
    ///
    /// - Throws: The first ``ApplePayRequestError`` found.
    public func validate() throws(ApplePayRequestError) {
        guard Self.isValidMerchantIdentifier(merchantIdentifier) else { throw .invalidMerchantIdentifier }
        guard Self.isValidLabel(merchantName) else { throw .invalidLabel(merchantName.prefix(Self.maximumLabelLength).description) }
        guard countryCode.utf8.count == 2, countryCode.utf8.allSatisfy({ (0x41...0x5A).contains($0) }) else {
            throw .invalidCountryCode
        }
        guard !items.isEmpty else { throw .noItems }
        guard items.count <= Self.maximumItems, shippingMethods.count <= Self.maximumItems else { throw .tooManyItems }
        guard !supportedNetworks.isEmpty else { throw .noSupportedNetworks }
        for label in items.map(\.label) + shippingMethods.map(\.label) where !Self.isValidLabel(label) {
            throw .invalidLabel(String(label.prefix(Self.maximumLabelLength)))
        }
        for detail in shippingMethods.map(\.detail) where !Self.isValidLabel(detail, allowEmpty: true) {
            throw .invalidLabel(String(detail.prefix(Self.maximumLabelLength)))
        }
        var shippingIDs: Set<String> = []
        for method in shippingMethods {
            guard !method.id.isEmpty, method.id.utf8.count <= Self.maximumLabelLength, shippingIDs.insert(method.id).inserted else {
                throw .invalidShippingMethodID(String(method.id.prefix(Self.maximumLabelLength)))
            }
            guard !method.amount.isNegative else { throw .negativeShippingAmount(label: method.label) }
        }
        for method in shippingMethods {
            guard try total(shippingMethodID: method.id).isNegative == false else { throw .negativeTotal }
        }
        guard try total().isNegative == false else { throw .negativeTotal }
    }

    func shippingMethod(withID id: String?) throws(ApplePayRequestError) -> ApplePayShippingMethod? {
        guard let id else { return shippingMethods.first }
        guard let method = shippingMethods.first(where: { $0.id == id }) else {
            throw .unknownShippingMethod(String(id.prefix(Self.maximumLabelLength)))
        }
        return method
    }

    static func isValidMerchantIdentifier(_ identifier: String) -> Bool {
        let bytes = identifier.utf8
        guard bytes.count > "merchant.".utf8.count, bytes.count <= 255, identifier.hasPrefix("merchant.") else { return false }
        // Reverse-DNS characters only: letters, digits, dots, hyphens.
        return bytes.allSatisfy { $0.isASCIILetter || $0.isASCIIDigit || $0 == UInt8(ascii: ".") || $0 == UInt8(ascii: "-") }
    }

    static func isValidLabel(_ label: String, allowEmpty: Bool = false) -> Bool {
        // Bound the byte count first so a huge string is not walked character by character.
        guard label.utf8.count <= maximumLabelLength * 4, label.count <= maximumLabelLength else { return false }
        guard !label.unicodeScalars.contains(where: { $0.properties.generalCategory == .control }) else { return false }
        return allowEmpty || !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// One line of the payment sheet above the total.
public struct ApplePaySummaryItem: Hashable, Sendable {
    public var label: String
    public var amount: Money
    /// Whether the amount is an estimate that can change, such as a taxi fare.
    public var isPending: Bool

    public init(_ label: String, _ amount: Money, isPending: Bool = false) {
        self.label = label
        self.amount = amount
        self.isPending = isPending
    }
}

/// A shipping choice on the payment sheet.
public struct ApplePayShippingMethod: Hashable, Sendable, Identifiable {
    /// Your identifier, returned in ``ApplePayPayment/shippingMethodID``.
    public var id: String
    public var label: String
    /// A short description, such as the delivery time.
    public var detail: String
    public var amount: Money

    public init(id: String, label: String, detail: String, amount: Money) {
        self.id = id
        self.label = label
        self.detail = detail
        self.amount = amount
    }
}

/// A card network Apple Pay can accept.
public enum ApplePayNetwork: String, CaseIterable, Hashable, Sendable {
    case visa, masterCard, amex, discover, jcb, chinaUnionPay, maestro, interac, eftpos, mada
    case cartesBancaires, girocard, elo, mir
}

/// Payment processing protocols and card types a merchant supports.
public struct ApplePayCapabilities: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// 3-D Secure, required by most payment providers.
    public static let threeDSecure = ApplePayCapabilities(rawValue: 1 << 0)
    /// EMV, used mainly in China.
    public static let emv = ApplePayCapabilities(rawValue: 1 << 1)
    /// Credit cards. Without `credit` and `debit`, both are accepted.
    public static let credit = ApplePayCapabilities(rawValue: 1 << 2)
    /// Debit cards.
    public static let debit = ApplePayCapabilities(rawValue: 1 << 3)
}

/// A contact field the payment sheet asks for.
public enum ApplePayContactField: String, CaseIterable, Hashable, Sendable {
    case name, postalAddress, emailAddress, phoneNumber
}

/// A problem with an ``ApplePayRequest``.
public enum ApplePayRequestError: Error, Hashable, Sendable {
    /// The merchant identifier does not start with `merchant.` or has other characters than
    /// letters, digits, dots and hyphens.
    case invalidMerchantIdentifier
    /// The country code is not two upper-case letters.
    case invalidCountryCode
    /// The request has no summary items.
    case noItems
    /// The request has more than ``ApplePayRequest/maximumItems`` items or shipping methods.
    case tooManyItems
    /// No card networks were given.
    case noSupportedNetworks
    /// A label is empty, longer than ``ApplePayRequest/maximumLabelLength`` or has control
    /// characters. Holds the label, cut to the maximum length.
    case invalidLabel(String)
    /// An amount is in another currency than the request.
    case currencyMismatch(label: String)
    /// Two shipping methods share an identifier, or one is empty or too long.
    case invalidShippingMethodID(String)
    /// The selected shipping method is not in the request.
    case unknownShippingMethod(String)
    /// A shipping method costs less than zero.
    case negativeShippingAmount(label: String)
    /// The total is below zero.
    case negativeTotal
    /// The total is larger than ``Money/maximumMinorUnits``.
    case amountOutOfRange
}

extension ApplePayRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidMerchantIdentifier: "The merchant identifier must look like merchant.com.example.shop."
        case .invalidCountryCode: "The country code must be two upper-case letters, such as US."
        case .noItems: "The payment request has no items."
        case .tooManyItems: "The payment request has more than \(ApplePayRequest.maximumItems) items or shipping methods."
        case .noSupportedNetworks: "The payment request accepts no card networks."
        case .invalidLabel(let label): "The label “\(label)” is empty, too long or has control characters."
        case .currencyMismatch(let label): "“\(label)” is in a different currency than the payment request."
        case .invalidShippingMethodID(let id): "The shipping method identifier “\(id)” is empty, too long or used twice."
        case .unknownShippingMethod(let id): "There is no shipping method “\(id)”."
        case .negativeShippingAmount(let label): "The shipping method “\(label)” costs less than zero."
        case .negativeTotal: "The total is less than zero."
        case .amountOutOfRange: "The total is too large to process."
        }
    }
}
