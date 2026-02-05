// StoreKitError.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit

/// Comprehensive error types for StoreKit operations
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public enum StoreKitError: LocalizedError, Equatable {
    
    // MARK: - Configuration Errors
    
    /// Configuration error with details
    case configurationError(String)
    
    // MARK: - Product Errors
    
    /// Failed to fetch products from App Store
    case productFetchFailed(String)
    
    /// Product not found
    case productNotFound(String)
    
    /// Invalid product configuration
    case invalidProduct(String)
    
    // MARK: - Purchase Errors
    
    /// Purchase was cancelled by user
    case purchaseCancelled
    
    /// Purchase is pending approval (e.g., Ask to Buy)
    case purchasePending
    
    /// Purchase failed
    case purchaseFailed(String)
    
    /// Unknown purchase result
    case unknownPurchaseResult
    
    /// There's already a pending transaction for this product
    case pendingTransaction(Transaction)
    
    /// User is not allowed to make purchases
    case purchaseNotAllowed
    
    // MARK: - Verification Errors
    
    /// Transaction verification failed
    case verificationFailed(String)
    
    /// Receipt validation failed
    case receiptValidationFailed(String)
    
    /// No receipt available
    case noReceipt
    
    // MARK: - Subscription Errors
    
    /// Subscription status check failed
    case subscriptionStatusFailed(String)
    
    /// Subscription upgrade/downgrade failed
    case subscriptionChangeFailed(String)
    
    // MARK: - Restore Errors
    
    /// Restore purchases failed
    case restoreFailed(String)
    
    /// No purchases to restore
    case noPurchasesToRestore
    
    // MARK: - Refund Errors
    
    /// Refund request failed
    case refundRequestFailed(String)
    
    // MARK: - Network Errors
    
    /// Network error
    case networkError(String)
    
    /// Server error
    case serverError(Int, String)
    
    // MARK: - General Errors
    
    /// Unknown error
    case unknown(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
            
        case .productFetchFailed(let message):
            return "Failed to fetch products: \(message)"
            
        case .productNotFound(let productId):
            return "Product not found: \(productId)"
            
        case .invalidProduct(let message):
            return "Invalid product: \(message)"
            
        case .purchaseCancelled:
            return "Purchase was cancelled"
            
        case .purchasePending:
            return "Purchase is pending approval"
            
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
            
        case .unknownPurchaseResult:
            return "Unknown purchase result"
            
        case .pendingTransaction:
            return "There's already a pending transaction for this product"
            
        case .purchaseNotAllowed:
            return "User is not allowed to make purchases"
            
        case .verificationFailed(let message):
            return "Transaction verification failed: \(message)"
            
        case .receiptValidationFailed(let message):
            return "Receipt validation failed: \(message)"
            
        case .noReceipt:
            return "No receipt available"
            
        case .subscriptionStatusFailed(let message):
            return "Failed to get subscription status: \(message)"
            
        case .subscriptionChangeFailed(let message):
            return "Subscription change failed: \(message)"
            
        case .restoreFailed(let message):
            return "Failed to restore purchases: \(message)"
            
        case .noPurchasesToRestore:
            return "No purchases to restore"
            
        case .refundRequestFailed(let message):
            return "Refund request failed: \(message)"
            
        case .networkError(let message):
            return "Network error: \(message)"
            
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
            
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .purchaseCancelled:
            return "The user decided not to complete the purchase."
            
        case .purchasePending:
            return "The purchase requires approval from a family organizer or guardian."
            
        case .purchaseNotAllowed:
            return "Purchases may be restricted on this device."
            
        case .verificationFailed:
            return "The transaction could not be verified as authentic."
            
        case .noReceipt:
            return "The app receipt is not available on this device."
            
        case .noPurchasesToRestore:
            return "There are no previous purchases associated with this Apple ID."
            
        default:
            return nil
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .purchaseCancelled:
            return "Try the purchase again when ready."
            
        case .purchasePending:
            return "Ask the family organizer to approve the purchase."
            
        case .purchaseNotAllowed:
            return "Check device restrictions in Settings."
            
        case .networkError:
            return "Check your internet connection and try again."
            
        case .restoreFailed, .noPurchasesToRestore:
            return "Make sure you're signed in with the correct Apple ID."
            
        default:
            return "Please try again later."
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: StoreKitError, rhs: StoreKitError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
    
    // MARK: - Error Code
    
    /// Numeric error code for analytics/logging
    public var code: Int {
        switch self {
        case .configurationError: return 1001
        case .productFetchFailed: return 1002
        case .productNotFound: return 1003
        case .invalidProduct: return 1004
        case .purchaseCancelled: return 2001
        case .purchasePending: return 2002
        case .purchaseFailed: return 2003
        case .unknownPurchaseResult: return 2004
        case .pendingTransaction: return 2005
        case .purchaseNotAllowed: return 2006
        case .verificationFailed: return 3001
        case .receiptValidationFailed: return 3002
        case .noReceipt: return 3003
        case .subscriptionStatusFailed: return 4001
        case .subscriptionChangeFailed: return 4002
        case .restoreFailed: return 5001
        case .noPurchasesToRestore: return 5002
        case .refundRequestFailed: return 6001
        case .networkError: return 7001
        case .serverError: return 7002
        case .unknown: return 9999
        }
    }
    
    // MARK: - Is Retryable
    
    /// Whether this error might succeed if retried
    public var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .productFetchFailed, .restoreFailed:
            return true
        default:
            return false
        }
    }
    
    /// Whether this error was caused by user action
    public var isUserInitiated: Bool {
        switch self {
        case .purchaseCancelled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Mapping

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StoreKitError {
    
    /// Create StoreKitError from a StoreKit error
    public static func from(_ error: Error) -> StoreKitError {
        if let storeKitError = error as? StoreKitError {
            return storeKitError
        }
        
        if let skError = error as? StoreKit.StoreKitError {
            switch skError {
            case .userCancelled:
                return .purchaseCancelled
            case .notAvailableInStorefront:
                return .productNotFound("Not available in current storefront")
            case .networkError(let underlying):
                return .networkError(underlying.localizedDescription)
            case .systemError(let underlying):
                return .unknown(underlying.localizedDescription)
            case .notEntitled:
                return .purchaseNotAllowed
            case .unknown:
                return .unknown("Unknown StoreKit error")
            @unknown default:
                return .unknown("Unknown StoreKit error")
            }
        }
        
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .invalidQuantity:
                return .purchaseFailed("Invalid quantity")
            case .productUnavailable:
                return .productNotFound("Product unavailable")
            case .purchaseNotAllowed:
                return .purchaseNotAllowed
            case .ineligibleForOffer:
                return .purchaseFailed("Not eligible for this offer")
            case .invalidOfferIdentifier:
                return .purchaseFailed("Invalid offer identifier")
            case .invalidOfferPrice:
                return .purchaseFailed("Invalid offer price")
            case .invalidOfferSignature:
                return .purchaseFailed("Invalid offer signature")
            case .missingOfferParameters:
                return .purchaseFailed("Missing offer parameters")
            @unknown default:
                return .purchaseFailed("Unknown purchase error")
            }
        }
        
        return .unknown(error.localizedDescription)
    }
}
