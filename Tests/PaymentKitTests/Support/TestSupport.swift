import Foundation
@testable import PaymentKit

/// A clock tests move forward by hand.
final class ManualClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        self.current = start
    }

    var now: Date {
        lock.withLock { current }
    }

    func advance(by seconds: TimeInterval) {
        lock.withLock { current += seconds }
    }
}

/// Records what a store's `deliver` closure received, and can fail on demand.
final class DeliveryRecorder: @unchecked Sendable {
    struct Failure: Error, LocalizedError {
        var errorDescription: String? { "The wallet service is offline." }
    }

    private let lock = NSLock()
    private var received: [StoreTransaction] = []
    private var failing = false

    var transactions: [StoreTransaction] {
        lock.withLock { received }
    }

    func setFailing(_ value: Bool) {
        lock.withLock { failing = value }
    }

    func deliver(_ transaction: StoreTransaction) throws {
        try lock.withLock {
            if failing { throw Failure() }
            received.append(transaction)
        }
    }
}

/// Waits until `condition` holds, for work that arrives through an `AsyncStream`.
@MainActor
func eventually(timeout: Duration = .seconds(5), _ condition: @MainActor () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while clock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return await condition()
}

enum Fixtures {
    static let monthly = StoreProduct.preview(id: "pro.monthly", kind: .autoRenewable, price: "4.99")
    static let yearly = StoreProduct.preview(id: "pro.yearly", kind: .autoRenewable, price: "39.99", period: SubscriptionPeriod(1, .year))
    static let lifetime = StoreProduct.preview(id: "pro.lifetime", kind: .nonConsumable, price: "99.99")
    static let coins = StoreProduct.preview(id: "coins.100", kind: .consumable, price: "0.99")
    static let season = StoreProduct.preview(id: "season.pass", kind: .nonRenewable, price: "9.99")

    static let products = [monthly, yearly, lifetime, coins, season]

    static let catalog: [ProductDefinition] = [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        .consumable("coins.100"),
        .nonRenewing("season.pass", unlocks: "season", lasts: SubscriptionPeriod(3, .month))
    ]
}
