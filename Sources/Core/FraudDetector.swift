import Foundation
import Logging

/// AI-powered fraud detection system for payment processing
/// Implements machine learning algorithms and behavioral analysis
public final class FraudDetector {
    
    // MARK: - Properties
    
    private let configuration: PaymentConfiguration
    private let logger: Logger
    private var fraudRules: [FraudRule] = []
    private var riskThresholds: [FraudRiskLevel: Double] = [:]
    
    // MARK: - Initialization
    
    public init(configuration: PaymentConfiguration) {
        self.configuration = configuration
        self.logger = Logger(label: "FraudDetector")
        
        setupFraudDetection()
    }
    
    // MARK: - Public Methods
    
    /// Analyzes fraud risk for a payment request
    /// - Parameter request: The payment request to analyze
    /// - Returns: Fraud risk assessment
    public func analyzeRisk(for request: PaymentRequest) async -> FraudRisk {
        logger.debug("Analyzing fraud risk for payment: \(request.id)")
        
        let riskFactors = await analyzeRiskFactors(for: request)
        let riskScore = calculateRiskScore(factors: riskFactors)
        let riskLevel = determineRiskLevel(score: riskScore)
        
        let fraudRisk = FraudRisk(
            level: riskLevel,
            score: riskScore,
            factors: riskFactors,
            timestamp: Date()
        )
        
        logger.debug("Fraud risk analysis completed: \(riskLevel.rawValue) (score: \(riskScore))")
        return fraudRisk
    }
    
    /// Updates fraud detection configuration
    /// - Parameter configuration: The new fraud detection configuration
    public func updateConfiguration(_ configuration: FraudDetectionConfiguration) {
        logger.info("Updating fraud detection configuration")
        
        self.fraudRules = configuration.rules
        updateRiskThresholds(for: configuration.sensitivity)
        
        logger.debug("Fraud detection configuration updated")
    }
    
    /// Checks if a card number is known to be fraudulent
    /// - Parameter cardNumber: The card number to check
    /// - Returns: True if the card is known to be fraudulent
    public func isKnownFraudulentCard(_ cardNumber: String) -> Bool {
        // Check against known fraudulent card database
        // This would typically query an external fraud database
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Simulate fraud database check
        return fraudulentCardNumbers.contains(cleanNumber)
    }
    
    /// Analyzes device fingerprint for fraud detection
    /// - Parameter deviceData: Device fingerprint data
    /// - Returns: Device risk assessment
    public func analyzeDeviceRisk(_ deviceData: DeviceFingerprint) -> DeviceRisk {
        logger.debug("Analyzing device risk")
        
        var riskFactors: [FraudFactor] = []
        var riskScore = 0.0
        
        // Check device reputation
        if deviceData.isKnownFraudulent {
            riskFactors.append(FraudFactor(
                type: .deviceFingerprint,
                weight: 0.8,
                severity: 1.0,
                description: "Device is known to be fraudulent"
            ))
            riskScore += 80.0
        }
        
        // Check device consistency
        if !deviceData.isConsistent {
            riskFactors.append(FraudFactor(
                type: .deviceFingerprint,
                weight: 0.6,
                severity: 0.8,
                description: "Device fingerprint is inconsistent"
            ))
            riskScore += 48.0
        }
        
        // Check for suspicious patterns
        if deviceData.hasSuspiciousPatterns {
            riskFactors.append(FraudFactor(
                type: .deviceFingerprint,
                weight: 0.7,
                severity: 0.9,
                description: "Device shows suspicious patterns"
            ))
            riskScore += 63.0
        }
        
        let riskLevel = determineRiskLevel(score: riskScore)
        
        return DeviceRisk(
            riskLevel: riskLevel,
            score: riskScore,
            factors: riskFactors,
            deviceData: deviceData
        )
    }
    
