import XCTest
@testable import PaymentProcessingFramework

final class SecurityManagerTests: XCTestCase {
    
    var securityManager: SecurityManager!
    var mockConfiguration: PaymentConfiguration!
    
    override func setUp() {
        super.setUp()
        mockConfiguration = PaymentConfiguration(
            merchantId: "test_merchant_id",
            apiKey: "test_api_key",
            environment: .development
        )
        securityManager = SecurityManager(configuration: mockConfiguration)
    }
    
    override func tearDown() {
        securityManager = nil
        mockConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Card Data Validation Tests
    
    func test_validateCardData_withValidCard_doesNotThrow() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertNoThrow(try securityManager.validateCardData(cardData))
    }
    
    func test_validateCardData_withInvalidCardNumber_throwsError() {
        // Given
        let cardData = CardData(
            number: "1234",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateCardData(cardData)) { error in
            XCTAssertEqual(error as? SecurityError, .invalidCardNumber)
        }
    }
    
    func test_validateCardData_withInvalidExpiryDate_throwsError() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 13, // Invalid month
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateCardData(cardData)) { error in
            XCTAssertEqual(error as? SecurityError, .invalidExpiryDate)
        }
    }
    
    func test_validateCardData_withExpiredCard_throwsError() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 1,
            expiryYear: 2020, // Expired
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateCardData(cardData)) { error in
            XCTAssertEqual(error as? SecurityError, .invalidExpiryDate)
        }
    }
    
    func test_validateCardData_withInvalidCVV_throwsError() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "12", // Too short
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateCardData(cardData)) { error in
            XCTAssertEqual(error as? SecurityError, .invalidCVV)
        }
    }
    
    func test_validateCardData_withFraudulentCard_throwsError() {
        // Given
        let cardData = CardData(
            number: "4000000000000002", // Known fraudulent card
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateCardData(cardData)) { error in
            XCTAssertEqual(error as? SecurityError, .fraudulentCard)
        }
    }
    
    // MARK: - Encryption Tests
    
    func test_encryptCardData_withValidCard_returnsEncryptedData() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When
        let encryptedData = try? securityManager.encryptCardData(cardData)
        
        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertNotNil(encryptedData?.encryptedData)
        XCTAssertNotNil(encryptedData?.nonce)
        XCTAssertEqual(encryptedData?.version, "1.0")
    }
    
    func test_encryptCardData_withInvalidCard_throwsError() {
        // Given
        let cardData = CardData(
            number: "1234", // Invalid card number
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.encryptCardData(cardData)) { error in
            XCTAssertTrue(error is SecurityError)
        }
    }
    
    // MARK: - Decryption Tests
    
    func test_decryptCardData_withValidEncryptedData_returnsOriginalCardData() {
        // Given
        let originalCardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        let encryptedData = try! securityManager.encryptCardData(originalCardData)
        
        // When
        let decryptedCardData = try? securityManager.decryptCardData(encryptedData)
        
        // Then
        XCTAssertNotNil(decryptedCardData)
        XCTAssertEqual(decryptedCardData?.number, originalCardData.number)
        XCTAssertEqual(decryptedCardData?.expiryMonth, originalCardData.expiryMonth)
        XCTAssertEqual(decryptedCardData?.expiryYear, originalCardData.expiryYear)
        XCTAssertEqual(decryptedCardData?.cvv, originalCardData.cvv)
        XCTAssertEqual(decryptedCardData?.cardholderName, originalCardData.cardholderName)
    }
    
    func test_decryptCardData_withInvalidData_throwsError() {
        // Given
        let invalidEncryptedData = EncryptedCardData(
            encryptedData: Data(),
            nonce: try! AES.GCM.Nonce(),
            timestamp: Date(),
            version: "1.0"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.decryptCardData(invalidEncryptedData)) { error in
            XCTAssertTrue(error is SecurityError)
        }
    }
    
    // MARK: - Tokenization Tests
    
    func test_tokenizeCardData_withValidCard_returnsToken() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When
        let token = try? securityManager.tokenizeCardData(cardData)
        
        // Then
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.lastFourDigits, "1111")
        XCTAssertEqual(token?.expiryMonth, 12)
        XCTAssertEqual(token?.expiryYear, 2025)
        XCTAssertEqual(token?.cardType, .visa)
        XCTAssertTrue(token?.isActive == true)
    }
    
    func test_tokenizeCardData_withInvalidCard_throwsError() {
        // Given
        let cardData = CardData(
            number: "1234", // Invalid card number
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.tokenizeCardData(cardData)) { error in
            XCTAssertTrue(error is SecurityError)
        }
    }
    
    // MARK: - Fraud Detection Tests
    
    func test_analyzeFraudRisk_withLowRiskRequest_returnsLowRisk() async {
        // Given
        let request = PaymentRequest(
            amount: 50.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Low risk payment"
        )
        
        // When
        let fraudRisk = await securityManager.analyzeFraudRisk(for: request)
        
        // Then
        XCTAssertEqual(fraudRisk.level, .low)
        XCTAssertTrue(fraudRisk.score < 30.0)
    }
    
    func test_analyzeFraudRisk_withHighAmount_returnsHigherRisk() async {
        // Given
        let request = PaymentRequest(
            amount: 10000.0, // High amount
            currency: .usd,
            paymentMethod: .creditCard,
            description: "High amount payment"
        )
        
        // When
        let fraudRisk = await securityManager.analyzeFraudRisk(for: request)
        
        // Then
        XCTAssertTrue(fraudRisk.score > 30.0)
    }
    
    // MARK: - Device Risk Tests
    
    func test_analyzeDeviceRisk_withCleanDevice_returnsLowRisk() async {
        // Given
        let deviceData = DeviceFingerprint(
            deviceId: "clean_device_123",
            isKnownFraudulent: false,
            isConsistent: true,
            hasSuspiciousPatterns: false
        )
        
        // When
        let deviceRisk = securityManager.analyzeDeviceRisk(deviceData)
        
        // Then
        XCTAssertEqual(deviceRisk.riskLevel, .low)
        XCTAssertTrue(deviceRisk.score < 30.0)
    }
    
    func test_analyzeDeviceRisk_withFraudulentDevice_returnsHighRisk() async {
        // Given
        let deviceData = DeviceFingerprint(
            deviceId: "fraudulent_device_123",
            isKnownFraudulent: true,
            isConsistent: false,
            hasSuspiciousPatterns: true
        )
        
        // When
        let deviceRisk = securityManager.analyzeDeviceRisk(deviceData)
        
        // Then
        XCTAssertEqual(deviceRisk.riskLevel, .high)
        XCTAssertTrue(deviceRisk.score > 70.0)
    }
    
    // MARK: - Behavioral Risk Tests
    
    func test_analyzeBehavioralRisk_withNormalBehavior_returnsLowRisk() async {
        // Given
        let behaviorData = UserBehavior(
            hasUnusualPatterns: false,
            velocityViolations: 0,
            hasGeographicAnomalies: false
        )
        
        // When
        let behavioralRisk = securityManager.analyzeBehavioralRisk(behaviorData)
        
        // Then
        XCTAssertEqual(behavioralRisk.riskLevel, .low)
        XCTAssertTrue(behavioralRisk.score < 30.0)
    }
    
    func test_analyzeBehavioralRisk_withSuspiciousBehavior_returnsHighRisk() async {
        // Given
        let behaviorData = UserBehavior(
            hasUnusualPatterns: true,
            velocityViolations: 5,
            hasGeographicAnomalies: true
        )
        
        // When
        let behavioralRisk = securityManager.analyzeBehavioralRisk(behaviorData)
        
        // Then
        XCTAssertEqual(behavioralRisk.riskLevel, .high)
        XCTAssertTrue(behavioralRisk.score > 70.0)
    }
    
    // MARK: - API Request Validation Tests
    
    func test_validateAPIRequest_withValidRequest_doesNotThrow() {
        // Given
        let request = NetworkRequest(
            endpoint: .processPayment,
            method: .post,
            body: PaymentRequestBody(
                amount: 100.0,
                currency: .usd,
                paymentMethod: .creditCard,
                encryptedCardData: nil,
                description: "Test payment"
            )
        )
        
        // When & Then
        XCTAssertNoThrow(try securityManager.validateAPIRequest(request))
    }
    
    func test_validateAPIRequest_withInvalidRequest_throwsError() {
        // Given
        let request = NetworkRequest(
            endpoint: .processPayment,
            method: .post,
            body: nil
        )
        
        // When & Then
        XCTAssertThrowsError(try securityManager.validateAPIRequest(request)) { error in
            XCTAssertTrue(error is SecurityError)
        }
    }
    
    // MARK: - Secure Token Generation Tests
    
    func test_generateSecureToken_returnsValidToken() {
        // When
        let token = securityManager.generateSecureToken(length: 32)
        
        // Then
        XCTAssertEqual(token.count, 32)
        XCTAssertTrue(token.allSatisfy { $0.isLetter || $0.isNumber })
    }
    
    func test_generateSecureToken_withCustomLength_returnsCorrectLength() {
        // When
        let token = securityManager.generateSecureToken(length: 64)
        
        // Then
        XCTAssertEqual(token.count, 64)
    }
    
    // MARK: - SSL Certificate Validation Tests
    
    func test_validateSSLCertificate_withValidCertificate_returnsTrue() {
        // Given
        let certificate = SecCertificate() // Mock certificate
        
        // When
        let isValid = securityManager.validateSSLCertificate(certificate)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Card Type Detection Tests
    
    func test_determineCardType_withVisaCard_returnsVisa() {
        // Given
        let cardNumber = "4111111111111111"
        
        // When
        let cardType = securityManager.determineCardType(from: cardNumber)
        
        // Then
        XCTAssertEqual(cardType, .visa)
    }
    
    func test_determineCardType_withMastercard_returnsMastercard() {
        // Given
        let cardNumber = "5555555555554444"
        
        // When
        let cardType = securityManager.determineCardType(from: cardNumber)
        
        // Then
        XCTAssertEqual(cardType, .mastercard)
    }
    
    func test_determineCardType_withAmex_returnsAmex() {
        // Given
        let cardNumber = "378282246310005"
        
        // When
        let cardType = securityManager.determineCardType(from: cardNumber)
        
        // Then
        XCTAssertEqual(cardType, .amex)
    }
    
    func test_determineCardType_withUnknownCard_returnsUnknown() {
        // Given
        let cardNumber = "9999999999999999"
        
        // When
        let cardType = securityManager.determineCardType(from: cardNumber)
        
        // Then
        XCTAssertEqual(cardType, .unknown)
    }
    
    // MARK: - Performance Tests
    
    func test_encryptCardData_performance() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        measure {
            _ = try? securityManager.encryptCardData(cardData)
        }
    }
    
    func test_validateCardData_performance() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        // When & Then
        measure {
            _ = try? securityManager.validateCardData(cardData)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func test_encryptCardData_concurrentRequests() {
        // Given
        let cardData = CardData(
            number: "4111111111111111",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            cardholderName: "John Doe"
        )
        
        let expectation = XCTestExpectation(description: "Concurrent encryption")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = try? self.securityManager.encryptCardData(cardData)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_analyzeFraudRisk_concurrentRequests() async {
        // Given
        let request = PaymentRequest(
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Concurrent test"
        )
        
        let expectation = XCTestExpectation(description: "Concurrent fraud analysis")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for _ in 0..<10 {
            Task {
                _ = await self.securityManager.analyzeFraudRisk(for: request)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Supporting Extensions

extension SecurityManager {
    func determineCardType(from number: String) -> CardType {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if cleanNumber.hasPrefix("4") {
            return .visa
        } else if cleanNumber.hasPrefix("5") {
            return .mastercard
        } else if cleanNumber.hasPrefix("34") || cleanNumber.hasPrefix("37") {
            return .amex
        } else if cleanNumber.hasPrefix("6") {
            return .discover
        } else {
            return .unknown
        }
    }
} 