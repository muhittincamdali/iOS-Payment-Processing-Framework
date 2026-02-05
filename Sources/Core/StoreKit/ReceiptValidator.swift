// ReceiptValidator.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit
import CryptoKit

/// Enterprise-grade receipt validation with server-side and on-device support
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class ReceiptValidator: Sendable {
    
    // MARK: - Properties
    
    private let configuration: ReceiptValidationConfiguration
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(configuration: ReceiptValidationConfiguration = .default) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    // MARK: - Public Methods
    
    /// Validate app receipt
    /// - Returns: Validation result
    public func validate() async throws -> ReceiptValidationResult {
        let receiptData = try getReceiptData()
        
        if configuration.useServerValidation {
            return try await validateWithServer(receiptData: receiptData)
        } else {
            return try await validateLocally(receiptData: receiptData)
        }
    }
    
    /// Get receipt data as base64 string
    /// - Returns: Base64 encoded receipt
    public func getReceiptData() throws -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            throw ReceiptValidationError.noReceipt
        }
        
        guard FileManager.default.fileExists(atPath: receiptURL.path) else {
            throw ReceiptValidationError.noReceipt
        }
        
        let receiptData = try Data(contentsOf: receiptURL)
        return receiptData.base64EncodedString()
    }
    
    /// Validate receipt with App Store servers directly (not recommended for production)
    /// - Parameters:
    ///   - receiptData: Base64 encoded receipt
    ///   - sandbox: Use sandbox environment
    /// - Returns: App Store response
    public func validateWithAppStore(receiptData: String, sandbox: Bool = false) async throws -> AppStoreReceiptResponse {
        let url = sandbox
            ? URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
            : URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        
        let requestBody: [String: Any] = [
            "receipt-data": receiptData,
            "password": configuration.sharedSecret ?? "",
            "exclude-old-transactions": true
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ReceiptValidationError.serverError("Invalid response")
        }
        
        let appStoreResponse = try JSONDecoder().decode(AppStoreReceiptResponse.self, from: data)
        
        // Handle sandbox redirect
        if appStoreResponse.status == 21007 && !sandbox {
            return try await validateWithAppStore(receiptData: receiptData, sandbox: true)
        }
        
        return appStoreResponse
    }
    
    /// Validate a JWS (JSON Web Signature) transaction
    /// - Parameter jwsRepresentation: The JWS string
    /// - Returns: Decoded transaction data
    public func validateJWS(_ jwsRepresentation: String) throws -> JWSTransactionInfo {
        let parts = jwsRepresentation.split(separator: ".")
        guard parts.count == 3 else {
            throw ReceiptValidationError.invalidJWS("Invalid JWS format")
        }
        
        // Decode payload (second part)
        let payload = String(parts[1])
        guard let payloadData = Data(base64URLDecoded: payload) else {
            throw ReceiptValidationError.invalidJWS("Failed to decode payload")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        return try decoder.decode(JWSTransactionInfo.self, from: payloadData)
    }
    
    // MARK: - Private Methods
    
    private func validateWithServer(receiptData: String) async throws -> ReceiptValidationResult {
        guard let serverURL = configuration.serverURL else {
            throw ReceiptValidationError.configurationError("Server URL not configured")
        }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ReceiptValidationRequest(
            receiptData: receiptData,
            appBundleId: Bundle.main.bundleIdentifier ?? "",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReceiptValidationError.serverError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(ReceiptValidationResult.self, from: data)
        case 401:
            throw ReceiptValidationError.authenticationFailed
        case 400..<500:
            throw ReceiptValidationError.invalidReceipt
        default:
            throw ReceiptValidationError.serverError("Status: \(httpResponse.statusCode)")
        }
    }
    
    private func validateLocally(receiptData: String) async throws -> ReceiptValidationResult {
        // On-device validation using Transaction API
        var purchases: [ValidatedPurchase] = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            let purchase = ValidatedPurchase(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                purchaseDate: transaction.purchaseDate,
                expiresDate: transaction.expirationDate,
                isTrialPeriod: transaction.offerType == .introductory,
                isInIntroOfferPeriod: transaction.offerType == .introductory,
                productType: mapProductType(transaction.productType),
                environment: transaction.environment == .sandbox ? "Sandbox" : "Production"
            )
            
            purchases.append(purchase)
        }
        
        return ReceiptValidationResult(
            isValid: true,
            environment: await determineEnvironment(),
            purchases: purchases,
            latestReceipt: receiptData
        )
    }
    
    private func mapProductType(_ type: Product.ProductType) -> String {
        switch type {
        case .consumable: return "consumable"
        case .nonConsumable: return "non_consumable"
        case .autoRenewable: return "auto_renewable"
        case .nonRenewable: return "non_renewing"
        @unknown default: return "unknown"
        }
    }
    
    private func determineEnvironment() async -> String {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                return transaction.environment == .sandbox ? "Sandbox" : "Production"
            }
        }
        return "Unknown"
    }
}

// MARK: - Configuration

