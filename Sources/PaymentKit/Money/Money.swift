import Foundation

/// An exact amount of money in one currency.
///
/// `Money` stores whole minor units (cents, fils, yen) as an `Int64`, so it never rounds the
/// way `Double` does and always holds a value a payment provider accepts. Every way of creating
/// one checks its input: an amount with more decimals than the currency has, `Decimal.nan`, or
/// more than ``maximumMinorUnits`` minor units throws a ``MoneyError`` instead of being rounded
/// silently or trapping.
///
/// ```swift
/// let price = try Money("19.99", .usd)
/// let tax = try price.multiplied(by: Decimal(8) / 100) // 1.60, rounded half to even
/// let total = try price.adding(tax)                    // 21.59
/// total.minorUnits                                     // 2159, what a payment API expects
/// total.formatted(locale: Locale(identifier: "en_US")) // "$21.59"
/// try total.split(into: 3).map(\.minorUnits)           // [720, 720, 719]
/// ```
///
/// Write amounts as strings or minor units, not as floating-point literals: `19.99` as a
/// `Decimal` literal goes through `Double` and becomes `19.98999999999999488`, which
/// ``init(_:_:)-(Decimal,_)`` rejects because it has more than two decimals.
public struct Money: Hashable, Sendable {
    /// The amount in the currency's minor unit: cents for `USD`, yen for `JPY`.
    public let minorUnits: Int64

    /// The currency of the amount.
    public let currency: Currency

    /// The largest magnitude, in minor units, that `Money` holds: 999 999 999 999 999.
    ///
    /// The limit keeps every amount exact in `Decimal`, in `Int64` and in the 53-bit integers of
    /// JavaScript and JSON parsers, so the value a server reads is the value the app sent.
    public static let maximumMinorUnits: Int64 = 999_999_999_999_999

    /// The largest number of parts ``allocated(_:)`` and ``split(into:)`` create.
    public static let maximumAllocationParts = 1_000

    /// Creates an amount from minor units, for example `1999` cents for 19.99 US dollars.
    ///
    /// - Throws: ``MoneyError/outOfRange`` when the magnitude is above ``maximumMinorUnits``.
    public init(minorUnits: Int64, currency: Currency) throws(MoneyError) {
        guard minorUnits.magnitude <= Self.maximumMinorUnits.magnitude else { throw .outOfRange }
        self.minorUnits = minorUnits
        self.currency = currency
    }

    /// Creates an amount that must be exact in the currency.
    ///
    /// Pass a `Decimal` that was computed or parsed, not a floating-point literal; for literals
    /// use ``init(_:_:)-(String,_)``.
    ///
    /// - Throws: ``MoneyError/tooManyFractionDigits(currency:)`` for `19.999` US dollars,
    ///   ``MoneyError/notANumber`` for `Decimal.nan`, or ``MoneyError/outOfRange``.
    public init(_ amount: Decimal, _ currency: Currency) throws(MoneyError) {
        let scaled = try Self.scaledToMinorUnits(amount, currency)
        guard let units = Self.integralValue(of: scaled) else {
            throw .tooManyFractionDigits(currency: currency)
        }
        try self.init(minorUnits: units, currency: currency)
    }

    /// Creates an amount by rounding to the currency's minor unit, for example a computed price.
    ///
    /// - Parameter rule: How to round. The default rounds half to even, as banks do.
    /// - Throws: ``MoneyError/notANumber`` or ``MoneyError/outOfRange``.
    public init(
        rounding amount: Decimal,
        _ currency: Currency,
        rule: FloatingPointRoundingRule = .toNearestOrEven
    ) throws(MoneyError) {
        let scaled = try Self.scaledToMinorUnits(amount, currency)
        guard let units = Self.integralValue(of: Self.round(scaled, rule: rule)) else {
            throw .outOfRange
        }
        try self.init(minorUnits: units, currency: currency)
    }

