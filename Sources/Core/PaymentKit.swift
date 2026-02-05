// PaymentKit.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

/// PaymentKit - World-class iOS Payment Processing Framework
///
/// A complete StoreKit 2 wrapper with enterprise-grade features for
/// In-App Purchases, Subscriptions, and Payment Processing.
///
/// ## Quick Start
/// ```swift
/// import PaymentProcessingFramework
///
/// // Configure product IDs
/// StoreKitManager.shared.configure(productIds: [
///     "com.app.premium.monthly",
///     "com.app.premium.yearly"
/// ])
///
/// // Fetch products
/// let products = try await StoreKitManager.shared.fetchProducts()
///
/// // Purchase
/// let transaction = try await StoreKitManager.shared.purchase(products.first!)
/// ```
///
/// ## Features
/// - ✅ StoreKit 2 native async/await API
/// - ✅ Entitlement management
/// - ✅ Receipt validation (local & server)
/// - ✅ Subscription lifecycle handling
/// - ✅ Promotional offers
/// - ✅ Price localization
/// - ✅ Grace period & billing retry
/// - ✅ Refund handling
/// - ✅ Family sharing support
/// - ✅ RevenueCat migration
/// - ✅ SwiftyStoreKit migration
/// - ✅ Sandbox testing tools
/// - ✅ Purchase analytics

import Foundation

// MARK: - Version Info

/// Framework version information
public enum PaymentKit {
    /// Current framework version
    public static let version = "2.0.0"
    
    /// Minimum iOS version supported
    public static let minimumIOSVersion = "15.0"
    
    /// Minimum macOS version supported
    public static let minimumMacOSVersion = "12.0"
    
    /// Build number
    public static let build = "2025.02.05"
}

// MARK: - Typealiases

/// Convenient typealias for StoreKitManager
public typealias PaymentManager = StoreKitManager

/// Convenient typealias for common use
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public typealias PurchaseManager = StoreKitManager
