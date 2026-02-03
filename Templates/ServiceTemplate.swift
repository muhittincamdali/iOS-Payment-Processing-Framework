// MARK: - Payment Service Template
// Use this template for creating Payment Services

import Foundation

// MARK: - Protocol
protocol PaymentServiceProtocol: Sendable {
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult
    func completeAuthentication(_ response: AuthenticationResponse) async throws -> PaymentResult
    func refundPayment(transactionId: String, amount: Decimal?) async throws -> RefundResult
    func getPaymentMethods() async throws -> [PaymentMethod]
}

// MARK: - Service Implementation
final class __NAME__PaymentService: PaymentServiceProtocol, @unchecked Sendable {
    // MARK: - Singleton
    static let shared = __NAME__PaymentService()
    
    // MARK: - Properties
    private let networkClient: NetworkClientProtocol
    private let encryptionService: EncryptionServiceProtocol
    private let configuration: PaymentConfiguration
    
    // MARK: - Initialization
    init(
        networkClient: NetworkClientProtocol = NetworkClient.shared,
        encryptionService: EncryptionServiceProtocol = EncryptionService.shared,
        configuration: PaymentConfiguration = .default
    ) {
        self.networkClient = networkClient
        self.encryptionService = encryptionService
        self.configuration = configuration
    }
    
    // MARK: - Process Payment
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        // Validate request
        try validateRequest(request)
        
        // Encrypt sensitive data
        let encryptedCard = try encryptionService.encrypt(request.card)
        
        // Create API request
        let apiRequest = PaymentAPIRequest(
            amount: request.amount,
            currency: request.currency.code,
            paymentMethodType: request.paymentMethod.type,
            encryptedCard: encryptedCard,
            merchantId: configuration.merchantId,
            idempotencyKey: UUID().uuidString
        )
        
        // Send request
        let response: PaymentAPIResponse = try await networkClient.post(
            configuration.paymentEndpoint,
            body: apiRequest,
            headers: authHeaders()
        )
        
        // Handle response
        return try handlePaymentResponse(response)
    }
    
    // MARK: - Complete Authentication (3DS)
    func completeAuthentication(_ response: AuthenticationResponse) async throws -> PaymentResult {
        let request = AuthenticationCompletionRequest(
            transactionId: response.transactionId,
            authenticationData: response.authenticationData
        )
        
        let apiResponse: PaymentAPIResponse = try await networkClient.post(
            configuration.authenticationEndpoint,
            body: request,
            headers: authHeaders()
        )
        
        return try handlePaymentResponse(apiResponse)
    }
    
    // MARK: - Refund
    func refundPayment(transactionId: String, amount: Decimal?) async throws -> RefundResult {
        let request = RefundRequest(
            transactionId: transactionId,
            amount: amount,
            reason: nil
        )
        
        let response: RefundAPIResponse = try await networkClient.post(
            configuration.refundEndpoint,
            body: request,
            headers: authHeaders()
        )
        
        return RefundResult(
            refundId: response.refundId,
            status: RefundStatus(rawValue: response.status) ?? .pending,
            amount: response.amount
        )
    }
    
    // MARK: - Payment Methods
    func getPaymentMethods() async throws -> [PaymentMethod] {
        let response: PaymentMethodsResponse = try await networkClient.get(
            configuration.paymentMethodsEndpoint,
            headers: authHeaders()
        )
        
        return response.methods.map { method in
            PaymentMethod(
                id: method.id,
                type: PaymentMethodType(rawValue: method.type) ?? .card,
                displayName: method.displayName,
                icon: method.iconURL
            )
        }
    }
    
    // MARK: - Private Methods
    private func validateRequest(_ request: PaymentRequest) throws {
        guard request.amount > 0 else {
            throw PaymentError.invalidAmount
        }
        
        guard CardValidator.validateNumber(request.card.number) else {
            throw PaymentError.invalidCardNumber
        }
        
        guard CardValidator.validateExpiry(request.card.expiry) else {
            throw PaymentError.invalidExpiry
        }
        
        guard CardValidator.validateCVV(request.card.cvv) else {
            throw PaymentError.invalidCVV
        }
    }
    
    private func handlePaymentResponse(_ response: PaymentAPIResponse) throws -> PaymentResult {
        switch response.status {
        case "success":
            return PaymentResult(
                transactionId: response.transactionId,
                status: .success,
                authenticationChallenge: nil
            )
            
        case "requires_authentication":
            guard let challenge = response.authenticationChallenge else {
                throw PaymentError.authenticationRequired
            }
            return PaymentResult(
                transactionId: response.transactionId,
                status: .requiresAuthentication,
                authenticationChallenge: AuthenticationChallenge(
                    type: challenge.type,
                    url: URL(string: challenge.url)!,
                    transactionId: response.transactionId
                )
            )
            
        case "declined":
            throw PaymentError.declined(reason: response.declineReason ?? "Unknown")
            
        default:
            throw PaymentError.unknown(nil)
        }
    }
    
    private func authHeaders() -> [String: String] {
        [
            "Authorization": "Bearer \(configuration.apiKey)",
            "X-Merchant-Id": configuration.merchantId,
            "X-API-Version": configuration.apiVersion
        ]
    }
}

// MARK: - Configuration
struct PaymentConfiguration {
    let apiKey: String
    let merchantId: String
    let apiVersion: String
    let baseURL: URL
    
    var paymentEndpoint: URL { baseURL.appendingPathComponent("payments") }
    var authenticationEndpoint: URL { baseURL.appendingPathComponent("auth/complete") }
    var refundEndpoint: URL { baseURL.appendingPathComponent("refunds") }
    var paymentMethodsEndpoint: URL { baseURL.appendingPathComponent("payment-methods") }
    
    static let `default` = PaymentConfiguration(
        apiKey: ProcessInfo.processInfo.environment["PAYMENT_API_KEY"] ?? "",
        merchantId: ProcessInfo.processInfo.environment["MERCHANT_ID"] ?? "",
        apiVersion: "2024-01",
        baseURL: URL(string: "https://api.payment.example.com/v1")!
    )
}

// MARK: - Error Types
enum PaymentError: LocalizedError {
    case invalidAmount
    case invalidCardNumber
    case invalidExpiry
    case invalidCVV
    case invalidPaymentDetails
    case noPaymentMethodSelected
    case declined(reason: String)
    case authenticationRequired
    case networkError(Error)
    case unknown(Error?)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "Invalid payment amount"
        case .invalidCardNumber: return "Invalid card number"
        case .invalidExpiry: return "Invalid expiry date"
        case .invalidCVV: return "Invalid CVV"
        case .invalidPaymentDetails: return "Invalid payment details"
        case .noPaymentMethodSelected: return "Please select a payment method"
        case .declined(let reason): return "Payment declined: \(reason)"
        case .authenticationRequired: return "Authentication required"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .unknown: return "An unknown error occurred"
        }
    }
}
