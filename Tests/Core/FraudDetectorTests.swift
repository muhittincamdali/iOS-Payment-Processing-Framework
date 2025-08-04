import XCTest
@testable import PaymentProcessingFramework

final class FraudDetectorTests: XCTestCase {
    
    var fraudDetector: FraudDetector!
    
    override func setUp() {
        super.setUp()
        fraudDetector = FraudDetector()
    }
    
    override func tearDown() {
        fraudDetector = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testFraudDetectorInitialization() {
        XCTAssertNotNil(fraudDetector)
        XCTAssertEqual(fraudDetector.isEnabled, true)
        XCTAssertEqual(fraudDetector.riskThreshold, 0.7)
    }
    
    func testFraudDetectorConfiguration() {
        let config = FraudDetectionConfiguration(
            enabled: true,
            riskThreshold: 0.8,
            maxRetries: 3,
            timeoutInterval: 5.0
        )
        
        fraudDetector.configure(config)
        
        XCTAssertEqual(fraudDetector.isEnabled, config.enabled)
        XCTAssertEqual(fraudDetector.riskThreshold, config.riskThreshold)
        XCTAssertEqual(fraudDetector.maxRetries, config.maxRetries)
        XCTAssertEqual(fraudDetector.timeoutInterval, config.timeoutInterval)
    }
    
    // MARK: - Risk Assessment Tests
    
    func testLowRiskTransaction() {
        let expectation = XCTestExpectation(description: "Low risk transaction")
        
        let transaction = Transaction(
            id: "txn_123",
            amount: 25.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        fraudDetector.assessRisk(transaction) { result in
            switch result {
            case .success(let riskAssessment):
                XCTAssertLessThan(riskAssessment.riskScore, 0.3)
                XCTAssertEqual(riskAssessment.recommendation, .approve)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Risk assessment failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testHighRiskTransaction() {
        let expectation = XCTestExpectation(description: "High risk transaction")
        
        let transaction = Transaction(
            id: "txn_456",
            amount: 5000.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_456",
            timestamp: Date()
        )
        
        fraudDetector.assessRisk(transaction) { result in
            switch result {
            case .success(let riskAssessment):
                XCTAssertGreaterThan(riskAssessment.riskScore, 0.7)
                XCTAssertEqual(riskAssessment.recommendation, .review)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Risk assessment failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSuspiciousActivityDetection() {
        let expectation = XCTestExpectation(description: "Suspicious activity detection")
        
        let transaction = Transaction(
            id: "txn_789",
            amount: 1000.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_789",
            timestamp: Date()
        )
        
        // Add suspicious patterns
        transaction.addSuspiciousPattern(.unusualAmount)
        transaction.addSuspiciousPattern(.newMerchant)
        
        fraudDetector.assessRisk(transaction) { result in
            switch result {
            case .success(let riskAssessment):
                XCTAssertGreaterThan(riskAssessment.riskScore, 0.8)
                XCTAssertEqual(riskAssessment.recommendation, .decline)
                XCTAssertTrue(riskAssessment.suspiciousPatterns.contains(.unusualAmount))
                XCTAssertTrue(riskAssessment.suspiciousPatterns.contains(.newMerchant))
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Risk assessment failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Pattern Detection Tests
    
    func testVelocityPatternDetection() {
        let expectation = XCTestExpectation(description: "Velocity pattern detection")
        
        // Create multiple transactions in short time
        let transactions = [
            Transaction(id: "txn_1", amount: 100.0, currency: .usd, paymentMethod: .creditCard, merchantId: "merchant_123", customerId: "customer_123", timestamp: Date()),
            Transaction(id: "txn_2", amount: 200.0, currency: .usd, paymentMethod: .creditCard, merchantId: "merchant_123", customerId: "customer_123", timestamp: Date().addingTimeInterval(60)),
            Transaction(id: "txn_3", amount: 300.0, currency: .usd, paymentMethod: .creditCard, merchantId: "merchant_123", customerId: "customer_123", timestamp: Date().addingTimeInterval(120))
        ]
        
        fraudDetector.detectVelocityPatterns(transactions) { patterns in
            XCTAssertTrue(patterns.contains(.highVelocity))
            XCTAssertGreaterThan(patterns.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGeographicPatternDetection() {
        let expectation = XCTestExpectation(description: "Geographic pattern detection")
        
        let transaction = Transaction(
            id: "txn_geo",
            amount: 500.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        // Set unusual geographic location
        transaction.location = Location(latitude: 40.7128, longitude: -74.0060, country: "US", city: "New York")
        
        fraudDetector.detectGeographicPatterns(transaction) { patterns in
            XCTAssertTrue(patterns.contains(.unusualLocation))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDevicePatternDetection() {
        let expectation = XCTestExpectation(description: "Device pattern detection")
        
        let transaction = Transaction(
            id: "txn_device",
            amount: 250.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        // Set suspicious device information
        transaction.deviceInfo = DeviceInfo(
            deviceId: "device_123",
            deviceType: .mobile,
            osVersion: "iOS 15.0",
            appVersion: "1.0.0",
            isEmulator: true
        )
        
        fraudDetector.detectDevicePatterns(transaction) { patterns in
            XCTAssertTrue(patterns.contains(.suspiciousDevice))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Machine Learning Tests
    
    func testMLModelPrediction() {
        let expectation = XCTestExpectation(description: "ML model prediction")
        
        let features = FraudFeatures(
            amount: 1000.0,
            currency: .usd,
            paymentMethod: .creditCard,
            customerAge: 25,
            customerLocation: "US",
            merchantCategory: "electronics",
            timeOfDay: 14,
            dayOfWeek: 3
        )
        
        fraudDetector.predictRisk(features) { prediction in
            XCTAssertNotNil(prediction.riskScore)
            XCTAssertNotNil(prediction.confidence)
            XCTAssertGreaterThanOrEqual(prediction.riskScore, 0.0)
            XCTAssertLessThanOrEqual(prediction.riskScore, 1.0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testModelAccuracy() {
        let expectation = XCTestExpectation(description: "Model accuracy")
        
        let testCases = [
            (features: FraudFeatures(amount: 50.0, currency: .usd, paymentMethod: .creditCard, customerAge: 30, customerLocation: "US", merchantCategory: "food", timeOfDay: 12, dayOfWeek: 1), expectedRisk: 0.1),
            (features: FraudFeatures(amount: 5000.0, currency: .usd, paymentMethod: .creditCard, customerAge: 25, customerLocation: "RU", merchantCategory: "electronics", timeOfDay: 2, dayOfWeek: 7), expectedRisk: 0.9)
        ]
        
        var accuracySum = 0.0
        var testCount = 0
        
        for (features, expectedRisk) in testCases {
            fraudDetector.predictRisk(features) { prediction in
                let accuracy = 1.0 - abs(prediction.riskScore - expectedRisk)
                accuracySum += accuracy
                testCount += 1
                
                if testCount == testCases.count {
                    let averageAccuracy = accuracySum / Double(testCount)
                    XCTAssertGreaterThan(averageAccuracy, 0.7) // 70% accuracy threshold
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Real-time Monitoring Tests
    
    func testRealTimeMonitoring() {
        let expectation = XCTestExpectation(description: "Real-time monitoring")
        
        let transaction = Transaction(
            id: "txn_realtime",
            amount: 750.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        fraudDetector.startRealTimeMonitoring()
        
        fraudDetector.monitorTransaction(transaction) { alert in
            XCTAssertNotNil(alert)
            XCTAssertNotNil(alert.timestamp)
            XCTAssertNotNil(alert.severity)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAlertGeneration() {
        let expectation = XCTestExpectation(description: "Alert generation")
        
        let suspiciousTransaction = Transaction(
            id: "txn_alert",
            amount: 2000.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        fraudDetector.generateAlert(for: suspiciousTransaction, riskScore: 0.85, patterns: [.unusualAmount, .newMerchant]) { alert in
            XCTAssertEqual(alert.transactionId, suspiciousTransaction.id)
            XCTAssertEqual(alert.riskScore, 0.85)
            XCTAssertTrue(alert.patterns.contains(.unusualAmount))
            XCTAssertTrue(alert.patterns.contains(.newMerchant))
            XCTAssertEqual(alert.severity, .high)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testHighVolumeProcessing() {
        let expectation = XCTestExpectation(description: "High volume processing")
        
        let startTime = Date()
        let transactionCount = 1000
        let group = DispatchGroup()
        var processedCount = 0
        
        for i in 1...transactionCount {
            group.enter()
            
            let transaction = Transaction(
                id: "txn_\(i)",
                amount: Double(i * 10),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "merchant_123",
                customerId: "customer_123",
                timestamp: Date()
            )
            
            fraudDetector.assessRisk(transaction) { _ in
                processedCount += 1
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            XCTAssertEqual(processedCount, transactionCount)
            XCTAssertLessThan(duration, 30.0) // Should complete within 30 seconds
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 35.0)
    }
    
    func testMemoryEfficiency() {
        let expectation = XCTestExpectation(description: "Memory efficiency")
        
        let initialMemory = getMemoryUsage()
        
        // Process many transactions
        let group = DispatchGroup()
        for i in 1...5000 {
            group.enter()
            
            let transaction = Transaction(
                id: "txn_mem_\(i)",
                amount: Double(i),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "merchant_123",
                customerId: "customer_123",
                timestamp: Date()
            )
            
            fraudDetector.assessRisk(transaction) { _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let finalMemory = getMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            // Memory increase should be reasonable (< 50MB)
            XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidTransactionHandling() {
        let expectation = XCTestExpectation(description: "Invalid transaction handling")
        
        let invalidTransaction = Transaction(
            id: "",
            amount: -100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "",
            customerId: "",
            timestamp: Date()
        )
        
        fraudDetector.assessRisk(invalidTransaction) { result in
            switch result {
            case .success(_):
                XCTFail("Invalid transaction should fail")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testModelLoadFailure() {
        let expectation = XCTestExpectation(description: "Model load failure")
        
        // Simulate model load failure
        fraudDetector.simulateModelLoadFailure = true
        
        let transaction = Transaction(
            id: "txn_model_fail",
            amount: 100.0,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "merchant_123",
            customerId: "customer_123",
            timestamp: Date()
        )
        
        fraudDetector.assessRisk(transaction) { result in
            switch result {
            case .success(_):
                XCTFail("Should fail when model fails to load")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("model"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
}

// MARK: - Test Extensions

extension Transaction {
    func addSuspiciousPattern(_ pattern: SuspiciousPattern) {
        // Implementation for testing
    }
    
    var location: Location? {
        get { nil }
        set { /* Implementation for testing */ }
    }
    
    var deviceInfo: DeviceInfo? {
        get { nil }
        set { /* Implementation for testing */ }
    }
}

extension FraudDetector {
    var simulateModelLoadFailure: Bool {
        get { false }
        set { /* Implementation for testing */ }
    }
} 