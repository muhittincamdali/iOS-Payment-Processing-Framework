// PaywallView.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import SwiftUI
import StoreKit

/// Beautiful, customizable paywall view for subscription products
@available(iOS 15.0, macOS 12.0, *)
public struct PaywallView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let configuration: PaywallConfiguration
    private let onPurchaseComplete: ((Transaction) -> Void)?
    private let onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Create a paywall view
    /// - Parameters:
    ///   - productIds: Product IDs to display
    ///   - configuration: Visual and behavioral configuration
    ///   - onPurchaseComplete: Called when purchase completes
    ///   - onDismiss: Called when user dismisses
    public init(
        productIds: [String],
        configuration: PaywallConfiguration = .default,
        onPurchaseComplete: ((Transaction) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: PaywallViewModel(productIds: Set(productIds)))
        self.configuration = configuration
        self.onPurchaseComplete = onPurchaseComplete
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            configuration.backgroundColor
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.products.isEmpty {
                loadingView
            } else {
                content
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Features
                if !configuration.features.isEmpty {
                    featuresSection
                }
                
                // Products
                productsSection
                
                // Terms
                termsSection
                
                // Restore
                restoreSection
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            if configuration.showCloseButton {
                closeButton
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            if let icon = configuration.headerIcon {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(configuration.accentColor)
            }
            
            Text(configuration.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(configuration.textColor)
                .multilineTextAlignment(.center)
            
            if let subtitle = configuration.subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(configuration.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    
    @ViewBuilder
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(configuration.features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(configuration.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.headline)
                            .foregroundStyle(configuration.textColor)
                        
                        if let description = feature.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(configuration.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.cardBackgroundColor)
        )
    }
    
    // MARK: - Products Section
    
    @ViewBuilder
    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: viewModel.selectedProduct?.id == product.id,
                    isBestValue: isBestValue(product),
                    configuration: configuration
                ) {
                    viewModel.selectedProduct = product
                }
            }
            
            // Purchase Button
            purchaseButton
        }
    }
    
    // MARK: - Product Card
    
    private func isBestValue(_ product: Product) -> Bool {
        guard product.subscription != nil else { return false }
        
        // Mark yearly subscriptions as best value
        return product.subscription?.subscriptionPeriod.unit == .year
    }
    
    // MARK: - Purchase Button
    
    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            Task {
                if let transaction = await viewModel.purchase() {
                    onPurchaseComplete?(transaction)
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(purchaseButtonText)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(configuration.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(viewModel.isLoading || viewModel.selectedProduct == nil)
        .padding(.top, 8)
    }
    
    private var purchaseButtonText: String {
        guard let product = viewModel.selectedProduct else {
            return configuration.purchaseButtonText
        }
        
        if let intro = product.subscription?.introductoryOffer,
           intro.paymentMode == .freeTrial {
            return "Start Free Trial"
        }
        
        return "Subscribe for \(product.displayPrice)"
    }
    
    // MARK: - Terms Section
    
    @ViewBuilder
    private var termsSection: some View {
        VStack(spacing: 8) {
            if let selectedProduct = viewModel.selectedProduct,
               let subscription = selectedProduct.subscription {
                Text(subscriptionTerms(for: selectedProduct, subscription: subscription))
                    .font(.caption)
                    .foregroundStyle(configuration.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                if let privacyURL = configuration.privacyPolicyURL {
                    Link("Privacy Policy", destination: privacyURL)
                        .font(.caption)
                }
                
                if let termsURL = configuration.termsOfServiceURL {
                    Link("Terms of Service", destination: termsURL)
                        .font(.caption)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func subscriptionTerms(for product: Product, subscription: Product.SubscriptionInfo) -> String {
        let period = subscription.subscriptionPeriod
        let periodString: String
        
        switch period.unit {
        case .day: periodString = period.value == 1 ? "day" : "\(period.value) days"
        case .week: periodString = period.value == 1 ? "week" : "\(period.value) weeks"
        case .month: periodString = period.value == 1 ? "month" : "\(period.value) months"
        case .year: periodString = period.value == 1 ? "year" : "\(period.value) years"
        @unknown default: periodString = "period"
        }
        
        var terms = "Subscription automatically renews every \(periodString) at \(product.displayPrice) unless cancelled at least 24 hours before the end of the current period."
        
        if let intro = subscription.introductoryOffer {
            switch intro.paymentMode {
            case .freeTrial:
                terms = "Free trial for \(intro.periodCount) \(introPeriodString(intro)), then \(terms)"
            case .payAsYouGo:
                terms = "Special price of \(intro.displayPrice) for \(intro.periodCount) \(introPeriodString(intro)), then \(terms)"
            case .payUpFront:
                terms = "Pay \(intro.displayPrice) upfront for \(intro.periodCount) \(introPeriodString(intro)), then \(terms)"
            @unknown default:
                break
            }
        }
        
        return terms
    }
    
    private func introPeriodString(_ offer: Product.SubscriptionOffer) -> String {
        switch offer.period.unit {
        case .day: return offer.periodCount == 1 ? "day" : "days"
        case .week: return offer.periodCount == 1 ? "week" : "weeks"
        case .month: return offer.periodCount == 1 ? "month" : "months"
        case .year: return offer.periodCount == 1 ? "year" : "years"
        @unknown default: return "periods"
        }
    }
    
    // MARK: - Restore Section
    
    @ViewBuilder
    private var restoreSection: some View {
        Button {
            Task {
                await viewModel.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(configuration.accentColor)
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundStyle(configuration.secondaryTextColor)
        }
    }
    
    // MARK: - Close Button
    
    @ViewBuilder
    private var closeButton: some View {
        Button {
            onDismiss?()
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(configuration.secondaryTextColor)
        }
        .padding()
    }
}

// MARK: - Product Card

@available(iOS 15.0, macOS 12.0, *)
struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let configuration: PaywallConfiguration
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(configuration.textColor)
                        
                        if isBestValue {
                            Text("Best Value")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(configuration.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let subscription = product.subscription {
                        Text(periodDescription(subscription.subscriptionPeriod))
                            .font(.subheadline)
                            .foregroundStyle(configuration.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(configuration.textColor)
                    
                    if let subscription = product.subscription {
                        Text(pricePerMonth(product, subscription))
                            .font(.caption)
                            .foregroundStyle(configuration.secondaryTextColor)
                    }
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? configuration.accentColor : configuration.secondaryTextColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? configuration.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func periodDescription(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 1 ? "Daily" : "Every \(period.value) days"
        case .week: return period.value == 1 ? "Weekly" : "Every \(period.value) weeks"
        case .month: return period.value == 1 ? "Monthly" : "Every \(period.value) months"
        case .year: return period.value == 1 ? "Yearly" : "Every \(period.value) years"
        @unknown default: return "Recurring"
        }
    }
    
    private func pricePerMonth(_ product: Product, _ subscription: Product.SubscriptionInfo) -> String {
        let period = subscription.subscriptionPeriod
        
        guard period.unit == .year else { return "" }
        
        let yearlyPrice = product.price
        let monthlyPrice = yearlyPrice / Decimal(12)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.priceFormatStyle.currencyCode
        
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: monthlyPrice)) {
            return "\(formatted)/month"
        }
        
        return ""
    }
}

// MARK: - View Model

@available(iOS 15.0, macOS 12.0, *)
@MainActor
class PaywallViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let productIds: Set<String>
    private let storeKit = StoreKitManager.shared
    
    init(productIds: Set<String>) {
        self.productIds = productIds
    }
    
    func loadProducts() async {
        isLoading = true
        
        do {
            let fetchedProducts = try await storeKit.fetchProducts(ids: productIds)
            products = fetchedProducts.sorted { $0.price < $1.price }
            
            // Auto-select recommended product
            if selectedProduct == nil {
                selectedProduct = products.first { $0.subscription?.subscriptionPeriod.unit == .year }
                    ?? products.first
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func purchase() async -> Transaction? {
        guard let product = selectedProduct else { return nil }
        
        isLoading = true
        
        do {
            let transaction = try await storeKit.purchase(product)
            isLoading = false
            return transaction
        } catch let error as StoreKitError {
            if error != .purchaseCancelled {
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
        return nil
    }
    
    func restorePurchases() async {
        isLoading = true
        
        do {
            let count = try await storeKit.restorePurchases()
            if count == 0 {
                errorMessage = "No purchases to restore"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
