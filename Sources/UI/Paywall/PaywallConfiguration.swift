// PaywallConfiguration.swift
// iOS-Payment-Processing-Framework
//
// Created by Muhittin Camdali
// Copyright © 2025 Muhittin Camdali. All rights reserved.

import SwiftUI

/// Comprehensive paywall customization configuration
@available(iOS 15.0, macOS 12.0, *)
public struct PaywallConfiguration: Sendable {
    
    // MARK: - Text Content
    
    /// Main title text
    public let title: String
    
    /// Subtitle text (optional)
    public let subtitle: String?
    
    /// Purchase button text
    public let purchaseButtonText: String
    
    /// Restore purchases text
    public let restoreButtonText: String
    
    // MARK: - Visual
    
    /// Header icon (SF Symbol name)
    public let headerIcon: String?
    
    /// Primary accent color
    public let accentColor: Color
    
    /// Background color
    public let backgroundColor: Color
    
    /// Card background color
    public let cardBackgroundColor: Color
    
    /// Primary text color
    public let textColor: Color
    
    /// Secondary text color
    public let secondaryTextColor: Color
    
    // MARK: - Features
    
    /// Feature items to display
    public let features: [Feature]
    
    // MARK: - URLs
    
    /// Privacy policy URL
    public let privacyPolicyURL: URL?
    
    /// Terms of service URL
    public let termsOfServiceURL: URL?
    
    // MARK: - Behavior
    
    /// Show close button
    public let showCloseButton: Bool
    
    /// Dismiss on purchase
    public let dismissOnPurchase: Bool
    
    /// Show restore button
    public let showRestoreButton: Bool
    
    // MARK: - Templates
    
    /// Default configuration
    public static let `default` = PaywallConfiguration(
        title: "Unlock Premium",
        subtitle: "Get access to all features",
        purchaseButtonText: "Continue",
        restoreButtonText: "Restore Purchases",
        headerIcon: "crown.fill",
        accentColor: .blue,
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        textColor: Color(.label),
        secondaryTextColor: Color(.secondaryLabel),
        features: [],
        privacyPolicyURL: nil,
        termsOfServiceURL: nil,
        showCloseButton: true,
        dismissOnPurchase: true,
        showRestoreButton: true
    )
    
    /// Dark theme configuration
    public static let dark = PaywallConfiguration(
        title: "Unlock Premium",
        subtitle: "Get access to all features",
        purchaseButtonText: "Continue",
        restoreButtonText: "Restore Purchases",
        headerIcon: "crown.fill",
        accentColor: .purple,
        backgroundColor: Color(.black),
        cardBackgroundColor: Color(.systemGray6),
        textColor: .white,
        secondaryTextColor: Color(.lightGray),
        features: [],
        privacyPolicyURL: nil,
        termsOfServiceURL: nil,
        showCloseButton: true,
        dismissOnPurchase: true,
        showRestoreButton: true
    )
    
    /// Minimal configuration
    public static let minimal = PaywallConfiguration(
        title: "Go Premium",
        subtitle: nil,
        purchaseButtonText: "Subscribe",
        restoreButtonText: "Restore",
        headerIcon: nil,
        accentColor: .accentColor,
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        textColor: Color(.label),
        secondaryTextColor: Color(.secondaryLabel),
        features: [],
        privacyPolicyURL: nil,
        termsOfServiceURL: nil,
        showCloseButton: true,
        dismissOnPurchase: true,
        showRestoreButton: true
    )
    
    // MARK: - Initialization
    
    public init(
        title: String,
        subtitle: String? = nil,
        purchaseButtonText: String = "Continue",
        restoreButtonText: String = "Restore Purchases",
        headerIcon: String? = "crown.fill",
        accentColor: Color = .blue,
        backgroundColor: Color = Color(.systemBackground),
        cardBackgroundColor: Color = Color(.secondarySystemBackground),
        textColor: Color = Color(.label),
        secondaryTextColor: Color = Color(.secondaryLabel),
        features: [Feature] = [],
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil,
        showCloseButton: Bool = true,
        dismissOnPurchase: Bool = true,
        showRestoreButton: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.purchaseButtonText = purchaseButtonText
        self.restoreButtonText = restoreButtonText
        self.headerIcon = headerIcon
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.cardBackgroundColor = cardBackgroundColor
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.features = features
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
        self.showCloseButton = showCloseButton
        self.dismissOnPurchase = dismissOnPurchase
        self.showRestoreButton = showRestoreButton
    }
    
    // MARK: - Builder
    
    /// Create a builder for customization
    public static func builder() -> Builder {
        Builder()
    }
    
