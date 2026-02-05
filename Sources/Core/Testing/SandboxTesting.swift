// SandboxTesting.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit
import OSLog

/// Comprehensive sandbox testing utilities for StoreKit development
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class SandboxTesting {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = SandboxTesting()
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "PaymentProcessingFramework", category: "SandboxTesting")
    private let storeKit = StoreKitManager.shared
    
    /// Current sandbox environment info
    public private(set) var environmentInfo: SandboxEnvironmentInfo?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Environment Detection
    
    /// Detect current StoreKit environment
    /// - Returns: Environment information
    public func detectEnvironment() async -> SandboxEnvironmentInfo {
        var isSandbox = false
        var isXcodeEnvironment = false
        var hasStoreKitConfiguration = false
        
        // Check transactions for environment
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                isSandbox = transaction.environment == .sandbox
                break
            }
        }
        
        // Check for Xcode environment
        #if DEBUG
        isXcodeEnvironment = true
        #endif
        
        // Check for StoreKit configuration file
        if let _ = Bundle.main.path(forResource: "StoreKitConfiguration", ofType: "storekit") {
            hasStoreKitConfiguration = true
        }
        
        let info = SandboxEnvironmentInfo(
            isSandbox: isSandbox,
            isXcodeEnvironment: isXcodeEnvironment,
            hasStoreKitConfiguration: hasStoreKitConfiguration,
            detectedAt: Date()
        )
        
        self.environmentInfo = info
        return info
    }
    
    /// Check if running in sandbox
    public func isSandbox() async -> Bool {
        let info = await detectEnvironment()
        return info.isSandbox || info.isXcodeEnvironment
    }
    
    // MARK: - Transaction Testing
    
    /// Get all sandbox transactions for debugging
    /// - Returns: Array of transaction debug info
    public func getAllTransactions() async -> [TransactionDebugInfo] {
        var transactions: [TransactionDebugInfo] = []
        
        for await result in Transaction.all {
            if case .verified(let transaction) = result {
                transactions.append(TransactionDebugInfo(from: transaction))
            }
        }
        
        return transactions.sorted { $0.purchaseDate > $1.purchaseDate }
    }
    
    /// Get current entitlements for debugging
    /// - Returns: Array of entitlement debug info
    public func getCurrentEntitlements() async -> [TransactionDebugInfo] {
        var transactions: [TransactionDebugInfo] = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                transactions.append(TransactionDebugInfo(from: transaction))
            }
        }
        
        return transactions
    }
    
    /// Get unfinished transactions (useful for debugging stuck purchases)
    /// - Returns: Array of unfinished transaction info
    public func getUnfinishedTransactions() async -> [TransactionDebugInfo] {
        var transactions: [TransactionDebugInfo] = []
        
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result {
                transactions.append(TransactionDebugInfo(from: transaction))
            }
        }
        
        return transactions
    }
    
    /// Finish all unfinished transactions (useful for clearing stuck state)
    /// - Returns: Number of transactions finished
    public func finishAllUnfinishedTransactions() async -> Int {
        var count = 0
        
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result {
                await transaction.finish()
                count += 1
                logger.info("Finished transaction: \(transaction.id)")
            }
        }
        
        return count
    }
    
    // MARK: - Subscription Testing
    
    /// Get subscription renewal info for testing
    /// - Parameter productId: Subscription product ID
    /// - Returns: Subscription debug info
    public func getSubscriptionDebugInfo(for productId: String) async throws -> SubscriptionDebugInfo? {
        guard let product = storeKit.product(for: productId),
              let subscription = product.subscription else {
            return nil
        }
        
        let statuses = try await subscription.status
        
        for status in statuses {
            guard case .verified(let renewalInfo) = status.renewalInfo,
                  case .verified(let transaction) = status.transaction else {
                continue
            }
            
            return SubscriptionDebugInfo(
                productId: productId,
                state: String(describing: status.state),
                renewalState: String(describing: renewalInfo.willAutoRenew),
                currentProductId: renewalInfo.currentProductID,
                autoRenewPreference: renewalInfo.autoRenewPreference,
                expirationReason: renewalInfo.expirationReason.map { String(describing: $0) },
                gracePeriodExpirationDate: renewalInfo.gracePeriodExpirationDate,
                isInBillingRetry: status.state == .inBillingRetryPeriod,
                transaction: TransactionDebugInfo(from: transaction)
            )
        }
        
        return nil
    }
    
    // MARK: - Sandbox Account Testing
    
    /// Simulate different subscription states (for UI testing only)
    /// Note: Actual state changes require App Store Connect sandbox controls
    public func simulateSubscriptionState(_ state: SimulatedSubscriptionState) -> SubscriptionStatus {
        let mockDetails = SubscriptionDetails(
            productId: "test.subscription",
            productName: "Test Subscription",
            purchaseDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
            expirationDate: state.expirationDate,
            originalTransactionId: 12345678,
            transactionId: 87654321,
            willAutoRenew: state.willAutoRenew,
            currentPeriodType: state.periodType,
            pricePerPeriod: "$9.99/month",
            subscriptionPeriod: SubscriptionPeriod(unit: .month, value: 1),
            isUpgraded: false,
            environment: .sandbox
        )
        
        switch state {
        case .active:
            return .subscribed(details: mockDetails)
        case .trial:
            return .inTrial(details: mockDetails)
        case .gracePeriod:
            return .inGracePeriod(details: mockDetails)
        case .billingRetry:
            return .inBillingRetry(details: mockDetails)
        case .expired:
            return .expired(details: mockDetails)
        case .cancelled:
            return .pendingCancellation(details: mockDetails)
        }
    }
    
    // MARK: - Debug Logging
    
    /// Print all transactions to console for debugging
    public func printAllTransactions() async {
        let transactions = await getAllTransactions()
        
        print("\n========== SANDBOX TRANSACTIONS ==========")
        print("Total: \(transactions.count)")
        print("==========================================\n")
        
        for transaction in transactions {
            print(transaction.debugDescription)
            print("------------------------------------------")
        }
    }
    
    /// Print subscription status to console
    public func printSubscriptionStatus(for productId: String) async {
        do {
            if let info = try await getSubscriptionDebugInfo(for: productId) {
                print("\n========== SUBSCRIPTION DEBUG ==========")
                print("Product: \(info.productId)")
                print("State: \(info.state)")
                print("Will Auto-Renew: \(info.renewalState)")
                print("Is In Billing Retry: \(info.isInBillingRetry)")
                if let expReason = info.expirationReason {
                    print("Expiration Reason: \(expReason)")
                }
                if let graceDate = info.gracePeriodExpirationDate {
                    print("Grace Period Expires: \(graceDate)")
                }
                print("=========================================\n")
            } else {
                print("No subscription found for \(productId)")
            }
        } catch {
            print("Error getting subscription info: \(error)")
        }
    }
    
    /// Generate test report
    public func generateTestReport() async -> SandboxTestReport {
        let environment = await detectEnvironment()
        let allTransactions = await getAllTransactions()
        let currentEntitlements = await getCurrentEntitlements()
        let unfinishedTransactions = await getUnfinishedTransactions()
        
        var productsFetched = 0
        do {
            let products = try await storeKit.fetchProducts()
            productsFetched = products.count
        } catch {
            logger.error("Failed to fetch products: \(error.localizedDescription)")
        }
        
        return SandboxTestReport(
            environment: environment,
            productsAvailable: productsFetched,
            totalTransactions: allTransactions.count,
            currentEntitlements: currentEntitlements.count,
            unfinishedTransactions: unfinishedTransactions.count,
            transactions: allTransactions,
            generatedAt: Date()
        )
    }
    
    /// Export test report as JSON
    public func exportTestReportJSON() async -> Data? {
        let report = await generateTestReport()
        
        let exportable: [String: Any] = [
            "environment": [
                "isSandbox": report.environment.isSandbox,
                "isXcodeEnvironment": report.environment.isXcodeEnvironment,
                "hasStoreKitConfiguration": report.environment.hasStoreKitConfiguration
            ],
            "productsAvailable": report.productsAvailable,
            "totalTransactions": report.totalTransactions,
            "currentEntitlements": report.currentEntitlements,
            "unfinishedTransactions": report.unfinishedTransactions,
            "generatedAt": ISO8601DateFormatter().string(from: report.generatedAt)
        ]
        
        return try? JSONSerialization.data(withJSONObject: exportable, options: .prettyPrinted)
    }
}