    /// Analyzes behavioral patterns for fraud detection
    /// - Parameter behaviorData: User behavior data
    /// - Returns: Behavioral risk assessment
    public func analyzeBehavioralRisk(_ behaviorData: UserBehavior) -> BehavioralRisk {
        logger.debug("Analyzing behavioral risk")
        
        var riskFactors: [FraudFactor] = []
        var riskScore = 0.0
        
        // Check for unusual transaction patterns
        if behaviorData.hasUnusualPatterns {
            riskFactors.append(FraudFactor(
                type: .behavioralPattern,
                weight: 0.7,
                severity: 0.8,
                description: "Unusual transaction patterns detected"
            ))
            riskScore += 56.0
        }
        
        // Check for velocity violations
        if behaviorData.velocityViolations > 0 {
            riskFactors.append(FraudFactor(
                type: .velocityCheck,
                weight: 0.8,
                severity: Double(behaviorData.velocityViolations) / 10.0,
                description: "Velocity violations detected: \(behaviorData.velocityViolations)"
            ))
            riskScore += 64.0
        }
        
        // Check for geographic anomalies
        if behaviorData.hasGeographicAnomalies {
            riskFactors.append(FraudFactor(
                type: .geolocationCheck,
                weight: 0.6,
                severity: 0.7,
                description: "Geographic anomalies detected"
            ))
            riskScore += 42.0
        }
        
        let riskLevel = determineRiskLevel(score: riskScore)
        
        return BehavioralRisk(
            riskLevel: riskLevel,
            score: riskScore,
            factors: riskFactors,
            behaviorData: behaviorData
        )
    }
    
    // MARK: - Private Methods
    
    private func setupFraudDetection() {
        logger.info("Setting up fraud detection system")
        
        // Initialize default fraud rules
        fraudRules = [
            .velocityCheck,
            .geolocationCheck,
            .deviceFingerprinting,
            .behavioralAnalysis,
            .cardPatternAnalysis,
            .amountPatternAnalysis
        ]
        
        // Set default risk thresholds
        updateRiskThresholds(for: .medium)
        
        logger.info("Fraud detection system initialized")
    }
    
    private func updateRiskThresholds(for sensitivity: FraudSensitivity) {
        switch sensitivity {
        case .low:
            riskThresholds = [
                .low: 30.0,
                .medium: 60.0,
                .high: 80.0,
                .critical: 90.0
            ]
        case .medium:
            riskThresholds = [
                .low: 20.0,
                .medium: 50.0,
                .high: 70.0,
                .critical: 85.0
            ]
        case .high:
            riskThresholds = [
                .low: 10.0,
                .medium: 40.0,
                .high: 60.0,
                .critical: 80.0
            ]
        }
    }
    
    private func analyzeRiskFactors(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Analyze each fraud rule
        for rule in fraudRules {
            let ruleFactors = await analyzeRule(rule, for: request)
            factors.append(contentsOf: ruleFactors)
        }
        
        return factors
    }
    
    private func analyzeRule(_ rule: FraudRule, for request: PaymentRequest) async -> [FraudFactor] {
        switch rule {
        case .velocityCheck:
            return await analyzeVelocityRisk(for: request)
        case .geolocationCheck:
            return await analyzeGeolocationRisk(for: request)
        case .deviceFingerprinting:
            return await analyzeDeviceRisk(for: request)
        case .behavioralAnalysis:
            return await analyzeBehavioralRisk(for: request)
        case .cardPatternAnalysis:
            return await analyzeCardPatternRisk(for: request)
        case .amountPatternAnalysis:
            return await analyzeAmountPatternRisk(for: request)
        }
    }
    
    private func analyzeVelocityRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Check transaction velocity (frequency)
        let recentTransactions = await getRecentTransactions(for: request)
        
        if recentTransactions.count > 5 {
            factors.append(FraudFactor(
                type: .velocityCheck,
                weight: 0.7,
                severity: min(Double(recentTransactions.count) / 10.0, 1.0),
                description: "High transaction velocity: \(recentTransactions.count) transactions"
            ))
        }
        
        // Check amount velocity
        let totalAmount = recentTransactions.reduce(0) { $0 + $1.amount }
        if totalAmount > 1000 {
            factors.append(FraudFactor(
                type: .velocityCheck,
                weight: 0.8,
                severity: min(totalAmount / 5000.0, 1.0),
                description: "High amount velocity: $\(totalAmount)"
            ))
        }
        
