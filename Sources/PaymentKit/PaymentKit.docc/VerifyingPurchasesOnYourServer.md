# Verifying Purchases on Your Server

Send each purchase to your server, verify Apple's signature there, and grant access from the
server's records.

## Overview

StoreKit 2 verifies transactions on the device, which is enough for an app that unlocks
features locally. When purchases unlock something on a server (an account upgrade, synced
content, coins spent elsewhere), the server must verify the purchase itself: it cannot trust a
request that only says "I paid".

Every ``StoreTransaction`` carries ``StoreTransaction/signedTransaction``, the JSON Web
Signature (JWS) the App Store signed. Your server checks the signature and the certificate
chain up to Apple's root certificate with Apple's App Store Server Library, which exists for
[Swift](https://github.com/apple/app-store-server-library-swift),
[Node](https://github.com/apple/app-store-server-library-node),
[Java](https://github.com/apple/app-store-server-library-java) and
[Python](https://github.com/apple/app-store-server-library-python).

### Send the transaction from the delivery closure

Deliver to the server inside the `deliver` closure of ``Store``. The transaction is finished
only after the server answered, so a purchase made while the server was unreachable is sent
again on the next launch. Refunds come through the same closure as
``TransactionChange/revoked(_:)``, with the same signed transaction:

```swift
let store = Store(catalog: catalog) { change in
    let transaction = change.transaction
    var request = URLRequest(url: URL(string: "https://api.example.com/v1/transactions")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(["signedTransaction": transaction.signedTransaction])
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse) // stays unfinished; delivered again later
    }
}
```

The closure runs at least once per transaction, so the server must treat a repeat of a
transaction identifier as a repeat, not a new purchase.

Purchase with an app account token (``PurchaseOptions/appAccountToken``) so the server knows
which account the transaction belongs to. The token is part of the signed data, so it cannot be
swapped in transit.

### The example server

`Examples/ReceiptServer` in the repository is a Node 24 server built on Apple's library. It
answers:

| Request                                                   | What it does                                                                                                 |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `POST /v1/transactions` with `{"signedTransaction": "…"}` | Verifies the JWS, records it for the account and returns the account's entitlements                          |
| `POST /v1/notifications`                                  | Verifies an App Store Server Notification V2 and records the transaction inside it, so refunds remove access |
| `GET /v1/accounts/:id`                                    | Returns an account's entitlements and coins                                                                  |

It checks the bundle identifier and environment of every transaction, credits a consumable once
even if the same transaction is sent twice, and limits request bodies to 64 KB.

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

### Transactions from Xcode

Transactions made with a StoreKit configuration file in Xcode are signed by Xcode, not by the
App Store, so no server can verify them. Apple's library accepts them only in its `Xcode`
environment, without checking the signature. The example server refuses that environment
unless you set `ALLOW_UNVERIFIED_TRANSACTIONS=1`, and always when `NODE_ENV=production`:

```sh
BUNDLE_ID=io.github.muhittincamdali.PaymentLab APPLE_ENVIRONMENT=Xcode \
  ALLOW_UNVERIFIED_TRANSACTIONS=1 npm start
```

Run PaymentLab with `PAYMENTLAB_SERVER_URL=http://127.0.0.1:8787` in its scheme's environment
to see each purchase verified before it is finished.

## See Also

- <doc:SellingInAppPurchases>
- <doc:TestingPurchases>
