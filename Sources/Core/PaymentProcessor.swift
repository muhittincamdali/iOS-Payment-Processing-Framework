import Foundation
import Crypto
import Logging

/// A comprehensive payment processing framework for iOS applications
/// Built with Clean Architecture principles and enterprise-grade security
public final class PaymentProcessor {
    
    // MARK: - Properties
    
    private let configuration: PaymentConfiguration
    private let securityManager: SecurityManager
    private let networkManager: NetworkManager
    private let fraudDetector: FraudDetector
    private let analyticsManager: AnalyticsManager
    private let logger: Logger
    
    // MARK: - Initialization
    
    /// Creates a new payment processor with the specified configuration
    /// - Parameter configuration: The payment configuration containing merchant credentials and settings
    public init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        self.securityManager = SecurityManager(configuration: configuration)
        self.networkManager = NetworkManager(configuration: configuration)
        self.fraudDetector = FraudDetector(configuration: configuration)
        self.analyticsManager = AnalyticsManager(configuration: configuration)
        self.logger = Logger(label: "PaymentProcessor")
        
        setupLogging()
        validateConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// Processes a payment request with comprehensive security and fraud detection
    /// - Parameters:
    ///   - request: The payment request containing amount, currency, and payment method
    ///   - completion: Completion handler with the result of the payment processing
    public func processPayment(
        _ request: PaymentRequest,
        completion: @escaping (Result<Transaction, PaymentError>) -> Void
    ) {
        logger.info("Processing payment request: \(request.id)")
        
        Task {
            do {
                // Validate request
                try validatePaymentRequest(request)
                
                // Perform fraud detection
                let fraudRisk = await fraudDetector.analyzeRisk(for: request)
                guard fraudRisk.level == .low else {
                    throw PaymentError.fraudDetected(risk: fraudRisk)
                }
                
                // Process payment based on method
                let transaction = try await processPaymentByMethod(request)
                
                // Record analytics
                await analyticsManager.recordTransaction(transaction)
                
                // Return success
                await MainActor.run {
                    completion(.success(transaction))
                }
                
            } catch {
                logger.error("Payment processing failed: \(error.localizedDescription)")
                
                // Record error analytics
                await analyticsManager.recordError(error, for: request)
                
                await MainActor.run {
                    completion(.failure(error as? PaymentError ?? .unknown(error)))
                }
            }
        }
    }
    
    /// Processes a subscription payment with recurring billing support
    /// - Parameters:
    ///   - subscription: The subscription configuration
    ///   - completion: Completion handler with the result
    public func processSubscription(
        _ subscription: SubscriptionRequest,
        completion: @escaping (Result<Subscription, PaymentError>) -> Void
    ) {
        logger.info("Processing subscription: \(subscription.id)")
        
        Task {
            do {
                // Validate subscription
                try validateSubscriptionRequest(subscription)
                
                // Create subscription
                let subscriptionResult = try await createSubscription(subscription)
                
                // Record analytics
                await analyticsManager.recordSubscription(subscriptionResult)
                
                await MainActor.run {
                    completion(.success(subscriptionResult))
                }
                
            } catch {
                logger.error("Subscription processing failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    completion(.failure(error as? PaymentError ?? .unknown(error)))
                }
            }
        }
    }
    
    /// Refunds a transaction with full or partial amount support
    /// - Parameters:
    ///   - transactionId: The ID of the transaction to refund
    ///   - amount: The amount to refund (nil for full refund)
    ///   - reason: The reason for the refund
    ///   - completion: Completion handler with the result
    public func refundTransaction(
        _ transactionId: String,
        amount: Decimal? = nil,
        reason: RefundReason,
        completion: @escaping (Result<Refund, PaymentError>) -> Void
    ) {
        logger.info("Processing refund for transaction: \(transactionId)")
        
        Task {
            do {
                // Validate refund request
                try validateRefundRequest(transactionId: transactionId, amount: amount)
                
                // Process refund
                let refund = try await processRefund(transactionId: transactionId, amount: amount, reason: reason)
                
                // Record analytics
                await analyticsManager.recordRefund(refund)
                
                await MainActor.run {
                    completion(.success(refund))
                }
                
            } catch {
                logger.error("Refund processing failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    completion(.failure(error as? PaymentError ?? .unknown(error)))
                }
            }
        }
    }
    
