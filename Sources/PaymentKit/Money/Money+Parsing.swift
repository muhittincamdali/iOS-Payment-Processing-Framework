import Foundation

extension Money {
    /// The longest text the parsing initializers read. Longer input throws without being scanned.
    public static let maximumTextLength = 64

    /// Creates an amount from a plain decimal string such as `"19.99"` or `"-5"`.
    ///
    /// The string uses a period as the decimal separator and has no grouping, currency symbol,
    /// exponent or surrounding spaces. Use it for literals and for amounts from an API;
    /// use ``init(parsing:currency:locale:)`` for what a person typed.
    ///
    /// - Throws: ``MoneyError/invalidText``, ``MoneyError/tooManyFractionDigits(currency:)`` or
    ///   ``MoneyError/outOfRange``.
    public init(_ text: String, _ currency: Currency) throws(MoneyError) {
        let decimal = try Self.strictDecimal(text)
        try self.init(decimal, currency)
    }

    /// Creates an amount from text a person typed in the given locale, such as `"1,234.50"` in
    /// the United States or `"1.234,50"` in Germany.
    ///
    /// Spaces around the number and the locale's grouping separators are ignored; currency
    /// symbols, letters, exponents and a second decimal separator are not. An amount with more
    /// decimals than the currency has throws instead of being rounded, so `"10.999"` dollars is
    /// reported to the person rather than charged as `11.00`.
    ///
    /// - Throws: ``MoneyError/invalidText``, ``MoneyError/tooManyFractionDigits(currency:)`` or
    ///   ``MoneyError/outOfRange``.
    public init(parsing text: String, currency: Currency, locale: Locale = .current) throws(MoneyError) {
        guard text.utf8.count <= Self.maximumTextLength else { throw .invalidText }
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ","
        // Grouping characters people type or that formatters produce, besides the locale's own.
        let ignored: Set<Character> = [" ", "\u{00A0}", "\u{202F}", "'", "’"]

        var normalized = ""
        for character in text.trimmingCharacters(in: .whitespaces) {
            if character == "\u{2212}" {
                // The minus sign some locales format negative numbers with.
                normalized.append("-")
            } else if String(character) == decimalSeparator {
                normalized.append(".")
            } else if String(character) == groupingSeparator || ignored.contains(character) {
                continue
            } else {
                normalized.append(character)
            }
        }
        let decimal = try Self.strictDecimal(normalized)
        try self.init(decimal, currency)
    }

    /// Parses `-?[0-9]+(\.[0-9]+)?` with ASCII digits only.
    static func strictDecimal(_ text: String) throws(MoneyError) -> Decimal {
        let bytes = Array(text.utf8)
        guard (1...maximumTextLength).contains(bytes.count) else { throw .invalidText }
        var index = bytes.first == UInt8(ascii: "-") ? 1 : 0
        let integerStart = index
        while index < bytes.count, bytes[index].isASCIIDigit { index += 1 }
        guard index > integerStart else { throw .invalidText }
        if index < bytes.count {
            guard bytes[index] == UInt8(ascii: ".") else { throw .invalidText }
            index += 1
            let fractionStart = index
            while index < bytes.count, bytes[index].isASCIIDigit { index += 1 }
            guard index > fractionStart, index == bytes.count else { throw .invalidText }
        }
        guard let decimal = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) else {
            throw .invalidText
        }
        return decimal
    }
}

extension Money: Codable {
    private enum CodingKeys: String, CodingKey {
        case amount
        case currency
    }

    /// Decodes `{"amount": "19.99", "currency": "USD"}` and checks the amount like
    /// ``init(_:_:)-(String,_)``, so malformed or out-of-range JSON fails to decode.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let currency = try container.decode(Currency.self, forKey: .currency)
        let text = try container.decode(String.self, forKey: .amount)
        do {
            try self.init(text, currency)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: container,
                debugDescription: error.localizedDescription
            )
        }
    }

    /// Encodes the amount as a decimal string so no JSON parser turns it into a `Double`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(plainAmount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
    }

    /// The amount as a plain decimal string with exactly the currency's digits, like `"19.99"`.
    public var plainAmount: String {
        let digits = currency.minorUnitDigits
        let magnitude = minorUnits.magnitude
        let sign = minorUnits < 0 ? "-" : ""
        guard digits > 0 else { return "\(sign)\(magnitude)" }
        var divisor: UInt64 = 1
        for _ in 0..<digits { divisor *= 10 }
        let fraction = String(magnitude % divisor)
        let padded = String(repeating: "0", count: digits - fraction.count) + fraction
        return "\(sign)\(magnitude / divisor).\(padded)"
    }
}
