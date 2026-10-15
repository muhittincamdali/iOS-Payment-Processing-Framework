import Foundation
import Testing
@testable import PaymentKit

@Suite("Card brand and number")
struct CardNumberTests {
    @Test("brands are detected from their prefixes", arguments: [
        ("4242424242424242", CardBrand.visa), ("4222222222222", .visa), ("4000000000000000006", .visa),
        ("5555555555554444", .mastercard), ("2223003122003222", .mastercard),
        ("378282246310005", .americanExpress), ("6011111111111117", .discover),
        ("6445644564456445", .discover), ("6500000000000002", .discover), ("6221260000000000", .discover),
        ("3566002020360505", .jcb), ("3056930009020004", .dinersClub), ("36227206271667", .dinersClub),
        ("38000000000006", .dinersClub), ("6200000000000005", .unionPay), ("8100000000000002", .unionPay),
        ("6759649826438453", .maestro), ("501800000009", .maestro), ("5018000000000000007", .maestro),
        ("2200000000000004", .mir)
    ])
    func validNumbers(number: String, brand: CardBrand) throws {
        let card = try CardNumber(number)
        #expect(card.brand == brand)
        #expect(card.last4 == String(number.suffix(4)))
        #expect(card.unmaskedDigits == number)
    }

    @Test("separators are accepted, other characters are not")
    func separators() throws {
        #expect(try CardNumber("4242 4242-4242 4242").unmaskedDigits == "4242424242424242")
        #expect(throws: CardValidationError.invalidCharacters) { try CardNumber("4242.4242.4242.4242") }
        #expect(throws: CardValidationError.invalidCharacters) { try CardNumber("4242424242424242\u{0}") }
        #expect(throws: CardValidationError.invalidCharacters) { try CardNumber("٤٢٤٢٤٢٤٢٤٢٤٢٤٢٤٢") } // Arabic-Indic digits
        #expect(throws: CardValidationError.empty) { try CardNumber(" - ") }
        #expect(throws: CardValidationError.empty) { try CardNumber("") }
    }

    @Test("input longer than the limit throws without being read")
    func longInput() {
        let long = String(repeating: "4", count: 1_000_000)
        #expect(throws: CardValidationError.invalidCharacters) { try CardNumber(long) }
        let padded = "4242424242424242" + String(repeating: " ", count: CardNumber.maximumInputLength)
        #expect(throws: CardValidationError.invalidCharacters) { try CardNumber(padded) }
    }

    @Test("lengths and check digits are enforced")
    func lengthAndChecksum() {
        #expect(throws: CardValidationError.invalidLength(.americanExpress)) { try CardNumber("37828224631000") }
        #expect(throws: CardValidationError.invalidLength(.visa)) { try CardNumber("42424242424242") }
        #expect(throws: CardValidationError.invalidLength(.unknown)) { try CardNumber("12345678901") }
        #expect(throws: CardValidationError.invalidLength(.unknown)) { try CardNumber("12345678901234567890") }
        #expect(throws: CardValidationError.failedChecksum) { try CardNumber("4242424242424241") }
        // UnionPay numbers may have no Luhn digit.
        #expect(throws: Never.self) { try CardNumber("6200000000000006") }
    }

    @Test("Luhn check", arguments: [("79927398713", true), ("79927398710", false), ("0", true), ("", false), ("1a", false)])
    func luhn(digits: String, valid: Bool) {
        #expect(CardNumber.passesLuhnCheck(digits) == valid)
    }

    @Test("the full number never appears in text, dumps or mirrors")
    func redaction() throws {
        let digits = "4242424242424242"
        let card = try CardNumber(digits)
        var dumped = ""
        dump(card, to: &dumped)
        let texts = [
            String(describing: card), "\(card)", String(reflecting: card), dumped,
            String(describing: Mirror(reflecting: card).children.map(\.value)),
            String(describing: [card]), String(describing: Optional(card)),
            String(describing: CardDetails(number: card, expiry: try CardExpiry(month: 1, year: 30), securityCode: try CardSecurityCode("123", brand: .visa)))
        ]
        for text in texts {
            #expect(!text.contains(digits), "\(text)")
            #expect(!text.contains("424242424242"), "\(text)")
        }
        #expect(card.description == "•••• 4242")
        #expect(card.debugDescription == "CardNumber(visa, •••• 4242)")
        #expect(card.issuerIdentificationNumber == "424242")
    }

    @Test("masked groups follow the brand's layout")
    func maskedGroups() throws {
        #expect(try CardNumber("378282246310005").maskedInGroups == "•••• •••••• •0005")
        #expect(try CardNumber("4242424242424242").maskedInGroups == "•••• •••• •••• 4242")
        #expect(try CardNumber("36227206271667").maskedInGroups == "•••• •••••• 1667")
    }

    @Test("entry formatting groups digits and stops at the brand's length", arguments: [
        ("4242424242424242", "4242 4242 4242 4242"), ("42424", "4242 4"), ("378282246310005", "3782 822463 10005"),
        ("3782822463100059999", "3782 822463 10005"), ("4242-4242 abc 42", "4242 4242 42"), ("", ""),
        ("4000000000000000006", "4000 0000 0000 0000 006")
    ])
    func entryFormatting(input: String, expected: String) {
        #expect(CardNumber.formatForEntry(input) == expected)
    }

    @Test("entry formatting reads a bounded prefix of huge input")
    func entryFormattingBounded() {
        let huge = String(repeating: "x", count: 500_000) + "4242"
        #expect(CardNumber.formatForEntry(huge) == "")
    }
}