        return factors
    }
    
    private func analyzeGeolocationRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Get user's location history
        let locationHistory = await getUserLocationHistory()
        let currentLocation = await getCurrentLocation()
        
        // Check for location anomalies
        if let lastLocation = locationHistory.last {
            let distance = calculateDistance(from: lastLocation, to: currentLocation)
            let timeDifference = Date().timeIntervalSince(lastLocation.timestamp)
            
            // Check for impossible travel (e.g., 1000km in 1 hour)
            let speedKmH = distance / (timeDifference / 3600)
            if speedKmH > 1000 {
                factors.append(FraudFactor(
                    type: .geolocationCheck,
                    weight: 0.9,
                    severity: 1.0,
                    description: "Impossible travel detected: \(Int(speedKmH)) km/h"
                ))
            }
        }
        
        // Check for high-risk locations
        if isHighRiskLocation(currentLocation) {
            factors.append(FraudFactor(
                type: .geolocationCheck,
                weight: 0.6,
                severity: 0.8,
                description: "Transaction from high-risk location"
            ))
        }
        
        return factors
    }
    
    private func analyzeDeviceRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Get device fingerprint
        let deviceFingerprint = await getDeviceFingerprint()
        
        // Check device reputation
        if deviceFingerprint.isKnownFraudulent {
            factors.append(FraudFactor(
                type: .deviceFingerprint,
                weight: 0.8,
                severity: 1.0,
                description: "Device is known to be fraudulent"
            ))
        }
        
        // Check device consistency
        if !deviceFingerprint.isConsistent {
            factors.append(FraudFactor(
                type: .deviceFingerprint,
                weight: 0.6,
                severity: 0.8,
                description: "Device fingerprint is inconsistent"
            ))
        }
        
        return factors
    }
    
    private func analyzeBehavioralRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Get user behavior data
        let userBehavior = await getUserBehavior()
        
        // Check for unusual patterns
        if userBehavior.hasUnusualPatterns {
            factors.append(FraudFactor(
                type: .behavioralPattern,
                weight: 0.7,
                severity: 0.8,
                description: "Unusual behavioral patterns detected"
            ))
        }
        
        // Check for velocity violations
        if userBehavior.velocityViolations > 0 {
            factors.append(FraudFactor(
                type: .velocityCheck,
                weight: 0.8,
                severity: Double(userBehavior.velocityViolations) / 10.0,
                description: "Velocity violations: \(userBehavior.velocityViolations)"
            ))
        }
        
        return factors
    }
    
    private func analyzeCardPatternRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        guard let cardData = request.cardData else {
            return factors
        }
        
        // Check for known fraudulent card patterns
        if isKnownFraudulentCard(cardData.number) {
            factors.append(FraudFactor(
                type: .cardPatternAnalysis,
                weight: 1.0,
                severity: 1.0,
                description: "Card is known to be fraudulent"
            ))
        }
        
        // Check for suspicious card patterns
        if hasSuspiciousCardPattern(cardData.number) {
            factors.append(FraudFactor(
                type: .cardPatternAnalysis,
                weight: 0.7,
                severity: 0.8,
                description: "Suspicious card pattern detected"
            ))
        }
        
        return factors
    }
    
    private func analyzeAmountPatternRisk(for request: PaymentRequest) async -> [FraudFactor] {
        var factors: [FraudFactor] = []
        
        // Check for unusual amount patterns
        if isUnusualAmount(request.amount) {
            factors.append(FraudFactor(
                type: .amountPatternAnalysis,
                weight: 0.6,
                severity: 0.7,
                description: "Unusual transaction amount: $\(request.amount)"
            ))
        }
        
        // Check for round amounts (potential test transactions)
        if isRoundAmount(request.amount) {
            factors.append(FraudFactor(
                type: .amountPatternAnalysis,
                weight: 0.5,
                severity: 0.6,
                description: "Round amount detected: $\(request.amount)"
            ))
        }
        
        return factors
    }
    
    private func calculateRiskScore(factors: [FraudFactor]) -> Double {
        var totalScore = 0.0
        
        for factor in factors {
            totalScore += factor.weight * factor.severity * 100.0
        }
        
        return min(totalScore, 100.0)
    }
    
    private func determineRiskLevel(score: Double) -> FraudRiskLevel {
        if score >= riskThresholds[.critical] ?? 90.0 {
            return .critical
        } else if score >= riskThresholds[.high] ?? 70.0 {
            return .high
        } else if score >= riskThresholds[.medium] ?? 50.0 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Helper Methods
    
    private func getRecentTransactions(for request: PaymentRequest) async -> [Transaction] {
        // Simulate fetching recent transactions
        // In a real implementation, this would query a database
        return []
    }
    
    private func getUserLocationHistory() async -> [LocationData] {
        // Simulate fetching location history
        return []
    }
    
    private func getCurrentLocation() async -> LocationData {
        // Simulate getting current location
        return LocationData(latitude: 0.0, longitude: 0.0, timestamp: Date())
    }
    
    private func getDeviceFingerprint() async -> DeviceFingerprint {
        // Simulate getting device fingerprint
        return DeviceFingerprint(
            deviceId: UUID().uuidString,
            isKnownFraudulent: false,
            isConsistent: true,
            hasSuspiciousPatterns: false
        )
    }
    
    private func getUserBehavior() async -> UserBehavior {
        // Simulate getting user behavior data
        return UserBehavior(
            hasUnusualPatterns: false,
            velocityViolations: 0,
            hasGeographicAnomalies: false
        )
    }
    
    private func calculateDistance(from location1: LocationData, to location2: LocationData) -> Double {
        // Simplified distance calculation
        let latDiff = location1.latitude - location2.latitude
        let lonDiff = location1.longitude - location2.longitude
        return sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111.0 // Approximate km
    }
    
    private func isHighRiskLocation(_ location: LocationData) -> Bool {
        // Simulate high-risk location check
        return false
    }
    
    private func hasSuspiciousCardPattern(_ cardNumber: String) -> Bool {
        // Check for suspicious patterns in card numbers
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Check for sequential numbers
        if cleanNumber.contains("1234") || cleanNumber.contains("5678") {
            return true
        }
        
        // Check for repeated numbers
        if cleanNumber.contains("1111") || cleanNumber.contains("0000") {
            return true
        }
        
        return false
    }
    
    private func isUnusualAmount(_ amount: Decimal) -> Bool {
        // Check for unusually high or low amounts
        return amount > 10000 || amount < 0.01
    }
    
    private func isRoundAmount(_ amount: Decimal) -> Bool {
        // Check for round amounts (e.g., 100.00, 50.00)
        let amountString = String(describing: amount)
        return amountString.hasSuffix(".00") || amountString.hasSuffix(".0")
    }
    
    // MARK: - Mock Data
    
    private let fraudulentCardNumbers: Set<String> = [
        "4111111111111111",
        "5555555555554444",
        "4000000000000002"
    ]
}

