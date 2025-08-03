# API Reference

Complete API documentation for the iOS Payment Processing Framework.

## Table of Contents

- [PaymentProcessor](#paymentprocessor)
- [PaymentConfiguration](#paymentconfiguration)
- [PaymentRequest](#paymentrequest)
- [Transaction](#transaction)
- [SecurityManager](#securitymanager)
- [FraudDetector](#frauddetector)
- [AnalyticsManager](#analyticsmanager)
- [PaymentSheet](#paymentsheet)
- [Error Handling](#error-handling)

## PaymentProcessor

The main class for processing payments with enterprise-grade security and fraud detection.

### Initialization

```swift
public init(configuration: PaymentConfiguration)
```

Creates a new payment processor with the specified configuration.

**Parameters:**
- `configuration`: The payment configuration containing merchant credentials and settings

**Example:**
```swift
let configuration = PaymentConfiguration(
    merchantId: "your_merchant_id",
    apiKey: "your_api_key",
    environment: .production
)
let paymentProcessor = PaymentProcessor(configuration: configuration)
```

### Methods

#### processPayment

```swift
public func processPayment(
    _ request: PaymentRequest,
    completion: @escaping (Result<Transaction, PaymentError>) -> Void
)
```

Processes a payment request with comprehensive security and fraud detection.

**Parameters:**
- `request`: The payment request containing amount, currency, and payment method
- `completion`: Completion handler with the result of the payment processing

**Example:**
```swift
let request = PaymentRequest(
    amount: 99.99,
    currency: .usd,
    paymentMethod: .creditCard,
    description: "Premium Subscription"
)

paymentProcessor.processPayment(request) { result in
    switch result {
    case .success(let transaction):
        print("Payment successful: \(transaction.id)")
    case .failure(let error):
        print("Payment failed: \(error.localizedDescription)")
    }
}
```

#### processSubscription

```swift
public func processSubscription(
    _ subscription: SubscriptionRequest,
    completion: @escaping (Result<Subscription, PaymentError>) -> Void
)
```

Processes a subscription payment with recurring billing support.

**Parameters:**
- `subscription`: The subscription configuration
- `completion`: Completion handler with the result

**Example:**
```swift
let subscription = SubscriptionRequest(
    amount: 29.99,
    currency: .usd,
    interval: .monthly,
    description: "Premium subscription"
)

paymentProcessor.processSubscription(subscription) { result in
    switch result {
    case .success(let subscription):
        print("Subscription created: \(subscription.id)")
    case .failure(let error):
        print("Subscription failed: \(error)")
    }
}
```

#### refundTransaction

```swift
public func refundTransaction(
    _ transactionId: String,
    amount: Decimal? = nil,
    reason: RefundReason,
    completion: @escaping (Result<Refund, PaymentError>) -> Void
)
```

Refunds a transaction with full or partial amount support.

**Parameters:**
- `transactionId`: The ID of the transaction to refund
- `amount`: The amount to refund (nil for full refund)
- `reason`: The reason for the refund
- `completion`: Completion handler with the result

**Example:**
```swift
paymentProcessor.refundTransaction(
    "txn_123456789",
    amount: 50.0,
    reason: .customerRequest
) { result in
    switch result {
    case .success(let refund):
        print("Refund successful: \(refund.id)")
    case .failure(let error):
        print("Refund failed: \(error)")
    }
}
```

#### getAnalytics

```swift
public func getAnalytics(
    dateRange: DateRange,
    metrics: [AnalyticsMetric],
    completion: @escaping (Result<TransactionAnalytics, PaymentError>) -> Void
)
```

Retrieves transaction analytics for the specified time period.

**Parameters:**
- `dateRange`: The date range for analytics
- `metrics`: The metrics to include in the analytics
- `completion`: Completion handler with analytics data

**Example:**
```swift
paymentProcessor.getAnalytics(
    dateRange: .last30Days,
    metrics: [.revenue, .transactions, .conversionRate]
) { result in
    switch result {
    case .success(let analytics):
        print("Revenue: \(analytics.revenue)")
        print("Transactions: \(analytics.transactionCount)")
    case .failure(let error):
        print("Analytics error: \(error)")
    }
}
```

#### configurePaymentMethods

```swift
public func configurePaymentMethods(_ methods: [PaymentMethod])
```

Configures supported payment methods.

**Parameters:**
- `methods`: Array of payment methods to enable

**Example:**
```swift
paymentProcessor.configurePaymentMethods([
    .creditCard,
    .applePay,
    .googlePay,
    .paypal
])
```

#### configureFraudDetection

```swift
public func configureFraudDetection(_ configuration: FraudDetectionConfiguration)
```

Configures fraud detection settings.

**Parameters:**
- `configuration`: The fraud detection configuration

**Example:**
```swift
let fraudConfig = FraudDetectionConfiguration(
    enabled: true,
    sensitivity: .high,
    rules: [.velocityCheck, .geolocationCheck]
)
paymentProcessor.configureFraudDetection(fraudConfig)
```

## PaymentConfiguration

Configuration for the payment processor.

### Properties

```swift
public let merchantId: String
public let apiKey: String
public let environment: Environment
public var supportedPaymentMethods: [PaymentMethod]
```

### Initialization

```swift
public init(
    merchantId: String,
    apiKey: String,
    environment: Environment,
    supportedPaymentMethods: [PaymentMethod] = []
)
```

**Parameters:**
- `merchantId`: Your merchant identifier
- `apiKey`: Your API key for authentication
- `environment`: The environment (development, staging, production)
- `supportedPaymentMethods`: Array of supported payment methods

### Environment

```swift
public enum Environment {
    case development
    case staging
    case production
}
```

## PaymentRequest

Payment request containing all necessary information.

### Properties

```swift
public let id: String
public let amount: Decimal
public let currency: Currency
public let paymentMethod: PaymentMethod
public let description: String
public let cardData: CardData?
public let applePayToken: String?
public let googlePayToken: String?
public let paypalToken: String?
public let bankAccountDetails: BankAccountDetails?
```

### Initialization

```swift
public init(
    amount: Decimal,
    currency: Currency,
    paymentMethod: PaymentMethod,
    description: String,
    cardData: CardData? = nil,
    applePayToken: String? = nil,
    googlePayToken: String? = nil,
    paypalToken: String? = nil,
    bankAccountDetails: BankAccountDetails? = nil
)
```

**Parameters:**
- `amount`: The payment amount
- `currency`: The currency code
- `paymentMethod`: The payment method to use
- `description`: Description of the payment
- `cardData`: Credit card data (for credit card payments)
- `applePayToken`: Apple Pay token (for Apple Pay payments)
- `googlePayToken`: Google Pay token (for Google Pay payments)
- `paypalToken`: PayPal token (for PayPal payments)
- `bankAccountDetails`: Bank account details (for bank transfers)

## Transaction

Transaction result from payment processing.

### Properties

```swift
public let id: String
public let amount: Decimal
public let currency: Currency
public let status: TransactionStatus
public let paymentMethod: PaymentMethod
public let timestamp: Date
public let metadata: [String: Any]
```

### TransactionStatus

```swift
public enum TransactionStatus: String {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case refunded = "refunded"
}
```

## SecurityManager

Enterprise-grade security manager for payment processing.

### Methods

#### encryptCardData

```swift
public func encryptCardData(_ cardData: CardData) throws -> EncryptedCardData
```

Encrypts sensitive card data using AES-256 encryption.

**Parameters:**
- `cardData`: The card data to encrypt

**Returns:**
- `EncryptedCardData`: The encrypted card data

**Throws:**
- `SecurityError.encryptionFailed`: If encryption fails

#### decryptCardData

```swift
public func decryptCardData(_ encryptedData: EncryptedCardData) throws -> CardData
```

Decrypts encrypted card data.

**Parameters:**
- `encryptedData`: The encrypted card data

**Returns:**
- `CardData`: The decrypted card data

**Throws:**
- `SecurityError.decryptionFailed`: If decryption fails

#### tokenizeCardData

```swift
public func tokenizeCardData(_ cardData: CardData) throws -> CardToken
```

Tokenizes card data for secure storage.

**Parameters:**
- `cardData`: The card data to tokenize

**Returns:**
- `CardToken`: The card token

**Throws:**
- `SecurityError.tokenizationFailed`: If tokenization fails

#### validateCardData

```swift
public func validateCardData(_ cardData: CardData) throws
```

Validates card data for security and compliance.

**Parameters:**
- `cardData`: The card data to validate

**Throws:**
- `SecurityError.invalidCardNumber`: If card number is invalid
- `SecurityError.invalidExpiryDate`: If expiry date is invalid
- `SecurityError.invalidCVV`: If CVV is invalid
- `SecurityError.fraudulentCard`: If card is known to be fraudulent

## FraudDetector

AI-powered fraud detection system for payment processing.

### Methods

#### analyzeRisk

```swift
public func analyzeRisk(for request: PaymentRequest) async -> FraudRisk
```

Analyzes fraud risk for a payment request.

**Parameters:**
- `request`: The payment request to analyze

**Returns:**
- `FraudRisk`: The fraud risk assessment

#### updateConfiguration

```swift
public func updateConfiguration(_ configuration: FraudDetectionConfiguration)
```

Updates fraud detection configuration.

**Parameters:**
- `configuration`: The new fraud detection configuration

#### isKnownFraudulentCard

```swift
public func isKnownFraudulentCard(_ cardNumber: String) -> Bool
```

Checks if a card number is known to be fraudulent.

**Parameters:**
- `cardNumber`: The card number to check

**Returns:**
- `Bool`: True if the card is known to be fraudulent

## AnalyticsManager

Comprehensive analytics manager for payment processing.

### Methods

#### recordTransaction

```swift
public func recordTransaction(_ transaction: Transaction) async
```

Records a transaction for analytics.

**Parameters:**
- `transaction`: The transaction to record

#### recordSubscription

```swift
public func recordSubscription(_ subscription: Subscription) async
```

Records a subscription for analytics.

**Parameters:**
- `subscription`: The subscription to record

#### recordRefund

```swift
public func recordRefund(_ refund: Refund) async
```

Records a refund for analytics.

**Parameters:**
- `refund`: The refund to record

#### recordError

```swift
public func recordError(_ error: Error, for request: PaymentRequest) async
```

Records an error for analytics.

**Parameters:**
- `error`: The error that occurred
- `request`: The request that caused the error

#### getAnalytics

```swift
public func getAnalytics(
    dateRange: DateRange,
    metrics: [AnalyticsMetric]
) async throws -> TransactionAnalytics
```

Retrieves analytics for the specified time period and metrics.

**Parameters:**
- `dateRange`: The date range for analytics
- `metrics`: The metrics to include

**Returns:**
- `TransactionAnalytics`: The analytics data

**Throws:**
- `AnalyticsError.retrievalFailed`: If retrieval fails

#### subscribeToAnalytics

```swift
public func subscribeToAnalytics(_ callback: @escaping (TransactionAnalytics) -> Void)
```

Subscribes to real-time analytics updates.

**Parameters:**
- `callback`: Callback for real-time updates

#### generateReport

```swift
public func generateReport(
    reportType: ReportType,
    dateRange: DateRange
) async throws -> AnalyticsReport
```

Generates a comprehensive analytics report.

**Parameters:**
- `reportType`: The type of report to generate
- `dateRange`: The date range for the report

**Returns:**
- `AnalyticsReport`: The generated report

**Throws:**
- `AnalyticsError.reportGenerationFailed`: If report generation fails

#### exportAnalytics

```swift
public func exportAnalytics(
    format: ExportFormat,
    dateRange: DateRange
) async throws -> URL
```

Exports analytics data in various formats.

**Parameters:**
- `format`: The export format
- `dateRange`: The date range to export

**Returns:**
- `URL`: URL to the exported file

**Throws:**
- `AnalyticsError.exportFailed`: If export fails

## PaymentSheet

Premium payment sheet with beautiful animations and enterprise-grade UI.

### Initialization

```swift
public init(
    amount: Decimal,
    currency: Currency,
    onPaymentComplete: @escaping (Transaction) -> Void,
    onPaymentFailed: @escaping (PaymentError) -> Void = { _ in },
    onDismiss: @escaping () -> Void = {}
)
```

**Parameters:**
- `amount`: The payment amount
- `currency`: The currency
- `onPaymentComplete`: Callback for successful payment
- `onPaymentFailed`: Callback for failed payment
- `onDismiss`: Callback when sheet is dismissed

### Usage

```swift
PaymentSheet(
    amount: 99.99,
    currency: .usd,
    onPaymentComplete: { transaction in
        print("Payment successful: \(transaction.id)")
    },
    onPaymentFailed: { error in
        print("Payment failed: \(error)")
    }
)
```

## Error Handling

### PaymentError

```swift
public enum PaymentError: LocalizedError {
    case invalidAmount
    case invalidTransactionId
    case unsupportedPaymentMethod
    case missingDescription
    case fraudDetected(risk: FraudRisk)
    case networkError
    case serverError
    case authenticationError
    case unknown(Error)
}
```

### SecurityError

```swift
public enum SecurityError: LocalizedError {
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case tokenizationFailed(Error)
    case invalidCardNumber
    case invalidExpiryDate
    case invalidCVV
    case fraudulentCard
    case authenticationFailed
    case invalidSignature
    case rateLimitExceeded
}
```

### AnalyticsError

```swift
public enum AnalyticsError: LocalizedError {
    case retrievalFailed(Error)
    case reportGenerationFailed(Error)
    case exportFailed(Error)
    case storageError(Error)
}
```

### NetworkError

```swift
public enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case connectionFailed
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case authenticationError
    case rateLimitExceeded
    case serverError
    case unknown
}
```

## Supporting Types

### Currency

```swift
public enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case brl = "BRL"
}
```

### PaymentMethod

```swift
public enum PaymentMethod: String, CaseIterable {
    case creditCard = "credit_card"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case paypal = "paypal"
    case bankTransfer = "bank_transfer"
}
```

### CardData

```swift
public struct CardData {
    public let number: String
    public let expiryMonth: Int
    public let expiryYear: Int
    public let cvv: String
    public let cardholderName: String?
}
```

### DateRange

```swift
public enum DateRange {
    case last7Days
    case last30Days
    case last90Days
    case custom(start: Date, end: Date)
}
```

### AnalyticsMetric

```swift
public enum AnalyticsMetric {
    case revenue
    case transactions
    case conversionRate
    case averageOrderValue
    case refundRate
}
```

### ReportType

```swift
public enum ReportType: String {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case custom = "custom"
}
```

### ExportFormat

```swift
public enum ExportFormat: String {
    case csv = "csv"
    case json = "json"
    case pdf = "pdf"
}
```

---

For more detailed examples and implementation guides, see the [Getting Started Guide](GettingStarted.md) and [Examples](Examples/) directory. 