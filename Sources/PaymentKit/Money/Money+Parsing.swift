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
        let decimal = try Self.strictDecimal(text, currency: currency)
        try self.init(decimal, currency)
    }

    /// Creates an amount from text a person typed in the given locale, such as `"1,234.50"` in
    /// the United States or `"1.234,50"` in Germany.
    ///
    /// Spaces around the number are ignored. Grouping separators (the locale's own, spaces and
    /// apostrophes) are accepted only where they group digits: before the decimal separator,
    /// with three digits after the last one and two or three between the others, and not after a
    /// leading `0`, as in `1,234,567` or the Indian `12,34,567`. So `"12,50"` in the United
    /// States or `"0.99"` and `"0.500"` in Germany, where the separator was meant as a decimal
    /// point, throws instead of becoming 100 or 1000 times larger. A period or comma the locale
    /// uses for neither, such as `"1.500"` in France, throws as well, because it could mean 1.50
    /// or 1500. Currency symbols, letters, exponents and a second decimal separator throw too.
    /// An amount with more decimals than the currency has throws instead of being rounded, so
    /// `"10.999"` dollars is reported to the person rather than charged as `11.00`.
    ///
    /// - Throws: ``MoneyError/invalidText``, ``MoneyError/tooManyFractionDigits(currency:)`` or
    ///   ``MoneyError/outOfRange``.
    public init(parsing text: String, currency: Currency, locale: Locale = .current) throws(MoneyError) {
        guard text.utf8.count <= Self.maximumTextLength else { throw .invalidText }
        let plain = try Self.plainNumber(
            from: text.trimmingCharacters(in: .whitespaces),
            decimalSeparator: locale.decimalSeparator ?? ".",
            groupingSeparator: locale.groupingSeparator ?? ","
        )
        let decimal = try Self.strictDecimal(plain, currency: currency)
        try self.init(decimal, currency)
    }

    /// Rewrites localized text as `-?digits(.digits)?`, checking where grouping separators are.
    /// Any other character throws, so only the locale's own decimal separator becomes a point.
    private static func plainNumber(
        from text: String,
        decimalSeparator: String,
        groupingSeparator: String
    ) throws(MoneyError) -> String {
        // Grouping characters people type or that formatters produce, besides the locale's own.
        let grouping: Set<Character> = [" ", "\u{00A0}", "\u{202F}", "'", "’"]
        var sign = ""
        var groups = [""]
        var fraction: String?
        for (offset, character) in text.enumerated() {
            if offset == 0, character == "-" || character == "\u{2212}" {
                sign = "-" // U+2212 is the minus sign some locales format negative numbers with.
            } else if String(character) == decimalSeparator, fraction == nil {
                fraction = ""
            } else if String(character) == groupingSeparator || grouping.contains(character) {
                guard fraction == nil else { throw .invalidText }
                groups.append("")
            } else if !character.isASCII || !character.isNumber {
                // A period or comma the locale does not use would otherwise reach strictDecimal,
                // which reads "." as a decimal point: "1.500" in France would become 1.50.
                throw .invalidText
            } else if fraction != nil {
                fraction?.append(character)
            } else {
                groups[groups.count - 1].append(character)
            }
        }
        guard hasDigitGroups(groups) else { throw .invalidText }
        return sign + groups.joined() + (fraction.map { ".\($0)" } ?? "")
    }

    // "12,50" in en_US or "0.99" and "0.500" in de_DE are decimals typed with the wrong
    // separator; reading the separator as grouping would charge 100 or 1000 times the amount.
    // No grouped number starts with 0, so a first group that does is never grouping.
    private static func hasDigitGroups(_ groups: [String]) -> Bool {
        guard groups.count > 1 else { return true }
        guard (1...3).contains(groups[0].count), groups[0].first != "0",
              groups[groups.count - 1].count == 3
        else { return false }
        return groups.dropFirst().dropLast().allSatisfy { (2...3).contains($0.count) }
    }

    /// The most significant digits a `Decimal` always holds exactly; it rounds longer numbers.
    static let maximumSignificantDigits = 38

    /// Parses `-?[0-9]+(\.[0-9]+)?` with ASCII digits only.
    ///
    /// A number with more than `maximumSignificantDigits` significant digits throws instead of
    /// being rounded by `Decimal`: ``MoneyError/outOfRange`` when its whole part alone is too
    /// large for any currency, else ``MoneyError/tooManyFractionDigits(currency:)``.
    static func strictDecimal(_ text: String, currency: Currency) throws(MoneyError) -> Decimal {
        let bytes = Array(text.utf8)
        guard (1...maximumTextLength).contains(bytes.count) else { throw .invalidText }
        var index = bytes.first == UInt8(ascii: "-") ? 1 : 0
        let integerStart = index
        while index < bytes.count, bytes[index].isASCIIDigit { index += 1 }
        let integerEnd = index
        guard integerEnd > integerStart else { throw .invalidText }
        if index < bytes.count {
            guard bytes[index] == UInt8(ascii: ".") else { throw .invalidText }
            index += 1
            let fractionStart = index
            while index < bytes.count, bytes[index].isASCIIDigit { index += 1 }
            guard index > fractionStart, index == bytes.count else { throw .invalidText }
        }
        let digits = bytes[integerStart...].filter { $0 != UInt8(ascii: ".") }
        let isZero = { (byte: UInt8) in byte == UInt8(ascii: "0") }
        let significant = digits.drop(while: isZero).reversed().drop(while: isZero).count
        if significant > maximumSignificantDigits {
            let wholeDigits = bytes[integerStart..<integerEnd].drop(while: isZero).count
            // A whole part with more digits than maximumMinorUnits is too large in any currency.
            throw wholeDigits > String(maximumMinorUnits).count ? .outOfRange : .tooManyFractionDigits(currency: currency)
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
