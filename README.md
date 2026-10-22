<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Latest version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Supported platforms: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Language version: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="License: MIT"></picture></a>
</p>

<p align="center">
<a href="#quick-start"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-en-light.svg" alt="Get started"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-en-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-en-light.svg" alt="Examples"></picture></a>
</p>

<!-- brand:end -->

PaymentKit is a Swift package for the payment code of apps on Apple platforms. It sells in-app
purchases with StoreKit 2, takes Apple Pay, and handles amounts and card details. It fixes the
parts that fail quietly: a purchase finished before its content was delivered is lost, a
`Decimal` literal such as `19.99` is really `19.98999999999999488`, a refund that arrives while
the app is closed never takes access away, and a card number ends up in a log through `print`.
The repository also has an iOS example app and a Node server that verifies purchases with
Apple's App Store Server Library. The package has no dependencies outside Apple's SDK.

## Highlights

- **Purchases delivered, then finished** — `Store` checks StoreKit's signature, hands each
  verified transaction to your `deliver` closure and finishes it only after that returns; a
  failed delivery comes back on the next launch. Refunds arrive as `.revoked`, never as a new
  purchase.
- **Coins credited exactly once** — consumables defined with a credit go into a ledger that
  saves the balance and the handled transactions in one atomic write, so repeats, restarts
  before `finish()` and refunds never credit twice.
- **Access that follows the App Store** — renewals, refunds, Ask to Buy approvals and purchases
  on other devices update `entitlements` by themselves, a subscription that runs out while the
  app is open is removed at its expiration date, and one the App Store could not renew keeps
  access until its Billing Grace Period ends.
- **Exact money** — `Money` stores minor units of an ISO 4217 currency; too many decimals, `NaN`,
  overflow and mixed currencies throw instead of rounding or crashing, and allocations never
  lose a cent.
- **Checked Apple Pay requests** — `ApplePayRequest` validates the merchant, currency, labels
  and totals before PassKit sees them, and `ApplePayController` reports the payment with
  async/await.
- **Card details that do not leak** — `CardNumber`, `CardSecurityCode` and `CardForm` validate
  input (brand, length, Luhn, expiry) and print as `•••• 4242` in logs, `dump` and the debugger.
- **Tested end to end** — 134 Swift Testing tests on macOS and an iPhone simulator, 11 StoreKit
  tests and 4 UI tests in the example app (real StoreKit through Xcode, the real Apple Pay
  sheet), and 38 tests for the receipt server.

## Quick start

**1. Add the package**

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Add the `PaymentKit` library to your app target.

**2. Import the module**

```swift
import PaymentKit
```

**3. Use it**

Replace the `ContentView.swift` of a new iOS app with:

```swift
import PaymentKit
import SwiftUI

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
```

To buy in the simulator before the products exist in App Store Connect, add a StoreKit
configuration file (**File › New › File from Template… › StoreKit Configuration File**) with an
auto-renewable subscription `pro.monthly` and a non-consumable `pro.lifetime`, and select it in
**Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**. Run the app and
tap a product: after the purchase the text reads **Pro is unlocked**.

## Installation

### Swift Package Manager

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Or add it to the `dependencies` in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git", from: "2.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "PaymentKit", package: "iOS-Payment-Processing-Framework")
    ])
]
```

## Usage

The samples below are copied from
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
which the example app and the package's tests compile.

### Selling in-app purchases

Create one `Store` when the app launches and call `start()` right away. Every new verified
transaction and every refund goes through `deliver` before StoreKit finishes it; throwing there
keeps it unfinished, and StoreKit delivers it again on the next launch.

```swift
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
```

`store.hasEntitlement("pro")` answers whether Pro is unlocked now. It is computed again from
StoreKit's verified transactions after every change, so a refund, an expiry or an upgrade takes
access away; it is never added up. Transactions StoreKit cannot verify are never delivered or
finished.

Coins are credited by a `ConsumableLedger` once per transaction, however often StoreKit sends
it. Spend them with `try await store.spend(30, of: "coins")`. The ledger is on the device and
sees only the refunds StoreKit sends: the refund of a pack that is not finished yet arrives, and
the pack credits nothing, but StoreKit does not send the refund of a finished pack to the app, so
those coins stay in the ledger. Only the server learns of that refund, from a `REFUND` App Store
Server Notification; for anything of value, the server is the source of truth.

### Handling a purchase

`purchase(_:options:)` throws a typed `StoreError`:

```swift
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
```

### Verifying purchases on a server

Each transaction carries `signedTransaction`, the JWS the App Store signed. Send it from
`deliver` (as `makeStore` above does) to a server that verifies it with Apple's App Store Server
Library. [`Examples/ReceiptServer`](Examples/ReceiptServer) is such a server, on Node 24:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

It checks the chain up to Apple Root CA - G3, the bundle identifier and the environment, keeps
the entitlements of each app account token in a file that a restart does not lose, takes App
Store Server Notifications so refunds remove access and a Billing Grace Period keeps it, credits
a consumable once, and limits every request. Transactions made with a StoreKit configuration
file in Xcode are not signed by the App Store; the server accepts them only with
`APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`, never with `NODE_ENV=production`.

### Money

```swift
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
    } catch MoneyError.tooManyFractionDigits {
        print("US dollars have two decimals") // never rounded silently
    }
    return (total, shares)
}
```

Write amounts as strings or minor units: `19.99` as a `Decimal` literal goes through `Double`,
and `Money` rejects it rather than charge `19.98999999999999488`.

### Apple Pay

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

```swift
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
```

### Card details

```swift
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
```

Collecting card numbers in your own fields puts the app in scope for PCI DSS; prefer Apple Pay or
your provider's card field where you can.

### Testing

`TestStoreClient` keeps products and transactions in memory and simulates refunds, renewals,
upgrades, Family Sharing, repeated deliveries, Ask to Buy approvals and purchases on other
devices, so purchase logic runs in plain unit tests:

```swift
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
```

## Demo

| Store | Checkout | Apple Pay sheet | Card form |
| ----- | -------- | --------------- | --------- |
| ![Pro unlocked after a subscription, light](docs/images/store-light.png) | ![Cart with delivery choices, light](docs/images/checkout-light.png) | ![Apple Pay sheet with the cart total, light](docs/images/apple-pay-light.png) | ![Card form with an error under each field, light](docs/images/card-light.png) |
| ![Pro unlocked after a subscription, dark](docs/images/store-dark.png) | ![Cart with delivery choices, dark](docs/images/checkout-dark.png) | ![Apple Pay sheet with the cart total, dark](docs/images/apple-pay-dark.png) | ![Card form with an error under each field, dark](docs/images/card-dark.png) |

The screenshots come from the UI tests of the example app on an iPhone simulator, run by
[`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh): a subscription bought
through StoreKit testing in Xcode, the cart and the real Apple Pay sheet with its total, and the
card form after checking a mistyped card.

