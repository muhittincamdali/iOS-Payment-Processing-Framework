# Selling In-App Purchases

Deliver every purchase exactly once, keep access in step with renewals and refunds, and tell
the person what happened.

## Overview

``Store`` wraps StoreKit 2 with the steps Apple's guidance asks for and that are easy to get
wrong: start listening for transactions at launch, check the signature, deliver the content,
and only then finish the transaction.

### Create one store at launch

```swift
@main
struct ShopApp: App {
    @State private var store = Store(catalog: [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        .consumable("coins.100")
    ]) { transaction in
        // Runs for every new verified transaction, before StoreKit finishes it.
        if transaction.productID == "coins.100" {
            try await Wallet.shared.add(100 * transaction.purchasedQuantity, for: transaction.id)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task { await store.start() }
        }
    }
}
```

Starting at launch matters: a subscription renews, a parent approves an Ask to Buy request, or a
refund arrives while the app is closed, and StoreKit hands these over the next time the app
listens.

### How a transaction is handled

Every transaction, whether it comes from ``Store/purchase(_:options:)``, from the updates
StoreKit sends, or from the unfinished transactions at launch, takes the same path:

1. A transaction StoreKit cannot verify is never delivered or finished. ``Store/lastError`` is
   set to ``StoreError/verificationFailed(productID:reason:)``.
2. A verified transaction goes to your `deliver` closure. Credit coins there, or send
   ``StoreTransaction/signedTransaction`` to your server.
3. Only after `deliver` returns is the transaction finished. If `deliver` throws, the
   transaction stays unfinished and StoreKit sends it again on the next ``Store/start()``.
4. ``Store/entitlements`` is recomputed from StoreKit's current entitlements.

Within one launch, a transaction is delivered once even if it arrives both as unfinished and as
an update. A refund of a delivered transaction is delivered again, with
``StoreTransaction/revocationDate`` set, so you can take back consumables.

Because a crash can happen between `deliver` and finishing, make delivery idempotent: remember
the identifiers of credited transactions, as the example app's wallet does.

### Check access

```swift
if store.hasEntitlement("pro") {
    ProFeatures()
}
```

``Store/hasEntitlement(_:)`` compares the expiration date with the current time, so access ends
on time even between refreshes. The store also schedules a refresh for the next expiration date,
so ``Store/entitlements`` drops a subscription that runs out while the app is open.

``EntitlementResolver`` decides what counts: refunded and upgraded transactions grant nothing,
auto-renewable subscriptions last until their expiration date, non-renewing subscriptions for
the ``ProductDefinition/duration`` you give, and non-consumables for good. When several
transactions grant the same entitlement, a lifetime purchase wins, then the one that ends last.

### Handle the outcome of a purchase

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

``Store/purchase(_:options:)`` throws a ``StoreError``. Pass an app account token to link the
purchase to your own account record; it comes back in the transaction and in App Store Server
Notifications. Quantities above 1 are only allowed for consumables, and at most
``PurchaseOptions/maximumQuantity``.

### Restore purchases

StoreKit 2 keeps purchases in sync by itself. Offer a **Restore Purchases** button that calls
``Store/restorePurchases()`` for people who switched accounts; it may ask them to sign in, so do
not call it on your own.

## See Also

- <doc:VerifyingPurchasesOnYourServer>
- <doc:TestingPurchases>
