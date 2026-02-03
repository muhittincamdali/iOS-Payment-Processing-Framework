// MARK: - Payment Test Template
// Use this template for creating Payment-related tests

import XCTest
@testable import __MODULE__

final class __NAME__PaymentTests: XCTestCase {
    // MARK: - Properties
    private var sut: __NAME__PaymentViewModel!
    private var mockPaymentService: MockPaymentService!
    private var mockAnalyticsService: MockAnalyticsService!
    
    // MARK: - Test Cards
    private enum TestCards {
        static let valid = "4242424242424242"
        static let declined = "4000000000000002"
        static let requires3DS = "4000000000003220"
        static let invalidLuhn = "4242424242424241"
    }
    
    // MARK: - Setup & Teardown
    @MainActor
    override func setUp() {
        super.setUp()
        mockPaymentService = MockPaymentService()
        mockAnalyticsService = MockAnalyticsService()
        sut = __NAME__PaymentViewModel(
            paymentService: mockPaymentService,
            analyticsService: mockAnalyticsService
        )
    }
    
    @MainActor
    override func tearDown() {
        sut = nil
        mockPaymentService = nil
        mockAnalyticsService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    @MainActor
    func test_init_startsWithIdleState() {
        XCTAssertEqual(sut.paymentState, .idle)
    }
    
    // MARK: - Card Validation Tests
    @MainActor
    func test_cardNumber_validVisaCard_isValid() {
        sut.cardNumber = TestCards.valid
        XCTAssertTrue(sut.isCardNumberValid)
    }
    
    @MainActor
    func test_cardNumber_invalidLuhn_isInvalid() {
        sut.cardNumber = TestCards.invalidLuhn
        XCTAssertFalse(sut.isCardNumberValid)
    }
    
    @MainActor
    func test_expiry_futureDate_isValid() {
        sut.expiryDate = "12/30"
        XCTAssertTrue(sut.isExpiryValid)
    }
    
    @MainActor
    func test_expiry_pastDate_isInvalid() {
        sut.expiryDate = "01/20"
        XCTAssertFalse(sut.isExpiryValid)
    }
    
    @MainActor
    func test_cvv_threedigits_isValid() {
        sut.cvv = "123"
        XCTAssertTrue(sut.isCVVValid)
    }
    
    @MainActor
    func test_cvv_twoDigits_isInvalid() {
        sut.cvv = "12"
        XCTAssertFalse(sut.isCVVValid)
    }
    
    // MARK: - Payment Processing Tests
    @MainActor
    func test_processPayment_withValidCard_succeeds() async {
        // Given
        setupValidCard()
        mockPaymentService.processResult = .success(PaymentResult.mock)
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        if case .success(let result) = sut.paymentState {
            XCTAssertNotNil(result.transactionId)
        } else {
            XCTFail("Expected success state")
        }
    }
    
    @MainActor
    func test_processPayment_whenDeclined_failsWithReason() async {
        // Given
        setupValidCard()
        mockPaymentService.processResult = .failure(PaymentError.declined(reason: "Insufficient funds"))
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        if case .failed(let error) = sut.paymentState {
            XCTAssertTrue(error.localizedDescription.contains("declined"))
        } else {
            XCTFail("Expected failed state")
        }
    }
    
    @MainActor
    func test_processPayment_requires3DS_showsAuthentication() async {
        // Given
        setupValidCard()
        let challenge = AuthenticationChallenge(
            type: "3ds2",
            url: URL(string: "https://auth.example.com")!,
            transactionId: "txn_123"
        )
        mockPaymentService.processResult = .success(
            PaymentResult(
                transactionId: "txn_123",
                status: .requiresAuthentication,
                authenticationChallenge: challenge
            )
        )
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        if case .requiresAuthentication(let returnedChallenge) = sut.paymentState {
            XCTAssertEqual(returnedChallenge.transactionId, "txn_123")
        } else {
            XCTFail("Expected requiresAuthentication state")
        }
    }
    
    @MainActor
    func test_processPayment_withInvalidDetails_failsImmediately() async {
        // Given - no card details set
        sut.selectedPaymentMethod = PaymentMethod.mock
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        if case .failed(let error) = sut.paymentState {
            XCTAssertEqual(error, .invalidPaymentDetails)
        } else {
            XCTFail("Expected failed state with invalidPaymentDetails")
        }
        
        // Service should not be called
        XCTAssertFalse(mockPaymentService.processCalled)
    }
    
    // MARK: - Analytics Tests
    @MainActor
    func test_processPayment_tracksStartEvent() async {
        // Given
        setupValidCard()
        mockPaymentService.processResult = .success(PaymentResult.mock)
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { $0.contains("paymentStarted") })
    }
    
    @MainActor
    func test_processPayment_onSuccess_tracksSuccessEvent() async {
        // Given
        setupValidCard()
        mockPaymentService.processResult = .success(PaymentResult.mock)
        
        // When
        await sut.processPayment(amount: 100.00, currency: .usd)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { $0.contains("paymentSuccess") })
    }
    
    // MARK: - Reset Tests
    @MainActor
    func test_reset_clearsAllFields() {
        // Given
        setupValidCard()
        sut.paymentState = .success(PaymentResult.mock)
        
        // When
        sut.reset()
        
        // Then
        XCTAssertEqual(sut.paymentState, .idle)
        XCTAssertTrue(sut.cardNumber.isEmpty)
        XCTAssertTrue(sut.expiryDate.isEmpty)
        XCTAssertTrue(sut.cvv.isEmpty)
        XCTAssertNil(sut.selectedPaymentMethod)
    }
    
    // MARK: - Helpers
    @MainActor
    private func setupValidCard() {
        sut.cardNumber = TestCards.valid
        sut.expiryDate = "12/30"
        sut.cvv = "123"
        sut.cardholderName = "John Doe"
        sut.selectedPaymentMethod = PaymentMethod.mock
    }
}

// MARK: - Mock Objects
final class MockPaymentService: PaymentServiceProtocol, @unchecked Sendable {
    var processCalled = false
    var processResult: Result<PaymentResult, PaymentError> = .success(PaymentResult.mock)
    
    func processPayment(_ request: PaymentRequest) async throws -> PaymentResult {
        processCalled = true
        return try processResult.get()
    }
    
    func completeAuthentication(_ response: AuthenticationResponse) async throws -> PaymentResult {
        return try processResult.get()
    }
    
    func refundPayment(transactionId: String, amount: Decimal?) async throws -> RefundResult {
        RefundResult(refundId: "ref_123", status: .success, amount: amount ?? 0)
    }
    
    func getPaymentMethods() async throws -> [PaymentMethod] {
        [PaymentMethod.mock]
    }
}

final class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [String] = []
    
    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(String(describing: event))
    }
}

// MARK: - Mock Data
extension PaymentResult {
    static var mock: PaymentResult {
        PaymentResult(transactionId: "txn_123", status: .success, authenticationChallenge: nil)
    }
}

extension PaymentMethod {
    static var mock: PaymentMethod {
        PaymentMethod(id: "pm_123", type: .card, displayName: "Visa •••• 4242", icon: nil)
    }
}
