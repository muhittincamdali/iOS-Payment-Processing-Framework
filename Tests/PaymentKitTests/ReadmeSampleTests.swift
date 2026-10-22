import Foundation
import Testing
@testable import PaymentKit

/// Runs the README samples (ReadmeExamples.swift links to the example app's ReadmeSamples.swift)
/// so the code people copy does what the README says.
@Suite("README samples")
struct ReadmeSampleTests {
    @Test("the money sample gives the amounts its comments show")
    func money() throws {
        let (total, shares) = try moneySamples()
        #expect(total == (try Money("21.59", .usd)))
        #expect(total.minorUnits == 2159)
        #expect(total.formatted(locale: Locale(identifier: "en_US")) == "$21.59")
        #expect(try total.subtracting(Money("19.99", .usd)) == Money("1.60", .usd)) // the tax
        #expect(shares == Array(repeating: try Money("411.50", .eur), count: 3))
        #expect(shares.map(\.description) == Array(repeating: "411.50 EUR", count: 3))
        #expect(throws: MoneyError.tooManyFractionDigits(currency: .usd)) { try Money("10.999", .usd) }
    }

    @Test("the card sample accepts a valid card and lists every problem of an invalid one")
    func cards() {
        #expect(checkCard(number: "4242 4242 4242 4242", expiry: "12/40", securityCode: "123") == "Visa •••• 4242 is valid")
        let problems = checkCard(number: "4242 4242 4242 4241", expiry: "13/40", securityCode: "1")
        #expect(problems.split(separator: "\n").count == 3)
        #expect(!problems.contains("4242424242424241"))
    }

    @Test("the Apple Pay sample builds a valid request")
    func applePay() throws {
        let request = try makeApplePayRequest()
        #expect(try request.total() == Money("20.99", .usd))
    }

    @MainActor
    @Test("the testing sample shows a refund taking Pro away")
    func refund() async throws {
        #expect(try await refundRemovesPro())
    }

    @MainActor
    @Test("the coins sample credits two packs and spends from them")
    func coins() async throws {
        #expect(try await buyAndSpendCoins() == 150)
    }
}
