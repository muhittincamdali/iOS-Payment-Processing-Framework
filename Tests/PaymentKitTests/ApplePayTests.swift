import Foundation
import Testing
@testable import PaymentKit
#if canImport(PassKit)
import PassKit
#endif

@Suite("Apple Pay request")
struct ApplePayRequestTests {
    func usd(_ text: String) -> Money {
        // Literals in these tests are valid by construction.
        try! Money(text, .usd)
    }

    func makeRequest() -> ApplePayRequest {
        var request = ApplePayRequest(
            merchantIdentifier: "merchant.com.example.shop",
            merchantName: "Example Shop",
            countryCode: "US",
            currency: .usd,
            items: [
                ApplePaySummaryItem("Coffee beans", usd("18.00")),
                ApplePaySummaryItem("Discount", usd("-2.00"))
            ]
        )
        request.shippingMethods = [
            ApplePayShippingMethod(id: "standard", label: "Standard", detail: "3–5 days", amount: usd("4.99")),
            ApplePayShippingMethod(id: "pickup", label: "Pick up in store", detail: "", amount: usd("0"))
        ]
        return request
    }

    @Test("the total adds the items and the selected shipping method")
    func total() throws {
        let request = makeRequest()
        #expect(try request.total() == usd("20.99"))
        #expect(try request.total(shippingMethodID: "pickup") == usd("16.00"))
        #expect(throws: ApplePayRequestError.unknownShippingMethod("express")) { try request.total(shippingMethodID: "express") }
        #expect(throws: Never.self) { try request.validate() }
    }

    @Test("amounts in another currency are rejected")
    func currencyMismatch() throws {
        var request = makeRequest()
        request.items.append(ApplePaySummaryItem("Tip", try Money("1", .eur)))
        #expect(throws: ApplePayRequestError.currencyMismatch(label: "Tip")) { try request.validate() }
        request = makeRequest()
        request.shippingMethods[0].amount = try Money("5", .gbp)
        #expect(throws: ApplePayRequestError.currencyMismatch(label: "Standard")) { try request.total() }
    }

    @Test("a negative total is rejected for every shipping choice")
    func negativeTotal() throws {
        var request = makeRequest()
        request.items[1].amount = usd("-20.00") // 18 − 20 + 4.99 ≥ 0, but pickup makes it −2
        #expect(try request.total() == usd("2.99"))
        #expect(throws: ApplePayRequestError.negativeTotal) { try request.validate() }
        request.shippingMethods[0].amount = usd("-1.00")
        #expect(throws: ApplePayRequestError.negativeShippingAmount(label: "Standard")) { try request.validate() }
    }

    @Test("totals beyond the Money range are reported, not trapped")
    func overflow() throws {
        var request = makeRequest()
        let huge = try Money(minorUnits: Money.maximumMinorUnits, currency: .usd)
        request.items = [ApplePaySummaryItem("A", huge), ApplePaySummaryItem("B", huge)]
        #expect(throws: ApplePayRequestError.amountOutOfRange) { try request.validate() }
    }

    @Test("merchant identifiers", arguments: [
        ("merchant.com.example.shop", true), ("merchant.a", true), ("merchant.", false), ("com.example", false),
        ("merchant.com example", false), ("merchant.com/example", false), ("merchant." + String(repeating: "a", count: 300), false),
        ("Merchant.com.example", false)
    ])
    func merchantIdentifier(identifier: String, valid: Bool) {
        var request = makeRequest()
        request.merchantIdentifier = identifier
        if valid {
            #expect(throws: Never.self) { try request.validate() }
        } else {
            #expect(throws: ApplePayRequestError.invalidMerchantIdentifier) { try request.validate() }
        }
    }

    @Test("country codes must be two upper-case letters", arguments: ["us", "USA", "U1", "", "ÜS"])
    func countryCode(code: String) {
        var request = makeRequest()
        request.countryCode = code
        #expect(throws: ApplePayRequestError.invalidCountryCode) { try request.validate() }
    }

    @Test("labels must be present, short and free of control characters")
    func labels() {
        var request = makeRequest()
        request.items[0].label = "  "
        #expect(throws: ApplePayRequestError.invalidLabel("  ")) { try request.validate() }
        request = makeRequest()
        request.items[0].label = "Line\u{0}break"
        #expect(throws: ApplePayRequestError.self) { try request.validate() }
        request = makeRequest()
        let long = String(repeating: "é", count: 200_000)
        request.merchantName = long
        #expect(throws: ApplePayRequestError.invalidLabel(String(long.prefix(ApplePayRequest.maximumLabelLength)))) { try request.validate() }
        request = makeRequest()
        request.shippingMethods[0].detail = String(repeating: "x", count: 129)
        #expect(throws: ApplePayRequestError.self) { try request.validate() }
    }

