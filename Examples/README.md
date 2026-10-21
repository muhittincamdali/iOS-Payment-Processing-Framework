# Examples

## PaymentLab

An iOS app that uses PaymentKit from this checkout (a local package reference to `../..`):

- **Store**: Pro monthly and yearly subscriptions (the monthly one with a free week), Pro
  Lifetime and a pack of 100 coins from [`Products.storekit`](PaymentLab/PaymentLab/Products.storekit);
  the Pro status with its end date, the coin balance (credited once per transaction) and Restore
  Purchases;
- **Checkout**: a cart with a discount and two delivery choices, paid with the Apple Pay button
  through `ApplePayController`. There is no payment provider behind it: the app accepts the
  authorization and shows what a server would receive;
- **Card**: a card form that groups the digits as you type, shows the brand and reports an error
  under each field.

Run it:

1. Open `Examples/PaymentLab/PaymentLab.xcodeproj` in Xcode 26 or later.
2. Choose the **PaymentLab** scheme and an iPhone simulator.
3. Press **Run** (⌘R). The scheme uses `Products.storekit`, so purchases go through StoreKit
   testing in Xcode and nothing is charged.

StoreKit testing reads the prices in `Products.storekit` with the simulator's region settings: in
a region that writes decimals with a comma, `4.99` becomes `4`. Run the simulator in English (US)
or another region that uses a period.

### With the receipt server

Start the server for Xcode transactions, then run the app with its address:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=io.github.muhittincamdali.PaymentLab APPLE_ENVIRONMENT=Xcode \
  ALLOW_UNVERIFIED_TRANSACTIONS=1 npm start
```

In Xcode, add `PAYMENTLAB_SERVER_URL` = `http://127.0.0.1:8787` under **Product › Scheme ›
Edit Scheme… › Run › Arguments › Environment Variables**. Every purchase is now sent to the
server before StoreKit finishes it, and the Store tab shows the server's answer.

### Tests

`PaymentLabTests` run PaymentKit's `Store` against real StoreKit through `SKTestSession`:
products and prices, a subscription, coins, a refund, Ask to Buy and an expiry under an
accelerated clock. With the receipt server running, one more test checks that the server
verified the purchase. `PaymentLabUITests` drive the three tabs, including the Apple Pay sheet.

```sh
cd Examples/PaymentLab
TEST_RUNNER_PAYMENTLAB_SERVER_URL=http://127.0.0.1:8787 \
  xcodebuild test -scheme PaymentLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Without `TEST_RUNNER_PAYMENTLAB_SERVER_URL`, the server test is skipped.
[`scripts/capture-screenshots.sh`](../scripts/capture-screenshots.sh) runs the UI tests in light
and dark appearance and saves the README screenshots.

The README samples live in
[`PaymentLab/ReadmeSamples.swift`](PaymentLab/PaymentLab/ReadmeSamples.swift). The README copies
its code from that file, and the package's test target compiles and runs it through the symlink
`Tests/PaymentKitTests/ReadmeExamples.swift`.

The project file is made with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from
[`project.yml`](PaymentLab/project.yml) and committed, so you only need XcodeGen after editing
`project.yml`.

## ReceiptServer

A Node 24 server that verifies StoreKit transactions with Apple's
[App Store Server Library](https://github.com/apple/app-store-server-library-node) and keeps the
entitlements of each account:

| Request | What it does |
| --- | --- |
| `POST /v1/transactions` with `{"signedTransaction": "…"}` | Verifies the JWS from `StoreTransaction.signedTransaction`, records it for the app account token and returns the account's entitlements and coins |
| `POST /v1/notifications` with `{"signedPayload": "…"}` | Verifies an App Store Server Notification V2 and records the transaction and renewal information inside it, so a refund removes access and a Billing Grace Period keeps it |
| `GET /v1/accounts/:id` | Returns the entitlements and coins of `token:<app account token>` or `original:<original transaction ID>` |
| `GET /health` | Returns the environment the server runs in |

Settings come from environment variables:

| Variable | Meaning |
| --- | --- |
| `BUNDLE_ID` | The app's bundle identifier (required) |
| `APPLE_ENVIRONMENT` | `Production`, `Sandbox`, `Xcode` or `LocalTesting` (required) |
| `APP_APPLE_ID` | The app's numeric Apple ID (required in `Production`) |
| `ALLOW_UNVERIFIED_TRANSACTIONS` | `1` to accept `Xcode` and `LocalTesting` transactions, which no one can verify; refused when `NODE_ENV=production` |
| `ROOT_CERTS_DIR` | Folder of trusted root certificates; defaults to [`certs/`](ReceiptServer/certs) with Apple Root CA - G3 |
| `ONLINE_CHECKS` | `0` turns off the OCSP revocation checks against Apple |
| `PORT`, `HOST` | Where to listen; defaults to `127.0.0.1:8787` |

A transaction only moves forward: once a refunded or revoked copy is recorded, no other copy of
that transaction replaces it, so posting the signed purchase from before a refund again brings
back neither the access nor the coins. A refund counts whenever Apple signed it; any other copy
replaces the stored one only when Apple signed it later. A reversed refund (`REFUND_REVERSED`)
does not restore anything; handle that notification yourself if your app should.

A subscription whose renewal failed keeps its entitlement until its Billing Grace Period ends,
as on the device. The end comes from `gracePeriodExpiresDate` in the verified renewal information
of a notification such as `DID_FAIL_TO_RENEW` with the `GRACE_PERIOD` subtype, and applies to
the latest period of that subscription only. Renewal information replaces the stored one only
when Apple signed it later, so a later status without a grace period ends the access. Renewal
information for another subscription than the notification's transaction is refused. Without a
grace period, access ends at `expiresDate`, also while Apple retries the payment.

Request bodies are limited to 64 KB, signed values to 16 KB, and the in-memory ledger to 10 000
accounts with 1 000 transactions each; use a database in production. The tests (`npm test`)
build a certificate chain shaped like Apple's with `openssl` and check that verified data is
accepted and forged or foreign data is rejected.