/// Receipt validation configuration
public struct ReceiptValidationConfiguration: Sendable {
    /// Your server URL for receipt validation
    public let serverURL: URL?
    
    /// API key for server authentication
    public let apiKey: String?
    
    /// App-specific shared secret (from App Store Connect)
    public let sharedSecret: String?
    
    /// Whether to use server-side validation
    public let useServerValidation: Bool
    
    /// Request timeout interval
    public let timeoutInterval: TimeInterval
    
    /// Default configuration (local validation)
    public static let `default` = ReceiptValidationConfiguration(
        serverURL: nil,
        apiKey: nil,
        sharedSecret: nil,
        useServerValidation: false,
        timeoutInterval: 30
    )
    
    public init(
        serverURL: URL? = nil,
        apiKey: String? = nil,
        sharedSecret: String? = nil,
        useServerValidation: Bool = false,
        timeoutInterval: TimeInterval = 30
    ) {
        self.serverURL = serverURL
        self.apiKey = apiKey
        self.sharedSecret = sharedSecret
        self.useServerValidation = useServerValidation
        self.timeoutInterval = timeoutInterval
    }
}

// MARK: - Models

/// Receipt validation request body
public struct ReceiptValidationRequest: Codable, Sendable {
    public let receiptData: String
    public let appBundleId: String
    public let appVersion: String
}

/// Receipt validation result
public struct ReceiptValidationResult: Codable, Sendable {
    /// Whether the receipt is valid
    public let isValid: Bool
    
    /// Environment (Sandbox or Production)
    public let environment: String
    
    /// Validated purchases
    public let purchases: [ValidatedPurchase]
    
    /// Latest receipt data
    public let latestReceipt: String?
}

/// Validated purchase information
public struct ValidatedPurchase: Codable, Sendable {
    public let productId: String
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDate: Date
    public let expiresDate: Date?
    public let isTrialPeriod: Bool
    public let isInIntroOfferPeriod: Bool
    public let productType: String
    public let environment: String
}

/// App Store receipt response
public struct AppStoreReceiptResponse: Codable, Sendable {
    public let status: Int
    public let environment: String?
    public let receipt: AppStoreReceipt?
    public let latestReceiptInfo: [AppStoreLatestReceipt]?
    public let pendingRenewalInfo: [AppStorePendingRenewal]?
    
    private enum CodingKeys: String, CodingKey {
        case status
        case environment
        case receipt
        case latestReceiptInfo = "latest_receipt_info"
        case pendingRenewalInfo = "pending_renewal_info"
    }
}

public struct AppStoreReceipt: Codable, Sendable {
    public let bundleId: String
    public let applicationVersion: String
    public let originalApplicationVersion: String
    public let receiptCreationDate: String
    public let inApp: [AppStoreInAppPurchase]?
    
    private enum CodingKeys: String, CodingKey {
        case bundleId = "bundle_id"
        case applicationVersion = "application_version"
        case originalApplicationVersion = "original_application_version"
        case receiptCreationDate = "receipt_creation_date"
        case inApp = "in_app"
    }
}

public struct AppStoreInAppPurchase: Codable, Sendable {
    public let productId: String
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDateMs: String
    public let expiresDateMs: String?
    
    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDateMs = "purchase_date_ms"
        case expiresDateMs = "expires_date_ms"
    }
}

public struct AppStoreLatestReceipt: Codable, Sendable {
    public let productId: String
    public let transactionId: String
    public let expiresDateMs: String?
    public let isTrialPeriod: String?
    
    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case transactionId = "transaction_id"
        case expiresDateMs = "expires_date_ms"
        case isTrialPeriod = "is_trial_period"
    }
}

public struct AppStorePendingRenewal: Codable, Sendable {
    public let productId: String
    public let autoRenewProductId: String
    public let autoRenewStatus: String
    
    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case autoRenewProductId = "auto_renew_product_id"
        case autoRenewStatus = "auto_renew_status"
    }
}

/// JWS Transaction info (decoded from StoreKit 2 JWS)
public struct JWSTransactionInfo: Codable, Sendable {
    public let transactionId: String
    public let originalTransactionId: String
    public let bundleId: String
    public let productId: String
    public let purchaseDate: Date
    public let expiresDate: Date?
    public let type: String
    public let environment: String
}

// MARK: - Errors

public enum ReceiptValidationError: LocalizedError {
    case noReceipt
    case invalidReceipt
    case serverError(String)
    case configurationError(String)
    case authenticationFailed
    case invalidJWS(String)
    
    public var errorDescription: String? {
        switch self {
        case .noReceipt:
            return "No receipt available on this device"
        case .invalidReceipt:
            return "The receipt is invalid"
        case .serverError(let message):
            return "Server error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .authenticationFailed:
            return "Server authentication failed"
        case .invalidJWS(let message):
            return "Invalid JWS: \(message)"
        }
    }
}

// MARK: - Base64URL Extension

extension Data {
    init?(base64URLDecoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        self.init(base64Encoded: base64)
    }
}
