// PromotionalOffers.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit
import CryptoKit

/// Promotional offer signature for StoreKit 2
public struct PromotionalOfferSignature: Sendable {
    /// Key identifier from App Store Connect
    public let keyId: String
    
    /// Unique nonce for this offer
    public let nonce: UUID
    
    /// ECDSA signature
    public let signature: Data
    
    /// Timestamp in milliseconds
    public let timestamp: Int
    
    public init(keyId: String, nonce: UUID, signature: Data, timestamp: Int) {
        self.keyId = keyId
        self.nonce = nonce
        self.signature = signature
        self.timestamp = timestamp
    }
}

/// Generates promotional offer signatures for subscription offers
/// Note: Signature generation should be done server-side in production
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class PromotionalOfferManager: Sendable {
    
    // MARK: - Properties
    
    private let serverURL: URL?
    private let apiKey: String?
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Initialize with server configuration
    /// - Parameters:
    ///   - serverURL: Your server URL for signature generation
    ///   - apiKey: API key for authentication
    public init(serverURL: URL?, apiKey: String? = nil) {
        self.serverURL = serverURL
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    // MARK: - Public Methods
    
    /// Request a promotional offer signature from your server
    /// - Parameters:
    ///   - productId: The subscription product ID
    ///   - offerId: The promotional offer ID
    ///   - appBundleId: Your app's bundle ID
    ///   - applicationUsername: Optional user identifier
    /// - Returns: Signature for the promotional offer
    public func requestSignature(
        for productId: String,
        offerId: String,
        appBundleId: String,
        applicationUsername: String?
    ) async throws -> PromotionalOfferSignature {
        guard let serverURL = serverURL else {
            throw PromotionalOfferError.configurationError("Server URL not configured")
        }
        
        let nonce = UUID()
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        
        let requestBody = SignatureRequest(
            productId: productId,
            offerId: offerId,
            bundleId: appBundleId,
            nonce: nonce.uuidString,
            timestamp: timestamp,
            applicationUsername: applicationUsername
        )
        
        var request = URLRequest(url: serverURL.appendingPathComponent("/api/promotional-offer/sign"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PromotionalOfferError.signatureRequestFailed("Invalid server response")
        }
        
        let signatureResponse = try JSONDecoder().decode(SignatureResponse.self, from: data)
        
        guard let signatureData = Data(base64Encoded: signatureResponse.signature) else {
            throw PromotionalOfferError.invalidSignature("Failed to decode signature")
        }
        
        return PromotionalOfferSignature(
            keyId: signatureResponse.keyId,
            nonce: nonce,
            signature: signatureData,
            timestamp: timestamp
        )
    }
    
    /// Get available promotional offers for a product
    /// - Parameter product: The subscription product
    /// - Returns: Array of promotional offers
    public func getPromotionalOffers(for product: Product) -> [OfferDetails] {
        guard let subscription = product.subscription else { return [] }
        
        return subscription.promotionalOffers.map { offer in
            OfferDetails(
                id: offer.id ?? "",
                type: mapOfferType(offer.type),
                period: mapPeriod(offer.period),
                periodCount: offer.periodCount,
                paymentMode: mapPaymentMode(offer.paymentMode),
                displayPrice: offer.displayPrice
            )
        }
    }
    
    /// Get introductory offer details for a product
    /// - Parameter product: The subscription product
    /// - Returns: Introductory offer details if available
    public func getIntroductoryOffer(for product: Product) -> OfferDetails? {
        guard let subscription = product.subscription,
              let intro = subscription.introductoryOffer else {
            return nil
        }
        
        return OfferDetails(
            id: intro.id ?? "intro",
            type: mapOfferType(intro.type),
            period: mapPeriod(intro.period),
            periodCount: intro.periodCount,
            paymentMode: mapPaymentMode(intro.paymentMode),
            displayPrice: intro.displayPrice
        )
    }
    
    /// Check eligibility for introductory offer
    /// - Parameter product: The subscription product
    /// - Returns: True if eligible for intro offer
    public func isEligibleForIntroductoryOffer(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }
    
    // MARK: - Private Methods
    
    private func mapOfferType(_ type: Product.SubscriptionOffer.OfferType) -> OfferType {
        switch type {
        case .introductory: return .introductory
        case .promotional: return .promotional
        case .code: return .offerCode
        @unknown default: return .promotional
        }
    }
    
    private func mapPeriod(_ period: Product.SubscriptionPeriod) -> OfferPeriod {
        switch period.unit {
        case .day: return OfferPeriod(value: period.value, unit: .day)
        case .week: return OfferPeriod(value: period.value, unit: .week)
        case .month: return OfferPeriod(value: period.value, unit: .month)
        case .year: return OfferPeriod(value: period.value, unit: .year)
        @unknown default: return OfferPeriod(value: period.value, unit: .month)
        }
    }
    
    private func mapPaymentMode(_ mode: Product.SubscriptionOffer.PaymentMode) -> PaymentMode {
        switch mode {
        case .freeTrial: return .freeTrial
        case .payAsYouGo: return .payAsYouGo
        case .payUpFront: return .payUpFront
        @unknown default: return .payAsYouGo
        }
    }
}

// MARK: - Supporting Types

/// Offer details for display
public struct OfferDetails: Identifiable, Sendable {
    public let id: String
    public let type: OfferType
    public let period: OfferPeriod
    public let periodCount: Int
    public let paymentMode: PaymentMode
    public let displayPrice: String
    
    /// Human-readable offer description
    public var description: String {
        switch paymentMode {
        case .freeTrial:
            return "\(periodCount) \(period.unit.pluralized(periodCount)) free trial"
        case .payAsYouGo:
            return "\(displayPrice)/\(period.unit.singular) for \(periodCount) \(period.unit.pluralized(periodCount))"
        case .payUpFront:
            return "\(displayPrice) for \(periodCount) \(period.unit.pluralized(periodCount))"
        }
    }
}

/// Offer type
public enum OfferType: String, Sendable {
    case introductory
    case promotional
    case offerCode
}

/// Offer period
public struct OfferPeriod: Sendable {
    public let value: Int
    public let unit: PeriodUnit
}

/// Period unit
public enum PeriodUnit: String, Sendable {
    case day
    case week
    case month
    case year
    
    var singular: String { rawValue }
    
    func pluralized(_ count: Int) -> String {
        count == 1 ? rawValue : rawValue + "s"
    }
}

/// Payment mode
public enum PaymentMode: String, Sendable {
    case freeTrial
    case payAsYouGo
    case payUpFront
}

// MARK: - Request/Response Models

struct SignatureRequest: Codable {
    let productId: String
    let offerId: String
    let bundleId: String
    let nonce: String
    let timestamp: Int
    let applicationUsername: String?
}

struct SignatureResponse: Codable {
    let keyId: String
    let signature: String
}

// MARK: - Errors

public enum PromotionalOfferError: LocalizedError {
    case configurationError(String)
    case signatureRequestFailed(String)
    case invalidSignature(String)
    case offerNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .signatureRequestFailed(let message):
            return "Signature request failed: \(message)"
        case .invalidSignature(let message):
            return "Invalid signature: \(message)"
        case .offerNotFound(let offerId):
            return "Offer not found: \(offerId)"
        }
    }
}
