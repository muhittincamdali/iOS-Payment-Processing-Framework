import SwiftUI
import PaymentProcessingFramework

/// Comprehensive example app demonstrating iOS Payment Processing Framework
/// Shows all payment methods, security features, and analytics
@main
struct PaymentExampleApp: App {
    
    @StateObject private var paymentManager = PaymentManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(paymentManager)
        }
    }
}

/// Main content view with navigation
struct ContentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Payment Methods") {
                    NavigationLink("Credit Card Payment", destination: CreditCardPaymentView())
                    NavigationLink("Apple Pay Payment", destination: ApplePayPaymentView())
                    NavigationLink("PayPal Payment", destination: PayPalPaymentView())
                    NavigationLink("Google Pay Payment", destination: GooglePayPaymentView())
                    NavigationLink("Bank Transfer Payment", destination: BankTransferPaymentView())
                }
                
                Section("Subscriptions") {
                    NavigationLink("Create Subscription", destination: SubscriptionView())
                    NavigationLink("Manage Subscriptions", destination: SubscriptionManagementView())
                }
                
                Section("Analytics & Reporting") {
                    NavigationLink("Transaction Analytics", destination: AnalyticsView())
                    NavigationLink("Generate Reports", destination: ReportsView())
                    NavigationLink("Real-time Dashboard", destination: DashboardView())
                }
                
                Section("Security & Compliance") {
                    NavigationLink("Fraud Detection", destination: FraudDetectionView())
                    NavigationLink("Security Settings", destination: SecuritySettingsView())
                    NavigationLink("Compliance Reports", destination: ComplianceView())
                }
                
                Section("Refunds & Disputes") {
                    NavigationLink("Process Refund", destination: RefundView())
                    NavigationLink("Dispute Management", destination: DisputeView())
                }
            }
            .navigationTitle("Payment Framework Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Payment manager for the example app
class PaymentManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var analytics: TransactionAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let paymentProcessor: PaymentProcessor
    
    init() {
        // Initialize payment processor with demo configuration
        let configuration = PaymentConfiguration(
            merchantId: "demo_merchant_id",
            apiKey: "demo_api_key",
            environment: .development,
            supportedPaymentMethods: PaymentMethod.allCases
        )
        
        self.paymentProcessor = PaymentProcessor(configuration: configuration)
        setupPaymentProcessor()
    }
    
    private func setupPaymentProcessor() {
        // Configure fraud detection
        let fraudConfig = FraudDetectionConfiguration(
            enabled: true,
            sensitivity: .medium,
            rules: [
                .velocityCheck,
                .geolocationCheck,
                .deviceFingerprinting,
                .behavioralAnalysis
            ]
        )
        paymentProcessor.configureFraudDetection(fraudConfig)
        
        // Subscribe to analytics
        paymentProcessor.subscribeToAnalytics { analytics in
            DispatchQueue.main.async {
                self.analytics = analytics
            }
        }
    }
    
    func processPayment(
        amount: Decimal,
        currency: Currency,
        paymentMethod: PaymentMethod,
        cardData: CardData? = nil,
        completion: @escaping (Result<Transaction, PaymentError>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let request = PaymentRequest(
            amount: amount,
            currency: currency,
            paymentMethod: paymentMethod,
            description: "Demo payment via \(paymentMethod.displayName)",
            cardData: cardData
        )
        
        paymentProcessor.processPayment(request) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let transaction):
                    self.transactions.append(transaction)
                    completion(.success(transaction))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createSubscription(
        amount: Decimal,
        currency: Currency,
        interval: SubscriptionInterval,
        completion: @escaping (Result<Subscription, PaymentError>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let subscription = SubscriptionRequest(
            amount: amount,
            currency: currency,
            interval: interval,
            description: "Demo subscription"
        )
        
        paymentProcessor.processSubscription(subscription) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let subscription):
                    completion(.success(subscription))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getAnalytics(completion: @escaping (Result<TransactionAnalytics, PaymentError>) -> Void) {
        paymentProcessor.getAnalytics(
            dateRange: .last30Days,
            metrics: [.revenue, .transactions, .conversionRate, .averageOrderValue, .refundRate]
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analytics):
                    self.analytics = analytics
                    completion(.success(analytics))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
}

/// Credit card payment view
struct CreditCardPaymentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var amount = "99.99"
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        Form {
            Section("Payment Details") {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                TextField("Card Number", text: $cardNumber)
                    .keyboardType(.numberPad)
                
                HStack {
                    TextField("MM/YY", text: $expiryDate)
                        .keyboardType(.numberPad)
                    
                    TextField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                }
                
                TextField("Cardholder Name", text: $cardholderName)
            }
            
            Section {
                Button(action: processPayment) {
                    HStack {
                        if paymentManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text("Pay $\(amount)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(paymentManager.isLoading || !isFormValid)
            }
        }
        .navigationTitle("Credit Card Payment")
        .alert("Payment Successful", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your payment has been processed successfully.")
        }
        .alert("Payment Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty && !cardholderName.isEmpty && !amount.isEmpty
    }
    
    private func processPayment() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        let cardData = CardData(
            number: cardNumber,
            expiryMonth: Int(expiryDate.prefix(2)) ?? 0,
            expiryYear: 2000 + (Int(expiryDate.suffix(2)) ?? 0),
            cvv: cvv,
            cardholderName: cardholderName
        )
        
        paymentManager.processPayment(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .creditCard,
            cardData: cardData
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// Apple Pay payment view
struct ApplePayPaymentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var amount = "50.00"
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "applelogo")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Text("Apple Pay")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Amount: $\(amount)")
                .font(.headline)
            
            Button(action: processApplePayPayment) {
                HStack {
                    if paymentManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Pay with Apple Pay")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .cornerRadius(12)
            }
            .disabled(paymentManager.isLoading)
            .padding(.horizontal)
        }
        .navigationTitle("Apple Pay")
        .alert("Payment Successful", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your Apple Pay payment has been processed successfully.")
        }
        .alert("Payment Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func processApplePayPayment() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        paymentManager.processPayment(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .applePay
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// PayPal payment view
struct PayPalPaymentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var amount = "75.00"
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("PayPal")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Amount: $\(amount)")
                .font(.headline)
            
            Button(action: processPayPalPayment) {
                HStack {
                    if paymentManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Pay with PayPal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(paymentManager.isLoading)
            .padding(.horizontal)
        }
        .navigationTitle("PayPal")
        .alert("Payment Successful", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your PayPal payment has been processed successfully.")
        }
        .alert("Payment Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func processPayPalPayment() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        paymentManager.processPayment(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .paypal
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// Google Pay payment view
struct GooglePayPaymentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var amount = "60.00"
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Google Pay")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Amount: $\(amount)")
                .font(.headline)
            
            Button(action: processGooglePayPayment) {
                HStack {
                    if paymentManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Pay with Google Pay")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.green)
                .cornerRadius(12)
            }
            .disabled(paymentManager.isLoading)
            .padding(.horizontal)
        }
        .navigationTitle("Google Pay")
        .alert("Payment Successful", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your Google Pay payment has been processed successfully.")
        }
        .alert("Payment Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func processGooglePayPayment() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        paymentManager.processPayment(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .googlePay
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// Bank transfer payment view
struct BankTransferPaymentView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var accountNumber = ""
    @State private var routingNumber = ""
    @State private var accountHolderName = ""
    @State private var amount = "200.00"
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        Form {
            Section("Bank Account Details") {
                TextField("Account Number", text: $accountNumber)
                    .keyboardType(.numberPad)
                
                TextField("Routing Number", text: $routingNumber)
                    .keyboardType(.numberPad)
                
                TextField("Account Holder Name", text: $accountHolderName)
            }
            
            Section("Payment Details") {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
            }
            
            Section {
                Button(action: processBankTransfer) {
                    HStack {
                        if paymentManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text("Process Bank Transfer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(paymentManager.isLoading || !isFormValid)
            }
        }
        .navigationTitle("Bank Transfer")
        .alert("Transfer Successful", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your bank transfer has been initiated successfully.")
        }
        .alert("Transfer Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private var isFormValid: Bool {
        !accountNumber.isEmpty && !routingNumber.isEmpty && !accountHolderName.isEmpty && !amount.isEmpty
    }
    
    private func processBankTransfer() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        let bankDetails = BankAccountDetails(
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            accountType: .checking,
            accountHolderName: accountHolderName
        )
        
        let request = PaymentRequest(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .bankTransfer,
            description: "Bank transfer payment",
            bankAccountDetails: bankDetails
        )
        
        paymentManager.processPayment(
            amount: amountDecimal,
            currency: .usd,
            paymentMethod: .bankTransfer
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// Subscription view
struct SubscriptionView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var amount = "29.99"
    @State private var selectedInterval: SubscriptionInterval = .monthly
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        Form {
            Section("Subscription Details") {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Billing Interval", selection: $selectedInterval) {
                    Text("Monthly").tag(SubscriptionInterval.monthly)
                    Text("Yearly").tag(SubscriptionInterval.yearly)
                    Text("Weekly").tag(SubscriptionInterval.weekly)
                }
            }
            
            Section {
                Button(action: createSubscription) {
                    HStack {
                        if paymentManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text("Create Subscription")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(paymentManager.isLoading || amount.isEmpty)
            }
        }
        .navigationTitle("Create Subscription")
        .alert("Subscription Created", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text("Your subscription has been created successfully.")
        }
        .alert("Subscription Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(paymentManager.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func createSubscription() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        paymentManager.createSubscription(
            amount: amountDecimal,
            currency: .usd,
            interval: selectedInterval
        ) { result in
            switch result {
            case .success:
                showingSuccess = true
            case .failure:
                showingError = true
            }
        }
    }
}

/// Analytics view
struct AnalyticsView: View {
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var analytics: TransactionAnalytics?
    @State private var isLoading = false
    
    var body: some View {
        List {
            if let analytics = analytics {
                Section("Revenue") {
                    HStack {
                        Text("Total Revenue")
                        Spacer()
                        Text("$\(analytics.revenue, specifier: "%.2f")")
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Transactions") {
                    HStack {
                        Text("Total Transactions")
                        Spacer()
                        Text("\(analytics.transactionCount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Conversion Rate")
                        Spacer()
                        Text("\(analytics.conversionRate, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Average Order Value")
                        Spacer()
                        Text("$\(analytics.averageOrderValue, specifier: "%.2f")")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Refund Rate")
                        Spacer()
                        Text("\(analytics.refundRate, specifier: "%.1f")%")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Section {
                Button(action: loadAnalytics) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text("Refresh Analytics")
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Analytics")
        .onAppear {
            loadAnalytics()
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        
        paymentManager.getAnalytics { result in
            isLoading = false
            
            switch result {
            case .success(let analytics):
                self.analytics = analytics
            case .failure:
                break
            }
        }
    }
}

/// Placeholder views for remaining features
struct SubscriptionManagementView: View {
    var body: some View {
        Text("Subscription Management")
            .navigationTitle("Manage Subscriptions")
    }
}

struct ReportsView: View {
    var body: some View {
        Text("Generate Reports")
            .navigationTitle("Reports")
    }
}

struct DashboardView: View {
    var body: some View {
        Text("Real-time Dashboard")
            .navigationTitle("Dashboard")
    }
}

struct FraudDetectionView: View {
    var body: some View {
        Text("Fraud Detection")
            .navigationTitle("Fraud Detection")
    }
}

struct SecuritySettingsView: View {
    var body: some View {
        Text("Security Settings")
            .navigationTitle("Security")
    }
}

struct ComplianceView: View {
    var body: some View {
        Text("Compliance Reports")
            .navigationTitle("Compliance")
    }
}

struct RefundView: View {
    var body: some View {
        Text("Process Refund")
            .navigationTitle("Refunds")
    }
}

struct DisputeView: View {
    var body: some View {
        Text("Dispute Management")
            .navigationTitle("Disputes")
    }
}

/// Preview
struct PaymentExampleApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PaymentManager())
    }
} 