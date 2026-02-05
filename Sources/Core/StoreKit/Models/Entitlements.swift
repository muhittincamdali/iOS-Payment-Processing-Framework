// Entitlements.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit

/// Enterprise-grade entitlement management system
/// Maps products to features for flexible access control
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct Entitlements: Equatable, Sendable {
    
    // MARK: - Properties
    
    /// Currently active entitlement identifiers
    public private(set) var activeEntitlements: Set<String> = []
    
    /// Product to entitlement mapping
    public private(set) var productEntitlements: [String: Set<String>] = [:]
    
    /// Entitlement metadata
    public private(set) var entitlementInfo: [String: EntitlementInfo] = [:]
    
    // MARK: - Initialization
    
    public init() {}
    
    public init(
        activeEntitlements: Set<String>,
        productEntitlements: [String: Set<String>],
        entitlementInfo: [String: EntitlementInfo]
    ) {
        self.activeEntitlements = activeEntitlements
        self.productEntitlements = productEntitlements
        self.entitlementInfo = entitlementInfo
    }
    
    // MARK: - Public Methods
    
    /// Check if user has a specific entitlement
    /// - Parameter entitlementId: The entitlement identifier
    /// - Returns: True if entitled
    public func isEntitled(to entitlementId: String) -> Bool {
        activeEntitlements.contains(entitlementId)
    }
    
    /// Check multiple entitlements at once
    /// - Parameter entitlementIds: Set of entitlement identifiers
    /// - Returns: True if all entitlements are active
    public func hasAllEntitlements(_ entitlementIds: Set<String>) -> Bool {
        entitlementIds.isSubset(of: activeEntitlements)
    }
    
    /// Check if user has any of the specified entitlements
    /// - Parameter entitlementIds: Set of entitlement identifiers
    /// - Returns: True if any entitlement is active
    public func hasAnyEntitlement(_ entitlementIds: Set<String>) -> Bool {
        !activeEntitlements.isDisjoint(with: entitlementIds)
    }
    
    /// Get entitlement info
    /// - Parameter entitlementId: The entitlement identifier
    /// - Returns: Entitlement information if available
    public func info(for entitlementId: String) -> EntitlementInfo? {
        entitlementInfo[entitlementId]
    }
    
    /// Get all entitlements for a product
    /// - Parameter productId: The product identifier
    /// - Returns: Set of entitlement IDs granted by this product
    public func entitlements(for productId: String) -> Set<String> {
        productEntitlements[productId] ?? []
    }
    
    // MARK: - Mutating Methods
    
    /// Add an active entitlement
    mutating func activate(_ entitlementId: String, info: EntitlementInfo) {
        activeEntitlements.insert(entitlementId)
        entitlementInfo[entitlementId] = info
    }
    
    /// Remove an active entitlement
    mutating func deactivate(_ entitlementId: String) {
        activeEntitlements.remove(entitlementId)
        entitlementInfo.removeValue(forKey: entitlementId)
    }
    
    /// Configure product to entitlement mapping
    mutating func mapProduct(_ productId: String, to entitlementIds: Set<String>) {
        productEntitlements[productId] = entitlementIds
    }
    
    /// Update entitlements from a transaction
    mutating func update(from transaction: Transaction, mapping: [String: Set<String>]) {
        guard let entitlementIds = mapping[transaction.productID] else { return }
        
        let info = EntitlementInfo(
            productId: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            isActive: true,
            transactionId: transaction.id
        )
        
        for entitlementId in entitlementIds {
            activate(entitlementId, info: info)
        }
    }
}

// MARK: - EntitlementInfo

/// Detailed information about an entitlement
public struct EntitlementInfo: Equatable, Sendable, Codable {
    /// Product that granted this entitlement
    public let productId: String
    
    /// When the entitlement was granted
    public let purchaseDate: Date
    
    /// When the entitlement expires (nil if lifetime)
    public let expirationDate: Date?
    
    /// Whether currently active
    public let isActive: Bool
    
    /// Transaction ID that granted this entitlement
    public let transactionId: UInt64
    
    /// Whether this is a lifetime entitlement
    public var isLifetime: Bool {
        expirationDate == nil
    }
    