To try it yourself, open `PaymentLab.xcodeproj` in [`Examples/PaymentLab`](Examples/PaymentLab),
choose an iPhone simulator and press **Run**. [Examples/README.md](Examples/README.md) shows how
to run it against the receipt server.

## Documentation

Reference documentation and articles:

- [API reference](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, published to GitHub Pages from `master`)
- Build it locally in Xcode with **Product › Build Documentation**, or from the command line:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Guides

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — add the package, list products and buy them in the simulator
  ([source](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — the path every transaction takes, refunds and repeats, coin balances, access checks and restoring
  ([source](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — sending signed transactions, the example server and Xcode transactions
  ([source](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — the request, its validation, the sheet and the token for your payment provider
  ([source](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — what is checked, formatting while typing and redaction
  ([source](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — which initializer to use, the errors and exact allocation
  ([source](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` and StoreKit testing in Xcode
  ([source](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Requirements

| Platform  | Minimum version       |
| --------- | --------------------- |
| iOS       | 17                    |
| macOS     | 14                    |
| watchOS   | 10                    |
| visionOS  | 1                     |
| Toolchain | Swift 6.2 · Xcode 26+ |

Apple Pay is available on all four platforms; in-app purchases on visionOS are shown in the
app's active window. `Money`, `Currency` and the card types use only Foundation. CI builds with
the default Xcode of GitHub's `macos-26` runner image; the package is developed with Xcode 27.
The receipt server needs Node 24.

## Architecture

- `Sources/PaymentKit` is split by job: `Money/` (`Money`, `Currency`, parsing and encoding),
  `Cards/` (number, brand, expiry, security code, form), `Store/` (store, entitlements, the
  App Store client and the test client) and `ApplePay/` (request, payment values, controller).
- `Store` is a `@MainActor` `@Observable` class. It reaches the App Store only through the
  `StoreClient` protocol: `AppStoreClient` wraps StoreKit 2, `TestStoreClient` keeps state in
  memory. `EntitlementResolver` is a pure type that turns transactions into access, tested
  without StoreKit. `ConsumableLedger` is an actor that credits each consumable transaction once
  and writes the balance and the handled transactions to disk in one atomic write.
- Input from outside is bounded and range-checked: text lengths for amounts and card fields,
  `Decimal` values before scaling and before conversion to `Int64`, expiry refresh delays before
  they become a `Duration`, purchase quantities, item counts and label lengths in Apple Pay
  requests, the caches of StoreKit objects and handled transactions, and the ledger file (size,
  entries, account names, `Int64` overflow).
- `Examples/PaymentLab` is an iOS app with app-hosted StoreKit tests (`SKTestSession`) and UI
  tests; `Examples/ReceiptServer` is a Node server on Apple's App Store Server Library.

Run the tests locally:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Roadmap

- Add the package to the Swift Package Index; `.spi.yml` is already in the repository.
- Subscription status and renewal information (`Product.SubscriptionInfo.Status`) next to
  entitlements, for billing retry and grace period messages.
- Offer codes and promotional offers signed by the receipt server.

## Contributing

Contributions are welcome. Read the [contributing guide](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) and the [code of conduct](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) before opening a pull request. Report security issues privately as described in the [security policy](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## License

Released under the MIT license. See [LICENSE](LICENSE).
