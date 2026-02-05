// StoreKitManager.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit
import Combine
import OSLog

/// World-class StoreKit 2 manager with enterprise-grade features
/// Provides unified API for In-App Purchases, Subscriptions, and Entitlements
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class StoreKitManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance for global access
    public static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    
    /// All available products fetched from App Store
    @Published public private(set) var products: [Product] = []
    
    /// Products organized by type
    @Published public private(set) var consumables: [Product] = []
    @Published public private(set) var nonConsumables: [Product] = []
    @Published public private(set) var subscriptions: [Product] = []
    @Published public private(set) var nonRenewingSubscriptions: [Product] = []
    
    /// Current user's purchased product IDs
    @Published public private(set) var purchasedProductIds: Set<String> = []
    
    /// Active subscription status
    @Published public private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    /// Current entitlements
    @Published public private(set) var entitlements: Entitlements = Entitlements()
    
    /// Loading state
    @Published public private(set) var isLoading: Bool = false
    
    /// Last error
    @Published public private(set) var lastError: StoreKitError?
    
    // MARK: - Private Properties
    
    private var productIds: Set<String> = []
    private var updateListenerTask: Task<Void, Error>?
    private let logger = Logger(subsystem: "PaymentProcessingFramework", category: "StoreKit")
    private let receiptValidator: ReceiptValidator
    private let entitlementManager: EntitlementManager
    private let analyticsTracker: PurchaseAnalytics
    private let configuration: StoreKitConfiguration
    private var cancellables = Set<AnyCancellable>()
    
    // Caching
    private var productCache: [String: Product] = [:]
    private var lastProductFetch: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    /// Initialize with configuration
    /// - Parameter configuration: StoreKit configuration options
    public init(configuration: StoreKitConfiguration = .default) {
        self.configuration = configuration
        self.receiptValidator = ReceiptValidator(configuration: configuration.receiptValidation)
        self.entitlementManager = EntitlementManager(configuration: configuration.entitlements)
        self.analyticsTracker = PurchaseAnalytics(configuration: configuration.analytics)
        
        startTransactionListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Configuration
    
    /// Configure product IDs for your app
    /// - Parameter productIds: Set of product identifiers from App Store Connect
    public func configure(productIds: Set<String>) {
        self.productIds = productIds
        logger.info("Configured with \(productIds.count) product IDs")
    }
    
    /// Configure with a plist file containing product IDs
    /// - Parameter plistName: Name of the plist file (without extension)
    public func configure(fromPlist plistName: String) throws {
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = plist as? [String: Any],
              let ids = dict["ProductIdentifiers"] as? [String] else {
            throw StoreKitError.configurationError("Failed to load product IDs from \(plistName).plist")
        }
        
        configure(productIds: Set(ids))
    }
    
    // MARK: - Product Fetching
    
    /// Fetch all configured products from App Store
    /// - Returns: Array of available products
    @discardableResult
    public func fetchProducts() async throws -> [Product] {
        guard !productIds.isEmpty else {
            throw StoreKitError.configurationError("No product IDs configured. Call configure(productIds:) first.")
        }
        
        // Check cache
        if let lastFetch = lastProductFetch,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           !products.isEmpty {
            logger.debug("Returning cached products")
            return products
        }
        
        await setLoading(true)
        
        do {
            logger.info("Fetching \(self.productIds.count) products from App Store")
            
            let storeProducts = try await Product.products(for: productIds)
            
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
                self.categorizeProducts()
                self.updateProductCache()
                self.lastProductFetch = Date()
                self.isLoading = false
            }
            
            logger.info("Fetched \(storeProducts.count) products successfully")
            
            // Track analytics
            analyticsTracker.trackProductsFetched(count: storeProducts.count)
            
            return storeProducts
            
        } catch {
            await setLoading(false)
            let storeError = StoreKitError.productFetchFailed(error.localizedDescription)
            await setError(storeError)
            throw storeError
        }
    }
    
    /// Fetch specific products by ID
    /// - Parameter ids: Product IDs to fetch
    /// - Returns: Array of products
    public func fetchProducts(ids: Set<String>) async throws -> [Product] {
        let cachedProducts = ids.compactMap { productCache[$0] }
        
        if cachedProducts.count == ids.count {
            return cachedProducts
        }
        
        let fetchedProducts = try await Product.products(for: ids)
        
        for product in fetchedProducts {
            productCache[product.id] = product
        }
        
        return Array(fetchedProducts)
    }
    
    /// Get a specific product by ID
    /// - Parameter id: Product identifier
    /// - Returns: Product if found
    public func product(for id: String) -> Product? {
        productCache[id] ?? products.first { $0.id == id }
    }
    
    // MARK: - Purchasing
    
    /// Purchase a product
    /// - Parameters:
    ///   - product: The product to purchase
    ///   - options: Optional purchase options
    /// - Returns: The verified transaction
    @discardableResult
    public func purchase(_ product: Product, options: Set<Product.PurchaseOption> = []) async throws -> Transaction {
        logger.info("Initiating purchase for \(product.id)")
        
        await setLoading(true)
        
        do {
            // Check for pending transactions first
            if let pending = await getPendingTransaction(for: product.id) {
                logger.warning("Found pending transaction for \(product.id)")
                await setLoading(false)
                throw StoreKitError.pendingTransaction(pending)
            }
            
            let result = try await product.purchase(options: options)
            
            switch result {
            case .success(let verification):
                let transaction = try await handleVerification(verification)
                
                await MainActor.run {
                    self.purchasedProductIds.insert(product.id)
                    self.updateEntitlements(from: transaction)
                    self.isLoading = false
                }
                
                // Track analytics
                analyticsTracker.trackPurchaseCompleted(
                    productId: product.id,
                    price: product.price,
                    currency: product.priceFormatStyle.currencyCode
                )
                
                logger.info("Purchase completed for \(product.id)")
                return transaction
                
            case .userCancelled:
                await setLoading(false)
                analyticsTracker.trackPurchaseCancelled(productId: product.id)
                throw StoreKitError.purchaseCancelled
                
            case .pending:
                await setLoading(false)
                analyticsTracker.trackPurchasePending(productId: product.id)
                throw StoreKitError.purchasePending
                
            @unknown default:
                await setLoading(false)
                throw StoreKitError.unknownPurchaseResult
            }
            
        } catch let error as StoreKitError {
            await setLoading(false)
            await setError(error)
            throw error
        } catch {
            await setLoading(false)
            let storeError = StoreKitError.purchaseFailed(error.localizedDescription)
            await setError(storeError)
            analyticsTracker.trackPurchaseFailed(productId: product.id, error: error)
            throw storeError
        }
    }
    
    /// Purchase a product by ID
    /// - Parameters:
    ///   - productId: The product identifier
    ///   - options: Optional purchase options
    /// - Returns: The verified transaction
    @discardableResult
    public func purchase(productId: String, options: Set<Product.PurchaseOption> = []) async throws -> Transaction {
        guard let product = product(for: productId) else {
            // Try to fetch the product
            let products = try await fetchProducts(ids: [productId])
            guard let product = products.first else {
                throw StoreKitError.productNotFound(productId)
            }
            return try await purchase(product, options: options)
        }
        
        return try await purchase(product, options: options)
    }
    
    /// Purchase with promotional offer
    /// - Parameters:
    ///   - product: The product to purchase
    ///   - offer: The promotional offer
    ///   - signature: Server-generated signature for the offer
    /// - Returns: The verified transaction
    @discardableResult
    public func purchase(
        _ product: Product,
        promotionalOffer offer: Product.SubscriptionOffer,
        signature: PromotionalOfferSignature
    ) async throws -> Transaction {
        let options: Set<Product.PurchaseOption> = [
            .promotionalOffer(
                offerID: offer.id ?? "",
                keyID: signature.keyId,
                nonce: signature.nonce,
                signature: signature.signature,
                timestamp: signature.timestamp
            )
        ]
        
        return try await purchase(product, options: options)
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    /// - Returns: Number of restored transactions
    @discardableResult
    public func restorePurchases() async throws -> Int {
        logger.info("Restoring purchases")
        
        await setLoading(true)
        
        do {
            // Sync with App Store
            try await AppStore.sync()
            
            var restoredCount = 0
            
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                await MainActor.run {
                    self.purchasedProductIds.insert(transaction.productID)
                }
                
                updateEntitlements(from: transaction)
                restoredCount += 1
            }
            
            await setLoading(false)
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            logger.info("Restored \(restoredCount) purchases")
            analyticsTracker.trackPurchasesRestored(count: restoredCount)
            
            return restoredCount
            
        } catch {
            await setLoading(false)
            let storeError = StoreKitError.restoreFailed(error.localizedDescription)
            await setError(storeError)
            throw storeError
        }
    }
    
    // MARK: - Subscription Management
    
    /// Get current subscription status
    /// - Parameter productId: Optional specific subscription product ID
    /// - Returns: Current subscription status
    public func getSubscriptionStatus(for productId: String? = nil) async -> SubscriptionStatus {
        do {
            let subscriptionProducts = productId != nil 
                ? subscriptions.filter { $0.id == productId }
                : subscriptions
            
            for product in subscriptionProducts {
                guard let subscription = product.subscription else { continue }
                
                let statuses = try await subscription.status
                
                for status in statuses {
                    guard case .verified(let renewalInfo) = status.renewalInfo,
                          case .verified(let transaction) = status.transaction else {
                        continue
                    }
                    
                    let subscriptionStatus = SubscriptionStatus(
                        from: status.state,
                        transaction: transaction,
                        renewalInfo: renewalInfo,
                        product: product
                    )
                    
                    await MainActor.run {
                        self.subscriptionStatus = subscriptionStatus
                    }
                    
                    return subscriptionStatus
                }
            }
            
            return .notSubscribed
            
        } catch {
            logger.error("Failed to get subscription status: \(error.localizedDescription)")
            return .notSubscribed
        }
    }
    
    /// Check if user has active subscription
    public func hasActiveSubscription() async -> Bool {
        let status = await getSubscriptionStatus()
        return status.isActive
    }
    
    /// Get subscription renewal info
    /// - Parameter productId: Subscription product ID
    /// - Returns: Renewal information if available
    public func getRenewalInfo(for productId: String) async throws -> Product.SubscriptionInfo.RenewalInfo? {
        guard let product = product(for: productId),
              let subscription = product.subscription else {
            return nil
        }
        
        let statuses = try await subscription.status
        
        for status in statuses {
            if case .verified(let renewalInfo) = status.renewalInfo {
                return renewalInfo
            }
        }
        
        return nil
    }
    
    /// Manage subscription (opens App Store subscription management)
    public func manageSubscriptions() async {
        if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                logger.error("Failed to show manage subscriptions: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Entitlements
    
    /// Check if user is entitled to a feature
    /// - Parameter entitlementId: The entitlement identifier
    /// - Returns: True if user has the entitlement
    public func isEntitled(to entitlementId: String) -> Bool {
        entitlements.isEntitled(to: entitlementId)
    }
    
    /// Check if user has purchased a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: True if product is purchased
    public func isPurchased(_ productId: String) -> Bool {
        purchasedProductIds.contains(productId)
    }
    
    /// Get all active entitlements
    /// - Returns: Set of active entitlement IDs
    public func getActiveEntitlements() -> Set<String> {
        entitlements.activeEntitlements
    }
    
    /// Refresh entitlements from current transactions
    public func refreshEntitlements() async {
        await updatePurchasedProducts()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Transaction History
    
    /// Get all transactions for the current user
    /// - Returns: Array of verified transactions
    public func getAllTransactions() async -> [Transaction] {
        var transactions: [Transaction] = []
        
        for await result in Transaction.all {
            if case .verified(let transaction) = result {
                transactions.append(transaction)
            }
        }
        
        return transactions.sorted { $0.purchaseDate > $1.purchaseDate }
    }
    
    /// Get latest transaction for a product
    /// - Parameter productId: Product identifier
    /// - Returns: Latest transaction if available
    public func getLatestTransaction(for productId: String) async -> Transaction? {
        await Transaction.latest(for: productId).flatMap { result in
            guard case .verified(let transaction) = result else { return nil }
            return transaction
        }
    }
    
    /// Get current entitlements
    /// - Returns: Array of currently entitled transactions
    public func getCurrentEntitlements() async -> [Transaction] {
        var transactions: [Transaction] = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                transactions.append(transaction)
            }
        }
        
        return transactions
    }
    
    // MARK: - Receipt Validation
    
    /// Validate receipt with server
    /// - Returns: Validation result
    public func validateReceipt() async throws -> ReceiptValidationResult {
        try await receiptValidator.validate()
    }
    
    /// Get app receipt data
    /// - Returns: Base64 encoded receipt data
    public func getReceiptData() throws -> String {
        try receiptValidator.getReceiptData()
    }
    
    // MARK: - Price Localization
    
    /// Get formatted price for a product
    /// - Parameter product: The product
    /// - Returns: Localized price string
    public func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
    
    /// Get price per period for subscription
    /// - Parameter product: Subscription product
    /// - Returns: Formatted price with period (e.g., "$9.99/month")
    public func pricePerPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else {
            return product.displayPrice
        }
        
        let period = subscription.subscriptionPeriod
        let periodString: String
        
        switch period.unit {
        case .day:
            periodString = period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            periodString = period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            periodString = period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            periodString = period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            periodString = "period"
        }
        
        return "\(product.displayPrice)/\(periodString)"
    }
    
    /// Calculate savings for yearly vs monthly subscription
    /// - Parameters:
    ///   - yearly: Yearly subscription product
    ///   - monthly: Monthly subscription product
    /// - Returns: Savings percentage
    public func calculateSavings(yearly: Product, monthly: Product) -> Double {
        let yearlyPrice = yearly.price as Decimal
        let monthlyPrice = monthly.price as Decimal
        let yearlyEquivalent = monthlyPrice * 12
        
        guard yearlyEquivalent > 0 else { return 0 }
        
        let savings = ((yearlyEquivalent - yearlyPrice) / yearlyEquivalent) * 100
        return NSDecimalNumber(decimal: savings).doubleValue
    }
    
    // MARK: - Promotional Offers
    
    /// Check eligibility for introductory offer
    /// - Parameter product: Subscription product
    /// - Returns: True if eligible for intro offer
    public func isEligibleForIntroOffer(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }
    
    /// Get available promotional offers for a product
    /// - Parameter product: Subscription product
    /// - Returns: Array of promotional offers
    public func getPromotionalOffers(for product: Product) -> [Product.SubscriptionOffer] {
        guard let subscription = product.subscription else { return [] }
        return subscription.promotionalOffers
    }
    
    /// Get introductory offer for a product
    /// - Parameter product: Subscription product
    /// - Returns: Introductory offer if available
    public func getIntroductoryOffer(for product: Product) -> Product.SubscriptionOffer? {
        product.subscription?.introductoryOffer
    }
    
    // MARK: - Refund Request
    
    /// Request refund for a transaction
    /// - Parameter transactionId: The transaction ID
    public func requestRefund(for transactionId: UInt64) async throws {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            throw StoreKitError.refundRequestFailed("No window scene available")
        }
        
        do {
            let status = try await Transaction.beginRefundRequest(for: transactionId, in: windowScene)
            
            switch status {
            case .success:
                analyticsTracker.trackRefundRequested(transactionId: transactionId)
                logger.info("Refund request submitted for transaction \(transactionId)")
            case .userCancelled:
                logger.info("User cancelled refund request")
            @unknown default:
                break
            }
        } catch {
            throw StoreKitError.refundRequestFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    
    private func startTransactionListener() {
        updateListenerTask = Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try await handleVerification(result)
                    
                    await MainActor.run {
                        self.purchasedProductIds.insert(transaction.productID)
                        self.updateEntitlements(from: transaction)
                    }
                    
                    logger.info("Transaction update received for \(transaction.productID)")
                    
                } catch {
                    logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleVerification(_ result: VerificationResult<Transaction>) async throws -> Transaction {
        switch result {
        case .unverified(let transaction, let error):
            logger.error("Transaction verification failed: \(error.localizedDescription)")
            analyticsTracker.trackVerificationFailed(productId: transaction.productID, error: error)
            throw StoreKitError.verificationFailed(error.localizedDescription)
            
        case .verified(let transaction):
            // Finish the transaction
            await transaction.finish()
            return transaction
        }
    }
    
    private func categorizeProducts() {
        consumables = products.filter { $0.type == .consumable }
        nonConsumables = products.filter { $0.type == .nonConsumable }
        subscriptions = products.filter { $0.type == .autoRenewable }
        nonRenewingSubscriptions = products.filter { $0.type == .nonRenewable }
    }
    
    private func updateProductCache() {
        for product in products {
            productCache[product.id] = product
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }
        
        await MainActor.run {
            self.purchasedProductIds = purchased
        }
    }
    
    private func updateSubscriptionStatus() async {
        let status = await getSubscriptionStatus()
        await MainActor.run {
            self.subscriptionStatus = status
        }
    }
    
    private func updateEntitlements(from transaction: Transaction) {
        entitlementManager.updateEntitlements(from: transaction)
        
        Task { @MainActor in
            self.entitlements = entitlementManager.currentEntitlements
        }
    }
    
    private func getPendingTransaction(for productId: String) async -> Transaction? {
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result,
               transaction.productID == productId {
                return transaction
            }
        }
        return nil
    }
    
    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    @MainActor
    private func setError(_ error: StoreKitError) {
        lastError = error
    }
}

// MARK: - UIKit Integration

#if canImport(UIKit)
import UIKit

@available(iOS 15.0, *)
extension StoreKitManager {
    @MainActor
    private func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
#endif