// MARK: - Debug Types

/// Sandbox environment information
public struct SandboxEnvironmentInfo: Sendable {
    public let isSandbox: Bool
    public let isXcodeEnvironment: Bool
    public let hasStoreKitConfiguration: Bool
    public let detectedAt: Date
}

/// Transaction debug information
public struct TransactionDebugInfo: Sendable, CustomDebugStringConvertible {
    public let id: UInt64
    public let originalId: UInt64
    public let productId: String
    public let productType: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let environment: String
    public let ownershipType: String
    public let offerType: String?
    public let isUpgraded: Bool
    public let jsonRepresentation: String?
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.originalId = transaction.originalID
        self.productId = transaction.productID
        self.productType = String(describing: transaction.productType)
        self.purchaseDate = transaction.purchaseDate
        self.expirationDate = transaction.expirationDate
        self.revocationDate = transaction.revocationDate
        self.environment = transaction.environment == .sandbox ? "Sandbox" : "Production"
        self.ownershipType = String(describing: transaction.ownershipType)
        self.offerType = transaction.offerType.map { String(describing: $0) }
        self.isUpgraded = transaction.isUpgraded
        self.jsonRepresentation = transaction.jsonRepresentation.flatMap {
            String(data: $0, encoding: .utf8)
        }
    }
    
    public var debugDescription: String {
        """
        Transaction #\(id)
        - Product: \(productId) (\(productType))
        - Original ID: \(originalId)
        - Purchase Date: \(purchaseDate)
        - Expiration: \(expirationDate?.description ?? "N/A")
        - Environment: \(environment)
        - Ownership: \(ownershipType)
        - Offer Type: \(offerType ?? "None")
        - Is Upgraded: \(isUpgraded)
        """
    }
}

