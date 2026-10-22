// The code samples of the README. PaymentLab compiles this file, and the package's tests
// compile it too through Tests/PaymentKitTests/ReadmeExamples.swift (a symlink), so a sample
// that stops compiling fails CI.
import Foundation
import PaymentKit
import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

// MARK: Quick start

struct ContentView: View {
    @State private var store = Store(catalog: [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro")
    ])

    var body: some View {
        List(store.products) { product in
            Button("\(product.displayName) · \(product.displayPrice)") {
                Task { try? await store.purchase(product) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text(store.hasEntitlement("pro") ? "Pro is unlocked" : "Pro is locked")
        }
        .task { await store.start() } // loads products, listens for renewals and refunds
    }
}

// MARK: Store

@MainActor
func makeStore(server: URL) -> Store {
    Store(catalog: [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        .consumable("coins.100", credits: 100, to: "coins") // store.balance(of: "coins")
    ]) { change in
        // Runs for each new verified transaction (.granted) and each refund (.revoked) before
        // StoreKit finishes it. Throwing keeps it unfinished and StoreKit sends it again on the
        // next launch, so the server must accept repeats of the same transaction.
        try await sendToServer(change.transaction.signedTransaction, server: server)
    }
}

@MainActor
func buy(_ product: StoreProduct, in store: Store, account: UUID) async -> String {
    do {
        switch try await store.purchase(product, options: PurchaseOptions(appAccountToken: account)) {
        case .purchased(let transaction):
            return "Bought \(transaction.productID)"
        case .pending:
            return "Waiting for approval (Ask to Buy)"
        case .cancelled:
            return "Cancelled"
        }
    } catch .verificationFailed {
        return "The App Store could not verify the purchase; nothing was unlocked."
    } catch {
        return error.localizedDescription
    }
}

// MARK: Money

func moneySamples() throws -> (total: Money, shares: [Money]) {
    let price = try Money("19.99", .usd)
    let tax = try price.multiplied(by: Decimal(8) / 100) // 1.60, rounded half to even
    let total = try price.adding(tax)                    // 21.59 USD
    print(total.minorUnits)                              // 2159, what payment APIs expect
    print(total.formatted(locale: Locale(identifier: "en_US"))) // $21.59

    let typed = try Money(parsing: "1.234,50", currency: .eur, locale: Locale(identifier: "de_DE"))
    let shares = try typed.split(into: 3)                // 411.50, 411.50, 411.50 EUR
    print(shares.map(\.description))

    do {
        _ = try Money("10.999", .usd)
    } catch {
        print("US dollars have two decimals: \(error)") // never rounded silently
    }
    return (total, shares)
}

// MARK: Cards

func checkCard(number: String, expiry: String, securityCode: String) -> String {
    let form = CardForm(number: number, expiry: expiry, securityCode: securityCode)
    switch form.validate() {
    case .success(let card):
        // print(card.number) shows "•••• 4242"; hand card.number.unmaskedDigits to your
        // payment provider's tokenization API and nowhere else.
        return "\(card.number.brand.displayName) \(card.number) is valid"
    case .failure(let errors):
        return [errors.number, errors.expiry, errors.securityCode]
            .compactMap { $0?.localizedDescription }
            .joined(separator: "\n")
    }
}

// MARK: Apple Pay

func makeApplePayRequest() throws -> ApplePayRequest {
    var request = ApplePayRequest(
        merchantIdentifier: "merchant.com.example.shop",
        merchantName: "Example Shop",
        countryCode: "US",
        currency: .usd,
        items: [
            ApplePaySummaryItem("Coffee beans", try Money("18.00", .usd)),
            ApplePaySummaryItem("Discount", try Money("-2.00", .usd))
        ]
    )
    request.shippingMethods = [
        ApplePayShippingMethod(id: "standard", label: "Standard", detail: "3–5 days", amount: try Money("4.99", .usd))
    ]
    request.requiredShippingFields = [.name, .postalAddress]
    try request.validate() // currency, labels, merchant ID, total ≥ 0
    return request
}

#if canImport(PassKit)
struct CheckoutButton: View {
    let request: ApplePayRequest
    let server: URL
    @State private var controller = ApplePayController()

    var body: some View {
        PayWithApplePayButton(.buy) {
            Task {
                do {
                    let outcome = try await controller.pay(request) { payment in
                        // Charge the token through your server and payment provider.
                        do {
                            try await chargeOnServer(payment.token.serverPayload(), server: server)
                            return .success
                        } catch {
                            return .failure(message: "The payment did not go through.")
                        }
                    }
                    if case .paid(let payment) = outcome {
                        print("Paid with", payment.token.displayName ?? "Apple Pay")
                    }
                } catch {
                    print("Apple Pay could not start:", error.localizedDescription)
                }
            }
        }
        .frame(height: 48)
    }
}
#endif

// MARK: Testing

@MainActor
func refundRemovesPro() async throws -> Bool {
    let client = TestStoreClient(products: [.preview(id: "pro.lifetime", kind: .nonConsumable)])
    let store = Store(catalog: [.nonConsumable("pro.lifetime", unlocks: "pro")], client: client)
    await store.start()

    guard case .purchased(let transaction) = try await store.purchase(store.products[0]) else { return false }
    let unlocked = store.hasEntitlement("pro")         // true
    try await client.refund(transaction.id)            // as if Apple refunded it
    await store.refreshEntitlements()
    return unlocked && !store.hasEntitlement("pro")    // access is gone
}

@MainActor
func buyAndSpendCoins() async throws -> Int64 {
    let client = TestStoreClient(products: [.preview(id: "coins.100", kind: .consumable)])
    let store = Store(
        catalog: [.consumable("coins.100", credits: 100, to: "coins")],
        client: client,
        ledger: ConsumableLedger(fileURL: nil) // in memory, for tests and previews
    )
    await store.start()

    try await store.purchase(store.products[0], options: PurchaseOptions(quantity: 2))
    try await store.spend(50, of: "coins")
    return store.balance(of: "coins")                  // 150
}

// MARK: Helpers used by the samples

func sendToServer(_ signedTransaction: String, server: URL) async throws {
    var request = URLRequest(url: server.appending(path: "v1/transactions"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(["signedTransaction": signedTransaction])
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
}

func chargeOnServer(_ payload: Data, server: URL) async throws {
    var request = URLRequest(url: server.appending(path: "charges"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = payload
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
}
