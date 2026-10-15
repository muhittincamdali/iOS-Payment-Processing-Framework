import Foundation

/// The text of a card entry form, checked field by field.
///
/// Bind the three properties to text fields, show ``CardFormErrors`` next to the fields, and
/// pass the ``CardDetails`` of a successful ``validate(at:calendar:)`` to your payment
/// provider.
///
/// ```swift
/// var form = CardForm()
/// form.number = "4242 4242 4242 4242"
/// form.expiry = "09/27"
/// form.securityCode = "123"
/// switch form.validate() {
/// case .success(let card): print(card.number)          // •••• 4242
/// case .failure(let errors): print(errors.number ?? "") // per-field errors
/// }
/// ```
public struct CardForm: Hashable, Sendable {
    /// The card number as typed.
    public var number: String
    /// The expiry date as typed, for example `09/27`.
    public var expiry: String
    /// The security code as typed.
    public var securityCode: String

    public init(number: String = "", expiry: String = "", securityCode: String = "") {
        self.number = number
        self.expiry = expiry
        self.securityCode = securityCode
    }

    /// The brand of the number typed so far, to show its logo while the person types.
    public var detectedBrand: CardBrand {
        CardBrand.detect(fromLeadingDigits: number.prefix(CardNumber.maximumInputLength).filter { $0.isASCII && $0.isNumber })
    }

    /// Checks every field and returns either the card details or an error for each bad field.
    public func validate(at date: Date = .now, calendar: Calendar = .current) -> Result<CardDetails, CardFormErrors> {
        var errors = CardFormErrors()
        var cardNumber: CardNumber?
        do {
            cardNumber = try CardNumber(number)
        } catch {
            errors.number = error
        }

        var cardExpiry: CardExpiry?
        do {
            let parsed = try CardExpiry(parsing: expiry)
            try parsed.validate(at: date, calendar: calendar)
            cardExpiry = parsed
        } catch {
            errors.expiry = error
        }

        var code: CardSecurityCode?
        do {
            code = try CardSecurityCode(securityCode, brand: cardNumber?.brand ?? detectedBrand)
        } catch {
            errors.securityCode = error
        }

        guard let cardNumber, let cardExpiry, let code else { return .failure(errors) }
        return .success(CardDetails(number: cardNumber, expiry: cardExpiry, securityCode: code))
    }
}

/// The errors of a ``CardForm``, one per field that failed; `nil` for a field that passed.
public struct CardFormErrors: Error, Hashable, Sendable {
    public var number: CardValidationError?
    public var expiry: CardValidationError?
    public var securityCode: CardValidationError?

    public init(number: CardValidationError? = nil, expiry: CardValidationError? = nil, securityCode: CardValidationError? = nil) {
        self.number = number
        self.expiry = expiry
        self.securityCode = securityCode
    }
}

/// Card details that passed validation, ready for your payment provider's tokenization API.
public struct CardDetails: Hashable, Sendable, CustomStringConvertible {
    public let number: CardNumber
    public let expiry: CardExpiry
    public let securityCode: CardSecurityCode

    /// The brand and masked number with the expiry, for example `visa •••• 4242 09/27`.
    public var description: String {
        "\(number.brand.rawValue) \(number.masked) \(expiry)"
    }
}

extension CardForm: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The form with the number cut to its last four digits and the security code hidden.
    public var description: String {
        let digits = number.prefix(CardNumber.maximumInputLength).filter { $0.isASCII && $0.isNumber }
        let shown = digits.count > 4 ? "•••• \(digits.suffix(4))" : String(repeating: "•", count: digits.count)
        return "CardForm(number: \(shown), expiry: \(expiry.prefix(CardExpiry.maximumInputLength)), securityCode: •••)"
    }

    public var debugDescription: String { description }

    /// A mirror without the typed number or security code, so `dump` and the debugger never
    /// show them.
    public var customMirror: Mirror {
        Mirror(self, children: ["detectedBrand": detectedBrand, "expiry": expiry], displayStyle: .struct)
    }
}
