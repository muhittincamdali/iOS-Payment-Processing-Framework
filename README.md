# iOS Payment Processing Framework

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift&logoColor=white" alt="Swift"></a>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-15.0+-000000?style=flat&logo=apple&logoColor=white" alt="iOS"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

<p align="center">
  <b>Unified payment processing: Apple Pay, Stripe, In-App Purchases, and subscriptions.</b>
</p>

---

## Features

- **Apple Pay** — Native Apple Pay integration
- **Stripe** — Card payments with Stripe SDK
- **In-App Purchases** — StoreKit 2 integration
- **Subscriptions** — Recurring payments and management
- **Receipt Validation** — Server-side receipt verification

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git", from: "1.0.0")
]
```

## Apple Pay

```swift
import PaymentKit

let applePay = ApplePayManager()

let request = PaymentRequest(
    amount: 29.99,
    currency: "USD",
    merchantIdentifier: "merchant.com.yourapp"
)

let result = try await applePay.pay(request)
```

## In-App Purchases

```swift
let store = StoreManager()

// Fetch products
let products = try await store.fetchProducts(ids: ["premium_monthly", "premium_yearly"])

// Purchase
let transaction = try await store.purchase(products[0])

// Restore
try await store.restorePurchases()

// Check entitlements
if store.hasActiveSubscription("premium") {
    // Unlock premium features
}
```

## Stripe

```swift
let stripe = StripeManager(publishableKey: "pk_live_...")

let paymentIntent = try await stripe.createPaymentIntent(
    amount: 1999,
    currency: "usd"
)

let result = try await stripe.confirmPayment(paymentIntent)
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## License

MIT License. See [LICENSE](LICENSE).

## Author

**Muhittin Camdali** — [@muhittincamdali](https://github.com/muhittincamdali)
