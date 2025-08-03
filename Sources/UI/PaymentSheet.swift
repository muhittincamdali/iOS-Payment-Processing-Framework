import SwiftUI
import PaymentProcessingFramework

/// Premium payment sheet with beautiful animations and enterprise-grade UI
/// Supports multiple payment methods with custom animations and accessibility
public struct PaymentSheet: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = PaymentSheetViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private let amount: Decimal
    private let currency: Currency
    private let onPaymentComplete: (Transaction) -> Void
    private let onPaymentFailed: (PaymentError) -> Void
    private let onDismiss: () -> Void
    
    // MARK: - Initialization
    
    public init(
        amount: Decimal,
        currency: Currency,
        onPaymentComplete: @escaping (Transaction) -> Void,
        onPaymentFailed: @escaping (PaymentError) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.amount = amount
        self.currency = currency
        self.onPaymentComplete = onPaymentComplete
        self.onPaymentFailed = onPaymentFailed
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Payment form
                paymentFormView
                
                // Payment methods
                paymentMethodsView
                
                // Action buttons
                actionButtonsView
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                viewModel.isVisible = true
            }
        }
        .onDisappear {
            onDismiss()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            // Amount display
            VStack(spacing: 8) {
                Text("Payment Amount")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(currency.symbol)\(amount, specifier: "%.2f")")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(viewModel.isVisible ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isVisible)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
    
    // MARK: - Payment Form View
    
    private var paymentFormView: some View {
        VStack(spacing: 20) {
            // Payment method selector
            paymentMethodSelector
            
            // Card form (when credit card is selected)
            if viewModel.selectedPaymentMethod == .creditCard {
                cardFormView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            // Apple Pay button (when Apple Pay is selected)
            if viewModel.selectedPaymentMethod == .applePay {
                applePayButton
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            // PayPal button (when PayPal is selected)
            if viewModel.selectedPaymentMethod == .paypal {
                paypalButton
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Payment Method Selector
    
    private var paymentMethodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodCard(
                        method: method,
                        isSelected: viewModel.selectedPaymentMethod == method,
                        action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.selectedPaymentMethod = method
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Card Form View
    
    private var cardFormView: some View {
        VStack(spacing: 16) {
            // Card number field
            CustomTextField(
                title: "Card Number",
                text: $viewModel.cardNumber,
                placeholder: "1234 5678 9012 3456",
                keyboardType: .numberPad,
                formatter: CardNumberFormatter()
            )
            .onChange(of: viewModel.cardNumber) { newValue in
                viewModel.validateCardNumber(newValue)
            }
            
            HStack(spacing: 12) {
                // Expiry date field
                CustomTextField(
                    title: "Expiry Date",
                    text: $viewModel.expiryDate,
                    placeholder: "MM/YY",
                    keyboardType: .numberPad,
                    formatter: ExpiryDateFormatter()
                )
                .onChange(of: viewModel.expiryDate) { newValue in
                    viewModel.validateExpiryDate(newValue)
                }
                
                // CVV field
                CustomTextField(
                    title: "CVV",
                    text: $viewModel.cvv,
                    placeholder: "123",
                    keyboardType: .numberPad,
                    formatter: CVVFormatter()
                )
                .onChange(of: viewModel.cvv) { newValue in
                    viewModel.validateCVV(newValue)
                }
            }
            
            // Cardholder name field
            CustomTextField(
                title: "Cardholder Name",
                text: $viewModel.cardholderName,
                placeholder: "John Doe",
                keyboardType: .default
            )
        }
    }
    
    // MARK: - Apple Pay Button
    
    private var applePayButton: some View {
        Button(action: {
            viewModel.processApplePayPayment()
        }) {
            HStack {
                Image(systemName: "applelogo")
                    .font(.title2)
                Text("Pay with Apple Pay")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isProcessing)
    }
    
    // MARK: - PayPal Button
    
    private var paypalButton: some View {
        Button(action: {
            viewModel.processPayPalPayment()
        }) {
            HStack {
                Image(systemName: "creditcard")
                    .font(.title2)
                Text("Pay with PayPal")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isProcessing)
    }
    
    // MARK: - Payment Methods View
    
    private var paymentMethodsView: some View {
        VStack(spacing: 16) {
            // Security badges
            securityBadgesView
            
            // Terms and conditions
            termsAndConditionsView
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Security Badges View
    
    private var securityBadgesView: some View {
        HStack(spacing: 16) {
            SecurityBadge(icon: "lock.shield", text: "SSL Encrypted")
            SecurityBadge(icon: "checkmark.shield", text: "PCI Compliant")
            SecurityBadge(icon: "hand.raised", text: "Fraud Protected")
        }
        .opacity(viewModel.isVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.5).delay(0.3), value: viewModel.isVisible)
    }
    
    // MARK: - Terms and Conditions View
    
    private var termsAndConditionsView: some View {
        VStack(spacing: 8) {
            Text("By completing this payment, you agree to our")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // Open terms of service
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Pay button
            Button(action: {
                viewModel.processPayment(
                    amount: amount,
                    currency: currency,
                    onComplete: onPaymentComplete,
                    onError: onPaymentFailed
                )
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Pay \(currency.symbol)\(amount, specifier: "%.2f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isProcessing || !viewModel.isFormValid)
            .scaleEffect(viewModel.isProcessing ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isProcessing)
            
            // Cancel button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isProcessing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Supporting Views

/// Payment method card component
struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(method.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Custom text field component
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let formatter: TextFormatter?
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        formatter: TextFormatter? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(keyboardType)
                .onChange(of: text) { newValue in
                    if let formatter = formatter {
                        text = formatter.format(newValue)
                    }
                }
        }
    }
}

/// Custom text field style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

/// Security badge component
struct SecurityBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - View Model

/// Payment sheet view model
@MainActor
class PaymentSheetViewModel: ObservableObject {
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var cardNumber = ""
    @Published var expiryDate = ""
    @Published var cvv = ""
    @Published var cardholderName = ""
    @Published var isProcessing = false
    @Published var isVisible = false
    @Published var isFormValid = false
    
    private let paymentProcessor = PaymentProcessor(
        configuration: PaymentConfiguration(
            merchantId: "demo_merchant",
            apiKey: "demo_api_key",
            environment: .development
        )
    )
    
    func validateCardNumber(_ number: String) {
        // Card number validation logic
        isFormValid = number.count >= 13 && number.count <= 19
    }
    
    func validateExpiryDate(_ date: String) {
        // Expiry date validation logic
        isFormValid = date.count == 5 && date.contains("/")
    }
    
    func validateCVV(_ cvv: String) {
        // CVV validation logic
        isFormValid = cvv.count >= 3 && cvv.count <= 4
    }
    
    func processPayment(
        amount: Decimal,
        currency: Currency,
        onComplete: @escaping (Transaction) -> Void,
        onError: @escaping (PaymentError) -> Void
    ) {
        isProcessing = true
        
        let cardData = CardData(
            number: cardNumber,
            expiryMonth: Int(expiryDate.prefix(2)) ?? 0,
            expiryYear: 2000 + (Int(expiryDate.suffix(2)) ?? 0),
            cvv: cvv,
            cardholderName: cardholderName
        )
        
        let request = PaymentRequest(
            amount: amount,
            currency: currency,
            paymentMethod: selectedPaymentMethod,
            description: "Payment via PaymentSheet",
            cardData: cardData
        )
        
        paymentProcessor.processPayment(request) { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let transaction):
                    onComplete(transaction)
                case .failure(let error):
                    onError(error)
                }
            }
        }
    }
    
    func processApplePayPayment() {
        isProcessing = true
        // Apple Pay processing logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isProcessing = false
        }
    }
    
    func processPayPalPayment() {
        isProcessing = true
        // PayPal processing logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isProcessing = false
        }
    }
}

// MARK: - Extensions

extension PaymentMethod {
    var displayName: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .paypal:
            return "PayPal"
        case .bankTransfer:
            return "Bank Transfer"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard:
            return "creditcard"
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "creditcard.fill"
        case .paypal:
            return "creditcard"
        case .bankTransfer:
            return "building.2"
        }
    }
}

extension Currency {
    var symbol: String {
        switch self {
        case .usd:
            return "$"
        case .eur:
            return "€"
        case .gbp:
            return "£"
        case .jpy:
            return "¥"
        case .cad:
            return "C$"
        case .aud:
            return "A$"
        case .chf:
            return "CHF"
        case .cny:
            return "¥"
        case .inr:
            return "₹"
        case .brl:
            return "R$"
        }
    }
}

// MARK: - Text Formatters

protocol TextFormatter {
    func format(_ text: String) -> String
}

struct CardNumberFormatter: TextFormatter {
    func format(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        
        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        return formatted
    }
}

struct ExpiryDateFormatter: TextFormatter {
    func format(_ text: String) -> String {
        let cleaned = text.replacingOccurrences(of: "/", with: "")
        var formatted = ""
        
        for (index, character) in cleaned.enumerated() {
            if index == 2 {
                formatted += "/"
            }
            formatted += String(character)
        }
        
        return formatted
    }
}

struct CVVFormatter: TextFormatter {
    func format(_ text: String) -> String {
        return text
    }
}

// MARK: - Preview

struct PaymentSheet_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheet(
            amount: 99.99,
            currency: .usd,
            onPaymentComplete: { _ in },
            onPaymentFailed: { _ in }
        )
    }
} 