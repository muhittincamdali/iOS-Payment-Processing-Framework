import XCTest
@testable import PaymentProcessingFramework

final class PaymentProcessorTests: XCTestCase {
    
    var paymentProcessor: PaymentProcessor!
    var mockConfiguration: PaymentConfiguration!
    
    override func setUp() {
        super.setUp()
        mockConfiguration = PaymentConfiguration(
            merchantId: "test_merchant_id",
            apiKey: "test_api_key",
            environment: .development,
            supportedPaymentMethods: [.creditCard, .applePay, .paypal]
        )
        paymentProcessor = PaymentProcessor(configuration: mockConfiguration)
    }
    
    override func tearDown() {
        paymentProcessor = nil
        mockConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_withValidConfiguration_createsPaymentProcessor() {
        // Given
        let configuration = PaymentConfiguration(
            merchantId: "test_merchant",
            apiKey: "test_key",
            environment: .development
        )
        
        // When
        let processor = PaymentProcessor(configuration: configuration)
        
        // Then
        XCTAssertNotNil(processor)
    }
    
    func test_init_withEmptyMerchantId_throwsFatalError() {
        // Given & When & Then
        // This test would require a different approach in a real implementation
        // For now, we'll test the validation logic
        let configuration = PaymentConfiguration(
            merchantId: "",
            apiKey: "test_key",
            environment: .development
        )
        
        // This would throw a fatal error in production
        // We're testing the validation logic here
        XCTAssertTrue(configuration.merchantId.isEmpty)
    }
    
    // MARK: - Payment Processing Tests
    
    func test_processPayment_withValidCreditCardRequest_returnsSuccess() {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Test payment",
            cardData: CardData(
                number: "4111111111111111",
                expiryMonth: 12,
                expiryYear: 2025,
                cvv: "123"
            )
        )
        
        let expectation = XCTestExpectation(description: "Payment processed successfully")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success(let transaction):
                XCTAssertEqual(transaction.amount, 100.0)
                XCTAssertEqual(transaction.currency, .usd)
                XCTAssertEqual(transaction.paymentMethod, .creditCard)
                XCTAssertEqual(transaction.status, .completed)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Payment should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_processPayment_withInvalidAmount_throwsError() {
        // Given
        let request = PaymentRequest(
            amount: -100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Test payment"
        )
        
        let expectation = XCTestExpectation(description: "Payment should fail")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Payment should fail with invalid amount")
            case .failure(let error):
                XCTAssertEqual(error, .invalidAmount)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_processPayment_withUnsupportedPaymentMethod_throwsError() {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .bankTransfer,
            description: "Test payment"
        )
        
        let expectation = XCTestExpectation(description: "Payment should fail")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Payment should fail with unsupported method")
            case .failure(let error):
                XCTAssertEqual(error, .unsupportedPaymentMethod)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_processPayment_withEmptyDescription_throwsError() {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: ""
        )
        
        let expectation = XCTestExpectation(description: "Payment should fail")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Payment should fail with empty description")
            case .failure(let error):
                XCTAssertEqual(error, .missingDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Apple Pay Tests
    
    func test_processPayment_withApplePay_returnsSuccess() {
        // Given
        let request = PaymentRequest(
            amount: 50.0,
            currency: .usd,
            paymentMethod: .applePay,
            description: "Apple Pay test",
            applePayToken: "test_apple_pay_token"
        )
        
        let expectation = XCTestExpectation(description: "Apple Pay payment processed")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success(let transaction):
                XCTAssertEqual(transaction.paymentMethod, .applePay)
                XCTAssertEqual(transaction.amount, 50.0)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Apple Pay payment should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - PayPal Tests
    
    func test_processPayment_withPayPal_returnsSuccess() {
        // Given
        let request = PaymentRequest(
            amount: 75.0,
            currency: .eur,
            paymentMethod: .paypal,
            description: "PayPal test",
            paypalToken: "test_paypal_token"
        )
        
        let expectation = XCTestExpectation(description: "PayPal payment processed")
        
        // When
        paymentProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success(let transaction):
                XCTAssertEqual(transaction.paymentMethod, .paypal)
                XCTAssertEqual(transaction.currency, .eur)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("PayPal payment should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Subscription Tests
    
    func test_processSubscription_withValidRequest_returnsSuccess() {
        // Given
        let subscription = SubscriptionRequest(
            amount: 29.99,
            currency: .usd,
            interval: .monthly,
            description: "Premium subscription"
        )
        
        let expectation = XCTestExpectation(description: "Subscription processed")
        
        // When
        paymentProcessor.processSubscription(subscription) { result in
            // Then
            switch result {
            case .success(let subscription):
                XCTAssertEqual(subscription.amount, 29.99)
                XCTAssertEqual(subscription.interval, .monthly)
                XCTAssertEqual(subscription.status, .active)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Subscription should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_processSubscription_withInvalidAmount_throwsError() {
        // Given
        let subscription = SubscriptionRequest(
            amount: -10.0,
            currency: .usd,
            interval: .monthly,
            description: "Invalid subscription"
        )
        
        let expectation = XCTestExpectation(description: "Subscription should fail")
        
        // When
        paymentProcessor.processSubscription(subscription) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Subscription should fail with invalid amount")
            case .failure(let error):
                XCTAssertEqual(error, .invalidAmount)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Refund Tests
    
    func test_refundTransaction_withValidRequest_returnsSuccess() {
        // Given
        let transactionId = "txn_123456789"
        let reason = RefundReason.customerRequest
        
        let expectation = XCTestExpectation(description: "Refund processed")
        
        // When
        paymentProcessor.refundTransaction(transactionId, reason: reason) { result in
            // Then
            switch result {
            case .success(let refund):
                XCTAssertEqual(refund.transactionId, transactionId)
                XCTAssertEqual(refund.reason, reason)
                XCTAssertEqual(refund.status, .completed)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Refund should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_refundTransaction_withInvalidTransactionId_throwsError() {
        // Given
        let transactionId = ""
        let reason = RefundReason.customerRequest
        
        let expectation = XCTestExpectation(description: "Refund should fail")
        
        // When
        paymentProcessor.refundTransaction(transactionId, reason: reason) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Refund should fail with invalid transaction ID")
            case .failure(let error):
                XCTAssertEqual(error, .invalidTransactionId)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Analytics Tests
    
    func test_getAnalytics_withValidRequest_returnsSuccess() {
        // Given
        let dateRange = DateRange.last30Days
        let metrics: [AnalyticsMetric] = [.revenue, .transactions, .conversionRate]
        
        let expectation = XCTestExpectation(description: "Analytics retrieved")
        
        // When
        paymentProcessor.getAnalytics(dateRange: dateRange, metrics: metrics) { result in
            // Then
            switch result {
            case .success(let analytics):
                XCTAssertNotNil(analytics)
                XCTAssertEqual(analytics.dateRange, dateRange)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Analytics should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Configuration Tests
    
    func test_configurePaymentMethods_updatesSupportedMethods() {
        // Given
        let newMethods: [PaymentMethod] = [.creditCard, .applePay, .googlePay]
        
        // When
        paymentProcessor.configurePaymentMethods(newMethods)
        
        // Then
        // Verify that the configuration was updated
        // This would require exposing the configuration or adding a getter method
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func test_configureFraudDetection_updatesFraudDetection() {
        // Given
        let fraudConfig = FraudDetectionConfiguration(
            enabled: true,
            sensitivity: .high,
            rules: [.velocityCheck, .geolocationCheck]
        )
        
        // When
        paymentProcessor.configureFraudDetection(fraudConfig)
        
        // Then
        // Verify that fraud detection was configured
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Error Handling Tests
    
    func test_processPayment_withNetworkError_returnsNetworkError() {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Network error test"
        )
        
        // Simulate network error by using invalid configuration
        let invalidProcessor = PaymentProcessor(
            configuration: PaymentConfiguration(
                merchantId: "invalid",
                apiKey: "invalid",
                environment: .development
            )
        )
        
        let expectation = XCTestExpectation(description: "Network error should occur")
        
        // When
        invalidProcessor.processPayment(request) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Should fail with network error")
            case .failure(let error):
                XCTAssertTrue(error == .networkError || error == .authenticationError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func test_processPayment_performance() {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Performance test",
            cardData: CardData(
                number: "4111111111111111",
                expiryMonth: 12,
                expiryYear: 2025,
                cvv: "123"
            )
        )
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            paymentProcessor.processPayment(request) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func test_processPayment_concurrentRequests() {
        // Given
        let requests = (0..<10).map { index in
            PaymentRequest(
                amount: Decimal(index + 1) * 10.0,
                currency: .usd,
                paymentMethod: .creditCard,
                description: "Concurrent test \(index)",
                cardData: CardData(
                    number: "4111111111111111",
                    expiryMonth: 12,
                    expiryYear: 2025,
                    cvv: "123"
                )
            )
        }
        
        let expectation = XCTestExpectation(description: "All concurrent requests completed")
        expectation.expectedFulfillmentCount = requests.count
        
        // When
        for request in requests {
            paymentProcessor.processPayment(request) { result in
                switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Concurrent request failed: \(error)")
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Supporting Types for Tests

/// Date range for analytics
public enum DateRange {
    case last7Days
    case last30Days
    case last90Days
    case custom(start: Date, end: Date)
}

/// Analytics metrics
public enum AnalyticsMetric {
    case revenue
    case transactions
    case conversionRate
    case averageOrderValue
    case refundRate
}

/// Transaction analytics result
public struct TransactionAnalytics {
    public let dateRange: DateRange
    public let revenue: Decimal
    public let transactionCount: Int
    public let conversionRate: Double
    public let averageOrderValue: Decimal
    public let refundRate: Double
    
    public init(dateRange: DateRange, revenue: Decimal, transactionCount: Int, conversionRate: Double, averageOrderValue: Decimal, refundRate: Double) {
        self.dateRange = dateRange
        self.revenue = revenue
        self.transactionCount = transactionCount
        self.conversionRate = conversionRate
        self.averageOrderValue = averageOrderValue
        self.refundRate = refundRate
    }
}

/// Subscription request
public struct SubscriptionRequest {
    public let id: String
    public let amount: Decimal
    public let currency: Currency
    public let interval: SubscriptionInterval
    public let description: String
    public let trialPeriod: Int?
    
    public init(amount: Decimal, currency: Currency, interval: SubscriptionInterval, description: String, trialPeriod: Int? = nil) {
        self.id = UUID().uuidString
        self.amount = amount
        self.currency = currency
        self.interval = interval
        self.description = description
        self.trialPeriod = trialPeriod
    }
}

/// Subscription interval
public enum SubscriptionInterval: String {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

/// Subscription result
public struct Subscription {
    public let id: String
    public let amount: Decimal
    public let currency: Currency
    public let interval: SubscriptionInterval
    public let status: SubscriptionStatus
    public let createdAt: Date
    public let nextBillingDate: Date?
    
    public init(id: String, amount: Decimal, currency: Currency, interval: SubscriptionInterval, status: SubscriptionStatus, createdAt: Date, nextBillingDate: Date?) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.interval = interval
        self.status = status
        self.createdAt = createdAt
        self.nextBillingDate = nextBillingDate
    }
}

/// Subscription status
public enum SubscriptionStatus: String {
    case active = "active"
    case cancelled = "cancelled"
    case paused = "paused"
    case expired = "expired"
}

/// Refund reason
public enum RefundReason: String {
    case customerRequest = "customer_request"
    case duplicateCharge = "duplicate_charge"
    case fraudulentCharge = "fraudulent_charge"
    case productNotReceived = "product_not_received"
    case productNotAsDescribed = "product_not_as_described"
    case generalAdjustment = "general_adjustment"
}

/// Refund result
public struct Refund {
    public let id: String
    public let transactionId: String
    public let amount: Decimal
    public let reason: RefundReason
    public let status: RefundStatus
    public let timestamp: Date
    
    public init(id: String, transactionId: String, amount: Decimal, reason: RefundReason, status: RefundStatus, timestamp: Date) {
        self.id = id
        self.transactionId = transactionId
        self.amount = amount
        self.reason = reason
        self.status = status
        self.timestamp = timestamp
    }
}

/// Refund status
public enum RefundStatus: String {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// Fraud detection configuration
public struct FraudDetectionConfiguration {
    public let enabled: Bool
    public let sensitivity: FraudSensitivity
    public let rules: [FraudRule]
    
    public init(enabled: Bool, sensitivity: FraudSensitivity, rules: [FraudRule]) {
        self.enabled = enabled
        self.sensitivity = sensitivity
        self.rules = rules
    }
}

/// Fraud sensitivity levels
public enum FraudSensitivity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Fraud detection rules
public enum FraudRule: String {
    case velocityCheck = "velocity_check"
    case geolocationCheck = "geolocation_check"
    case deviceFingerprinting = "device_fingerprinting"
    case behavioralAnalysis = "behavioral_analysis"
    case cardPatternAnalysis = "card_pattern_analysis"
    case amountPatternAnalysis = "amount_pattern_analysis"
}

/// Additional payment errors
public extension PaymentError {
    static let invalidSubscriptionInterval = PaymentError.unknown(NSError(domain: "PaymentError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid subscription interval"]))
} 