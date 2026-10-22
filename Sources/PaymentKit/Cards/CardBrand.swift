/// A card network, detected from the first digits of a card number.
public enum CardBrand: String, CaseIterable, Hashable, Sendable, Codable {
    case visa
    case mastercard
    case americanExpress
    case discover
    case jcb
    case dinersClub
    case unionPay
    case maestro
    case mir
    /// A number whose first digits match none of the networks above.
    case unknown

    /// The name to show, for example `"American Express"`.
    public var displayName: String {
        switch self {
        case .visa: "Visa"
        case .mastercard: "Mastercard"
        case .americanExpress: "American Express"
        case .discover: "Discover"
        case .jcb: "JCB"
        case .dinersClub: "Diners Club"
        case .unionPay: "UnionPay"
        case .maestro: "Maestro"
        case .mir: "Mir"
        case .unknown: "Card"
        }
    }

    /// The number lengths the network issues.
    public var validLengths: Set<Int> {
        switch self {
        case .visa: [13, 16, 19]
        case .mastercard, .mir: [16]
        case .americanExpress: [15]
        case .discover, .jcb, .unionPay: Set(16...19)
        case .dinersClub: Set(14...19)
        case .maestro, .unknown: Set(12...19)
        }
    }

    /// The length of the security code (CVC, CVV or CID) printed on the card.
    public var securityCodeLength: Int {
        self == .americanExpress ? 4 : 3
    }

    /// Whether the last digit is a Luhn check digit. Some UnionPay numbers have none.
    public var usesLuhnCheck: Bool {
        self != .unionPay
    }

    /// The sizes of the digit groups shown on the card, for a number of the given length.
    public func groupSizes(forLength length: Int) -> [Int] {
        switch (self, length) {
        case (.americanExpress, _): [4, 6, 5]
        case (.dinersClub, 14): [4, 6, 4]
        default: Array(repeating: 4, count: (length + 3) / 4)
        }
    }

    /// The brand for the leading digits of a card number, as far as they decide it.
    ///
    /// - Parameter digits: ASCII digits; only the first 6 are read.
    public static func detect(fromLeadingDigits digits: some StringProtocol) -> CardBrand {
        let prefix = digits.utf8.prefix(6)
        guard !prefix.isEmpty, prefix.allSatisfy(\.isASCIIDigit) else { return .unknown }
        for rule in rules {
            guard prefix.count >= rule.length else { continue }
            let value = prefix.prefix(rule.length).reduce(0) { $0 * 10 + Int($1 - 0x30) }
            if rule.range.contains(value) { return rule.brand }
        }
        return .unknown
    }

    /// Prefix ranges in the order they are checked; narrower ranges come before wider ones.
    private static let rules: [(brand: CardBrand, length: Int, range: ClosedRange<Int>)] = [
        (.discover, 6, 622_126...622_925),
        (.mir, 4, 2200...2204),
        (.maestro, 4, 5018...5018), (.maestro, 4, 5020...5020), (.maestro, 4, 5038...5038),
        (.maestro, 4, 5893...5893), (.maestro, 4, 6304...6304), (.maestro, 4, 6759...6759),
        (.maestro, 4, 6761...6763),
        (.discover, 4, 6011...6011),
        (.mastercard, 4, 2221...2720),
        (.jcb, 4, 3528...3589),
        (.dinersClub, 3, 300...305),
        (.discover, 3, 644...649),
        (.americanExpress, 2, 34...34), (.americanExpress, 2, 37...37),
        (.dinersClub, 2, 36...36), (.dinersClub, 2, 38...39),
        (.mastercard, 2, 51...55),
        (.discover, 2, 65...65),
        (.unionPay, 2, 62...62), (.unionPay, 2, 81...81),
        (.visa, 1, 4...4)
    ]
}