    /// Configuration builder
    public final class Builder: @unchecked Sendable {
        private var title: String = "Unlock Premium"
        private var subtitle: String?
        private var purchaseButtonText: String = "Continue"
        private var restoreButtonText: String = "Restore Purchases"
        private var headerIcon: String? = "crown.fill"
        private var accentColor: Color = .blue
        private var backgroundColor: Color = Color(.systemBackground)
        private var cardBackgroundColor: Color = Color(.secondarySystemBackground)
        private var textColor: Color = Color(.label)
        private var secondaryTextColor: Color = Color(.secondaryLabel)
        private var features: [Feature] = []
        private var privacyPolicyURL: URL?
        private var termsOfServiceURL: URL?
        private var showCloseButton: Bool = true
        private var dismissOnPurchase: Bool = true
        private var showRestoreButton: Bool = true
        
        public init() {}
        
        @discardableResult
        public func title(_ title: String) -> Builder {
            self.title = title
            return self
        }
        
        @discardableResult
        public func subtitle(_ subtitle: String?) -> Builder {
            self.subtitle = subtitle
            return self
        }
        
        @discardableResult
        public func purchaseButtonText(_ text: String) -> Builder {
            self.purchaseButtonText = text
            return self
        }
        
        @discardableResult
        public func headerIcon(_ icon: String?) -> Builder {
            self.headerIcon = icon
            return self
        }
        
        @discardableResult
        public func accentColor(_ color: Color) -> Builder {
            self.accentColor = color
            return self
        }
        
        @discardableResult
        public func backgroundColor(_ color: Color) -> Builder {
            self.backgroundColor = color
            return self
        }
        
        @discardableResult
        public func textColors(primary: Color, secondary: Color) -> Builder {
            self.textColor = primary
            self.secondaryTextColor = secondary
            return self
        }
        
        @discardableResult
        public func features(_ features: [Feature]) -> Builder {
            self.features = features
            return self
        }
        
        @discardableResult
        public func addFeature(icon: String, title: String, description: String? = nil) -> Builder {
            self.features.append(Feature(icon: icon, title: title, description: description))
            return self
        }
        
        @discardableResult
        public func legalURLs(privacy: URL?, terms: URL?) -> Builder {
            self.privacyPolicyURL = privacy
            self.termsOfServiceURL = terms
            return self
        }
        
        @discardableResult
        public func showCloseButton(_ show: Bool) -> Builder {
            self.showCloseButton = show
            return self
        }
        
        @discardableResult
        public func dismissOnPurchase(_ dismiss: Bool) -> Builder {
            self.dismissOnPurchase = dismiss
            return self
        }
        
        public func build() -> PaywallConfiguration {
            PaywallConfiguration(
                title: title,
                subtitle: subtitle,
                purchaseButtonText: purchaseButtonText,
                restoreButtonText: restoreButtonText,
                headerIcon: headerIcon,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                cardBackgroundColor: cardBackgroundColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                features: features,
                privacyPolicyURL: privacyPolicyURL,
                termsOfServiceURL: termsOfServiceURL,
                showCloseButton: showCloseButton,
                dismissOnPurchase: dismissOnPurchase,
                showRestoreButton: showRestoreButton
            )
        }
    }
}

// MARK: - Feature

/// Feature item for paywall display
public struct Feature: Identifiable, Sendable {
    public let id = UUID()
    
    /// SF Symbol icon name
    public let icon: String
    
    /// Feature title
    public let title: String
    
    /// Feature description (optional)
    public let description: String?
    
    public init(icon: String, title: String, description: String? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
    }
}

// MARK: - Common Feature Presets

public extension Feature {
    /// Remove ads feature
    static let removeAds = Feature(
        icon: "nosign",
        title: "Remove Ads",
        description: "Enjoy an ad-free experience"
    )
    
    /// Unlimited access feature
    static let unlimitedAccess = Feature(
        icon: "infinity",
        title: "Unlimited Access",
        description: "Access all content without restrictions"
    )
    
    /// Offline access feature
    static let offlineAccess = Feature(
        icon: "icloud.and.arrow.down",
        title: "Offline Access",
        description: "Download for offline use"
    )
    
    /// Priority support feature
    static let prioritySupport = Feature(
        icon: "person.badge.shield.checkmark",
        title: "Priority Support",
        description: "Get help when you need it"
    )
    
    /// Exclusive content feature
    static let exclusiveContent = Feature(
        icon: "star.fill",
        title: "Exclusive Content",
        description: "Access premium-only features"
    )
    
    /// Cloud sync feature
    static let cloudSync = Feature(
        icon: "icloud",
        title: "Cloud Sync",
        description: "Sync across all your devices"
    )
    
    /// Dark mode feature
    static let darkMode = Feature(
        icon: "moon.fill",
        title: "Dark Mode",
        description: "Easy on your eyes"
    )
    
    /// Family sharing feature
    static let familySharing = Feature(
        icon: "person.3.fill",
        title: "Family Sharing",
        description: "Share with up to 6 family members"
    )
}