    /// Zero in the given currency.
    public static func zero(_ currency: Currency) -> Money {
        Money(uncheckedMinorUnits: 0, currency: currency)
    }

    private init(uncheckedMinorUnits: Int64, currency: Currency) {
        self.minorUnits = uncheckedMinorUnits
        self.currency = currency
    }

    /// The amount in the currency's major unit, for example `19.99`.
    public var amount: Decimal {
        Decimal(
            sign: minorUnits < 0 ? .minus : .plus,
            exponent: -currency.minorUnitDigits,
            significand: Decimal(minorUnits.magnitude)
        )
    }

    /// Whether the amount is zero.
    public var isZero: Bool { minorUnits == 0 }

    /// Whether the amount is below zero, as in a refund.
    public var isNegative: Bool { minorUnits < 0 }

    /// The amount as `NSDecimalNumber`, for PassKit and other Foundation APIs.
    public var decimalNumber: NSDecimalNumber {
        NSDecimalNumber(decimal: amount)
    }
}

// MARK: - Arithmetic

extension Money {
    /// Adds an amount in the same currency.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(_:_:)`` or ``MoneyError/outOfRange``.
    public func adding(_ other: Money) throws(MoneyError) -> Money {
        try requireSameCurrency(other)
        return try Money(minorUnits: minorUnits + other.minorUnits, currency: currency)
    }

    /// Subtracts an amount in the same currency.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(_:_:)`` or ``MoneyError/outOfRange``.
    public func subtracting(_ other: Money) throws(MoneyError) -> Money {
        try requireSameCurrency(other)
        return try Money(minorUnits: minorUnits - other.minorUnits, currency: currency)
    }

    /// Multiplies by a factor such as a tax rate or quantity and rounds to the minor unit.
    ///
    /// - Throws: ``MoneyError/notANumber`` for a NaN factor, ``MoneyError/outOfRange``.
    public func multiplied(
        by factor: Decimal,
        rule: FloatingPointRoundingRule = .toNearestOrEven
    ) throws(MoneyError) -> Money {
        guard !factor.isNaN else { throw .notANumber }
        // A factor this large always overflows, and rejecting it first keeps Decimal finite.
        guard factor.magnitude <= Decimal(Self.maximumMinorUnits) else { throw .outOfRange }
        return try Money(rounding: amount * factor, currency, rule: rule)
    }

    /// The same amount with the opposite sign.
    public func negated() -> Money {
        Money(uncheckedMinorUnits: -minorUnits, currency: currency)
    }

    /// Adds amounts that are all in `currency`. An empty sequence adds up to zero.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(_:_:)`` or ``MoneyError/outOfRange``.
    public static func sum(_ values: some Sequence<Money>, in currency: Currency) throws(MoneyError) -> Money {
        var total = Money.zero(currency)
        for value in values {
            total = try total.adding(value)
        }
        return total
    }

    private func requireSameCurrency(_ other: Money) throws(MoneyError) {
        guard currency == other.currency else { throw .currencyMismatch(currency, other.currency) }
    }
}

// MARK: - Allocation

