# Testing Purchases

Test purchase logic in fast unit tests, then against real StoreKit in Xcode.

## Overview

``Store`` talks to the App Store only through the ``StoreClient`` protocol. In the app it uses
``AppStoreClient``; in tests and SwiftUI previews, ``TestStoreClient`` keeps products and
transactions in memory and behaves like the App Store where it matters to your code.

### Unit tests with TestStoreClient

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

``TestStoreClient`` can also:

- make the next purchase of a product succeed, wait for approval, be cancelled, fail
  verification or fail with an error (``TestStoreClient/setPurchaseBehavior(_:for:)``);
- approve an Ask to Buy purchase (``TestStoreClient/approvePendingPurchase(of:)``), renew a
  subscription (``TestStoreClient/renew(_:)``) or record a purchase made on another device
  (``TestStoreClient/purchaseOnAnotherDevice(_:)``); these arrive as updates, as they would from
  the App Store;
- refund a transaction or revoke a family member's shared purchase
  (``TestStoreClient/refund(_:)``), move a subscriber to a higher plan
  (``TestStoreClient/upgrade(from:to:)``), share a purchase from a family member
  (``TestStoreClient/shareFromFamily(_:)``) or send a transaction again
  (``TestStoreClient/redeliver(_:)``), to check that repeats and refunds never grant twice;
- report which transactions were finished
  (``TestStoreClient/finishedTransactionIDs``) and which are still unfinished.

Pass a fixed clock to both the client and the store to test expiration dates:

```swift
let start = Date()
let client = TestStoreClient(products: products) { start }
let store = Store(catalog: catalog, client: client, now: { start.addingTimeInterval(40 * 86_400) })
```

Consumables with a credit need a ledger; keep it in memory in tests so every test starts from
zero:

```swift
let store = Store(
    catalog: [.consumable("coins.100", credits: 100, to: "coins")],
    client: client,
    ledger: ConsumableLedger(fileURL: nil)
)
```

PaymentKit's own tests replay random histories of purchases, repeats, refunds, upgrades and
renewals and check that the coins and access always equal what was paid for and not refunded.

### StoreKit testing in Xcode

Unit tests that run inside your app can drive real StoreKit with `SKTestSession` and a StoreKit
configuration file. PaymentLab's `StoreKitEndToEndTests` do this for purchases, refunds, Ask to
Buy and an expiry under an accelerated clock:

```swift
let session = try SKTestSession(configurationFileNamed: "Products")
session.disableDialogs = true
session.clearTransactions()
session.timeRate = .monthlyRenewalEveryThirtySeconds // a one-week trial ends after about 7 seconds
```

Two things to know about StoreKit testing in Xcode:

- `clearTransactions()` takes effect after a moment; wait until `Transaction.currentEntitlements`
  is empty before the next test starts.
- `finish()` takes effect after a moment too. Buying the same consumable again before that
  returns the earlier transaction; the ledger credits it once.
- Prices from the configuration file are read with the device's region settings, so in a region
  that writes decimals with a comma, `4.99` becomes `4`. Run the simulator in a region that uses
  a period.

## See Also

- ``TestStoreClient``
- ``StoreClient``
- <doc:SellingInAppPurchases>