    /// Retrieves transaction analytics for the specified time period
    /// - Parameters:
    ///   - dateRange: The date range for analytics
    ///   - metrics: The metrics to include in the analytics
    ///   - completion: Completion handler with analytics data
    public func getAnalytics(
        dateRange: DateRange,
        metrics: [AnalyticsMetric],
        completion: @escaping (Result<TransactionAnalytics, PaymentError>) -> Void
    ) {
        logger.info("Retrieving analytics for date range: \(dateRange)")
        
        Task {
            do {
                let analytics = try await analyticsManager.getAnalytics(
                    dateRange: dateRange,
                    metrics: metrics
                )
                
                await MainActor.run {
                    completion(.success(analytics))
                }
                
            } catch {
                logger.error("Analytics retrieval failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    completion(.failure(error as? PaymentError ?? .unknown(error)))
                }
            }
        }
    }
    
    /// Configures supported payment methods
    /// - Parameter methods: Array of payment methods to enable
    public func configurePaymentMethods(_ methods: [PaymentMethod]) {
        logger.info("Configuring payment methods: \(methods)")
        configuration.supportedPaymentMethods = methods
    }
    
    /// Configures fraud detection settings
    /// - Parameter configuration: The fraud detection configuration
    public func configureFraudDetection(_ configuration: FraudDetectionConfiguration) {
        logger.info("Configuring fraud detection")
        fraudDetector.updateConfiguration(configuration)
    }
    
    // MARK: - Private Methods
    
    private func setupLogging() {
        logger.logLevel = configuration.environment == .production ? .info : .debug
    }
    
    private func validateConfiguration() {
        if configuration.merchantId.isEmpty {
            logger.error("Merchant ID cannot be empty")
        }
        if configuration.apiKey.isEmpty {
            logger.error("API Key cannot be empty")
        }
    }
    
    private func validatePaymentRequest(_ request: PaymentRequest) throws {
        guard request.amount > 0 else {
            throw PaymentError.invalidAmount
        }
        
        guard configuration.supportedPaymentMethods.contains(request.paymentMethod) else {
            throw PaymentError.unsupportedPaymentMethod
        }
        
        guard !request.description.isEmpty else {
            throw PaymentError.missingDescription
        }
    }
    
    private func validateSubscriptionRequest(_ subscription: SubscriptionRequest) throws {
        guard subscription.amount > 0 else {
            throw PaymentError.invalidAmount
        }
        
        guard subscription.interval != .none else {
            throw PaymentError.invalidSubscriptionInterval
        }
        
        guard !subscription.description.isEmpty else {
            throw PaymentError.missingDescription
        }
    }
    
    private func validateRefundRequest(transactionId: String, amount: Decimal?) throws {
        guard !transactionId.isEmpty else {
            throw PaymentError.invalidTransactionId
        }
        
        if let amount = amount {
            guard amount > 0 else {
                throw PaymentError.invalidAmount
            }
        }
    }
    
    private func processPaymentByMethod(_ request: PaymentRequest) async throws -> Transaction {
        switch request.paymentMethod {
        case .creditCard:
            return try await processCreditCardPayment(request)
        case .applePay:
            return try await processApplePayPayment(request)
        case .googlePay:
            return try await processGooglePayPayment(request)
        case .paypal:
            return try await processPayPalPayment(request)
        case .bankTransfer:
            return try await processBankTransferPayment(request)
        }
    }
    