@Suite("Card expiry and security code")
struct CardExpiryTests {
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }

    @Test("formats people type", arguments: [
        ("09/27", 9, 2027), ("9/27", 9, 2027), ("09 / 2027", 9, 2027), ("0927", 9, 2027), ("12/99", 12, 2099)
    ])
    func parsing(text: String, month: Int, year: Int) throws {
        let expiry = try CardExpiry(parsing: text)
        #expect(expiry.month == month)
        #expect(expiry.year == year)
    }

    @Test("bad expiry text throws", arguments: [
        ("", CardValidationError.invalidExpiryFormat), ("13/27", .invalidMonth), ("00/27", .invalidMonth),
        ("09/2", .invalidExpiryFormat), ("09/027", .invalidExpiryFormat), ("9/27/1", .invalidExpiryFormat),
        ("ab/cd", .invalidExpiryFormat), ("09/2100", .invalidYear), ("09/1999", .invalidYear),
        ("０9/27", .invalidExpiryFormat), (String(repeating: "1", count: 100), .invalidExpiryFormat)
    ])
    func badParsing(text: String, error: CardValidationError) {
        #expect(throws: error) { try CardExpiry(parsing: text) }
    }

    @Test("a card is valid through the last moment of its month")
    func expiryBoundary() throws {
        let expiry = try CardExpiry(month: 2, year: 28)
        let calendar = Self.utc
        #expect(!expiry.isExpired(at: date("2028-02-29T23:59:59Z"), calendar: calendar))
        #expect(expiry.isExpired(at: date("2028-03-01T00:00:00Z"), calendar: calendar))
        #expect(throws: CardValidationError.expired) { try expiry.validate(at: date("2028-03-01T00:00:00Z"), calendar: calendar) }
        let december = try CardExpiry(month: 12, year: 2030)
        #expect(!december.isExpired(at: date("2030-12-31T23:59:59Z"), calendar: calendar))
        #expect(december.isExpired(at: date("2031-01-01T00:00:00Z"), calendar: calendar))
    }

    @Test("years far ahead are rejected")
    func tooFarAhead() throws {
        let now = date("2026-10-15T12:00:00Z")
        #expect(throws: Never.self) { try CardExpiry(month: 1, year: 2046).validate(at: now, calendar: Self.utc) }
        #expect(throws: CardValidationError.expiryTooFarAhead) { try CardExpiry(month: 1, year: 2047).validate(at: now, calendar: Self.utc) }
    }

    @Test("expiry prints and encodes as MM/YY")
    func expiryText() throws {
        let expiry = try CardExpiry(month: 3, year: 2005)
        #expect(expiry.description == "03/05")
        let data = try JSONEncoder().encode([expiry])
        #expect(String(decoding: data, as: UTF8.self) == #"["03\/05"]"#)
        #expect(try JSONDecoder().decode([CardExpiry].self, from: data) == [expiry])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([CardExpiry].self, from: Data(#"["13/30"]"#.utf8)) }
    }

    @Test("security codes match the brand and never print")
    func securityCode() throws {
        #expect(try CardSecurityCode("1234", brand: .americanExpress).unmaskedDigits == "1234")
        #expect(throws: CardValidationError.invalidSecurityCode(expectedLength: 4)) { try CardSecurityCode("123", brand: .americanExpress) }
        #expect(throws: CardValidationError.invalidSecurityCode(expectedLength: 3)) { try CardSecurityCode("12a", brand: .visa) }
        #expect(throws: CardValidationError.empty) { try CardSecurityCode("", brand: .visa) }
        let code = try CardSecurityCode("987", brand: .visa)
        var dumped = ""
        dump(code, to: &dumped)
        for text in [code.description, code.debugDescription, "\(code)", dumped] {
            #expect(!text.contains("987"))
        }
    }
}

@Suite("Card form")
struct CardFormTests {
    private let now = ISO8601DateFormatter().date(from: "2026-10-15T12:00:00Z")!

    @Test("a complete form yields card details")
    func success() throws {
        let form = CardForm(number: "3782 822463 10005", expiry: "09/27", securityCode: "1234")
        let details = try form.validate(at: now).get()
        #expect(details.number.brand == .americanExpress)
        #expect(details.description == "americanExpress •••• 0005 09/27")
    }

    @Test("every bad field reports its own error")
    func perFieldErrors() {
        let form = CardForm(number: "4242424242424241", expiry: "09/25", securityCode: "12")
        guard case .failure(let errors) = form.validate(at: now) else {
            Issue.record("expected errors")
            return
        }
        #expect(errors == CardFormErrors(number: .failedChecksum, expiry: .expired, securityCode: .invalidSecurityCode(expectedLength: 3)))
    }

    @Test("the security code length follows the typed brand even when the number is incomplete")
    func codeUsesDetectedBrand() {
        let form = CardForm(number: "3782", expiry: "09/27", securityCode: "123")
        guard case .failure(let errors) = form.validate(at: now) else {
            Issue.record("expected errors")
            return
        }
        #expect(form.detectedBrand == .americanExpress)
        #expect(errors.securityCode == .invalidSecurityCode(expectedLength: 4))
    }

    @Test("the form state does not print the typed number or code")
    func formRedaction() {
        let form = CardForm(number: "4242 4242 4242 4242", expiry: "09/27", securityCode: "321")
        var dumped = ""
        dump(form, to: &dumped)
        for text in [String(describing: form), String(reflecting: form), dumped] {
            #expect(!text.contains("4242 4242 4242"), "\(text)")
            #expect(!text.contains("424242424242"), "\(text)")
            #expect(!text.contains("321"), "\(text)")
        }
        #expect(form.description == "CardForm(number: •••• 4242, expiry: 09/27, securityCode: •••)")
    }
}
