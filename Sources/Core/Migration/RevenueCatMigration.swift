// RevenueCatMigration.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit

/// Migration helper for transitioning from RevenueCat SDK
/// Provides equivalent APIs and data migration utilities
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class RevenueCatMigration {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = RevenueCatMigration()
    
    // MARK: - Properties
    
    private let storeKit = StoreKitManager.shared
    private var userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    private init() {
        self.userDefaults = UserDefaults.standard
    }
    
    // MARK: - API Equivalents
    
    // RevenueCat: Purchases.shared.logIn(...)
    /// Equivalent to RevenueCat's logIn - identifies the user
    /// - Parameter userId: Your app's user identifier
    public func logIn(_ userId: String) {
        userDefaults.set(userId, forKey: "PaymentFramework_UserId")
    }
    
    // RevenueCat: Purchases.shared.logOut()
    /// Equivalent to RevenueCat's logOut - resets to anonymous user
    public func logOut() {
        userDefaults.removeObject(forKey: "PaymentFramework_UserId")
    }
    
    // RevenueCat: Purchases.shared.getCustomerInfo()
    /// Equivalent to RevenueCat's getCustomerInfo
    /// - Returns: Customer info equivalent
    public func getCustomerInfo() async throws -> CustomerInfo {
        await storeKit.refreshEntitlements()
        
        let entitlements = storeKit.entitlements
        let subscriptionStatus = storeKit.subscriptionStatus
        
        return CustomerInfo(
            entitlements: EntitlementsInfo(from: entitlements),
            subscriptions: await getSubscriptionInfo(),
            nonSubscriptions: await getNonSubscriptionInfo(),
            firstSeen: userDefaults.object(forKey: "PaymentFramework_FirstSeen") as? Date ?? Date(),
            originalAppUserId: userDefaults.string(forKey: "PaymentFramework_UserId") ?? "anonymous"
        )
    }
    
    // RevenueCat: Purchases.shared.getOfferings()
    /// Equivalent to RevenueCat's getOfferings
    /// - Returns: Offerings equivalent
    public func getOfferings() async throws -> Offerings {
        let products = try await storeKit.fetchProducts()
        
        // Group products into offerings
        var packages: [Package] = []
        
        for product in products {
            let packageType: PackageType = determinePackageType(for: product)
            packages.append(Package(
                identifier: product.id,
                packageType: packageType,
                storeProduct: StoreProduct(from: product),
                offeringIdentifier: "default"
            ))
        }
        
        let currentOffering = Offering(
            identifier: "default",
            serverDescription: "Default Offering",
            availablePackages: packages
        )
        
        return Offerings(
            all: ["default": currentOffering],
            current: currentOffering
        )
    }
    
    // RevenueCat: Purchases.shared.purchase(package:)
    /// Equivalent to RevenueCat's purchase(package:)
    /// - Parameter package: Package to purchase
    /// - Returns: Purchase result
    public func purchase(package: Package) async throws -> (Transaction, CustomerInfo) {
        guard let product = storeKit.product(for: package.identifier) else {
            throw MigrationError.productNotFound(package.identifier)
        }
        
        let transaction = try await storeKit.purchase(product)
        let customerInfo = try await getCustomerInfo()
        
        return (transaction, customerInfo)
    }
    
    // RevenueCat: Purchases.shared.restorePurchases()
    /// Equivalent to RevenueCat's restorePurchases
    /// - Returns: Customer info after restore
    public func restorePurchases() async throws -> CustomerInfo {
        _ = try await storeKit.restorePurchases()
        return try await getCustomerInfo()
    }
    
    // RevenueCat: Purchases.shared.syncPurchases()
    /// Equivalent to RevenueCat's syncPurchases
    /// - Returns: Customer info after sync
    public func syncPurchases() async throws -> CustomerInfo {
        try await AppStore.sync()
        return try await getCustomerInfo()
    }
    
    // MARK: - Data Migration
    
    /// Migrate entitlement data from RevenueCat cache
    /// - Returns: Migrated entitlements
    public func migrateRevenueCatData() -> MigrationResult {
        var migratedEntitlements: [String] = []
        var errors: [String] = []
        
        // Try to find RevenueCat cached data
        let revenueCatKeys = [
            "com.revenuecat.userdefaults.appUserID",
            "com.revenuecat.userdefaults.cachedCustomerInfo",
            "com.revenuecat.userdefaults.subscriberAttributesSync"
        ]
        
        for key in revenueCatKeys {
            if let data = userDefaults.object(forKey: key) {
                // Mark as migrated
                userDefaults.set(data, forKey: "PaymentFramework_Migrated_\(key)")
                migratedEntitlements.append(key)
            }
        }
        
        // Copy user ID if exists
        if let revenueCatUserId = userDefaults.string(forKey: "com.revenuecat.userdefaults.appUserID") {
            logIn(revenueCatUserId)
        }
        
        return MigrationResult(
            success: true,
            migratedItems: migratedEntitlements,
            errors: errors
        )
    }
    
    // MARK: - Private Methods
    
    private func determinePackageType(for product: Product) -> PackageType {
        guard let subscription = product.subscription else {
            return product.type == .consumable ? .custom : .lifetime
        }
        
        let period = subscription.subscriptionPeriod
        
        switch period.unit {
        case .week:
            return period.value == 1 ? .weekly : .custom
        case .month:
            switch period.value {
            case 1: return .monthly
            case 2: return .twoMonth
            case 3: return .threeMonth
            case 6: return .sixMonth
            default: return .custom
            }
        case .year:
            return period.value == 1 ? .annual : .custom
        default:
            return .custom
        }
    }
    
    private func getSubscriptionInfo() async -> [String: SubscriptionInfo] {
        var subscriptions: [String: SubscriptionInfo] = [:]
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable else {
                continue
            }
            
            subscriptions[transaction.productID] = SubscriptionInfo(
                productId: transaction.productID,
                purchaseDate: transaction.purchaseDate,
                expiresDate: transaction.expirationDate,
                isActive: transaction.expirationDate ?? Date() > Date()
            )
        }
        
        return subscriptions
    }
    
    private func getNonSubscriptionInfo() async -> [String: NonSubscriptionInfo] {
        var nonSubscriptions: [String: NonSubscriptionInfo] = [:]
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType != .autoRenewable else {
                continue
            }
            
            nonSubscriptions[transaction.productID] = NonSubscriptionInfo(
                productId: transaction.productID,
                purchaseDate: transaction.purchaseDate,
                transactionId: String(transaction.id)
            )
        }
        
        return nonSubscriptions
    }
}