    private func processCreditCardPayment(_ request: PaymentRequest) async throws -> Transaction {
        logger.debug("Processing credit card payment")
        
        // Encrypt card data
        let encryptedData = try securityManager.encryptCardData(request.cardData)
        
        // Create network request
        let networkRequest = NetworkRequest(
            endpoint: .processPayment,
            method: .post,
            body: PaymentRequestBody(
                amount: request.amount,
                currency: request.currency,
                paymentMethod: request.paymentMethod,
                encryptedCardData: encryptedData,
                description: request.description
            )
        )
        
        // Send request
        let response: PaymentResponse = try await networkManager.sendRequest(networkRequest)
        
        // Create transaction
        return Transaction(
            id: response.transactionId,
            amount: request.amount,
            currency: request.currency,
            status: response.status,
            paymentMethod: request.paymentMethod,
            timestamp: Date(),
            metadata: response.metadata
        )
    }
    
    private func processApplePayPayment(_ request: PaymentRequest) async throws -> Transaction {
        logger.debug("Processing Apple Pay payment")
        
        // Apple Pay specific processing
        let networkRequest = NetworkRequest(
            endpoint: .processApplePay,
            method: .post,
            body: ApplePayRequestBody(
                amount: request.amount,
                currency: request.currency,
                token: request.applePayToken,
                description: request.description
            )
        )
        
        let response: PaymentResponse = try await networkManager.sendRequest(networkRequest)
        
        return Transaction(
            id: response.transactionId,
            amount: request.amount,
            currency: request.currency,
            status: response.status,
            paymentMethod: request.paymentMethod,
            timestamp: Date(),
            metadata: response.metadata
        )
    }
    
    private func processGooglePayPayment(_ request: PaymentRequest) async throws -> Transaction {
        logger.debug("Processing Google Pay payment")
        
        let networkRequest = NetworkRequest(
            endpoint: .processGooglePay,
            method: .post,
            body: GooglePayRequestBody(
                amount: request.amount,
                currency: request.currency,
                token: request.googlePayToken,
                description: request.description
            )
        )
        
        let response: PaymentResponse = try await networkManager.sendRequest(networkRequest)
        
        return Transaction(
            id: response.transactionId,
            amount: request.amount,
            currency: request.currency,
            status: response.status,
            paymentMethod: request.paymentMethod,
            timestamp: Date(),
            metadata: response.metadata
        )
    }
    
    private func processPayPalPayment(_ request: PaymentRequest) async throws -> Transaction {
        logger.debug("Processing PayPal payment")
        
        let networkRequest = NetworkRequest(
            endpoint: .processPayPal,
            method: .post,
            body: PayPalRequestBody(
                amount: request.amount,
                currency: request.currency,
                paypalToken: request.paypalToken,
                description: request.description
            )
        )
        
        let response: PaymentResponse = try await networkManager.sendRequest(networkRequest)
        
        return Transaction(
            id: response.transactionId,
            amount: request.amount,
            currency: request.currency,
            status: response.status,
            paymentMethod: request.paymentMethod,
            timestamp: Date(),
            metadata: response.metadata
        )
    }
    
    private func processBankTransferPayment(_ request: PaymentRequest) async throws -> Transaction {
        logger.debug("Processing bank transfer payment")
        
        let networkRequest = NetworkRequest(
            endpoint: .processBankTransfer,
            method: .post,
            body: BankTransferRequestBody(
                amount: request.amount,
                currency: request.currency,
                accountDetails: request.bankAccountDetails,
                description: request.description
            )
        )
        
        let response: PaymentResponse = try await networkManager.sendRequest(networkRequest)
        
        return Transaction(
            id: response.transactionId,
            amount: request.amount,
            currency: request.currency,
            status: response.status,
            paymentMethod: request.paymentMethod,
            timestamp: Date(),
            metadata: response.metadata
        )
    }
    
    private func createSubscription(_ subscription: SubscriptionRequest) async throws -> Subscription {
        logger.debug("Creating subscription")
        
        let networkRequest = NetworkRequest(
            endpoint: .createSubscription,
            method: .post,
            body: SubscriptionRequestBody(
                amount: subscription.amount,
                currency: subscription.currency,
                interval: subscription.interval,
                description: subscription.description,
                trialPeriod: subscription.trialPeriod
            )
        )
        
        let response: SubscriptionResponse = try await networkManager.sendRequest(networkRequest)
        
        return Subscription(
            id: response.subscriptionId,
            amount: subscription.amount,
            currency: subscription.currency,
            interval: subscription.interval,
            status: response.status,
            createdAt: Date(),
            nextBillingDate: response.nextBillingDate
        )
    }
    