extension Money {
    /// Splits the amount into parts proportional to `ratios`, without losing a minor unit.
    ///
    /// Each part gets its share rounded down; the minor units left over go one at a time to the
    /// parts with the largest remainders, earlier parts first on a tie. The parts always add up
    /// to the original amount.
    ///
    /// ```swift
    /// try Money(100, .usd).allocated([1, 1, 1]).map(\.minorUnits) // [3334, 3333, 3333]
    /// ```
    ///
    /// - Throws: ``MoneyError/invalidRatios`` when `ratios` is empty, has more than
    ///   ``maximumAllocationParts`` values, has a negative value or adds up to zero.
    public func allocated(_ ratios: [Int]) throws(MoneyError) -> [Money] {
        guard (1...Self.maximumAllocationParts).contains(ratios.count) else { throw .invalidRatios }
        var ratioSum: UInt64 = 0
        for ratio in ratios {
            guard ratio >= 0 else { throw .invalidRatios }
            let (sum, overflow) = ratioSum.addingReportingOverflow(UInt64(ratio))
            guard !overflow else { throw .invalidRatios }
            ratioSum = sum
        }
        guard ratioSum > 0 else { throw .invalidRatios }

        let total = minorUnits.magnitude
        var shares: [UInt64] = []
        var remainders: [UInt64] = []
        for ratio in ratios {
            // total × ratio needs up to 113 bits; the quotient is at most `total`, so it fits.
            let product = total.multipliedFullWidth(by: UInt64(ratio))
            let (share, remainder) = ratioSum.dividingFullWidth(product)
            shares.append(share)
            remainders.append(remainder)
        }
        let leftover = Int(total - shares.reduce(0, +))
        let order = remainders.indices.sorted { remainders[$0] != remainders[$1] ? remainders[$0] > remainders[$1] : $0 < $1 }
        for index in order.prefix(leftover) {
            shares[index] += 1
        }
        let sign: Int64 = minorUnits < 0 ? -1 : 1
        return shares.map { Money(uncheckedMinorUnits: sign * Int64($0), currency: currency) }
    }

    /// Splits the amount into `parts` equal parts; the first parts get the leftover minor units.
    ///
    /// - Throws: ``MoneyError/invalidRatios`` when `parts` is outside
    ///   1...``maximumAllocationParts``.
    public func split(into parts: Int) throws(MoneyError) -> [Money] {
        guard (1...Self.maximumAllocationParts).contains(parts) else { throw .invalidRatios }
        return try allocated(Array(repeating: 1, count: parts))
    }
}

// MARK: - Decimal helpers

extension Money {
    private static func scaledToMinorUnits(_ amount: Decimal, _ currency: Currency) throws(MoneyError) -> Decimal {
        guard !amount.isNaN else { throw .notANumber }
        // Minor units are never smaller than the amount, so this bound is checked before
        // multiplying, while the Decimal cannot overflow yet.
        guard amount.magnitude <= Decimal(maximumMinorUnits) else { throw .outOfRange }
        let scaled = amount * Decimal(sign: .plus, exponent: currency.minorUnitDigits, significand: 1)
        // Values just below the next whole unit may still round down into range.
        guard scaled.magnitude < Decimal(maximumMinorUnits) + 1 else { throw .outOfRange }
        return scaled
    }

    /// The value as `Int64` when it is a whole number within ``maximumMinorUnits``, else `nil`.
    private static func integralValue(of value: Decimal) -> Int64? {
        guard !value.isNaN, value.magnitude <= Decimal(maximumMinorUnits) else { return nil }
        guard round(value, rule: .towardZero) == value else { return nil }
        // An integral Decimal within the bound prints as plain digits with an optional sign.
        return Int64(value.description)
    }

    static func round(_ value: Decimal, rule: FloatingPointRoundingRule) -> Decimal {
        var input = value
        var result = Decimal()
        let mode: NSDecimalNumber.RoundingMode
        switch rule {
        case .toNearestOrEven: mode = .bankers
        case .toNearestOrAwayFromZero: mode = .plain
        case .up: mode = .up
        case .down: mode = .down
        case .towardZero: mode = value < 0 ? .up : .down
        case .awayFromZero: mode = value < 0 ? .down : .up
        @unknown default: mode = .bankers
        }
        NSDecimalRound(&result, &input, 0, mode)
        return result
    }
}

// MARK: - Text

extension Money: CustomStringConvertible {
    /// The amount and code with a period separator, for example `"19.99 USD"`.
    public var description: String {
        "\(plainAmount) \(currency.code)"
    }

    /// The amount formatted for display, for example `"$19.99"` or `"19,99 €"`.
    ///
    /// Always shows exactly the currency's minor-unit digits.
    public func formatted(locale: Locale = .current) -> String {
        amount.formatted(
            .currency(code: currency.code)
                .locale(locale)
                .precision(.fractionLength(currency.minorUnitDigits))
        )
    }
}