// MARK: - RevenueCat Equivalent Types

/// Customer info (equivalent to RevenueCat's CustomerInfo)
public struct CustomerInfo: Sendable {
    public let entitlements: EntitlementsInfo
    public let subscriptions: [String: SubscriptionInfo]
    public let nonSubscriptions: [String: NonSubscriptionInfo]
    public let firstSeen: Date
    public let originalAppUserId: String
}

/// Entitlements info (equivalent to RevenueCat's EntitlementInfos)
public struct EntitlementsInfo: Sendable {
    public let all: [String: EntitlementInfo]
    public let active: [String: EntitlementInfo]
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(from entitlements: Entitlements) {
        var all: [String: EntitlementInfo] = [:]
        var active: [String: EntitlementInfo] = [:]
        
        for id in entitlements.activeEntitlements {
            if let info = entitlements.entitlementInfo[id] {
                all[id] = info
                if info.isActive {
                    active[id] = info
                }
            }
        }
        
        self.all = all
        self.active = active
    }
    
    public subscript(key: String) -> EntitlementInfo? {
        all[key]
    }
}

/// Subscription info
public struct SubscriptionInfo: Sendable {
    public let productId: String
    public let purchaseDate: Date
    public let expiresDate: Date?
    public let isActive: Bool
}

/// Non-subscription info
public struct NonSubscriptionInfo: Sendable {
    public let productId: String
    public let purchaseDate: Date
    public let transactionId: String
}

/// Offerings (equivalent to RevenueCat's Offerings)
public struct Offerings: Sendable {
    public let all: [String: Offering]
    public let current: Offering?
    
    public subscript(key: String) -> Offering? {
        all[key]
    }
}

/// Offering (equivalent to RevenueCat's Offering)
public struct Offering: Sendable {
    public let identifier: String
    public let serverDescription: String
    public let availablePackages: [Package]
    
    /// Get package by type
    public func package(ofType type: PackageType) -> Package? {
        availablePackages.first { $0.packageType == type }
    }
    
    public var monthly: Package? { package(ofType: .monthly) }
    public var annual: Package? { package(ofType: .annual) }
    public var weekly: Package? { package(ofType: .weekly) }
    public var lifetime: Package? { package(ofType: .lifetime) }
}

/// Package (equivalent to RevenueCat's Package)
public struct Package: Identifiable, Sendable {
    public var id: String { identifier }
    public let identifier: String
    public let packageType: PackageType
    public let storeProduct: StoreProduct
    public let offeringIdentifier: String
    
    public var localizedPriceString: String {
        storeProduct.localizedPriceString
    }
}

/// Package type (equivalent to RevenueCat's PackageType)
public enum PackageType: String, Sendable {
    case unknown
    case custom
    case lifetime
    case annual
    case sixMonth
    case threeMonth
    case twoMonth
    case monthly
    case weekly
}

/// Store product (equivalent to RevenueCat's StoreProduct)
public struct StoreProduct: Sendable {
    public let productIdentifier: String
    public let productType: ProductType
    public let localizedTitle: String
    public let localizedDescription: String
    public let price: Decimal
    public let localizedPriceString: String
    public let currencyCode: String?
    
    public enum ProductType: String, Sendable {
        case consumable
        case nonConsumable
        case autoRenewable
        case nonRenewable
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(from product: Product) {
        self.productIdentifier = product.id
        self.localizedTitle = product.displayName
        self.localizedDescription = product.description
        self.price = product.price
        self.localizedPriceString = product.displayPrice
        self.currencyCode = product.priceFormatStyle.currencyCode
        
        switch product.type {
        case .consumable: self.productType = .consumable
        case .nonConsumable: self.productType = .nonConsumable
        case .autoRenewable: self.productType = .autoRenewable
        case .nonRenewable: self.productType = .nonRenewable
        @unknown default: self.productType = .nonConsumable
        }
    }
}

/// Migration result
public struct MigrationResult: Sendable {
    public let success: Bool
    public let migratedItems: [String]
    public let errors: [String]
}

/// Migration errors
public enum MigrationError: LocalizedError {
    case productNotFound(String)
    case migrationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        }
    }
}
