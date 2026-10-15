import Foundation

/// Why card details that a person entered cannot be used.
///
/// The cases never contain the digits that were entered, so an error can be logged or sent to
/// analytics without leaking a card number or security code.
public enum CardValidationError: Error, Hashable, Sendable {
    /// Nothing was entered.
    case empty
    /// The text has characters other than digits, spaces and dashes, or is longer than
    /// ``CardNumber/maximumInputLength``.
    case invalidCharacters
    /// The number has a length the brand does not issue.
    case invalidLength(CardBrand)
    /// The last digit does not match the Luhn check digit, which usually means a typo.
    case failedChecksum
    /// The expiry text is not `MM/YY` or `MM/YYYY`.
    case invalidExpiryFormat
    /// The expiry month is not 1 to 12.
    case invalidMonth
    /// The expiry year is outside 2000 to 2099.
    case invalidYear
    /// The card expired before the date it was checked against.
    case expired
    /// The expiry date is further away than ``CardExpiry/maximumYearsAhead`` years.
    case expiryTooFarAhead
    /// The security code is not the number of digits the brand prints on the card.
    case invalidSecurityCode(expectedLength: Int)
}

extension CardValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .empty: "Enter the card number."
        case .invalidCharacters: "A card number has only digits."
        case .invalidLength(let brand): "This isn't a valid \(brand.displayName) number length."
        case .failedChecksum: "Check the card number for a typo."
        case .invalidExpiryFormat: "Enter the expiry date as MM/YY."
        case .invalidMonth: "The expiry month must be 01 to 12."
        case .invalidYear: "Enter a valid expiry year."
        case .expired: "This card has expired."
        case .expiryTooFarAhead: "Check the expiry year."
        case .invalidSecurityCode(let length): "The security code has \(length) digits."
        }
    }
}
