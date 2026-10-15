import Foundation
import Testing
@testable import PaymentKit

/// Runs the README samples (ReadmeExamples.swift links to the example app's ReadmeSamples.swift)
/// so the code people copy does what the README says.
@Suite("README samples")
struct ReadmeSampleTests {
    @Test("the money sample runs without throwing")
    func money() throws {
        try moneySamples()
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
