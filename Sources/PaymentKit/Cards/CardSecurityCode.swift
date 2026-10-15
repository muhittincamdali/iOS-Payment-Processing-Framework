/// The security code on a card (CVC, CVV or CID), which never prints.
///
/// Like ``CardNumber``, it is not `Codable` and shows only `•••` in logs, `dump` and the
/// debugger. PCI DSS forbids storing it after authorization, even encrypted.
public struct CardSecurityCode: Hashable, Sendable {
    private let digits: String

    /// Validates a security code for a card of the given brand: 4 digits for American Express,
    /// 3 for the others.
    ///
    /// - Throws: ``CardValidationError/empty`` or ``CardValidationError/invalidSecurityCode(expectedLength:)``.
    public init(_ text: some StringProtocol, brand: CardBrand) throws(CardValidationError) {
        let expected = brand.securityCodeLength
        guard !text.isEmpty else { throw .empty }
        guard text.utf8.count == expected, text.utf8.allSatisfy(\.isASCIIDigit) else {
            throw .invalidSecurityCode(expectedLength: expected)
        }
        self.digits = String(text)
    }

    /// The digits, to pass straight to your payment provider; never log or save them.
    public var unmaskedDigits: String {
        digits
    }
}

extension CardSecurityCode: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String { "•••" }
    public var debugDescription: String { "CardSecurityCode(•••)" }
    public var customMirror: Mirror { Mirror(self, children: [], displayStyle: .struct) }
}
