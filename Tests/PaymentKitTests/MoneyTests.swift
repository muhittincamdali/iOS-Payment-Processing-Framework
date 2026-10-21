import Foundation
import Testing
@testable import PaymentKit

@Suite("Currency")
struct CurrencyTests {
    @Test("codes are normalised and take ISO 4217 minor units", arguments: [
        ("usd", "USD", 2), ("JPY", "JPY", 0), ("kwd", "KWD", 3), ("CLF", "CLF", 4), ("TRY", "TRY", 2)
    ])
    func isoDigits(input: String, code: String, digits: Int) throws {
        let currency = try Currency(input)
        #expect(currency.code == code)
        #expect(currency.minorUnitDigits == digits)
    }

    @Test("malformed codes throw", arguments: ["", "US", "USDD", "U5D", "ÜSD", "usd ", String(repeating: "A", count: 10_000)])
    func malformed(code: String) throws {
        #expect(throws: MoneyError.self) { try Currency(code) }
    }

    @Test("the error keeps at most 8 characters of a long code")
    func errorTruncatesInput() throws {
        let long = String(repeating: "x", count: 1_000)
        #expect(throws: MoneyError.invalidCurrencyCode("xxxxxxxx")) { try Currency(long) }
    }

    @Test("explicit minor units are limited to 0...4")
    func explicitDigits() throws {
        #expect(try Currency("XBT", minorUnitDigits: 4).minorUnitDigits == 4)
        #expect(throws: MoneyError.invalidMinorUnitDigits(5)) { try Currency("XBT", minorUnitDigits: 5) }
        #expect(throws: MoneyError.invalidMinorUnitDigits(-1)) { try Currency("XBT", minorUnitDigits: -1) }
    }

    @Test("Codable uses the bare code and rejects bad codes")
    func codable() throws {
        let data = try JSONEncoder().encode([Currency.jpy])
        #expect(String(decoding: data, as: UTF8.self) == #"["JPY"]"#)
        #expect(try JSONDecoder().decode([Currency].self, from: Data(#"["kwd"]"#.utf8)) == [.kwd])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([Currency].self, from: Data(#"["12"]"#.utf8)) }
    }
}

@Suite("Money")
struct MoneyTests {
    @Test("string amounts become exact minor units")
    func exactAmounts() throws {
        #expect(try Money("19.99", .usd).minorUnits == 1999)
        #expect(try Money("-0.5", .usd).minorUnits == -50)
        #expect(try Money("1234", .jpy).minorUnits == 1234)
        #expect(try Money("1.234", .kwd).minorUnits == 1234)
        #expect(try Money("19.990", .usd).minorUnits == 1999) // trailing zeros are exact
    }

    @Test("too many decimals throw instead of rounding", arguments: [
        ("19.999", Currency.usd), ("10.5", Currency.jpy), ("1.2345", Currency.kwd)
    ])
    func tooManyDigits(text: String, currency: Currency) throws {
        #expect(throws: MoneyError.tooManyFractionDigits(currency: currency)) { try Money(text, currency) }
    }

