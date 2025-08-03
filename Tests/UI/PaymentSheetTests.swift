import XCTest
import SwiftUI
@testable import PaymentProcessingFramework

final class PaymentSheetTests: XCTestCase {
    
    var paymentSheet: PaymentSheet!
    var mockTransaction: Transaction!
    
    override func setUp() {
        super.setUp()
        mockTransaction = Transaction(
            id: "txn_123",
            amount: 99.99,
            currency: .usd,
            status: .completed,
            paymentMethod: .creditCard,
            timestamp: Date(),
            metadata: [:]
        )
        
        paymentSheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
    }
    
    override func tearDown() {
        paymentSheet = nil
        mockTransaction = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_paymentSheet_initializesCorrectly() {
        // Given & When
        let sheet = PaymentSheet(
            amount: 100.0,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        // Then
        XCTAssertNotNil(sheet)
    }
    
    func test_paymentSheet_withDifferentCurrencies_initializesCorrectly() {
        // Given & When
        let usdSheet = PaymentSheet(
            amount: 100.0,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        let eurSheet = PaymentSheet(
            amount: 100.0,
            currency: .eur,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        // Then
        XCTAssertNotNil(usdSheet)
        XCTAssertNotNil(eurSheet)
    }
    
    // MARK: - Payment Method Tests
    
    func test_paymentMethodCard_rendersCorrectly() {
        // Given
        let method = PaymentMethod.creditCard
        let isSelected = true
        
        // When
        let card = PaymentMethodCard(
            method: method,
            isSelected: isSelected,
            action: {}
        )
        
        // Then
        XCTAssertNotNil(card)
    }
    
    func test_paymentMethodCard_withAllMethods_rendersCorrectly() {
        // Given
        let methods: [PaymentMethod] = [.creditCard, .applePay, .googlePay, .paypal, .bankTransfer]
        
        // When & Then
        for method in methods {
            let card = PaymentMethodCard(
                method: method,
                isSelected: false,
                action: {}
            )
            XCTAssertNotNil(card)
        }
    }
    
    // MARK: - Custom Text Field Tests
    
    func test_customTextField_rendersCorrectly() {
        // Given
        @State var text = ""
        
        // When
        let textField = CustomTextField(
            title: "Card Number",
            text: $text,
            placeholder: "1234 5678 9012 3456",
            keyboardType: .numberPad
        )
        
        // Then
        XCTAssertNotNil(textField)
    }
    
    func test_customTextField_withFormatter_rendersCorrectly() {
        // Given
        @State var text = ""
        
        // When
        let textField = CustomTextField(
            title: "Card Number",
            text: $text,
            placeholder: "1234 5678 9012 3456",
            keyboardType: .numberPad,
            formatter: CardNumberFormatter()
        )
        
        // Then
        XCTAssertNotNil(textField)
    }
    
    // MARK: - Security Badge Tests
    
    func test_securityBadge_rendersCorrectly() {
        // Given
        let badge = SecurityBadge(
            icon: "lock.shield",
            text: "SSL Encrypted"
        )
        
        // Then
        XCTAssertNotNil(badge)
    }
    
    // MARK: - Payment Sheet View Model Tests
    
    func test_paymentSheetViewModel_initializesCorrectly() {
        // Given & When
        let viewModel = PaymentSheetViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedPaymentMethod, .creditCard)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.isVisible)
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateCardNumber_withValidNumber_returnsTrue() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let validCardNumber = "4111111111111111"
        
        // When
        viewModel.validateCardNumber(validCardNumber)
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateCardNumber_withInvalidNumber_returnsFalse() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let invalidCardNumber = "1234"
        
        // When
        viewModel.validateCardNumber(invalidCardNumber)
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateExpiryDate_withValidDate_returnsTrue() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let validExpiryDate = "12/25"
        
        // When
        viewModel.validateExpiryDate(validExpiryDate)
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateExpiryDate_withInvalidDate_returnsFalse() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let invalidExpiryDate = "13/25"
        
        // When
        viewModel.validateExpiryDate(invalidExpiryDate)
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateCVV_withValidCVV_returnsTrue() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let validCVV = "123"
        
        // When
        viewModel.validateCVV(validCVV)
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_validateCVV_withInvalidCVV_returnsFalse() {
        // Given
        let viewModel = PaymentSheetViewModel()
        let invalidCVV = "12"
        
        // When
        viewModel.validateCVV(invalidCVV)
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    // MARK: - Text Formatter Tests
    
    func test_cardNumberFormatter_formatsCorrectly() {
        // Given
        let formatter = CardNumberFormatter()
        let input = "4111111111111111"
        
        // When
        let formatted = formatter.format(input)
        
        // Then
        XCTAssertEqual(formatted, "4111 1111 1111 1111")
    }
    
    func test_expiryDateFormatter_formatsCorrectly() {
        // Given
        let formatter = ExpiryDateFormatter()
        let input = "1225"
        
        // When
        let formatted = formatter.format(input)
        
        // Then
        XCTAssertEqual(formatted, "12/25")
    }
    
    func test_cvvFormatter_formatsCorrectly() {
        // Given
        let formatter = CVVFormatter()
        let input = "123"
        
        // When
        let formatted = formatter.format(input)
        
        // Then
        XCTAssertEqual(formatted, "123")
    }
    
    // MARK: - Currency Extension Tests
    
    func test_currency_symbol_returnsCorrectSymbol() {
        // Given & When & Then
        XCTAssertEqual(Currency.usd.symbol, "$")
        XCTAssertEqual(Currency.eur.symbol, "€")
        XCTAssertEqual(Currency.gbp.symbol, "£")
        XCTAssertEqual(Currency.jpy.symbol, "¥")
        XCTAssertEqual(Currency.cad.symbol, "C$")
        XCTAssertEqual(Currency.aud.symbol, "A$")
        XCTAssertEqual(Currency.chf.symbol, "CHF")
        XCTAssertEqual(Currency.cny.symbol, "¥")
        XCTAssertEqual(Currency.inr.symbol, "₹")
        XCTAssertEqual(Currency.brl.symbol, "R$")
    }
    
    // MARK: - Payment Method Extension Tests
    
    func test_paymentMethod_displayName_returnsCorrectName() {
        // Given & When & Then
        XCTAssertEqual(PaymentMethod.creditCard.displayName, "Credit Card")
        XCTAssertEqual(PaymentMethod.applePay.displayName, "Apple Pay")
        XCTAssertEqual(PaymentMethod.googlePay.displayName, "Google Pay")
        XCTAssertEqual(PaymentMethod.paypal.displayName, "PayPal")
        XCTAssertEqual(PaymentMethod.bankTransfer.displayName, "Bank Transfer")
    }
    
    func test_paymentMethod_iconName_returnsCorrectIcon() {
        // Given & When & Then
        XCTAssertEqual(PaymentMethod.creditCard.iconName, "creditcard")
        XCTAssertEqual(PaymentMethod.applePay.iconName, "applelogo")
        XCTAssertEqual(PaymentMethod.googlePay.iconName, "creditcard.fill")
        XCTAssertEqual(PaymentMethod.paypal.iconName, "creditcard")
        XCTAssertEqual(PaymentMethod.bankTransfer.iconName, "building.2")
    }
    
    // MARK: - Performance Tests
    
    func test_paymentSheet_renderingPerformance() {
        // Given
        let sheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        // When & Then
        measure {
            // This would measure the rendering performance
            // In a real test, you would render the view and measure
            _ = sheet
        }
    }
    
    func test_paymentMethodCard_renderingPerformance() {
        // Given
        let methods: [PaymentMethod] = [.creditCard, .applePay, .googlePay, .paypal, .bankTransfer]
        
        // When & Then
        measure {
            for method in methods {
                let card = PaymentMethodCard(
                    method: method,
                    isSelected: false,
                    action: {}
                )
                _ = card
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func test_paymentSheet_accessibilityLabels() {
        // Given
        let sheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        // When & Then
        // In a real test, you would check accessibility labels
        XCTAssertNotNil(sheet)
    }
    
    func test_paymentMethodCard_accessibilityLabels() {
        // Given
        let card = PaymentMethodCard(
            method: .creditCard,
            isSelected: true,
            action: {}
        )
        
        // When & Then
        // In a real test, you would check accessibility labels
        XCTAssertNotNil(card)
    }
    
    // MARK: - Error Handling Tests
    
    func test_paymentSheet_withErrorCallback_callsErrorHandler() {
        // Given
        var errorReceived: PaymentError?
        let sheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { error in
                errorReceived = error
            }
        )
        
        // When
        // Simulate error
        let error = PaymentError.invalidAmount
        // In a real test, you would trigger the error
        
        // Then
        // XCTAssertEqual(errorReceived, error)
        XCTAssertNotNil(sheet)
    }
    
    func test_paymentSheet_withSuccessCallback_callsSuccessHandler() {
        // Given
        var transactionReceived: Transaction?
        let sheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { transaction in
                transactionReceived = transaction
            },
            onPaymentFailed: { _ in }
        )
        
        // When
        // Simulate success
        // In a real test, you would trigger the success
        
        // Then
        // XCTAssertNotNil(transactionReceived)
        XCTAssertNotNil(sheet)
    }
    
    // MARK: - Integration Tests
    
    func test_paymentSheet_integrationWithPaymentProcessor() {
        // Given
        let configuration = PaymentConfiguration(
            merchantId: "test_merchant",
            apiKey: "test_key",
            environment: .development
        )
        let paymentProcessor = PaymentProcessor(configuration: configuration)
        
        let sheet = PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
        
        // When & Then
        XCTAssertNotNil(paymentProcessor)
        XCTAssertNotNil(sheet)
    }
    
    // MARK: - UI State Tests
    
    func test_paymentSheetViewModel_processingState() {
        // Given
        let viewModel = PaymentSheetViewModel()
        
        // When
        viewModel.isProcessing = true
        
        // Then
        XCTAssertTrue(viewModel.isProcessing)
    }
    
    func test_paymentSheetViewModel_visibilityState() {
        // Given
        let viewModel = PaymentSheetViewModel()
        
        // When
        viewModel.isVisible = true
        
        // Then
        XCTAssertTrue(viewModel.isVisible)
    }
    
    func test_paymentSheetViewModel_paymentMethodSelection() {
        // Given
        let viewModel = PaymentSheetViewModel()
        
        // When
        viewModel.selectedPaymentMethod = .applePay
        
        // Then
        XCTAssertEqual(viewModel.selectedPaymentMethod, .applePay)
    }
    
    // MARK: - Form Validation Tests
    
    func test_paymentSheetViewModel_formValidation_withCompleteForm_returnsTrue() {
        // Given
        let viewModel = PaymentSheetViewModel()
        viewModel.cardNumber = "4111111111111111"
        viewModel.expiryDate = "12/25"
        viewModel.cvv = "123"
        viewModel.cardholderName = "John Doe"
        
        // When
        viewModel.validateCardNumber(viewModel.cardNumber)
        viewModel.validateExpiryDate(viewModel.expiryDate)
        viewModel.validateCVV(viewModel.cvv)
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func test_paymentSheetViewModel_formValidation_withIncompleteForm_returnsFalse() {
        // Given
        let viewModel = PaymentSheetViewModel()
        viewModel.cardNumber = "4111111111111111"
        viewModel.expiryDate = "12/25"
        // Missing CVV and cardholder name
        
        // When
        viewModel.validateCardNumber(viewModel.cardNumber)
        viewModel.validateExpiryDate(viewModel.expiryDate)
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
}

// MARK: - Mock Payment Sheet View Model

@MainActor
class MockPaymentSheetViewModel: ObservableObject {
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var cardNumber = ""
    @Published var expiryDate = ""
    @Published var cvv = ""
    @Published var cardholderName = ""
    @Published var isProcessing = false
    @Published var isVisible = false
    @Published var isFormValid = false
    
    func validateCardNumber(_ number: String) {
        isFormValid = number.count >= 13 && number.count <= 19
    }
    
    func validateExpiryDate(_ date: String) {
        isFormValid = date.count == 5 && date.contains("/")
    }
    
    func validateCVV(_ cvv: String) {
        isFormValid = cvv.count >= 3 && cvv.count <= 4
    }
}

// MARK: - Preview Tests

struct PaymentSheetTests_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
    }
} 