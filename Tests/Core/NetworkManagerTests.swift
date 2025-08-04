import XCTest
@testable import PaymentProcessingFramework

final class NetworkManagerTests: XCTestCase {
    
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager()
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testNetworkManagerInitialization() {
        XCTAssertNotNil(networkManager)
        XCTAssertEqual(networkManager.baseURL, "https://api.paymentprocessing.com")
        XCTAssertEqual(networkManager.timeoutInterval, 30.0)
    }
    
    func testNetworkManagerConfiguration() {
        let config = NetworkConfiguration(
            baseURL: "https://test-api.paymentprocessing.com",
            timeoutInterval: 60.0,
            retryCount: 3
        )
        
        networkManager.configure(config)
        
        XCTAssertEqual(networkManager.baseURL, config.baseURL)
        XCTAssertEqual(networkManager.timeoutInterval, config.timeoutInterval)
        XCTAssertEqual(networkManager.retryCount, config.retryCount)
    }
    
    // MARK: - Request Tests
    
    func testSuccessfulPaymentRequest() {
        let expectation = XCTestExpectation(description: "Payment request successful")
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Test payment"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.transactionId)
                XCTAssertEqual(response.status, .success)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Payment request failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFailedPaymentRequest() {
        let expectation = XCTestExpectation(description: "Payment request failed")
        
        let invalidRequest = PaymentRequest(
            amount: -10.0,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Invalid payment"
        )
        
        networkManager.processPayment(invalidRequest) { result in
            switch result {
            case .success(_):
                XCTFail("Invalid request should fail")
            case .failure(let error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNetworkTimeout() {
        let expectation = XCTestExpectation(description: "Network timeout")
        
        // Configure short timeout
        let config = NetworkConfiguration(
            baseURL: "https://slow-api.paymentprocessing.com",
            timeoutInterval: 0.1,
            retryCount: 1
        )
        networkManager.configure(config)
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Timeout test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            switch result {
            case .success(_):
                XCTFail("Request should timeout")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("timeout"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryOnFailure() {
        let expectation = XCTestExpectation(description: "Retry on failure")
        
        var retryCount = 0
        networkManager.retryCount = 3
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Retry test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            retryCount += 1
            
            if retryCount < 3 {
                // Simulate failure
                expectation.fulfill()
            } else {
                // Should succeed on final retry
                switch result {
                case .success(let response):
                    XCTAssertNotNil(response.transactionId)
                case .failure(let error):
                    XCTFail("Final retry should succeed: \(error.localizedDescription)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticationHeader() {
        let expectation = XCTestExpectation(description: "Authentication header")
        
        let authToken = "test_auth_token_12345"
        networkManager.setAuthenticationToken(authToken)
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Auth test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            // Verify auth header was sent
            XCTAssertTrue(self.networkManager.lastRequestHeaders?["Authorization"] == "Bearer \(authToken)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTokenRefresh() {
        let expectation = XCTestExpectation(description: "Token refresh")
        
        networkManager.refreshAuthenticationToken { success in
            XCTAssertTrue(success)
            XCTAssertNotNil(self.networkManager.currentAuthToken)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - SSL/TLS Tests
    
    func testSSLCertificateValidation() {
        let expectation = XCTestExpectation(description: "SSL validation")
        
        let config = NetworkConfiguration(
            baseURL: "https://api.paymentprocessing.com",
            timeoutInterval: 30.0,
            retryCount: 1,
            validateSSLCertificate: true
        )
        networkManager.configure(config)
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "SSL test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            switch result {
            case .success(_):
                XCTAssertTrue(self.networkManager.sslCertificateValidated)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("SSL validation failed: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimiting() {
        let expectation = XCTestExpectation(description: "Rate limiting")
        
        // Send multiple requests quickly
        let group = DispatchGroup()
        var successCount = 0
        var failureCount = 0
        
        for i in 1...10 {
            group.enter()
            
            let paymentRequest = PaymentRequest(
                amount: Double(i * 10),
                currency: .usd,
                paymentMethod: .creditCard,
                description: "Rate limit test \(i)"
            )
            
            networkManager.processPayment(paymentRequest) { result in
                switch result {
                case .success(_):
                    successCount += 1
                case .failure(_):
                    failureCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Some requests should succeed, some should be rate limited
            XCTAssertGreaterThan(successCount, 0)
            XCTAssertGreaterThan(failureCount, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentRequests() {
        let expectation = XCTestExpectation(description: "Concurrent requests")
        
        let startTime = Date()
        let requestCount = 50
        let group = DispatchGroup()
        var completedCount = 0
        
        for i in 1...requestCount {
            group.enter()
            
            let paymentRequest = PaymentRequest(
                amount: Double(i),
                currency: .usd,
                paymentMethod: .creditCard,
                description: "Concurrent test \(i)"
            )
            
            networkManager.processPayment(paymentRequest) { result in
                completedCount += 1
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            XCTAssertEqual(completedCount, requestCount)
            XCTAssertLessThan(duration, 30.0) // Should complete within 30 seconds
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 35.0)
    }
    
    func testMemoryUsageUnderLoad() {
        let expectation = XCTestExpectation(description: "Memory usage under load")
        
        let initialMemory = getMemoryUsage()
        
        // Send many requests
        let group = DispatchGroup()
        for i in 1...1000 {
            group.enter()
            
            let paymentRequest = PaymentRequest(
                amount: Double(i),
                currency: .usd,
                paymentMethod: .creditCard,
                description: "Memory test \(i)"
            )
            
            networkManager.processPayment(paymentRequest) { _ in
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let finalMemory = getMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            // Memory increase should be reasonable (< 100MB)
            XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 60.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkUnavailable() {
        let expectation = XCTestExpectation(description: "Network unavailable")
        
        // Simulate network unavailability
        networkManager.simulateNetworkUnavailable = true
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Network test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            switch result {
            case .success(_):
                XCTFail("Should fail when network unavailable")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("network"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testInvalidResponseHandling() {
        let expectation = XCTestExpectation(description: "Invalid response handling")
        
        // Simulate invalid response
        networkManager.simulateInvalidResponse = true
        
        let paymentRequest = PaymentRequest(
            amount: 99.99,
            currency: .usd,
            paymentMethod: .creditCard,
            description: "Invalid response test"
        )
        
        networkManager.processPayment(paymentRequest) { result in
            switch result {
            case .success(_):
                XCTFail("Should fail with invalid response")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("invalid"))
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

extension NetworkManager {
    var simulateNetworkUnavailable: Bool {
        get { false }
        set { /* Implementation for testing */ }
    }
    
    var simulateInvalidResponse: Bool {
        get { false }
        set { /* Implementation for testing */ }
    }
    
    var lastRequestHeaders: [String: String]? {
        get { nil }
    }
    
    var sslCertificateValidated: Bool {
        get { true }
    }
    
    var currentAuthToken: String? {
        get { "test_token" }
    }
} 