    @Test("a Double-based Decimal literal is rejected, not silently rounded")
    func floatLiteralIsRejected() throws {
        let literal: Decimal = 19.99 // 19.98999999999999488 through Double
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .usd)) { try Money(literal, .usd) }
        #expect(try Money(rounding: literal, .usd).minorUnits == 1999)
    }

    @Test("NaN never becomes an amount")
    func notANumber() throws {
        #expect(throws: MoneyError.notANumber) { try Money(Decimal.nan, .usd) }
        #expect(throws: MoneyError.notANumber) { try Money(rounding: .nan, .usd) }
        #expect(throws: MoneyError.notANumber) { try Money("1", .usd).multiplied(by: .nan) }
    }

    @Test("the range limit holds at the boundary and beyond")
    func range() throws {
        let max = Money.maximumMinorUnits
        #expect(try Money(minorUnits: max, currency: .usd).minorUnits == max)
        #expect(try Money(minorUnits: -max, currency: .usd).minorUnits == -max)
        #expect(throws: MoneyError.outOfRange) { try Money(minorUnits: max + 1, currency: .usd) }
        #expect(throws: MoneyError.outOfRange) { try Money(minorUnits: .min, currency: .usd) }
        #expect(throws: MoneyError.outOfRange) { try Money("10000000000000.00", .usd) }
        #expect(throws: MoneyError.outOfRange) { try Money(Decimal(string: "1e120")!, .usd) }
        #expect(throws: MoneyError.outOfRange) { try Money(rounding: Decimal.greatestFiniteMagnitude, .usd) }
        // Rounding up across the limit is out of range, not a wrapped or trapped value.
        #expect(throws: MoneyError.outOfRange) { try Money(rounding: Decimal(string: "9999999999999.995")!, .usd) }
        #expect(try Money(rounding: Decimal(string: "9999999999999.994")!, .usd).minorUnits == max)
        #expect(throws: MoneyError.outOfRange) { try Money(minorUnits: max, currency: .usd).adding(Money(minorUnits: 1, currency: .usd)) }
        #expect(throws: MoneyError.outOfRange) { try Money(minorUnits: -max, currency: .usd).subtracting(Money(minorUnits: 1, currency: .usd)) }
        #expect(throws: MoneyError.outOfRange) { try Money("2", .usd).multiplied(by: Decimal(string: "1e120")!) }
        #expect(throws: MoneyError.outOfRange) { try Money(minorUnits: max, currency: .usd).multiplied(by: 2) }
    }

    @Test("amount reflects minor units and the currency's digits")
    func amount() throws {
        #expect(try Money(minorUnits: 1999, currency: .usd).amount == Decimal(string: "19.99"))
        #expect(try Money(minorUnits: -5, currency: .kwd).amount == Decimal(string: "-0.005"))
        #expect(try Money(minorUnits: 500, currency: .jpy).amount == 500)
    }

    @Test("arithmetic keeps the currency and checks it")
    func arithmetic() throws {
        let price = try Money("19.99", .usd)
        let tax = try price.multiplied(by: Decimal(8) / 100)
        #expect(tax.minorUnits == 160)
        #expect(try price.adding(tax).minorUnits == 2159)
        #expect(try price.subtracting(price).isZero)
        #expect(price.negated().minorUnits == -1999)
        #expect(throws: MoneyError.currencyMismatch(.usd, .eur)) { try price.adding(Money("1", .eur)) }
        #expect(try Money.sum([price, price, tax], in: .usd).minorUnits == 4158)
        #expect(try Money.sum([], in: .eur) == .zero(.eur))
        #expect(throws: MoneyError.currencyMismatch(.usd, .eur)) { try Money.sum([price, Money("1", .eur)], in: .usd) }
    }

    @Test("rounding rules", arguments: [
        (FloatingPointRoundingRule.toNearestOrEven, "0.125", 12), (.toNearestOrEven, "0.135", 14),
        (.toNearestOrAwayFromZero, "0.125", 13), (.toNearestOrAwayFromZero, "-0.125", -13),
        (.up, "-0.121", -12), (.down, "-0.121", -13), (.towardZero, "-0.129", -12),
        (.awayFromZero, "0.121", 13), (.awayFromZero, "-0.121", -13)
    ])
    func rounding(rule: FloatingPointRoundingRule, text: String, expected: Int64) throws {
        let value = try #require(Decimal(string: text))
        #expect(try Money(rounding: value, .usd, rule: rule).minorUnits == expected)
    }

    @Test("allocation keeps every minor unit")
    func allocation() throws {
        let hundred = try Money("100", .usd)
        #expect(try hundred.split(into: 3).map(\.minorUnits) == [3334, 3333, 3333])
        #expect(try hundred.allocated([70, 20, 10]).map(\.minorUnits) == [7000, 2000, 1000])
        #expect(try Money("0.05", .usd).allocated([1, 1, 1]).map(\.minorUnits) == [2, 2, 1])
        #expect(try Money("-0.05", .usd).split(into: 2).map(\.minorUnits) == [-3, -2])
        #expect(try Money("0.10", .usd).allocated([0, 1, 0]).map(\.minorUnits) == [0, 10, 0])
        // The largest remainder wins, not the first part.
        #expect(try Money("0.10", .usd).allocated([1, 2]).map(\.minorUnits) == [3, 7])
    }

    @Test("allocation adds up for large amounts and ratios")
    func allocationSums() throws {
        let total = try Money(minorUnits: Money.maximumMinorUnits, currency: .usd)
        let ratios = [Int.max / 4, 3, Int.max / 4, 1]
        let parts = try total.allocated(ratios)
        #expect(parts.map(\.minorUnits).reduce(0, +) == total.minorUnits)
        let thousand = try Money("1", .usd).split(into: Money.maximumAllocationParts)
        #expect(thousand.map(\.minorUnits).reduce(0, +) == 100)
        #expect(thousand.prefix(100).allSatisfy { $0.minorUnits == 1 })
    }

    @Test("invalid allocation ratios throw")
    func invalidRatios() throws {
        let money = try Money("1", .usd)
        #expect(throws: MoneyError.invalidRatios) { try money.allocated([]) }
        #expect(throws: MoneyError.invalidRatios) { try money.allocated([0, 0]) }
        #expect(throws: MoneyError.invalidRatios) { try money.allocated([1, -1]) }
        #expect(throws: MoneyError.invalidRatios) { try money.allocated([Int.max, Int.max, Int.max]) }
        #expect(throws: MoneyError.invalidRatios) { try money.split(into: 0) }
        #expect(throws: MoneyError.invalidRatios) { try money.split(into: Money.maximumAllocationParts + 1) }
        #expect(throws: MoneyError.invalidRatios) { try money.split(into: .max) }
    }

    @Test("description and plain amount print exact digits")
    func text() throws {
        #expect(try Money("19.9", .usd).description == "19.90 USD")
        #expect(try Money("-0.05", .usd).plainAmount == "-0.05")
        #expect(try Money("7", .jpy).description == "7 JPY")
        #expect(try Money("0.001", .kwd).plainAmount == "0.001")
        #expect(try Money(minorUnits: -Money.maximumMinorUnits, currency: .usd).plainAmount == "-9999999999999.99")
    }

    @Test("formatting shows the currency's digits for the locale")
    func formatting() throws {
        let price = try Money("1234.5", .usd)
        #expect(price.formatted(locale: Locale(identifier: "en_US")) == "$1,234.50")
        #expect(try Money("1234", .jpy).formatted(locale: Locale(identifier: "en_US")) == "¥1,234")
        let euro = try Money("1234.5", .eur).formatted(locale: Locale(identifier: "de_DE"))
        #expect(euro.hasPrefix("1.234,50"))
        #expect(euro.hasSuffix("€"))
    }

    @Test("Codable round-trips and validates")
    func codable() throws {
        let price = try Money("19.99", .usd)
        let data = try JSONEncoder().encode(price)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(object == ["amount": "19.99", "currency": "USD"])
        #expect(try JSONDecoder().decode(Money.self, from: data) == price)

        for json in [
            #"{"amount":"19.999","currency":"USD"}"#,
            #"{"amount":"1e3","currency":"USD"}"#,
            #"{"amount":"NaN","currency":"USD"}"#,
            #"{"amount":"99999999999999999","currency":"USD"}"#,
            #"{"amount":19.99,"currency":"USD"}"#,
            #"{"amount":"1","currency":"US"}"#
        ] {
            #expect(throws: DecodingError.self, "\(json)") { try JSONDecoder().decode(Money.self, from: Data(json.utf8)) }
        }
    }
}

