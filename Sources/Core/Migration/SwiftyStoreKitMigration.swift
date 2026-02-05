// SwiftyStoreKitMigration.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import Foundation
import StoreKit

/// Migration helper for transitioning from SwiftyStoreKit
/// Provides equivalent APIs for easy migration
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class SwiftyStoreKitMigration {
    
    // MARK: - Singleton
    
    /// Shared instance (like SwiftyStoreKit's static methods)
    public static let shared = SwiftyStoreKitMigration()
    
    // MARK: - Properties
    
    private let storeKit = StoreKitManager.shared
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - SwiftyStoreKit API Equivalents
    
    // SwiftyStoreKit.retrieveProductsInfo(...)
    /// Equivalent to SwiftyStoreKit's retrieveProductsInfo
    /// - Parameters:
    ///   - productIds: Set of product identifiers
    ///   - completion: Completion handler with result
    public func retrieveProductsInfo(
        _ productIds: Set<String>,
        completion: @escaping (RetrieveResults) -> Void
    ) {
        Task {
            do {
                let products = try await storeKit.fetchProducts(ids: productIds)
                let retrieved = products.map { SKProduct(from: $0) }
                let invalidIds = productIds.subtracting(Set(products.map(\.id)))
                
                await MainActor.run {
                    completion(RetrieveResults(
                        retrievedProducts: Set(retrieved),
                        invalidProductIDs: invalidIds,
                        error: nil
                    ))
                }
            } catch {
                await MainActor.run {
                    completion(RetrieveResults(
                        retrievedProducts: [],
                        invalidProductIDs: productIds,
                        error: error
                    ))
                }
            }
        }
    }
    
    // SwiftyStoreKit.purchaseProduct(...)
    /// Equivalent to SwiftyStoreKit's purchaseProduct
    /// - Parameters:
    ///   - productId: Product identifier
    ///   - quantity: Quantity (ignored for subscriptions)
    ///   - atomically: Whether to finish immediately
    ///   - completion: Completion handler with result
    public func purchaseProduct(
        _ productId: String,
        quantity: Int = 1,
        atomically: Bool = true,
        completion: @escaping (PurchaseResult) -> Void
    ) {
        Task {
            do {
                let transaction = try await storeKit.purchase(productId: productId)
                
                await MainActor.run {
                    completion(.success(purchase: PurchaseDetails(
                        productId: transaction.productID,
                        quantity: 1,
                        transaction: transaction,
                        needsFinishTransaction: !atomically
                    )))
                }
            } catch let error as StoreKitError {
                await MainActor.run {
                    switch error {
                    case .purchaseCancelled:
                        completion(.error(error: .paymentCancelled))
                    default:
                        completion(.error(error: .unknown))
                    }
                }
            } catch {
                await MainActor.run {
                    completion(.error(error: .unknown))
                }
            }
        }
    }
    
    // SwiftyStoreKit.restorePurchases(...)
    /// Equivalent to SwiftyStoreKit's restorePurchases
    /// - Parameters:
    ///   - atomically: Whether to finish immediately
    ///   - completion: Completion handler with result
    public func restorePurchases(
        atomically: Bool = true,
        completion: @escaping (RestoreResults) -> Void
    ) {
        Task {
            do {
                let count = try await storeKit.restorePurchases()
                let transactions = await storeKit.getCurrentEntitlements()
                
                let restoredPurchases = transactions.map { transaction in
                    Purchase(
                        productId: transaction.productID,
                        quantity: 1,
                        transaction: transaction,
                        needsFinishTransaction: !atomically
                    )
                }
                
                await MainActor.run {
                    completion(RestoreResults(
                        restoredPurchases: restoredPurchases,
                        restoreFailedPurchases: []
                    ))
                }
            } catch {
                await MainActor.run {
                    completion(RestoreResults(
                        restoredPurchases: [],
                        restoreFailedPurchases: [(SKError(.unknown), nil)]
                    ))
                }
            }
        }
    }
    
    // SwiftyStoreKit.verifyReceipt(...)
    /// Equivalent to SwiftyStoreKit's verifyReceipt
    /// - Parameters:
    ///   - using: Receipt validator type
    ///   - forceRefresh: Force refresh receipt
    ///   - completion: Completion handler with result
    public func verifyReceipt(
        using validator: ReceiptValidatorType,
        forceRefresh: Bool = false,
        completion: @escaping (VerifyReceiptResult) -> Void
    ) {
        Task {
            do {
                let result = try await storeKit.validateReceipt()
                
                await MainActor.run {
                    completion(.success(receipt: [
                        "status": 0,
                        "environment": result.environment,
                        "receipt": [
                            "bundle_id": Bundle.main.bundleIdentifier ?? "",
                            "in_app": result.purchases.map { purchase in
                                [
                                    "product_id": purchase.productId,
                                    "transaction_id": purchase.transactionId,
                                    "original_transaction_id": purchase.originalTransactionId,
                                    "purchase_date_ms": String(Int(purchase.purchaseDate.timeIntervalSince1970 * 1000)),
                                    "expires_date_ms": purchase.expiresDate.map { String(Int($0.timeIntervalSince1970 * 1000)) }
                                ]
                            }
                        ]
                    ]))
                }
            } catch {
                await MainActor.run {
                    completion(.error(error: .noReceiptData))
                }
            }
        }
    }
    
    // SwiftyStoreKit.verifySubscription(...)
    /// Equivalent to SwiftyStoreKit's verifySubscription
    /// - Parameters:
    ///   - ofType: Subscription type
    ///   - productId: Product identifier
    ///   - inReceipt: Receipt data
    ///   - validUntil: Validation date
    /// - Returns: Verification result
    public func verifySubscription(
        ofType type: SubscriptionType,
        productId: String,
        inReceipt receipt: [String: Any],
        validUntil date: Date = Date()
    ) -> VerifySubscriptionResult {
        // Parse receipt and check subscription status
        guard let receiptInfo = receipt["receipt"] as? [String: Any],
              let inAppPurchases = receiptInfo["in_app"] as? [[String: Any]] else {
            return .notPurchased
        }
        
        // Find matching purchase
        let matchingPurchases = inAppPurchases.filter { $0["product_id"] as? String == productId }
        
        guard !matchingPurchases.isEmpty else {
            return .notPurchased
        }
        
        // Check expiration
        for purchase in matchingPurchases {
            if let expiresMs = purchase["expires_date_ms"] as? String,
               let expiresTimestamp = Double(expiresMs) {
                let expiresDate = Date(timeIntervalSince1970: expiresTimestamp / 1000)
                
                if expiresDate > date {
                    let items = matchingPurchases.compactMap { dict -> ReceiptItem? in
                        guard let productId = dict["product_id"] as? String,
                              let transactionId = dict["transaction_id"] as? String,
                              let purchaseMs = dict["purchase_date_ms"] as? String,
                              let purchaseTimestamp = Double(purchaseMs) else {
                            return nil
                        }
                        
                        return ReceiptItem(
                            productId: productId,
                            quantity: 1,
                            transactionId: transactionId,
                            originalTransactionId: dict["original_transaction_id"] as? String ?? transactionId,
                            purchaseDate: Date(timeIntervalSince1970: purchaseTimestamp / 1000),
                            subscriptionExpirationDate: expiresDate,
                            cancellationDate: nil,
                            isTrialPeriod: dict["is_trial_period"] as? String == "true",
                            isInIntroOfferPeriod: dict["is_in_intro_offer_period"] as? String == "true"
                        )
                    }
                    
                    return .purchased(expiryDate: expiresDate, items: items)
                }
            }
        }
        
        // Check for non-expiring (lifetime)
        if matchingPurchases.first?["expires_date_ms"] == nil {
            let items = matchingPurchases.compactMap { dict -> ReceiptItem? in
                guard let productId = dict["product_id"] as? String,
                      let transactionId = dict["transaction_id"] as? String,
                      let purchaseMs = dict["purchase_date_ms"] as? String,
                      let purchaseTimestamp = Double(purchaseMs) else {
                    return nil
                }
                
                return ReceiptItem(
                    productId: productId,
                    quantity: 1,
                    transactionId: transactionId,
                    originalTransactionId: dict["original_transaction_id"] as? String ?? transactionId,
                    purchaseDate: Date(timeIntervalSince1970: purchaseTimestamp / 1000),
                    subscriptionExpirationDate: nil,
                    cancellationDate: nil,
                    isTrialPeriod: false,
                    isInIntroOfferPeriod: false
                )
            }
            
            return .purchased(expiryDate: nil, items: items)
        }
        
        return .expired(expiryDate: date, items: [])
    }
    
    // SwiftyStoreKit.completeTransactions(...)
    /// Equivalent to SwiftyStoreKit's completeTransactions
    /// Handles unfinished transactions on app launch
    public func completeTransactions(
        atomically: Bool = true,
        completion: @escaping ([Purchase]) -> Void
    ) {
        Task {
            var completedPurchases: [Purchase] = []
            
            for await result in Transaction.unfinished {
                if case .verified(let transaction) = result {
                    if atomically {
                        await transaction.finish()
                    }
                    
                    completedPurchases.append(Purchase(
                        productId: transaction.productID,
                        quantity: 1,
                        transaction: transaction,
                        needsFinishTransaction: !atomically
                    ))
                }
            }
            
            await MainActor.run {
                completion(completedPurchases)
            }
        }
    }
}