    /// Whether the entitlement has expired
    public var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }
    
    /// Days until expiration (nil if lifetime or expired)
    public var daysUntilExpiration: Int? {
        guard let expiration = expirationDate, !isExpired else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiration)
        return components.day
    }
}

// MARK: - EntitlementManager

/// Manages entitlements with automatic transaction sync
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class EntitlementManager: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Current entitlements
    public private(set) var currentEntitlements: Entitlements
    
    /// Product to entitlement mapping
    private var productMapping: [String: Set<String>] = [:]
    
    /// Configuration
    private let configuration: EntitlementConfiguration
    
    // MARK: - Initialization
    
    public init(configuration: EntitlementConfiguration = .default) {
        self.configuration = configuration
        self.currentEntitlements = Entitlements()
        
        // Load configured mappings
        loadMappings()
    }
    
    // MARK: - Configuration
    
    /// Configure product to entitlement mapping
    /// - Parameters:
    ///   - productId: The product identifier
    ///   - entitlementIds: Entitlements granted by this product
    public func mapProduct(_ productId: String, to entitlementIds: Set<String>) {
        productMapping[productId] = entitlementIds
        currentEntitlements.mapProduct(productId, to: entitlementIds)
    }
    
    /// Configure multiple mappings at once
    /// - Parameter mapping: Dictionary of product IDs to entitlement IDs
    public func configureMappings(_ mapping: [String: Set<String>]) {
        for (productId, entitlementIds) in mapping {
            mapProduct(productId, to: entitlementIds)
        }
    }
    
    /// Load mappings from a plist file
    /// - Parameter plistName: Name of the plist file
    public func loadMappings(from plistName: String) throws {
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let mapping = plist as? [String: [String]] else {
            throw EntitlementError.configurationError("Failed to load mappings from \(plistName).plist")
        }
        
        for (productId, entitlementIds) in mapping {
            mapProduct(productId, to: Set(entitlementIds))
        }
    }
    
    // MARK: - Entitlement Updates
    
    /// Update entitlements from a transaction
    /// - Parameter transaction: The verified transaction
    public func updateEntitlements(from transaction: Transaction) {
        currentEntitlements.update(from: transaction, mapping: productMapping)
    }
    
    /// Sync entitlements with current transactions
    public func syncEntitlements() async {
        var newEntitlements = Entitlements()
        newEntitlements.productEntitlements = productMapping
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            newEntitlements.update(from: transaction, mapping: productMapping)
        }
        
        currentEntitlements = newEntitlements
    }
    
    /// Check entitlement
    /// - Parameter entitlementId: The entitlement to check
    /// - Returns: Whether user is entitled
    public func isEntitled(to entitlementId: String) -> Bool {
        currentEntitlements.isEntitled(to: entitlementId)
    }
    
    // MARK: - Private Methods
    
    private func loadMappings() {
        // Load from configuration
        configureMappings(configuration.defaultMappings)
    }
}

// MARK: - Configuration

/// Entitlement manager configuration
public struct EntitlementConfiguration: Sendable {
    /// Default product to entitlement mappings
    public let defaultMappings: [String: Set<String>]
    
    /// Whether to automatically sync on app launch
    public let autoSync: Bool
    
    /// Default configuration
    public static let `default` = EntitlementConfiguration(
        defaultMappings: [:],
        autoSync: true
    )
    
    public init(defaultMappings: [String: Set<String>], autoSync: Bool = true) {
        self.defaultMappings = defaultMappings
        self.autoSync = autoSync
    }
}

// MARK: - Errors

public enum EntitlementError: LocalizedError {
    case configurationError(String)
    case syncFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Entitlement configuration error: \(message)"
        case .syncFailed(let message):
            return "Entitlement sync failed: \(message)"
        }
    }
}

// MARK: - Common Entitlement IDs

/// Common entitlement identifiers for convenience
public struct CommonEntitlements {
    /// Premium access entitlement
    public static let premium = "premium"
    
    /// Pro tier entitlement
    public static let pro = "pro"
    
    /// Remove ads entitlement
    public static let removeAds = "remove_ads"
    
    /// Unlimited access entitlement
    public static let unlimited = "unlimited"
    
    /// VIP access entitlement
    public static let vip = "vip"
}
