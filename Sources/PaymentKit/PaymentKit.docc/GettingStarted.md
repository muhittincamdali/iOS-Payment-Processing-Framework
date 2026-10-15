# Getting Started

Add the package, sell a subscription and a lifetime unlock, and see the purchase go through in
the simulator.

## Overview

This article starts from a new iOS app in Xcode and ends with a list of products that can be
bought in the simulator, using StoreKit testing in Xcode so no App Store Connect setup is needed
yet.

### Add the package

In Xcode, choose **File › Add Package Dependencies…**, enter
`https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git` and add the
`PaymentKit` library to your app target. In a `Package.swift`:

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

PaymentKit needs iOS 17, macOS 14, watchOS 10 or visionOS 1, and Swift 6.2. It has no
dependencies besides Apple's SDK.

### Describe what you sell

A ``ProductDefinition`` names a product from App Store Connect and the entitlement it unlocks.
Several products can unlock the same entitlement:

```swift
let catalog: [ProductDefinition] = [
    .autoRenewable("pro.monthly", unlocks: "pro"),
    .nonConsumable("pro.lifetime", unlocks: "pro")
]
```

### Show the products

Replace the `ContentView.swift` of the app with:

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

``Store/start()`` loads the products, delivers transactions that were never finished and starts
listening for updates. Call it once, as early as possible; in a real app, create the store in
your `App` and keep it for the app's lifetime.

### Try it in the simulator

Until the products exist in App Store Connect, let Xcode act as the App Store:

1. Choose **File › New › File from Template… › StoreKit Configuration File** and add an
   auto-renewable subscription `pro.monthly` and a non-consumable `pro.lifetime`.
2. In **Product › Scheme › Edit Scheme… › Run › Options**, select the file as the
   **StoreKit Configuration**.
3. Run the app, tap a product and confirm the purchase. The text changes to
   **Pro is unlocked**.

Xcode reads the prices of the configuration file with the simulator's region settings. In a
region that writes decimals with a comma, `4.99` becomes `4`; run the simulator in a region that
uses a period, such as the United States, while you test prices.

## Next steps

- <doc:SellingInAppPurchases> covers consumables, delivery before finishing, Ask to Buy and
  errors.
- <doc:VerifyingPurchasesOnYourServer> sends each purchase to a server that checks Apple's
  signature.
- <doc:AcceptingApplePay> takes payments for physical goods and services.
