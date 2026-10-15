# `PaymentKit`

Sell in-app purchases with StoreKit 2, take Apple Pay, and handle amounts and card details
without rounding errors or leaks.

## Overview

PaymentKit is a Swift package for the payment code of an app on Apple platforms. It has three
parts that work alone or together:

- **In-app purchases.** ``Store`` loads products, shows the purchase sheet, listens for
  renewals, refunds and Ask to Buy approvals, delivers each verified transaction before it is
  finished, and keeps the list of ``Entitlement``s the person has. ``TestStoreClient`` runs the
  same logic in unit tests and previews.
- **Apple Pay.** ``ApplePayRequest`` describes a payment with ``Money`` values and is checked
  before PassKit sees it; ``ApplePayController`` shows the payment sheet and reports the
  outcome with async/await.
- **Amounts and cards.** ``Money`` stores whole minor units of a ``Currency``, so `19.99`
  dollars are `1999` cents and never `19.989999`; ``CardNumber``, ``CardExpiry`` and
  ``CardSecurityCode`` validate what a person types and never print in full.

Every way into the package checks its input: amounts with too many decimals, `NaN`, values
beyond ``Money/maximumMinorUnits``, malformed currency codes, oversized text and
out-of-range quantities throw a typed error instead of being rounded or trapping.

The repository also has an iOS example app, PaymentLab, and a Node server that verifies
purchases with Apple's App Store Server Library; see <doc:VerifyingPurchasesOnYourServer>.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:SellingInAppPurchases>
- <doc:VerifyingPurchasesOnYourServer>
- <doc:AcceptingApplePay>
- <doc:AcceptingCards>
- <doc:WorkingWithMoney>
- <doc:TestingPurchases>

### In-app purchases

- ``Store``
- ``ProductDefinition``
- ``StoreProduct``
- ``SubscriptionPeriod``
- ``PurchaseOptions``
- ``Entitlement``
- ``EntitlementResolver``
- ``StoreError``

### Transactions and the App Store

- ``StoreTransaction``
- ``TransactionEvent``
- ``StoreClient``
- ``AppStoreClient``
- ``PurchaseResult``
- ``TestStoreClient``

### Apple Pay

- ``ApplePayRequest``
- ``ApplePaySummaryItem``
- ``ApplePayShippingMethod``
- ``ApplePayNetwork``
- ``ApplePayCapabilities``
- ``ApplePayContactField``
- ``ApplePayController``
- ``ApplePayPayment``
- ``ApplePayToken``
- ``ApplePayContact``
- ``ApplePayAuthorizationResult``
- ``ApplePayOutcome``
- ``ApplePayRequestError``
- ``ApplePayError``

### Money

- ``Money``
- ``Currency``
- ``MoneyError``

### Cards

- ``CardForm``
- ``CardFormErrors``
- ``CardDetails``
- ``CardNumber``
- ``CardBrand``
- ``CardExpiry``
- ``CardSecurityCode``
- ``CardValidationError``
