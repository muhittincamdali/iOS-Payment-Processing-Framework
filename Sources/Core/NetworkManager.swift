import Foundation
import Logging

/// Network manager for handling API requests and communication
/// Implements secure networking with retry logic and error handling
public final class NetworkManager {
    
    // MARK: - Properties
    
    private let configuration: PaymentConfiguration
    private let session: URLSession
    private let logger: Logger
    private let retryPolicy: RetryPolicy
    
    // MARK: - Initialization
    
    public init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        self.logger = Logger(label: "NetworkManager")
        self.retryPolicy = RetryPolicy(maxRetries: 3, backoffMultiplier: 2.0)
        
        // Configure URL session with security settings
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": "iOS-Payment-Processing-Framework/1.0.0",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    // MARK: - Public Methods
    
    /// Sends a network request with automatic retry and error handling
    /// - Parameter request: The network request to send
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    public func sendRequest<T: Codable>(_ request: NetworkRequest) async throws -> T {
        logger.debug("Sending network request: \(request.endpoint)")
        
        do {
            // Create URL request
            let urlRequest = try createURLRequest(from: request)
            
            // Send request with retry logic
            let (data, response) = try await sendRequestWithRetry(urlRequest)
            
            // Validate response
            try validateResponse(response)
            
            // Decode response
            let decodedResponse = try decodeResponse(data: data, type: T.self)
            
            logger.debug("Network request completed successfully")
            return decodedResponse
            
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw mapError(error)
        }
    }
    
    /// Sends a network request with custom timeout
    /// - Parameters:
    ///   - request: The network request to send
    ///   - timeout: Custom timeout interval
    /// - Returns: Decoded response of the specified type
    /// - Throws: NetworkError if the request fails
    public func sendRequest<T: Codable>(
        _ request: NetworkRequest,
        timeout: TimeInterval
    ) async throws -> T {
        logger.debug("Sending network request with custom timeout: \(timeout)")
        
        do {
            // Create URL request with custom timeout
            var urlRequest = try createURLRequest(from: request)
            urlRequest.timeoutInterval = timeout
            
            // Send request
            let (data, response) = try await session.data(for: urlRequest)
            
            // Validate response
            try validateResponse(response)
            
            // Decode response
            let decodedResponse = try decodeResponse(data: data, type: T.self)
            
            logger.debug("Network request with custom timeout completed")
            return decodedResponse
            
        } catch {
            logger.error("Network request with custom timeout failed: \(error.localizedDescription)")
            throw mapError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func createURLRequest(from request: NetworkRequest) throws -> URLRequest {
        // Build URL
        let baseURL = configuration.environment.baseURL
        let url = baseURL.appendingPathComponent(request.endpoint.path)
        
        // Create URL request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        // Add headers
        urlRequest.allHTTPHeaderFields = createHeaders(for: request)
        
        // Add body if present
        if let body = request.body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }
        
        return urlRequest
    }
    
    private func createHeaders(for request: NetworkRequest) -> [String: String] {
        var headers: [String: String] = [
            "Authorization": "Bearer \(configuration.apiKey)",
            "X-Merchant-ID": configuration.merchantId,
            "X-Request-ID": UUID().uuidString,
            "X-Timestamp": String(Int(Date().timeIntervalSince1970))
        ]
        
        // Add custom headers if provided
        if let customHeaders = request.customHeaders {
            headers.merge(customHeaders) { _, new in new }
        }
        
        return headers
    }
    
    private func sendRequestWithRetry(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0...retryPolicy.maxRetries {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                
                // Check if response indicates retry is needed
                if shouldRetry(response: response, attempt: attempt) {
                    let delay = retryPolicy.calculateDelay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                return (data, response)
                
            } catch {
                lastError = error
                
                // Check if error is retryable
                if isRetryableError(error) && attempt < retryPolicy.maxRetries {
                    let delay = retryPolicy.calculateDelay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    private func shouldRetry(response: URLResponse, attempt: Int) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        // Retry on 5xx errors (server errors)
        let shouldRetry = (500...599).contains(httpResponse.statusCode)
        
        if shouldRetry {
            logger.warning("Retrying request due to server error: \(httpResponse.statusCode)")
        }
        
        return shouldRetry && attempt < retryPolicy.maxRetries
    }
    
    private func isRetryableError(_ error: Error) -> Bool {
        // Network errors that can be retried
        let retryableErrors: [URLError.Code] = [
            .networkConnectionLost,
            .notConnectedToInternet,
            .timedOut,
            .cannotConnectToHost,
            .cannotFindHost
        ]
        
        if let urlError = error as? URLError {
            return retryableErrors.contains(urlError.code)
        }
        
        return false
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check for successful status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func decodeResponse<T: Codable>(data: Data, type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            throw NetworkError.decodingError(error)
        }
    }
    
    private func mapError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .noConnection
            case .timedOut:
                return .timeout
            case .cannotConnectToHost:
                return .connectionFailed
            default:
                return .unknown
            }
        }
        
        return .unknown
    }
}

// MARK: - Supporting Types

/// Network request structure
public struct NetworkRequest {
    public let endpoint: APIEndpoint
    public let method: HTTPMethod
    public let body: Codable?
    public let customHeaders: [String: String]?
    
    public init(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Codable? = nil,
        customHeaders: [String: String]? = nil
    ) {
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.customHeaders = customHeaders
    }
}

/// API endpoints
public enum APIEndpoint {
    case processPayment
    case processApplePay
    case processGooglePay
    case processPayPal
    case processBankTransfer
    case createSubscription
    case processRefund
    case getTransaction
    case getAnalytics
    
