// AnalyticsExport.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation

/// Analytics module re-exports
/// Import PaymentProcessingAnalytics for analytics-specific features

@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

/// Analytics module version
public enum PaymentAnalytics {
    public static let version = "2.0.0"
}

/// Analytics export helper
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class AnalyticsExporter {
    
    /// Export analytics data to JSON
    /// - Parameter analytics: Purchase analytics instance
    /// - Returns: JSON data
    public static func exportToJSON(from analytics: PurchaseAnalytics) -> Data? {
        analytics.exportEventsJSON()
    }
    
    /// Export metrics summary
    /// - Parameter analytics: Purchase analytics instance
    /// - Returns: Summary dictionary
    public static func exportMetricsSummary(from analytics: PurchaseAnalytics) -> [String: Any] {
        let metrics = analytics.getMetrics()
        
        return [
            "totalRevenue": NSDecimalNumber(decimal: metrics.totalRevenue).doubleValue,
            "transactionCount": metrics.transactionCount,
            "failureCount": metrics.failureCount,
            "successRate": metrics.successRate,
            "formattedRevenue": metrics.formattedRevenue()
        ]
    }
}