@Suite("Money parsing")
struct MoneyParsingTests {
    @Test("strict strings", arguments: ["", "-", ".5", "5.", "1.2.3", "+1", "1e3", " 1", "1 ", "１", "0x10", "NaN", "1,5", "--1"])
    func strictRejects(text: String) throws {
        #expect(throws: MoneyError.invalidText) { try Money(text, .usd) }
    }

    @Test("digits beyond what Decimal holds exactly throw instead of being rounded")
    func significantDigits() throws {
        let tinyFraction = "1." + String(repeating: "0", count: 38) + "1"
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .jpy)) { try Money(tinyFraction, .jpy) }
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .usd)) { try Money(tinyFraction, .usd) }
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .jpy)) {
            try Money(parsing: tinyFraction, currency: .jpy, locale: Locale(identifier: "en_US"))
        }
        let huge = String(repeating: "9", count: 39)
        #expect(throws: MoneyError.outOfRange) { try Money(huge, .usd) }
        #expect(throws: MoneyError.outOfRange) { try Money(huge + ".5", .usd) }
        // Leading and trailing zeros are not significant.
        #expect(try Money(String(repeating: "0", count: 50) + "12.5", .usd).minorUnits == 1250)
        #expect(try Money("12." + String(repeating: "0", count: 50), .jpy).minorUnits == 12)
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .usd)) { try Money("-0." + String(repeating: "0", count: 50) + "1", .usd) }
    }

    @Test("long input throws before it is scanned")
    func longInput() throws {
        let long = String(repeating: "9", count: 100_000)
        #expect(throws: MoneyError.invalidText) { try Money(long, .usd) }
        #expect(throws: MoneyError.invalidText) { try Money(parsing: long, currency: .usd, locale: Locale(identifier: "en_US")) }
    }

    @Test("typed text in a locale", arguments: [
        ("1,234.50", "en_US", 123_450), (" 12.5 ", "en_US", 1250), ("1.234,50", "de_DE", 123_450),
        ("1 234,5", "fr_FR", 123_450), ("1\u{202F}234,50", "fr_FR", 123_450), ("1'234.50", "de_CH", 123_450),
        ("-3,10", "tr_TR", -310), ("\u{2212}3,10", "sv_SE", -310)
    ])
    func localized(text: String, locale: String, expected: Int64) throws {
        let money = try Money(parsing: text, currency: .usd, locale: Locale(identifier: locale))
        #expect(money.minorUnits == expected)
    }

    @Test("grouped amounts in a locale", arguments: [
        ("1,234,567.89", "en_US", 123_456_789), ("-1,234", "en_US", -123_400), ("12,34,567.50", "en_IN", 123_456_750),
        ("1.234", "de_DE", 123_400), ("1.234.567,8", "de_DE", 123_456_780), ("1 234 567", "fr_FR", 123_456_700),
        ("999", "de_DE", 99_900)
    ])
    func grouped(text: String, locale: String, expected: Int64) throws {
        #expect(try Money(parsing: text, currency: .usd, locale: Locale(identifier: locale)).minorUnits == expected)
    }

    // A decimal typed with the other separator must not become 10 or 100 times larger.
    @Test("separators that do not group three digits throw", arguments: [
        ("12,50", "en_US"), ("9,99", "en_US"), ("1,5", "en_US"), ("1234,567", "en_US"), (",5", "en_US"),
        ("1,", "en_US"), ("1,,234", "en_US"), ("1,234.5,6", "en_US"), ("1,2345", "en_US"), ("12 50", "en_US"),
        ("0.99", "de_DE"), ("1.5", "de_DE"), ("12.50", "de_DE"), ("1.234.5", "de_DE"), ("1,234.50", "de_DE"),
        ("1 5", "fr_FR"), ("12'50", "de_CH"), ("1,2,345", "en_IN")
    ])
    func misplacedGrouping(text: String, locale: String) {
        #expect(throws: MoneyError.invalidText, "\(text) in \(locale)") {
            try Money(parsing: text, currency: .usd, locale: Locale(identifier: locale))
        }
    }

    // No grouped number starts with 0, so a leading 0 means the separator was typed as a decimal
    // point; reading it as grouping would charge 100 or 1000 times the amount.
    @Test("grouped amounts that start with 0 throw", arguments: [
        ("0,990", "en_US", Currency.usd), ("0.500", "de_DE", .eur), ("0,500", "en_US", .kwd),
        ("0.050", "tr_TR", .try), ("00,100", "en_US", .usd), ("0,000,500", "en_US", .usd),
        ("-0,500", "en_US", .usd), ("0 500", "fr_FR", .eur)
    ])
    func leadingZeroGroup(text: String, locale: String, currency: Currency) {
        #expect(throws: MoneyError.invalidText, "\(text) in \(locale)") {
            try Money(parsing: text, currency: currency, locale: Locale(identifier: locale))
        }
    }

    @Test("amounts below one without grouping still parse", arguments: [
        ("0.99", "en_US", Currency.usd, 99), ("0,50", "de_DE", .eur, 50), ("0.500", "en_US", .kwd, 500),
        ("0,05", "tr_TR", .try, 5), ("-0.5", "en_US", .usd, -50), ("0", "en_US", .usd, 0)
    ])
    func belowOne(text: String, locale: String, currency: Currency, expected: Int64) throws {
        #expect(try Money(parsing: text, currency: currency, locale: Locale(identifier: locale)).minorUnits == expected)
    }

    @Test("typed text that is not a plain amount throws", arguments: ["$12", "12 USD", "1.2.3", "12abc", "1e5", "", "   "])
    func localizedRejects(text: String) throws {
        #expect(throws: MoneyError.self) { try Money(parsing: text, currency: .usd, locale: Locale(identifier: "en_US")) }
    }

    @Test("typed decimals beyond the currency are reported, not rounded")
    func localizedTooManyDigits() throws {
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .usd)) {
            try Money(parsing: "10.999", currency: .usd, locale: Locale(identifier: "en_US"))
        }
    }
}