// MARK: - SwiftyStoreKit Equivalent Types

/// Retrieve results
public struct RetrieveResults: Sendable {
    public let retrievedProducts: Set<SKProduct>
    public let invalidProductIDs: Set<String>
    public let error: Error?
}

/// SK Product equivalent
public struct SKProduct: Hashable, Sendable {
    public let productIdentifier: String
    public let localizedTitle: String
    public let localizedDescription: String
    public let price: Decimal
    public let priceLocale: Locale
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    init(from product: Product) {
        self.productIdentifier = product.id
        self.localizedTitle = product.displayName
        self.localizedDescription = product.description
        self.price = product.price
        self.priceLocale = .current
    }
}

/// Purchase result
public enum PurchaseResult {
    case success(purchase: PurchaseDetails)
    case error(error: SKErrorCode)
    
    public enum SKErrorCode {
        case unknown
        case paymentCancelled
        case paymentInvalid
        case paymentNotAllowed
        case storeProductNotAvailable
    }
}

/// Purchase details
public struct PurchaseDetails: @unchecked Sendable {
    public let productId: String
    public let quantity: Int
    public let transaction: Transaction
    public let needsFinishTransaction: Bool
}

/// Restore results
public struct RestoreResults: @unchecked Sendable {
    public let restoredPurchases: [Purchase]
    public let restoreFailedPurchases: [(SKError, String?)]
}

