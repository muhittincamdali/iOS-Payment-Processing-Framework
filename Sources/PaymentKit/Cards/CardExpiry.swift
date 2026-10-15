import Foundation

/// The month and year printed on a card.
///
/// A card is valid through the last day of its expiry month, so `09/27` can be charged until
/// the end of September 2027. The month and year on a card are Gregorian, so the checks always
/// use the Gregorian calendar and take only the time zone from the calendar you pass; a device
/// set to the Japanese, Buddhist or Islamic calendar gets the same answer.
///
/// ```swift
/// let expiry = try CardExpiry(parsing: "09/27")
/// expiry.month                 // 9
/// expiry.year                  // 2027
/// try expiry.validate()        // throws .expired after September 2027
/// ```
public struct CardExpiry: Hashable, Sendable, Codable, CustomStringConvertible {
    /// The longest text ``init(parsing:)`` reads.
    public static let maximumInputLength = 16

    /// How many years ahead an expiry date can be before ``validate(at:calendar:)`` rejects it.
    public static let maximumYearsAhead = 20

    /// The month, 1 to 12.
    public let month: Int

    /// The four-digit year, 2000 to 2099.
    public let year: Int

    /// Creates an expiry date from a month and a two- or four-digit year.
    ///
    /// - Throws: ``CardValidationError/invalidMonth`` or ``CardValidationError/invalidYear``.
    public init(month: Int, year: Int) throws(CardValidationError) {
        guard (1...12).contains(month) else { throw .invalidMonth }
        let fullYear = (0...99).contains(year) ? 2000 + year : year
        guard (2000...2099).contains(fullYear) else { throw .invalidYear }
        self.month = month
        self.year = fullYear
    }

    /// Parses `MM/YY`, `MM/YYYY`, `M/YY`, `MMYY` or `MM / YY` as typed in an expiry field.
    ///
    /// - Throws: ``CardValidationError/invalidExpiryFormat``,
    ///   ``CardValidationError/invalidMonth`` or ``CardValidationError/invalidYear``.
    public init(parsing text: some StringProtocol) throws(CardValidationError) {
        guard text.utf8.count <= Self.maximumInputLength else { throw .invalidExpiryFormat }
        let compact = Substring(text.filter { $0 != " " })
        let parts = compact.split(separator: "/", omittingEmptySubsequences: false)
        let monthText: Substring
        let yearText: Substring
        switch parts.count {
        case 1 where compact.count == 4:
            monthText = compact.prefix(2)
            yearText = compact.suffix(2)
        case 2:
            monthText = parts[0]
            yearText = parts[1]
        default:
            throw .invalidExpiryFormat
        }
        guard (1...2).contains(monthText.count), [2, 4].contains(yearText.count),
              monthText.utf8.allSatisfy(\.isASCIIDigit), yearText.utf8.allSatisfy(\.isASCIIDigit),
              let month = Int(monthText), let year = Int(yearText)
        else { throw .invalidExpiryFormat }
        try self.init(month: month, year: year)
    }

    /// The first moment after the card stops being valid: the start of the following month.
    ///
    /// - Parameter calendar: Only its time zone is used; the date is Gregorian.
    public func endDate(in calendar: Calendar = .current) -> Date? {
        let nextMonth = month == 12 ? DateComponents(year: year + 1, month: 1, day: 1)
                                    : DateComponents(year: year, month: month + 1, day: 1)
        return Self.gregorian(in: calendar.timeZone).date(from: nextMonth)
    }

    /// Whether the card has expired at `date`.
    ///
    /// - Parameters:
    ///   - date: The moment to check, now by default.
    ///   - calendar: Only its time zone is used; the date is Gregorian.
    public func isExpired(at date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let end = endDate(in: calendar) else { return true }
        return date >= end
    }

    /// Checks that the card has not expired and that the year is plausible.
    ///
    /// - Parameters:
    ///   - date: The moment to check, now by default.
    ///   - calendar: Only its time zone is used; the date is Gregorian.
    /// - Throws: ``CardValidationError/expired`` or ``CardValidationError/expiryTooFarAhead``.
    public func validate(at date: Date = .now, calendar: Calendar = .current) throws(CardValidationError) {
        guard !isExpired(at: date, calendar: calendar) else { throw .expired }
        let currentYear = Self.gregorian(in: calendar.timeZone).component(.year, from: date)
        guard year <= currentYear + Self.maximumYearsAhead else { throw .expiryTooFarAhead }
    }

    // A card's 09/27 is Gregorian: read as a Buddhist year it ended in 1484 and as a year of the
    // current Japanese era it is centuries ahead, so the caller's calendar lends only its time zone.
    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// The expiry as printed on the card, `MM/YY`.
    public var description: String {
        let monthText = month < 10 ? "0\(month)" : "\(month)"
        let shortYear = year % 100
        return "\(monthText)/\(shortYear < 10 ? "0" : "")\(shortYear)"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        do {
            try self.init(parsing: text)
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: error.localizedDescription)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