    @Test("item counts, networks and shipping identifiers are checked")
    func structure() {
        var request = makeRequest()
        request.items = []
        #expect(throws: ApplePayRequestError.noItems) { try request.validate() }
        request = makeRequest()
        request.items = Array(repeating: ApplePaySummaryItem("x", usd("1")), count: ApplePayRequest.maximumItems + 1)
        #expect(throws: ApplePayRequestError.tooManyItems) { try request.validate() }
        request = makeRequest()
        request.supportedNetworks = []
        #expect(throws: ApplePayRequestError.noSupportedNetworks) { try request.validate() }
        request = makeRequest()
        request.shippingMethods[1].id = "standard"
        #expect(throws: ApplePayRequestError.invalidShippingMethodID("standard")) { try request.validate() }
        request.shippingMethods[1].id = ""
        #expect(throws: ApplePayRequestError.invalidShippingMethodID("")) { try request.validate() }
    }

    @Test("the server payload has the token structure and the token never prints its data")
    func tokenPayload() throws {
        let secret = Data(#"{"version":"EC_v1","data":"c2VjcmV0"}"#.utf8)
        let token = ApplePayToken(paymentData: secret, transactionIdentifier: "ABC123", network: "Visa", displayName: "Visa 0224", type: "debit")
        let json = try #require(try JSONSerialization.jsonObject(with: token.serverPayload()) as? [String: Any])
        #expect(json["paymentData"] as? String == secret.base64EncodedString())
        #expect(json["transactionIdentifier"] as? String == "ABC123")
        let method = try #require(json["paymentMethod"] as? [String: String])
        #expect(method == ["displayName": "Visa 0224", "network": "Visa", "type": "debit"])

        var dumped = ""
        dump(token, to: &dumped)
        for text in [token.description, String(reflecting: token), "\(token)", dumped] {
            #expect(!text.contains("c2VjcmV0"), "\(text)")
            #expect(!text.contains(secret.base64EncodedString()), "\(text)")
        }
        #expect(token.description.hasPrefix("ApplePayToken(Visa 0224, "))
    }

    #if canImport(PassKit)
    @Test("the PassKit request carries every value and ends with the merchant's total")
    func passKitRequest() throws {
        var request = makeRequest()
        request.items.append(ApplePaySummaryItem("Estimated tax", usd("1.50"), isPending: true))
        request.requiredShippingFields = [.postalAddress, .name]
        request.capabilities = [.threeDSecure, .debit]
        request.supportedNetworks = [.visa, .jcb, .mir]
        let pk = try request.makePaymentRequest()
        #expect(pk.merchantIdentifier == "merchant.com.example.shop")
        #expect(pk.currencyCode == "USD")
        #expect(pk.countryCode == "US")
        #expect(pk.supportedNetworks == [.visa, .JCB, .mir])
        #expect(pk.merchantCapabilities == [.threeDSecure, .debit])
        #expect(pk.requiredShippingContactFields == [.postalAddress, .name])
        #expect(pk.shippingMethods?.map(\.identifier) == ["standard", "pickup"])
        let items = pk.paymentSummaryItems
        #expect(items.map(\.label) == ["Coffee beans", "Discount", "Estimated tax", "Standard", "Example Shop"])
        #expect(items.last?.amount == NSDecimalNumber(string: "22.49"))
        #expect(items.last?.type == .pending)
        #expect(items[1].amount == NSDecimalNumber(string: "-2"))
    }

    @Test("an invalid request never becomes a PassKit request")
    func invalidPassKitRequest() {
        var request = makeRequest()
        request.countryCode = "usa"
        #expect(throws: ApplePayRequestError.invalidCountryCode) { try request.makePaymentRequest() }
    }

    @Test("a shipping change recomputes the summary lines")
    func shippingUpdate() throws {
        let items = try makeRequest().summaryItems(shippingMethodID: "pickup")
        #expect(items.map(\.label) == ["Coffee beans", "Discount", "Pick up in store", "Example Shop"])
        #expect(items.last?.amount == NSDecimalNumber(string: "16"))
    }

    @Test("authorization results map to the sheet's status")
    func authorizationResults() {
        #expect(ApplePayAuthorizationResult.success.passKitResult.status == .success)
        let failure = ApplePayAuthorizationResult.failure(message: "Card declined").passKitResult
        #expect(failure.status == .failure)
        #expect(failure.errors.first?.localizedDescription == "Card declined")
        #expect(ApplePayAuthorizationResult.failure(message: nil).passKitResult.errors.isEmpty)
    }

    @Test("the outcome reflects the last authorization when the sheet closes")
    func outcomes() {
        let payment = ApplePayPayment(token: ApplePayToken(paymentData: Data(), transactionIdentifier: "t", network: nil, displayName: nil, type: "credit"))
        #expect(ApplePayController.Session.outcome(payment: nil, result: nil) == .cancelled)
        #expect(ApplePayController.Session.outcome(payment: payment, result: .success) == .paid(payment))
        #expect(ApplePayController.Session.outcome(payment: payment, result: .failure(message: nil)) == .failed(payment))
    }

    @MainActor
    @Test("an invalid request throws before the sheet shows")
    func controllerGuards() async {
        let controller = ApplePayController()
        var request = makeRequest()
        request.countryCode = "x"
        await #expect(throws: ApplePayError.invalidRequest(.invalidCountryCode)) {
            try await controller.pay(request) { _ in .success }
        }
        #expect(!controller.isPresenting)
    }
    #endif
}
