import Foundation

/// An ISO 4217 currency and the number of digits after its decimal separator.
///
/// The number of minor-unit digits decides how amounts are stored and sent to a payment
/// provider: `12.34` US dollars are `1234` cents, but `1234` Japanese yen have no minor unit,
/// and `1.234` Kuwaiti dinars are `1234` fils.
///
/// ```swift
/// let euro = try Currency("eur")      // codes are upper-cased
/// euro.code                           // "EUR"
/// euro.minorUnitDigits                // 2
/// try Currency("JPY").minorUnitDigits // 0
/// ```
public struct Currency: Hashable, Sendable, CustomStringConvertible {
    /// The three-letter ISO 4217 code, for example `"USD"`.
    public let code: String

    /// The number of digits after the decimal separator, from 0 to ``maximumMinorUnitDigits``.
    public let minorUnitDigits: Int

    /// The largest number of minor-unit digits a currency can have. ISO 4217 uses at most 4.
    public static let maximumMinorUnitDigits = 4

    /// Creates a currency from its ISO 4217 code and takes the number of minor-unit digits from
    /// the ISO 4217 list.
    ///
    /// - Parameter code: Three letters, upper or lower case, such as `"usd"` or `"TRY"`.
    /// - Throws: ``MoneyError/invalidCurrencyCode(_:)`` when the code is not three ASCII letters.
    public init(_ code: String) throws(MoneyError) {
        let normalized = try Self.normalizedCode(code)
        self.code = normalized
        self.minorUnitDigits = Self.isoMinorUnitDigits[normalized] ?? 2
    }

    /// Creates a currency with an explicit number of minor-unit digits, for codes whose digits
    /// differ from the ISO 4217 list your app was built with.
    ///
    /// - Throws: ``MoneyError/invalidCurrencyCode(_:)`` for a malformed code, or
    ///   ``MoneyError/invalidMinorUnitDigits(_:)`` when `minorUnitDigits` is outside 0...4.
    public init(_ code: String, minorUnitDigits: Int) throws(MoneyError) {
        guard (0...Self.maximumMinorUnitDigits).contains(minorUnitDigits) else {
            throw .invalidMinorUnitDigits(minorUnitDigits)
        }
        self.code = try Self.normalizedCode(code)
        self.minorUnitDigits = minorUnitDigits
    }

    private init(validCode: String, digits: Int) {
        self.code = validCode
        self.minorUnitDigits = digits
    }

    public var description: String { code }

    private static func normalizedCode(_ code: String) throws(MoneyError) -> String {
        // Check the length before upper-casing so a long string is never copied.
        guard code.utf8.count == 3, code.utf8.allSatisfy({ $0.isASCIILetter }) else {
            throw .invalidCurrencyCode(String(code.prefix(8)))
        }
        return code.uppercased()
    }

    /// Currencies whose ISO 4217 minor unit is not 2. Every other code uses 2 digits.
    static let isoMinorUnitDigits: [String: Int] = [
        // No minor unit.
        "BIF": 0, "CLP": 0, "DJF": 0, "GNF": 0, "ISK": 0, "JPY": 0, "KMF": 0, "KRW": 0,
        "PYG": 0, "RWF": 0, "UGX": 0, "UYI": 0, "VND": 0, "VUV": 0, "XAF": 0, "XOF": 0,
        "XPF": 0,
        // Three digits.
        "BHD": 3, "IQD": 3, "JOD": 3, "KWD": 3, "LYD": 3, "OMR": 3, "TND": 3,
        // Four digits.
        "CLF": 4, "UYW": 4
    ]
}

extension Currency {
    /// US dollar, 2 digits.
    public static let usd = Currency(validCode: "USD", digits: 2)
    /// Euro, 2 digits.
    public static let eur = Currency(validCode: "EUR", digits: 2)
    /// Pound sterling, 2 digits.
    public static let gbp = Currency(validCode: "GBP", digits: 2)
    /// Japanese yen, no minor unit.
    public static let jpy = Currency(validCode: "JPY", digits: 0)
    /// Turkish lira, 2 digits.
    public static let `try` = Currency(validCode: "TRY", digits: 2)
    /// Kuwaiti dinar, 3 digits.
    public static let kwd = Currency(validCode: "KWD", digits: 3)
}

extension Currency: Codable {
    /// Decodes a currency from its code; the minor-unit digits come from the ISO 4217 list.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        do {
            try self.init(code)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: error.localizedDescription
            )
        }
    }

    /// Encodes the currency as its three-letter code.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }
}

extension UInt8 {
    var isASCIILetter: Bool {
        (0x41...0x5A).contains(self) || (0x61...0x7A).contains(self)
    }

    var isASCIIDigit: Bool {
        (0x30...0x39).contains(self)
    }
}
