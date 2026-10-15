import PassKit
import PaymentKit
import SwiftUI

/// A cart paid with Apple Pay through `ApplePayRequest` and `ApplePayController`.
struct CheckoutScreen: View {
    @State private var shippingID = "standard"
    @State private var controller = ApplePayController()
    @State private var result: String?

    private var request: ApplePayRequest { CheckoutCart.request(shippingID: shippingID) }

    var body: some View {
        NavigationStack {
            List {
                Section("Cart") {
                    ForEach(request.items, id: \.label) { item in
                        LabeledContent(item.label, value: item.amount.formatted(locale: .labLocale))
                    }
                }

                Section("Delivery") {
                    Picker("Delivery", selection: $shippingID) {
                        ForEach(request.shippingMethods) { method in
                            Text("\(method.label) · \(method.amount.formatted(locale: .labLocale))")
                                .tag(method.id)
                                .accessibilityIdentifier("shipping.\(method.id)")
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    LabeledContent("Total") {
                        Text(totalText).font(.headline).monospacedDigit()
                    }
                    .accessibilityIdentifier("checkout.total")
                }

                Section {
                    if ApplePayController.canMakePayments() {
                        PayWithApplePayButton(.checkout) { pay() }
                            .frame(height: 48)
                            .listRowInsets(EdgeInsets())
                            .accessibilityIdentifier("checkout.applePay")
                    } else {
                        Text("Apple Pay is not available on this device.")
                    }
                } footer: {
                    Text("This example has no payment provider: it accepts the authorization and shows what your server would receive.")
                }

                if let result {
                    Section("Last payment") {
                        Text(result)
                            .font(.subheadline)
                            .accessibilityIdentifier("checkout.result")
                    }
                }
            }
            .navigationTitle("Checkout")
        }
    }

    private var totalText: String {
        (try? request.total(shippingMethodID: shippingID).formatted(locale: .labLocale)) ?? "–"
    }

    private func pay() {
        Task {
            do {
                let outcome = try await controller.pay(request) { payment in
                    // A real app sends payment.token.serverPayload() to its server here, which
                    // charges the token through its payment provider.
                    payment.token.serverPayload().isEmpty ? .failure(message: "The token is empty.") : .success
                }
                result = describe(outcome)
            } catch {
                result = error.localizedDescription
            }
        }
    }

    private func describe(_ outcome: ApplePayOutcome) -> String {
        switch outcome {
        case .paid(let payment):
            let card = payment.token.displayName ?? payment.token.network ?? "card"
            return "Paid \(totalText) with \(card). Token: \(payment.token.paymentData.count) bytes of payment data, transaction \(payment.token.transactionIdentifier.prefix(8))…"
        case .failed:
            return "The payment was declined."
        case .cancelled:
            return "Cancelled."
        }
    }
}

/// The demo cart, kept apart from the view so it reads like app code.
enum CheckoutCart {
    static func request(shippingID: String) -> ApplePayRequest {
        // The amounts are literals in the request's currency, so they cannot fail.
        let usd = { (text: String) in (try? Money(text, .usd)) ?? .zero(.usd) }
        var request = ApplePayRequest(
            merchantIdentifier: "merchant.io.github.muhittincamdali.paymentlab",
            merchantName: "Payment Lab",
            countryCode: "US",
            currency: .usd,
            items: [
                ApplePaySummaryItem("Coffee beans, 1 kg", usd("18.00")),
                ApplePaySummaryItem("Grinder brush", usd("6.50")),
                ApplePaySummaryItem("Welcome discount", usd("-2.00"))
            ]
        )
        let methods = [
            ApplePayShippingMethod(id: "standard", label: "Standard", detail: "3–5 business days", amount: usd("4.99")),
            ApplePayShippingMethod(id: "pickup", label: "Pick up in store", detail: "Ready tomorrow", amount: usd("0"))
        ]
        // The selected method goes first, so the sheet opens with it.
        request.shippingMethods = methods.filter { $0.id == shippingID } + methods.filter { $0.id != shippingID }
        request.requiredShippingFields = [.name, .postalAddress]
        return request
    }
}

extension Locale {
    /// The example shows prices in US English, as its StoreKit storefront does.
    static let labLocale = Locale(identifier: "en_US")
}
