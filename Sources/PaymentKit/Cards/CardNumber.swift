/// A card number that passed validation and never prints in full.
///
/// `print`, string interpolation, `dump`, `Mirror`, the debugger and error messages all show
/// the masked form, `•••• 4242`. The full number is only available through ``unmaskedDigits``,
/// a name that stands out in code review, for handing it to your payment provider's
/// tokenization API. `CardNumber` is not `Codable`, so it cannot end up in a saved file or a
/// JSON body by accident.
///
/// ```swift
/// let card = try CardNumber("4242 4242 4242 4242")
/// card.brand          // .visa
/// print(card)         // •••• 4242
/// card.last4          // "4242"
/// ```
///
/// Collecting card numbers in your own interface puts the app in scope for PCI DSS. Most apps
/// use their provider's card field or Apple Pay instead; see <doc:AcceptingCards>.
public struct CardNumber: Hashable, Sendable {
    /// The longest text the initializer reads: 19 digits with a separator between each.
    public static let maximumInputLength = 40

    private let digits: String

    /// The network the number belongs to.
    public let brand: CardBrand

    /// Validates a card number as typed or pasted, with or without spaces and dashes.
    ///
    /// - Throws: ``CardValidationError/empty``, ``CardValidationError/invalidCharacters``,
    ///   ``CardValidationError/invalidLength(_:)`` or ``CardValidationError/failedChecksum``.
    public init(_ text: some StringProtocol) throws(CardValidationError) {
        guard text.utf8.count <= Self.maximumInputLength else { throw .invalidCharacters }
        var digits = ""
        for byte in text.utf8 {
            if byte.isASCIIDigit {
                digits.unicodeScalars.append(Unicode.Scalar(byte))
            } else if byte != UInt8(ascii: " ") && byte != UInt8(ascii: "-") {
                throw .invalidCharacters
            }
        }
        guard !digits.isEmpty else { throw .empty }
        let brand = CardBrand.detect(fromLeadingDigits: digits)
        guard brand.validLengths.contains(digits.utf8.count) else { throw .invalidLength(brand) }
        guard !brand.usesLuhnCheck || Self.passesLuhnCheck(digits) else { throw .failedChecksum }
        self.digits = digits
        self.brand = brand
    }

    /// The last four digits, safe to show and store.
    public var last4: String {
        String(digits.suffix(4))
    }

    /// The first six digits (the issuer identification number), which PCI DSS allows to show.
    public var issuerIdentificationNumber: String {
        String(digits.prefix(6))
    }

    /// The masked number, for example `•••• 4242`.
    public var masked: String {
        "•••• \(last4)"
    }

    /// The full number without separators.
    ///
    /// Pass it straight to your payment provider's tokenization call; do not log, save or send
    /// it anywhere else.
    public var unmaskedDigits: String {
        digits
    }

    /// The number in the brand's groups, with all but the last four digits masked, for example
    /// `•••• •••••• •1005` for American Express.
    public var maskedInGroups: String {
        let visible = digits.count - 4
        let masked = digits.enumerated().map { $0.offset < visible ? "•" : $0.element }
        return Self.group(masked, sizes: brand.groupSizes(forLength: digits.count))
    }

    /// Whether the digits pass the Luhn (mod 10) check that most card numbers end with.
    ///
    /// - Parameter digits: ASCII digits only; any other character makes the check fail.
    public static func passesLuhnCheck(_ digits: some StringProtocol) -> Bool {
        var sum = 0
        var doubles = false
        for byte in digits.utf8.reversed() {
            guard byte.isASCIIDigit else { return false }
            var value = Int(byte - 0x30)
            if doubles {
                value *= 2
                if value > 9 { value -= 9 }
            }
            sum += value
            doubles.toggle()
        }
        return !digits.isEmpty && sum % 10 == 0
    }

    /// Formats what a person typed so far into the brand's groups, for a card number field.
    ///
    /// Characters other than digits are dropped, and digits beyond the longest number the
    /// brand issues are cut off. Only the first ``maximumInputLength`` characters are read.
    ///
    /// ```swift
    /// CardNumber.formatForEntry("378282246310005") // "3782 822463 10005"
    /// ```
    public static func formatForEntry(_ text: some StringProtocol) -> String {
        let digits = String(text.prefix(maximumInputLength).filter { $0.isASCII && $0.isNumber })
        let brand = CardBrand.detect(fromLeadingDigits: digits)
        let kept = Array(digits.prefix(brand.validLengths.max() ?? 19))
        return group(kept, sizes: brand.groupSizes(forLength: max(kept.count, brand.validLengths.min() ?? 16)))
    }

    private static func group(_ characters: [Character], sizes: [Int]) -> String {
        var groups: [String] = []
        var index = 0
        for size in sizes where index < characters.count {
            let end = min(index + size, characters.count)
            groups.append(String(characters[index..<end]))
            index = end
        }
        if index < characters.count {
            groups.append(String(characters[index...]))
        }
        return groups.joined(separator: " ")
    }
}

extension CardNumber: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The masked number, `•••• 4242`.
    public var description: String { masked }

    /// The brand and masked number, `CardNumber(visa, •••• 4242)`.
    public var debugDescription: String { "CardNumber(\(brand.rawValue), \(masked))" }

    /// A mirror with only the brand and last four digits, so `dump` and the debugger never
    /// show the full number.
    public var customMirror: Mirror {
        Mirror(self, children: ["brand": brand, "last4": last4], displayStyle: .struct)
    }
}
