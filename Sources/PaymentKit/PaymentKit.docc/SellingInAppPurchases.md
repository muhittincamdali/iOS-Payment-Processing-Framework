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
        .consumable("coins.100", credits: 100, to: "coins")
    ])

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
2. A verified transaction goes to your `deliver` closure, if you passed one, as a
   ``TransactionChange``: ``TransactionChange/granted(_:)`` for a purchase, renewal or approval,
   ``TransactionChange/revoked(_:)`` for a refund. Send ``StoreTransaction/signedTransaction`` to
   your server there.
3. A consumable defined with a credit is credited to the ``ConsumableLedger``, or taken back
   for a refund. StoreKit sends a consumable's refund only while its transaction is unfinished
   (see "Refunds, repeats and restarts").
4. Only after both succeed is the transaction finished. If either throws, the transaction stays
   unfinished and StoreKit sends it again on the next ``Store/start()``.
5. ``Store/entitlements`` is recomputed from StoreKit's current entitlements. For a refund it
   is also recomputed before step 2, so the refunded access ends even when `deliver` throws and
   the refund waits, unfinished, to be delivered again.

### Refunds, repeats and restarts

Access is never added up: ``Store/entitlements`` is computed again from the current verified
transactions after every change, so a refunded, revoked, expired or upgraded transaction stops
granting at once. When two refreshes overlap, a list read earlier never replaces one read
later, and ``Store/refreshEntitlements()`` returns only once the entitlements reflect a list read
after it was called.

A refund or revocation is final while the store runs. StoreKit can hand over a copy of a transaction it
read before the refund after the refund itself, for example as an unfinished transaction at
launch; that copy has no revocation date, but it is not delivered, credited or finished, and the
transaction grants no access even while StoreKit's list of current entitlements still has it.
The same holds for a copy whose delivery was under way when the refund arrived: once `deliver`
returns, the copy is neither credited nor finished, because StoreKit finishes a transaction by
its identifier and finishing the copy would finish a refund whose delivery failed.

Coins are different, because they are counted. The ledger credits each transaction once,
however often StoreKit sends it, and saves the balance together with the list of handled
transactions in one atomic write. If the app stops after the credit and before `finish()`,
StoreKit sends the transaction again on the next launch and the ledger credits nothing.

A refund that reaches the app takes the credit back once, even if the coins were spent; the
balance can then be below zero, and ``Store/spend(_:of:)`` refuses until it is positive again.
Decide what else that means in your app. The ledger takes back the balance and amount it
recorded for the purchase, so a refund still counts after an app update removed the product from
the catalog, left it to `deliver` or changed its credit.

StoreKit sends the refund of a consumable only while its transaction is unfinished, for example
because its delivery failed; the ledger then takes back what the purchase credited, or keeps it
from crediting anything. Once the transaction is finished, the refund does not reach the app: neither the updates nor the unfinished
transactions carry it, also not after a relaunch. This was observed with StoreKit testing in
Xcode 27.1, also with `SKIncludeConsumableInAppPurchaseHistory`, and PaymentLab's
`StoreKitEndToEndTests` check it. Coins that were credited and then refunded therefore stay in
the ledger on the device. The App Store tells your server, with a `REFUND` App Store Server
Notification, so the server is the only reliable record of refunded coins: keep balances that
matter there, as the example receipt server does, and show the server's balance in the app.

Your `deliver` closure runs at least once per transaction, so whatever it does must accept
repeats; the example receipt server keys everything on the transaction identifier.

### Spend coins

```swift
Text("\(store.balance(of: "coins")) coins")

Button("Unlock the level for 30 coins") {
    Task {
        do {
            try await store.spend(30, of: "coins")
        } catch .insufficientBalance {
            showCoinStore = true
        } catch {
            message = error.localizedDescription
        }
    }
}
```

The ledger lives on the device. For anything of value, keep the balance on your server, which
receives App Store Server Notifications for refunds even when the app is not running; see
<doc:VerifyingPurchasesOnYourServer>.

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

When the App Store cannot renew a subscription and you turned on Billing Grace Period in App
Store Connect, the person keeps access until the grace period ends. ``AppStoreClient`` reads the
subscription's verified renewal status for each subscription StoreKit lists:

- in a grace period, ``StoreTransaction/gracePeriodExpirationDate`` holds its end, and access
  lasts until then instead of the expiration date;
- in billing retry, expired or revoked for the transaction StoreKit listed, the subscription
  grants nothing;
- when the status cannot be read or verified, StoreKit's list counts as it is.

Without a grace period, access ends at the expiration date, also while the App Store retries
the payment. The store schedules a refresh for the end of the grace period as for any other
expiration date.

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
