# Accepting Apple Pay

Build a payment request from exact amounts, show the payment sheet and charge the token through
your payment provider.

## Overview

Apple Pay pays for physical goods and services: orders, tickets, rides. Digital content and
features used in the app must be sold with in-app purchases instead (see
<doc:SellingInAppPurchases>).

To take Apple Pay you need a merchant identifier, the Apple Pay capability in your app target,
and a payment provider that processes Apple Pay tokens. Apple's
[Apple Pay documentation](https://developer.apple.com/documentation/passkit/apple-pay) covers
the setup.

### Describe the payment

``ApplePayRequest`` keeps every amount as ``Money`` in the request's currency:

```swift
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
```

``ApplePayRequest/validate()`` reports what PassKit would reject or show wrongly as an
``ApplePayRequestError``: a merchant identifier that does not start with `merchant.`, a country
code that is not two upper-case letters, an amount in another currency, an empty or overlong
label, a negative shipping amount, or a total below zero for any shipping choice. The total
line shows ``ApplePayRequest/merchantName``, as Apple's Human Interface Guidelines ask.

### Show the payment sheet

```swift
let controller = ApplePayController()

let outcome = try await controller.pay(request) { payment in
    // Charge the token through your server and payment provider.
    do {
        try await api.charge(payment.token.serverPayload())
        return .success
    } catch {
        return .failure(message: "The payment did not go through.")
    }
}
switch outcome {
case .paid(let payment): showReceipt(for: payment)
case .failed: break // the person saw the error on the sheet
case .cancelled: break
}
```

``ApplePayController`` uses `PKPaymentAuthorizationController`, so it works from SwiftUI
without a view controller. The `authorize` closure runs when the person authorizes with Face ID,
Touch ID or the side button; the sheet waits for its result. If the sheet times out while the
closure is still charging, the outcome waits for the charge, so a payment that went through is
not reported as cancelled.

Use SwiftUI's `PayWithApplePayButton` to start the payment, and check
``ApplePayController/canMakePayments(using:capabilities:)`` to decide between a buy button and a
set-up button.

### Send the token to your server

``ApplePayToken/serverPayload()`` encodes the token in the structure of Apple's
`PKPaymentToken`, with the encrypted payment data as base64. Your server passes it to the
payment provider; most providers take the `paymentData` value as their Apple Pay token
parameter. The token never prints its payment data: `print(payment.token)` shows only the card
name and the data size.

In the simulator, Apple Pay shows test cards and returns a token with empty payment data, which
is enough to build and test the flow.

## See Also

- ``ApplePayRequest``
- ``ApplePayController``
- <doc:WorkingWithMoney>