    private func processRefund(
        transactionId: String,
        amount: Decimal?,
        reason: RefundReason
    ) async throws -> Refund {
        logger.debug("Processing refund for transaction: \(transactionId)")
        
        let networkRequest = NetworkRequest(
            endpoint: .processRefund,
            method: .post,
            body: RefundRequestBody(
                transactionId: transactionId,
                amount: amount,
                reason: reason
            )
        )
        
        let response: RefundResponse = try await networkManager.sendRequest(networkRequest)
        
        return Refund(
            id: response.refundId,
            transactionId: transactionId,
            amount: response.amount,
            reason: reason,
            status: response.status,
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

/// Configuration for the payment processor
public struct PaymentConfiguration {
    public let merchantId: String
    public let apiKey: String
    public let environment: Environment
    public var supportedPaymentMethods: [PaymentMethod]
    
    public init(
        merchantId: String,
        apiKey: String,
        environment: Environment,
        supportedPaymentMethods: [PaymentMethod] = []
    ) {
        self.merchantId = merchantId
        self.apiKey = apiKey
        self.environment = environment
        self.supportedPaymentMethods = supportedPaymentMethods
    }
}

/// Environment configuration
public enum Environment {
    case development
    case staging
    case production
}

/// Payment methods supported by the framework
public enum PaymentMethod: String, CaseIterable {
    case creditCard = "credit_card"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case paypal = "paypal"
    case bankTransfer = "bank_transfer"
}

/// Payment request containing all necessary information
public struct PaymentRequest {
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
    ) {
        self.id = UUID().uuidString
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.description = description
        self.cardData = cardData
        self.applePayToken = applePayToken
        self.googlePayToken = googlePayToken
        self.paypalToken = paypalToken
        self.bankAccountDetails = bankAccountDetails
    }
}

/// Currency enumeration
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

/// Card data for credit card payments
public struct CardData {
    public let number: String
    public let expiryMonth: Int
    public let expiryYear: Int
    public let cvv: String
    public let cardholderName: String?
    
    public init(
        number: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvv: String,
        cardholderName: String? = nil
    ) {
        self.number = number
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cvv = cvv
        self.cardholderName = cardholderName
    }
}

/// Bank account details for bank transfers
public struct BankAccountDetails {
    public let accountNumber: String
    public let routingNumber: String
    public let accountType: AccountType
    public let accountHolderName: String
    
    public init(
        accountNumber: String,
        routingNumber: String,
        accountType: AccountType,
        accountHolderName: String
    ) {
        self.accountNumber = accountNumber
        self.routingNumber = routingNumber
        self.accountType = accountType
        self.accountHolderName = accountHolderName
    }
}

/// Bank account types
public enum AccountType: String {
    case checking = "checking"
    case savings = "savings"
}

/// Transaction result from payment processing
public struct Transaction {
    public let id: String
    public let amount: Decimal
    public let currency: Currency
    public let status: TransactionStatus
    public let paymentMethod: PaymentMethod
    public let timestamp: Date
    public let metadata: [String: Any]
    
    public init(
        id: String,
        amount: Decimal,
        currency: Currency,
        status: TransactionStatus,
        paymentMethod: PaymentMethod,
        timestamp: Date,
        metadata: [String: Any]
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.status = status
        self.paymentMethod = paymentMethod
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Transaction status
public enum TransactionStatus: String {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case refunded = "refunded"
}

/// Payment errors that can occur during processing
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
    
    public var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidTransactionId:
            return "Invalid transaction ID"
        case .unsupportedPaymentMethod:
            return "Unsupported payment method"
        case .missingDescription:
            return "Payment description is required"
        case .fraudDetected(let risk):
            return "Fraud detected: \(risk.description)"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server processing error"
        case .authenticationError:
            return "Authentication failed"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
} 