/// Purchase
public struct Purchase: @unchecked Sendable {
    public let productId: String
    public let quantity: Int
    public let transaction: Transaction
    public let needsFinishTransaction: Bool
}

/// Verify receipt result
public enum VerifyReceiptResult {
    case success(receipt: [String: Any])
    case error(error: ReceiptError)
    
    public enum ReceiptError {
        case noReceiptData
        case networkError
        case jsonDecodeError
        case receiptInvalid
    }
}

/// Subscription type
public enum SubscriptionType {
    case autoRenewable
    case nonRenewing
}

/// Verify subscription result
public enum VerifySubscriptionResult {
    case purchased(expiryDate: Date?, items: [ReceiptItem])
    case expired(expiryDate: Date, items: [ReceiptItem])
    case notPurchased
}

/// Receipt item
public struct ReceiptItem: Sendable {
    public let productId: String
    public let quantity: Int
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDate: Date
    public let subscriptionExpirationDate: Date?
    public let cancellationDate: Date?
    public let isTrialPeriod: Bool
    public let isInIntroOfferPeriod: Bool
}

/// Receipt validator type
public enum ReceiptValidatorType {
    case apple(sharedSecret: String)
    case server(url: URL)
}

/// SKError placeholder
public struct SKError: Error {
    public let code: Code
    
    public enum Code {
        case unknown
        case paymentCancelled
        case paymentInvalid
    }
    
    public init(_ code: Code) {
        self.code = code
    }
}