/// Subscription debug information
public struct SubscriptionDebugInfo: Sendable {
    public let productId: String
    public let state: String
    public let renewalState: String
    public let currentProductId: String
    public let autoRenewPreference: String?
    public let expirationReason: String?
    public let gracePeriodExpirationDate: Date?
    public let isInBillingRetry: Bool
    public let transaction: TransactionDebugInfo
}

/// Simulated subscription state for testing
public enum SimulatedSubscriptionState {
    case active(willAutoRenew: Bool = true)
    case trial
    case gracePeriod
    case billingRetry
    case expired
    case cancelled
    
    var willAutoRenew: Bool {
        switch self {
        case .active(let willRenew): return willRenew
        case .trial: return true
        case .cancelled, .expired: return false
        default: return true
        }
    }
    
    var expirationDate: Date? {
        switch self {
        case .active, .trial, .gracePeriod, .billingRetry:
            return Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
        case .expired:
            return Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        case .cancelled:
            return Date().addingTimeInterval(15 * 24 * 60 * 60) // 15 days from now
        }
    }
    
    var periodType: PeriodType {
        switch self {
        case .trial: return .trial
        default: return .standard
        }
    }
}

/// Sandbox test report
public struct SandboxTestReport: Sendable {
    public let environment: SandboxEnvironmentInfo
    public let productsAvailable: Int
    public let totalTransactions: Int
    public let currentEntitlements: Int
    public let unfinishedTransactions: Int
    public let transactions: [TransactionDebugInfo]
    public let generatedAt: Date
}