    var path: String {
        switch self {
        case .processPayment:
            return "/v1/payments"
        case .processApplePay:
            return "/v1/payments/apple-pay"
        case .processGooglePay:
            return "/v1/payments/google-pay"
        case .processPayPal:
            return "/v1/payments/paypal"
        case .processBankTransfer:
            return "/v1/payments/bank-transfer"
        case .createSubscription:
            return "/v1/subscriptions"
        case .processRefund:
            return "/v1/refunds"
        case .getTransaction:
            return "/v1/transactions"
        case .getAnalytics:
            return "/v1/analytics"
        }
    }
}

/// HTTP methods
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Network errors
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
    
    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .connectionFailed:
            return "Failed to connect to server"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError:
            return "Server error"
        case .unknown:
            return "Unknown network error"
        }
    }
}

/// Retry policy for network requests
public struct RetryPolicy {
    public let maxRetries: Int
    public let backoffMultiplier: Double
    
    public init(maxRetries: Int, backoffMultiplier: Double) {
        self.maxRetries = maxRetries
        self.backoffMultiplier = backoffMultiplier
    }
    
    public func calculateDelay(for attempt: Int) -> TimeInterval {
        return pow(backoffMultiplier, Double(attempt))
    }
}

/// Environment extension for base URLs
public extension Environment {
    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://api-dev.paymentframework.com")!
        case .staging:
            return URL(string: "https://api-staging.paymentframework.com")!
        case .production:
            return URL(string: "https://api.paymentframework.com")!
        }
    }
}

// MARK: - Request/Response Types

/// Payment request body
public struct PaymentRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let paymentMethod: PaymentMethod
    public let encryptedCardData: EncryptedCardData?
    public let description: String
    
    public init(amount: Decimal, currency: Currency, paymentMethod: PaymentMethod, encryptedCardData: EncryptedCardData?, description: String) {
        self.amount = amount
        self.currency = currency
        self.paymentMethod = paymentMethod
        self.encryptedCardData = encryptedCardData
        self.description = description
    }
}

/// Apple Pay request body
public struct ApplePayRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let token: String?
    public let description: String
    
    public init(amount: Decimal, currency: Currency, token: String?, description: String) {
        self.amount = amount
        self.currency = currency
        self.token = token
        self.description = description
    }
}

/// Google Pay request body
public struct GooglePayRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let token: String?
    public let description: String
    
    public init(amount: Decimal, currency: Currency, token: String?, description: String) {
        self.amount = amount
        self.currency = currency
        self.token = token
        self.description = description
    }
}

/// PayPal request body
public struct PayPalRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let paypalToken: String?
    public let description: String
    
    public init(amount: Decimal, currency: Currency, paypalToken: String?, description: String) {
        self.amount = amount
        self.currency = currency
        self.paypalToken = paypalToken
        self.description = description
    }
}

/// Bank transfer request body
public struct BankTransferRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let accountDetails: BankAccountDetails?
    public let description: String
    
    public init(amount: Decimal, currency: Currency, accountDetails: BankAccountDetails?, description: String) {
        self.amount = amount
        self.currency = currency
        self.accountDetails = accountDetails
        self.description = description
    }
}

/// Subscription request body
public struct SubscriptionRequestBody: Codable {
    public let amount: Decimal
    public let currency: Currency
    public let interval: SubscriptionInterval
    public let description: String
    public let trialPeriod: Int?
    
    public init(amount: Decimal, currency: Currency, interval: SubscriptionInterval, description: String, trialPeriod: Int?) {
        self.amount = amount
        self.currency = currency
        self.interval = interval
        self.description = description
        self.trialPeriod = trialPeriod
    }
}

/// Refund request body
public struct RefundRequestBody: Codable {
    public let transactionId: String
    public let amount: Decimal?
    public let reason: RefundReason
    
    public init(transactionId: String, amount: Decimal?, reason: RefundReason) {
        self.transactionId = transactionId
        self.amount = amount
        self.reason = reason
    }
}

/// Payment response
public struct PaymentResponse: Codable {
    public let transactionId: String
    public let status: TransactionStatus
    public let metadata: [String: Any]
    
    public init(transactionId: String, status: TransactionStatus, metadata: [String: Any]) {
        self.transactionId = transactionId
        self.status = status
        self.metadata = metadata
    }
    
    // Custom coding keys for metadata
    private enum CodingKeys: String, CodingKey {
        case transactionId, status, metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transactionId = try container.decode(String.self, forKey: .transactionId)
        status = try container.decode(TransactionStatus.self, forKey: .status)
        metadata = [:] // Simplified for this example
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transactionId, forKey: .transactionId)
        try container.encode(status, forKey: .status)
        // Metadata encoding would be implemented here
    }
}

/// Subscription response
public struct SubscriptionResponse: Codable {
    public let subscriptionId: String
    public let status: SubscriptionStatus
    public let nextBillingDate: Date?
    
    public init(subscriptionId: String, status: SubscriptionStatus, nextBillingDate: Date?) {
        self.subscriptionId = subscriptionId
        self.status = status
        self.nextBillingDate = nextBillingDate
    }
}

/// Refund response
public struct RefundResponse: Codable {
    public let refundId: String
    public let amount: Decimal
    public let status: RefundStatus
    
    public init(refundId: String, amount: Decimal, status: RefundStatus) {
        self.refundId = refundId
        self.amount = amount
        self.status = status
    }
} 