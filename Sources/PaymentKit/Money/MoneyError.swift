import Foundation

/// An amount or currency that cannot be used for a payment.
public enum MoneyError: Error, Hashable, Sendable {
    /// The currency code is not three ASCII letters. Holds at most the first 8 characters.
    case invalidCurrencyCode(String)
    /// The number of minor-unit digits is outside 0...4.
    case invalidMinorUnitDigits(Int)
    /// The amount is not a number (`Decimal.nan`).
    case notANumber
    /// The amount has more digits after the decimal separator than the currency allows,
    /// for example `1.005` US dollars or `10.5` yen.
    case tooManyFractionDigits(currency: Currency)
    /// The amount is larger than ``Money/maximumMinorUnits`` minor units.
    case outOfRange
    /// Two amounts in different currencies were combined.
    case currencyMismatch(Currency, Currency)
    /// Text that was parsed as an amount is not a plain number in the given locale.
    case invalidText
    /// The ratios given to ``Money/allocated(_:)`` are empty, negative, too many or sum to zero.
    case invalidRatios
}

extension MoneyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCurrencyCode(let code):
            "“\(code)” is not a three-letter ISO 4217 currency code."
        case .invalidMinorUnitDigits(let digits):
            "A currency has 0 to 4 minor-unit digits, not \(digits)."
        case .notANumber:
            "The amount is not a number."
        case .tooManyFractionDigits(let currency):
            "\(currency.code) amounts have at most \(currency.minorUnitDigits) digits after the decimal separator."
        case .outOfRange:
            "The amount is too large to process."
        case .currencyMismatch(let lhs, let rhs):
            "Amounts in \(lhs.code) and \(rhs.code) cannot be combined."
        case .invalidText:
            "The text is not an amount."
        case .invalidRatios:
            "Allocation ratios must be 1 to \(Money.maximumAllocationParts) non-negative numbers with a positive sum."
        }
    }
}
