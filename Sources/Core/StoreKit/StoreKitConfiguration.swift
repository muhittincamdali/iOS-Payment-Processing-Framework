// StoreKitConfiguration.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// Comprehensive StoreKit configuration
public struct StoreKitConfiguration: Sendable {
    
    // MARK: - Properties
    
    /// Receipt validation configuration
    public let receiptValidation: ReceiptValidationConfiguration
    
    /// Entitlement configuration
    public let entitlements: EntitlementConfiguration
    
    /// Analytics configuration
    public let analytics: AnalyticsConfiguration
    
    /// Product caching configuration
    public let caching: CachingConfiguration
    
    /// Debug/Logging configuration
    public let debug: DebugConfiguration
    
    // MARK: - Default Configuration
    
    /// Default configuration
    public static let `default` = StoreKitConfiguration(
        receiptValidation: .default,
        entitlements: .default,
        analytics: .default,
        caching: .default,
        debug: .default
    )
    
    // MARK: - Initialization
    
    public init(
        receiptValidation: ReceiptValidationConfiguration = .default,
        entitlements: EntitlementConfiguration = .default,
        analytics: AnalyticsConfiguration = .default,
        caching: CachingConfiguration = .default,
        debug: DebugConfiguration = .default
    ) {
        self.receiptValidation = receiptValidation
        self.entitlements = entitlements
        self.analytics = analytics
        self.caching = caching
        self.debug = debug
    }
    
    // MARK: - Builder
    
    /// Builder for creating configurations
    public static func builder() -> Builder {
        Builder()
    }
    
    /// Configuration builder
    public final class Builder {
        private var receiptValidation: ReceiptValidationConfiguration = .default
        private var entitlements: EntitlementConfiguration = .default
        private var analytics: AnalyticsConfiguration = .default
        private var caching: CachingConfiguration = .default
        private var debug: DebugConfiguration = .default
        
        public init() {}
        
        /// Configure receipt validation
        @discardableResult
        public func receiptValidation(
            serverURL: URL? = nil,
            apiKey: String? = nil,
            sharedSecret: String? = nil,
            useServerValidation: Bool = false
        ) -> Builder {
            self.receiptValidation = ReceiptValidationConfiguration(
                serverURL: serverURL,
                apiKey: apiKey,
                sharedSecret: sharedSecret,
                useServerValidation: useServerValidation
            )
            return self
        }
        
        /// Configure entitlements
        @discardableResult
        public func entitlements(
            defaultMappings: [String: Set<String>],
            autoSync: Bool = true
        ) -> Builder {
            self.entitlements = EntitlementConfiguration(
                defaultMappings: defaultMappings,
                autoSync: autoSync
            )
            return self
        }
        
        /// Configure analytics
        @discardableResult
        public func analytics(
            enabled: Bool = true,
            trackPurchases: Bool = true,
            trackErrors: Bool = true
        ) -> Builder {
            self.analytics = AnalyticsConfiguration(
                enabled: enabled,
                trackPurchases: trackPurchases,
                trackErrors: trackErrors
            )
            return self
        }
        
        /// Configure caching
        @discardableResult
        public func caching(
            productCacheDuration: TimeInterval = 300,
            enableOfflineCache: Bool = true
        ) -> Builder {
            self.caching = CachingConfiguration(
                productCacheDuration: productCacheDuration,
                enableOfflineCache: enableOfflineCache
            )
            return self
        }
        
        /// Configure debug options
        @discardableResult
        public func debug(
            verboseLogging: Bool = false,
            simulateErrors: Bool = false
        ) -> Builder {
            self.debug = DebugConfiguration(
                verboseLogging: verboseLogging,
                simulateErrors: simulateErrors
            )
            return self
        }
        
        /// Build the configuration
        public func build() -> StoreKitConfiguration {
            StoreKitConfiguration(
                receiptValidation: receiptValidation,
                entitlements: entitlements,
                analytics: analytics,
                caching: caching,
                debug: debug
            )
        }
    }
}

// MARK: - Analytics Configuration

/// Analytics tracking configuration
public struct AnalyticsConfiguration: Sendable {
    /// Whether analytics is enabled
    public let enabled: Bool
    
