// MARK: - Payment ViewModel Template
// Use this template for creating Payment-related ViewModels

import Foundation
import Combine

// MARK: - Protocol
@MainActor
protocol PaymentViewModelProtocol: ObservableObject {
    var paymentState: PaymentState { get }
    var selectedPaymentMethod: PaymentMethod? { get set }
    func processPayment(amount: Decimal, currency: Currency) async
    func validatePaymentDetails() -> Bool
}

// MARK: - Payment State
enum PaymentState: Equatable {
    case idle
    case validating
    case processing
    case requiresAuthentication(AuthenticationChallenge)
    case success(PaymentResult)
    case failed(PaymentError)
    
    var isProcessing: Bool {
        switch self {
        case .validating, .processing, .requiresAuthentication:
            return true
        default:
            return false
        }
    }
}

// MARK: - ViewModel
@MainActor
final class __NAME__PaymentViewModel: PaymentViewModelProtocol {
    // MARK: - Published Properties
    @Published private(set) var paymentState: PaymentState = .idle
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var cardNumber: String = ""
    @Published var expiryDate: String = ""
    @Published var cvv: String = ""
    @Published var cardholderName: String = ""
    
    // MARK: - Validation State
    @Published private(set) var isCardNumberValid: Bool = false
    @Published private(set) var isExpiryValid: Bool = false
    @Published private(set) var isCVVValid: Bool = false
    
    // MARK: - Dependencies
    private let paymentService: PaymentServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        paymentService: PaymentServiceProtocol = PaymentService.shared,
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared
    ) {
        self.paymentService = paymentService
        self.analyticsService = analyticsService
        setupValidation()
    }
    
    // MARK: - Validation Setup
    private func setupValidation() {
        $cardNumber
            .map { CardValidator.validateNumber($0) }
            .assign(to: &$isCardNumberValid)
        
        $expiryDate
            .map { CardValidator.validateExpiry($0) }
            .assign(to: &$isExpiryValid)
        
        $cvv
            .map { CardValidator.validateCVV($0) }
            .assign(to: &$isCVVValid)
    }
    
    // MARK: - Public Methods
    func validatePaymentDetails() -> Bool {
        return isCardNumberValid && isExpiryValid && isCVVValid && !cardholderName.isEmpty
    }
    
    func processPayment(amount: Decimal, currency: Currency) async {
        guard validatePaymentDetails() else {
            paymentState = .failed(.invalidPaymentDetails)
            return
        }
        
        guard let paymentMethod = selectedPaymentMethod else {
            paymentState = .failed(.noPaymentMethodSelected)
            return
        }
        
        paymentState = .validating
        analyticsService.track(.paymentStarted(amount: amount, currency: currency))
        
        do {
            // Create payment request
            let request = PaymentRequest(
                amount: amount,
                currency: currency,
                paymentMethod: paymentMethod,
                card: CardDetails(
                    number: cardNumber.replacingOccurrences(of: " ", with: ""),
                    expiry: expiryDate,
                    cvv: cvv,
                    holderName: cardholderName
                )
            )
            
            paymentState = .processing
            
            // Process payment
            let result = try await paymentService.processPayment(request)
            
            // Handle authentication if required
            if let challenge = result.authenticationChallenge {
                paymentState = .requiresAuthentication(challenge)
                return
            }
            
            paymentState = .success(result)
            analyticsService.track(.paymentSuccess(transactionId: result.transactionId))
            
        } catch let error as PaymentError {
            paymentState = .failed(error)
            analyticsService.track(.paymentFailed(error: error.localizedDescription))
        } catch {
            paymentState = .failed(.unknown(error))
            analyticsService.track(.paymentFailed(error: error.localizedDescription))
        }
    }
    
    func handleAuthentication(response: AuthenticationResponse) async {
        paymentState = .processing
        
        do {
            let result = try await paymentService.completeAuthentication(response)
            paymentState = .success(result)
            analyticsService.track(.paymentSuccess(transactionId: result.transactionId))
        } catch let error as PaymentError {
            paymentState = .failed(error)
        } catch {
            paymentState = .failed(.unknown(error))
        }
    }
    
    func reset() {
        paymentState = .idle
        cardNumber = ""
        expiryDate = ""
        cvv = ""
        cardholderName = ""
        selectedPaymentMethod = nil
    }
}

// MARK: - Card Validator
enum CardValidator {
    static func validateNumber(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        guard cleaned.count >= 13, cleaned.count <= 19,
              cleaned.allSatisfy({ $0.isNumber }) else { return false }
        return luhnCheck(cleaned)
    }
    
    static func validateExpiry(_ expiry: String) -> Bool {
        let components = expiry.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]) else { return false }
        
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        guard month >= 1, month <= 12 else { return false }
        guard year >= currentYear else { return false }
        if year == currentYear { return month >= currentMonth }
        return true
    }
    
    static func validateCVV(_ cvv: String) -> Bool {
        return cvv.count >= 3 && cvv.count <= 4 && cvv.allSatisfy { $0.isNumber }
    }
    
    private static func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let digits = number.reversed().map { Int(String($0))! }
        
        for (index, digit) in digits.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        
        return sum % 10 == 0
    }
}

// MARK: - Preview
#if DEBUG
extension __NAME__PaymentViewModel {
    static var preview: __NAME__PaymentViewModel {
        __NAME__PaymentViewModel()
    }
}
#endif