// MARK: - Supporting Types

/// Device fingerprint data
public struct DeviceFingerprint {
    public let deviceId: String
    public let isKnownFraudulent: Bool
    public let isConsistent: Bool
    public let hasSuspiciousPatterns: Bool
    
    public init(deviceId: String, isKnownFraudulent: Bool, isConsistent: Bool, hasSuspiciousPatterns: Bool) {
        self.deviceId = deviceId
        self.isKnownFraudulent = isKnownFraudulent
        self.isConsistent = isConsistent
        self.hasSuspiciousPatterns = hasSuspiciousPatterns
    }
}

/// User behavior data
public struct UserBehavior {
    public let hasUnusualPatterns: Bool
    public let velocityViolations: Int
    public let hasGeographicAnomalies: Bool
    
    public init(hasUnusualPatterns: Bool, velocityViolations: Int, hasGeographicAnomalies: Bool) {
        self.hasUnusualPatterns = hasUnusualPatterns
        self.velocityViolations = velocityViolations
        self.hasGeographicAnomalies = hasGeographicAnomalies
    }
}

/// Location data
public struct LocationData {
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}

/// Device risk assessment
public struct DeviceRisk {
    public let riskLevel: FraudRiskLevel
    public let score: Double
    public let factors: [FraudFactor]
    public let deviceData: DeviceFingerprint
    
    public init(riskLevel: FraudRiskLevel, score: Double, factors: [FraudFactor], deviceData: DeviceFingerprint) {
        self.riskLevel = riskLevel
        self.score = score
        self.factors = factors
        self.deviceData = deviceData
    }
}

/// Behavioral risk assessment
public struct BehavioralRisk {
    public let riskLevel: FraudRiskLevel
    public let score: Double
    public let factors: [FraudFactor]
    public let behaviorData: UserBehavior
    
    public init(riskLevel: FraudRiskLevel, score: Double, factors: [FraudFactor], behaviorData: UserBehavior) {
        self.riskLevel = riskLevel
        self.score = score
        self.factors = factors
        self.behaviorData = behaviorData
    }
} 