    /// Track purchase events
    public let trackPurchases: Bool
    
    /// Track error events
    public let trackErrors: Bool
    
    /// Custom analytics handler
    public let customHandler: (@Sendable (AnalyticsEvent) -> Void)?
    
    /// Default configuration
    public static let `default` = AnalyticsConfiguration(
        enabled: true,
        trackPurchases: true,
        trackErrors: true
    )
    
    public init(
        enabled: Bool = true,
        trackPurchases: Bool = true,
        trackErrors: Bool = true,
        customHandler: (@Sendable (AnalyticsEvent) -> Void)? = nil
    ) {
        self.enabled = enabled
        self.trackPurchases = trackPurchases
        self.trackErrors = trackErrors
        self.customHandler = customHandler
    }
}

// MARK: - Caching Configuration

/// Product caching configuration
public struct CachingConfiguration: Sendable {
    /// How long to cache product information
    public let productCacheDuration: TimeInterval
    
    /// Enable offline caching
    public let enableOfflineCache: Bool
    
    /// Maximum cache size in bytes
    public let maxCacheSize: Int
    
    /// Default configuration
    public static let `default` = CachingConfiguration(
        productCacheDuration: 300, // 5 minutes
        enableOfflineCache: true,
        maxCacheSize: 1024 * 1024 // 1 MB
    )
    
    public init(
        productCacheDuration: TimeInterval = 300,
        enableOfflineCache: Bool = true,
        maxCacheSize: Int = 1024 * 1024
    ) {
        self.productCacheDuration = productCacheDuration
        self.enableOfflineCache = enableOfflineCache
        self.maxCacheSize = maxCacheSize
    }
}

// MARK: - Debug Configuration

/// Debug and logging configuration
public struct DebugConfiguration: Sendable {
    /// Enable verbose logging
    public let verboseLogging: Bool
    
    /// Simulate errors for testing
    public let simulateErrors: Bool
    
    /// Simulated error rate (0.0 - 1.0)
    public let simulatedErrorRate: Double
    
    /// Print transactions to console
    public let printTransactions: Bool
    
    /// Default configuration
    public static let `default` = DebugConfiguration(
        verboseLogging: false,
        simulateErrors: false,
        simulatedErrorRate: 0.0,
        printTransactions: false
    )
    
    public init(
        verboseLogging: Bool = false,
        simulateErrors: Bool = false,
        simulatedErrorRate: Double = 0.0,
        printTransactions: Bool = false
    ) {
        self.verboseLogging = verboseLogging
        self.simulateErrors = simulateErrors
        self.simulatedErrorRate = simulatedErrorRate
        self.printTransactions = printTransactions
    }
}

// MARK: - Analytics Event

/// Analytics event types
public enum AnalyticsEvent: Sendable {
    case productsFetched(count: Int)
    case purchaseStarted(productId: String)
    case purchaseCompleted(productId: String, price: Decimal, currency: String?)
    case purchaseCancelled(productId: String)
    case purchasePending(productId: String)
    case purchaseFailed(productId: String, error: String)
    case subscriptionRenewed(productId: String)
    case subscriptionExpired(productId: String)
    case subscriptionCancelled(productId: String)
    case refundRequested(transactionId: UInt64)
    case restoreCompleted(count: Int)
    case verificationFailed(productId: String, error: String)
    case receiptValidated(success: Bool)
    case custom(name: String, parameters: [String: String])
    
    /// Event name for logging
    public var name: String {
        switch self {
        case .productsFetched: return "products_fetched"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseCancelled: return "purchase_cancelled"
        case .purchasePending: return "purchase_pending"
        case .purchaseFailed: return "purchase_failed"
        case .subscriptionRenewed: return "subscription_renewed"
        case .subscriptionExpired: return "subscription_expired"
        case .subscriptionCancelled: return "subscription_cancelled"
        case .refundRequested: return "refund_requested"
        case .restoreCompleted: return "restore_completed"
        case .verificationFailed: return "verification_failed"
        case .receiptValidated: return "receipt_validated"
        case .custom(let name, _): return name
        }
    }
}
