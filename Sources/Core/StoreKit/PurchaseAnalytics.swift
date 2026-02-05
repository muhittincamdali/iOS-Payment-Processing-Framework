// PurchaseAnalytics.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import OSLog

/// Comprehensive analytics tracking for purchases and subscriptions
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class PurchaseAnalytics: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let configuration: AnalyticsConfiguration
    private let logger = Logger(subsystem: "PaymentProcessingFramework", category: "Analytics")
    private var eventQueue: [AnalyticsEvent] = []
    private let queue = DispatchQueue(label: "com.payment.analytics", qos: .utility)
    
    /// Revenue metrics
    private var totalRevenue: Decimal = 0
    private var transactionCount: Int = 0
    private var failureCount: Int = 0
    
    // MARK: - Initialization
    
    public init(configuration: AnalyticsConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Event Tracking
    
    /// Track products fetched
    public func trackProductsFetched(count: Int) {
        track(.productsFetched(count: count))
    }
    
    /// Track purchase started
    public func trackPurchaseStarted(productId: String) {
        track(.purchaseStarted(productId: productId))
    }
    
    /// Track purchase completed
    public func trackPurchaseCompleted(productId: String, price: Decimal, currency: String?) {
        queue.async { [weak self] in
            self?.totalRevenue += price
            self?.transactionCount += 1
        }
        track(.purchaseCompleted(productId: productId, price: price, currency: currency))
    }
    
    /// Track purchase cancelled
    public func trackPurchaseCancelled(productId: String) {
        track(.purchaseCancelled(productId: productId))
    }
    
    /// Track purchase pending
    public func trackPurchasePending(productId: String) {
        track(.purchasePending(productId: productId))
    }
    
    /// Track purchase failed
    public func trackPurchaseFailed(productId: String, error: Error) {
        queue.async { [weak self] in
            self?.failureCount += 1
        }
        track(.purchaseFailed(productId: productId, error: error.localizedDescription))
    }
    
    /// Track subscription renewed
    public func trackSubscriptionRenewed(productId: String) {
        track(.subscriptionRenewed(productId: productId))
    }
    
    /// Track subscription expired
    public func trackSubscriptionExpired(productId: String) {
        track(.subscriptionExpired(productId: productId))
    }
    
    /// Track subscription cancelled
    public func trackSubscriptionCancelled(productId: String) {
        track(.subscriptionCancelled(productId: productId))
    }
    
    /// Track refund requested
    public func trackRefundRequested(transactionId: UInt64) {
        track(.refundRequested(transactionId: transactionId))
    }
    
    /// Track purchases restored
    public func trackPurchasesRestored(count: Int) {
        track(.restoreCompleted(count: count))
    }
    
    /// Track verification failed
    public func trackVerificationFailed(productId: String, error: Error) {
        track(.verificationFailed(productId: productId, error: error.localizedDescription))
    }
    
    /// Track receipt validation
    public func trackReceiptValidated(success: Bool) {
        track(.receiptValidated(success: success))
    }
    
    /// Track custom event
    public func trackCustom(name: String, parameters: [String: String] = [:]) {
        track(.custom(name: name, parameters: parameters))
    }
    
    // MARK: - Metrics
    
    /// Get current revenue metrics
    public func getMetrics() -> RevenueMetrics {
        var metrics = RevenueMetrics(
            totalRevenue: 0,
            transactionCount: 0,
            failureCount: 0,
            successRate: 0
        )
        
        queue.sync {
            metrics = RevenueMetrics(
                totalRevenue: self.totalRevenue,
                transactionCount: self.transactionCount,
                failureCount: self.failureCount,
                successRate: self.transactionCount > 0 
                    ? Double(self.transactionCount - self.failureCount) / Double(self.transactionCount) 
                    : 0
            )
        }
        
        return metrics
    }
    
    /// Reset metrics
    public func resetMetrics() {
        queue.async { [weak self] in
            self?.totalRevenue = 0
            self?.transactionCount = 0
            self?.failureCount = 0
        }
    }
    
    // MARK: - Event Export
    
    /// Get all tracked events
    public func getEvents() -> [AnalyticsEvent] {
        var events: [AnalyticsEvent] = []
        queue.sync {
            events = self.eventQueue
        }
        return events
    }
    
    /// Clear event queue
    public func clearEvents() {
        queue.async { [weak self] in
            self?.eventQueue.removeAll()
        }
    }
    
    /// Export events as JSON
    public func exportEventsJSON() -> Data? {
        let events = getEvents()
        let exportable = events.map { event -> [String: Any] in
            var dict: [String: Any] = ["name": event.name, "timestamp": Date().timeIntervalSince1970]
            
            switch event {
            case .productsFetched(let count):
                dict["count"] = count
            case .purchaseStarted(let productId):
                dict["productId"] = productId
            case .purchaseCompleted(let productId, let price, let currency):
                dict["productId"] = productId
                dict["price"] = NSDecimalNumber(decimal: price).doubleValue
                dict["currency"] = currency ?? "USD"
            case .purchaseCancelled(let productId):
                dict["productId"] = productId
            case .purchasePending(let productId):
                dict["productId"] = productId
            case .purchaseFailed(let productId, let error):
                dict["productId"] = productId
                dict["error"] = error
            case .subscriptionRenewed(let productId):
                dict["productId"] = productId
            case .subscriptionExpired(let productId):
                dict["productId"] = productId
            case .subscriptionCancelled(let productId):
                dict["productId"] = productId
            case .refundRequested(let transactionId):
                dict["transactionId"] = transactionId
            case .restoreCompleted(let count):
                dict["count"] = count
            case .verificationFailed(let productId, let error):
                dict["productId"] = productId
                dict["error"] = error
            case .receiptValidated(let success):
                dict["success"] = success
            case .custom(let name, let parameters):
                dict["customName"] = name
                dict["parameters"] = parameters
            }
            
            return dict
        }
        
        return try? JSONSerialization.data(withJSONObject: exportable, options: .prettyPrinted)
    }
    
    // MARK: - Private Methods
    
    private func track(_ event: AnalyticsEvent) {
        guard configuration.enabled else { return }
        
        // Log event
        logger.info("[\(event.name)] tracked")
        
        // Add to queue
        queue.async { [weak self] in
            self?.eventQueue.append(event)
            
            // Keep queue size manageable
            if self?.eventQueue.count ?? 0 > 1000 {
                self?.eventQueue.removeFirst(100)
            }
        }
        
        // Call custom handler
        configuration.customHandler?(event)
    }
}

// MARK: - Revenue Metrics

/// Revenue metrics structure
public struct RevenueMetrics: Sendable {
    /// Total revenue tracked
    public let totalRevenue: Decimal
    
    /// Total transaction count
    public let transactionCount: Int
    
    /// Failed transaction count
    public let failureCount: Int
    
    /// Success rate (0.0 - 1.0)
    public let successRate: Double
    
    /// Formatted total revenue
    public func formattedRevenue(currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: totalRevenue)) ?? "$0.00"
    }
}
