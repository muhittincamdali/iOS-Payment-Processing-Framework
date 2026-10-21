# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-15

A rebuild of the package as `PaymentKit` on StoreKit 2, PassKit and Swift 6. The 1.x sources did
not compile with Xcode 27, and their payment, fraud and network managers returned simulated
results; they are removed (see "Removed").

### Added

- `Store`, an `@Observable` model for in-app purchases: loads the catalog's products, purchases
  them, listens for transaction updates from launch, delivers each verified transaction to a
  `deliver` closure before finishing it, and keeps `entitlements` current, including a refresh at
  the next expiration date. Unverified transactions are never delivered or finished; a failed
  delivery leaves the transaction unfinished for the next launch. `deliver` receives a
  `TransactionChange`, `.granted` or `.revoked`, so a refund cannot pass for a purchase.
- `ConsumableLedger` and `.consumable(_:credits:to:)`: coin-style balances credited once per
  transaction and taken back once on a refund, saved with the handled transactions in one
  atomic write; `Store.balance(of:)` and `Store.spend(_:of:)`.
- `ProductDefinition` (consumable, non-consumable, auto-renewable, non-renewing with a duration),
  `StoreProduct`, `SubscriptionPeriod`, `StoreTransaction`, `TransactionEvent`, `Entitlement`,
  `EntitlementResolver`, `PurchaseOptions` and the typed `StoreError`.
- `StoreClient` with `AppStoreClient` (StoreKit 2, `purchase(confirmIn:)` on visionOS) and
  `TestStoreClient`, an in-memory App Store for tests and previews that simulates Ask to Buy,
  renewals, refunds, upgrades, Family Sharing, repeated deliveries, purchases on other devices,
  failed renewals with a Billing Grace Period and unverified updates.
- Billing Grace Period: `AppStoreClient` reads each listed subscription's verified renewal
  status, `StoreTransaction.gracePeriodExpirationDate` holds the end of a grace period, and
  `EntitlementResolver` grants access until then. A subscription whose status is billing retry,
  expired or revoked grants nothing.
- `Money` and `Currency`: exact minor units with ISO 4217 digits, strict and locale-aware
  parsing that rejects misplaced grouping separators, a period or comma the locale does not use
  and digits `Decimal` would round, rounding rules, arithmetic that checks currencies and range, allocation by ratios without losing a
  minor unit, formatting and validating `Codable`.
- `CardNumber`, `CardBrand`, `CardExpiry`, `CardSecurityCode`, `CardForm`, `CardFormErrors` and
  `CardDetails`: brand detection, lengths, Luhn check, expiry through the end of the month in the
  Gregorian calendar whatever calendar the device uses, formatting while typing, and redaction in
  every text form.
- `ApplePayRequest` with `ApplePaySummaryItem`, `ApplePayShippingMethod`, `ApplePayNetwork`,
  `ApplePayCapabilities` and `ApplePayContactField`, validated before it becomes a
  `PKPaymentRequest`; `ApplePayController`, which shows the payment sheet and returns
  `ApplePayOutcome` with async/await; `ApplePayToken.serverPayload()` for payment providers.
- watchOS 10 and visionOS 1 support next to iOS 17 and macOS 14.
- Example app `Examples/PaymentLab` with StoreKit tests through `SKTestSession` and UI tests that
  include the Apple Pay sheet; `Examples/ReceiptServer`, a Node 24 server that verifies
  transactions and App Store Server Notifications with Apple's App Store Server Library, and
  keeps a subscription's entitlement through its Billing Grace Period from the renewal
  information in notifications.
- A DocC catalog with seven articles, published to GitHub Pages.
- `scripts/capture-screenshots.sh`, which produces the README screenshots from the UI tests.
- 130 Swift Testing tests, run on macOS and an iPhone simulator, including seeded random
  histories of purchases, repeats, refunds, upgrades and renewals.

### Changed

- Swift tools version 6.2 and the Swift 6 language mode; minimum iOS 17 and macOS 14. The
  library product is `PaymentKit`.
- CI, documentation, link and wording checks run through the shared workflows of
  `muhittincamdali/.github`.

### Removed

- `PaymentProcessor`, `NetworkManager`, `FraudDetector`, `SecurityManager`, `AnalyticsManager`,
  `PaymentSheet` and `PaywallView`, which simulated payments instead of calling a provider; use
  `ApplePayController` with your payment provider, or your provider's SDK.
- `ReceiptValidator`, which called Apple's deprecated `verifyReceipt` endpoint; verify
  `StoreTransaction.signedTransaction` on your server with the App Store Server Library.
- The `PaymentProcessingUI` and `PaymentProcessingAnalytics` products, the RevenueCat and
  SwiftyStoreKit migration helpers, and the CocoaPods spec.

### Security

- Amounts never round silently or trap: too many decimals, `NaN` and values beyond
  999 999 999 999 999 minor units throw, and parsed text is limited to 64 bytes.
- Card numbers and security codes print only masked (`•••• 4242`) in descriptions, `dump`,
  `Mirror` and the debugger, and the card types are not `Codable`.
- Purchase quantities are limited to StoreKit's 1...10, expiry refresh delays are clamped before
  they become a `Duration`, and caches of StoreKit objects and handled transactions are bounded.
- Access is recomputed from StoreKit's current verified transactions after every change and is
  never accumulated; a refresh that started before a refund cannot overwrite a newer one.
- Consumables cannot be credited twice: repeats, a restart between crediting and `finish()`, and
  a refund that arrives before its purchase are handled by the ledger, whose file is size-checked
  and validated when read.
- A refund or revocation is final while a `Store` runs: a copy of the same transaction from
  before the refund that arrives after it is not delivered, credited or finished, and grants no
  access even while StoreKit still lists it. A copy whose delivery was under way when the refund
  arrived is neither credited nor finished once `deliver` returns, so the refund stays unfinished
  until it is delivered.
- A refund ends access before it is delivered: when `deliver` throws, for example because the
  server cannot be reached, the refund stays unfinished and is delivered later, but the refunded
  purchase grants nothing meanwhile.
- The example receipt server keeps a refund: once a revoked copy of a transaction is recorded, no
  other copy replaces it, so posting the signed purchase from before the refund again restores
  neither the access nor the coins. Other copies replace the stored one only when Apple signed
  them later. Its ledger is saved atomically to `LEDGER_FILE` before a change counts and read at
  start, so a restart does not forget a refund; a file it cannot read stops the server.

## [1.0.0] - 2026-02-02

### Added

- `PaymentProcessor` with simulated card, Apple Pay and subscription flows, fraud scoring and
  analytics, and StoreKit 2 helpers.

[Unreleased]: https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases/tag/v1.0.0
