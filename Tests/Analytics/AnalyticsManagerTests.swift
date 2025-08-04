import XCTest
@testable import PaymentProcessingFramework

final class AnalyticsManagerTests: XCTestCase {
    
    var analyticsManager: AnalyticsManager!
    
    override func setUp() {
        super.setUp()
        analyticsManager = AnalyticsManager()
    }
    
    override func tearDown() {
        analyticsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAnalyticsManagerInitialization() {
        XCTAssertNotNil(analyticsManager)
        XCTAssertEqual(analyticsManager.isEnabled, true)
    }
    
    func testAnalyticsManagerConfiguration() {
        let config = AnalyticsConfiguration(
            trackingEnabled: true,
            sessionTimeout: 300,
            batchSize: 50
        )
        
        analyticsManager.configure(config)
        
        XCTAssertEqual(analyticsManager.isEnabled, config.trackingEnabled)
        XCTAssertEqual(analyticsManager.sessionTimeout, config.sessionTimeout)
        XCTAssertEqual(analyticsManager.batchSize, config.batchSize)
    }
    
    // MARK: - Event Tracking Tests
    
    func testTrackPaymentEvent() {
        let expectation = XCTestExpectation(description: "Payment event tracked")
        
        let paymentEvent = PaymentEvent(
            type: .paymentInitiated,
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "test_merchant"
        )
        
        analyticsManager.trackEvent(paymentEvent) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTrackFraudEvent() {
        let expectation = XCTestExpectation(description: "Fraud event tracked")
        
        let fraudEvent = FraudEvent(
            type: .suspiciousActivity,
            riskScore: 0.85,
            transactionId: "txn_123",
            reason: "Unusual spending pattern"
        )
        
        analyticsManager.trackEvent(fraudEvent) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTrackPerformanceEvent() {
        let expectation = XCTestExpectation(description: "Performance event tracked")
        
        let performanceEvent = PerformanceEvent(
            type: .apiResponseTime,
            metric: "payment_processing",
            value: 150.0,
            unit: "ms"
        )
        
        analyticsManager.trackEvent(performanceEvent) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Session Management Tests
    
    func testSessionStart() {
        let expectation = XCTestExpectation(description: "Session started")
        
        analyticsManager.startSession { success in
            XCTAssertTrue(success)
            XCTAssertNotNil(self.analyticsManager.currentSessionId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionEnd() {
        let expectation = XCTestExpectation(description: "Session ended")
        
        analyticsManager.startSession { _ in
            self.analyticsManager.endSession { success in
                XCTAssertTrue(success)
                XCTAssertNil(self.analyticsManager.currentSessionId)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSessionTimeout() {
        let expectation = XCTestExpectation(description: "Session timeout")
        
        analyticsManager.startSession { _ in
            // Simulate timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.analyticsManager.checkSessionTimeout()
                XCTAssertNil(self.analyticsManager.currentSessionId)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Data Batching Tests
    
    func testEventBatching() {
        let expectation = XCTestExpectation(description: "Events batched")
        
        // Add multiple events
        for i in 1...10 {
            let event = PaymentEvent(
                type: .paymentInitiated,
                amount: Double(i * 10),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "test_merchant"
            )
            
            analyticsManager.trackEvent(event) { _ in }
        }
        
        // Check if events are batched
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.analyticsManager.pendingEvents.count, 10)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBatchFlush() {
        let expectation = XCTestExpectation(description: "Batch flushed")
        
        // Add events
        for i in 1...5 {
            let event = PaymentEvent(
                type: .paymentInitiated,
                amount: Double(i * 10),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "test_merchant"
            )
            
            analyticsManager.trackEvent(event) { _ in }
        }
        
        // Flush batch
        analyticsManager.flushBatch { success in
            XCTAssertTrue(success)
            XCTAssertEqual(self.analyticsManager.pendingEvents.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        let expectation = XCTestExpectation(description: "Network error handled")
        
        // Simulate network error
        analyticsManager.simulateNetworkError = true
        
        let event = PaymentEvent(
            type: .paymentInitiated,
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            merchantId: "test_merchant"
        )
        
        analyticsManager.trackEvent(event) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInvalidEventHandling() {
        let expectation = XCTestExpectation(description: "Invalid event handled")
        
        let invalidEvent = InvalidEvent()
        
        analyticsManager.trackEvent(invalidEvent) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testHighVolumeEventTracking() {
        let expectation = XCTestExpectation(description: "High volume tracking")
        
        let startTime = Date()
        
        // Track 1000 events
        for i in 1...1000 {
            let event = PaymentEvent(
                type: .paymentInitiated,
                amount: Double(i),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "test_merchant"
            )
            
            analyticsManager.trackEvent(event) { _ in }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete within 5 seconds
        XCTAssertLessThan(duration, 5.0)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 6.0)
    }
    
    func testMemoryUsage() {
        let expectation = XCTestExpectation(description: "Memory usage test")
        
        let initialMemory = getMemoryUsage()
        
        // Track many events
        for i in 1...10000 {
            let event = PaymentEvent(
                type: .paymentInitiated,
                amount: Double(i),
                currency: .usd,
                paymentMethod: .creditCard,
                merchantId: "test_merchant"
            )
            
            analyticsManager.trackEvent(event) { _ in }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (< 50MB)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 10.0)
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

// MARK: - Test Event Types

struct InvalidEvent: AnalyticsEvent {
    var eventType: String = "invalid_event"
    var timestamp: Date = Date()
    var properties: [String: Any] = [:]
}

extension AnalyticsManager {
    var simulateNetworkError: Bool {
        get { false }
        set { /* Implementation for testing */ }
    }
} 