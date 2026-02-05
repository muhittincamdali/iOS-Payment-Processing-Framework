// SubscriptionStatus.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit

/// Comprehensive subscription status with all details
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public enum SubscriptionStatus: Equatable, Sendable {
    /// User is not subscribed
    case notSubscribed
    
    /// User has an active subscription
    case subscribed(details: SubscriptionDetails)
    
    /// User has a subscription but it's in grace period (payment failed but still has access)
    case inGracePeriod(details: SubscriptionDetails)
    
    /// User's subscription is in billing retry period
    case inBillingRetry(details: SubscriptionDetails)
    
    /// User's subscription has expired
    case expired(details: SubscriptionDetails)
    
    /// User's subscription was revoked (refund)
    case revoked(details: SubscriptionDetails)
    
    /// User is in free trial
    case inTrial(details: SubscriptionDetails)
    
    /// User has cancelled but subscription is still active until period ends
    case pendingCancellation(details: SubscriptionDetails)
    
    // MARK: - Computed Properties
    
    /// Whether the user currently has access to subscription features
    public var isActive: Bool {
        switch self {
        case .subscribed, .inGracePeriod, .inTrial, .pendingCancellation:
            return true
        case .notSubscribed, .expired, .revoked, .inBillingRetry:
            return false
        }
    }
    
    /// Whether the subscription will renew
    public var willRenew: Bool {
        switch self {
        case .subscribed(let details), .inTrial(let details), .inGracePeriod(let details):
            return details.willAutoRenew
        case .pendingCancellation, .expired, .revoked, .notSubscribed, .inBillingRetry:
            return false
        }
    }
    
    /// Get the subscription details if available
    public var details: SubscriptionDetails? {
        switch self {
        case .notSubscribed:
            return nil
        case .subscribed(let details),
             .inGracePeriod(let details),
             .inBillingRetry(let details),
             .expired(let details),
             .revoked(let details),
             .inTrial(let details),
             .pendingCancellation(let details):
            return details
        }
    }
    
    /// Human-readable status description
    public var description: String {
        switch self {
        case .notSubscribed:
            return "Not Subscribed"
        case .subscribed:
            return "Active Subscription"
        case .inGracePeriod:
            return "Grace Period"
        case .inBillingRetry:
            return "Billing Retry"
        case .expired:
            return "Expired"
        case .revoked:
            return "Revoked"
        case .inTrial:
            return "Free Trial"
        case .pendingCancellation:
            return "Cancelled (Active Until Period End)"
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize from StoreKit 2 subscription state
    init(
        from state: Product.SubscriptionInfo.RenewalState,
        transaction: Transaction,
        renewalInfo: Product.SubscriptionInfo.RenewalInfo,
        product: Product
    ) {
        let details = SubscriptionDetails(
            productId: product.id,
            productName: product.displayName,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            originalTransactionId: transaction.originalID,
            transactionId: transaction.id,
            willAutoRenew: renewalInfo.willAutoRenew,
            currentPeriodType: Self.determinePeriodType(from: transaction),
            pricePerPeriod: product.displayPrice,
            subscriptionPeriod: product.subscription?.subscriptionPeriod,
            isUpgraded: renewalInfo.currentProductID != product.id,
            environment: transaction.environment
        )
        
        // Check if user cancelled but still has access
        if !renewalInfo.willAutoRenew && state == .subscribed {
            self = .pendingCancellation(details: details)
            return
        }
        
        switch state {
        case .subscribed:
            // Check if in trial
            if transaction.offerType == .introductory {
                self = .inTrial(details: details)
            } else {
                self = .subscribed(details: details)
            }
            
        case .expired:
            self = .expired(details: details)
            
        case .inBillingRetryPeriod:
            self = .inBillingRetry(details: details)
            
        case .inGracePeriod:
            self = .inGracePeriod(details: details)
            
        case .revoked:
            self = .revoked(details: details)
            
        @unknown default:
            self = .notSubscribed
        }
    }
    
    private static func determinePeriodType(from transaction: Transaction) -> PeriodType {
        guard let offerType = transaction.offerType else {
            return .standard
        }
        
        switch offerType {
        case .introductory:
            return .trial
        case .promotional:
            return .promotional
        case .code:
            return .offerCode
        @unknown default:
            return .standard
        }
    }
}

// MARK: - Supporting Types

/// Detailed subscription information
public struct SubscriptionDetails: Equatable, Sendable, Codable {
    /// Product identifier
    public let productId: String
    
    /// Product display name
    public let productName: String
    
    /// Original purchase date
    public let purchaseDate: Date
    
    /// Expiration date (nil for non-subscriptions)
    public let expirationDate: Date?
    
    /// Original transaction ID (stays same across renewals)
    public let originalTransactionId: UInt64
    
    /// Current transaction ID
    public let transactionId: UInt64
    
    /// Whether subscription will auto-renew
    public let willAutoRenew: Bool
    
    /// Current subscription period type
    public let currentPeriodType: PeriodType
    
    /// Formatted price per period
    public let pricePerPeriod: String
    
    /// Subscription period (duration)
    public let subscriptionPeriod: SubscriptionPeriod?
    
    /// Whether this subscription was upgraded from another
    public let isUpgraded: Bool
    
    /// Environment (sandbox or production)
    public let environment: AppStore.Environment
    
    // MARK: - Computed Properties
    
    /// Days remaining in current period
    public var daysRemaining: Int? {
        guard let expiration = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiration)
        return max(0, components.day ?? 0)
    }
    
    /// Whether subscription is expired
    public var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }
    
    /// Whether in sandbox environment
    public var isSandbox: Bool {
        environment == .sandbox
    }
}

/// Subscription period type
public enum PeriodType: String, Codable, Sendable {
    case trial
    case introductory
    case standard
    case promotional
    case offerCode
}

/// Subscription period duration
public struct SubscriptionPeriod: Equatable, Sendable, Codable {
    public let unit: Unit
    public let value: Int
    
    public enum Unit: String, Codable, Sendable {
        case day
        case week
        case month
        case year
    }
    
    public var description: String {
        let unitString: String
        switch unit {
        case .day: unitString = value == 1 ? "day" : "days"
        case .week: unitString = value == 1 ? "week" : "weeks"
        case .month: unitString = value == 1 ? "month" : "months"
        case .year: unitString = value == 1 ? "year" : "years"
        }
        return "\(value) \(unitString)"
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SubscriptionPeriod {
    init?(from period: Product.SubscriptionPeriod) {
        self.value = period.value
        switch period.unit {
        case .day: self.unit = .day
        case .week: self.unit = .week
        case .month: self.unit = .month
        case .year: self.unit = .year
        @unknown default: return nil
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SubscriptionDetails {
    init(
        productId: String,
        productName: String,
        purchaseDate: Date,
        expirationDate: Date?,
        originalTransactionId: UInt64,
        transactionId: UInt64,
        willAutoRenew: Bool,
        currentPeriodType: PeriodType,
        pricePerPeriod: String,
        subscriptionPeriod: Product.SubscriptionPeriod?,
        isUpgraded: Bool,
        environment: AppStore.Environment
    ) {
        self.productId = productId
        self.productName = productName
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.originalTransactionId = originalTransactionId
        self.transactionId = transactionId
        self.willAutoRenew = willAutoRenew
        self.currentPeriodType = currentPeriodType
        self.pricePerPeriod = pricePerPeriod
        self.subscriptionPeriod = subscriptionPeriod.flatMap { SubscriptionPeriod(from: $0) }
        self.isUpgraded = isUpgraded
        self.environment = environment
    }
}
