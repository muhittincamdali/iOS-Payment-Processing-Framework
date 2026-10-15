import Foundation
import PaymentKit
import StoreKit
import StoreKitTest
import Testing
@testable import PaymentLab

/// Runs PaymentKit's `Store` against real StoreKit, driven by Products.storekit through
/// `SKTestSession`: purchases, Ask to Buy, refunds and expiry go through the App Store
/// simulation in Xcode, and the transactions carry real signed JWS.
///
/// With `PAYMENTLAB_SERVER_URL` set (CI sets `TEST_RUNNER_PAYMENTLAB_SERVER_URL`), purchases
/// are also verified by Examples/ReceiptServer before they are finished.
@MainActor
@Suite("StoreKit end to end", .serialized)
struct StoreKitEndToEndTests {
    let session: SKTestSession

    init() async throws {
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.storefront = "USA"
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
        // Clearing takes effect asynchronously; start each test without entitlements.
        let cleared = await eventually {
            var count = 0
            for await _ in Transaction.currentEntitlements { count += 1 }
            return count == 0
        }
        try #require(cleared, "StoreKit still reports entitlements from an earlier test")
    }

    private func makeModel(server: ReceiptServerClient? = nil) -> LabModel {
        let name = "PaymentLabTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        return LabModel(defaults: defaults, server: server)
    }

    private func started(_ model: LabModel) async throws -> Store {
        await model.store.start()
        try #require(
            model.store.products.count == 4,
            "Products.storekit has four products; loaded \(model.store.products.map(\.id)), error: \(String(describing: model.store.lastError))"
        )
        return model.store
    }

    @Test("products load from the StoreKit configuration with exact prices")
    func products() async throws {
        let model = makeModel()
        let store = try await started(model)
        // StoreKit testing parses the configuration's prices with the device's locale: in a
        // decimal-comma locale such as tr_TR, "4.99" becomes 4. Run the simulator in English (US).
        try #require(Locale.current.decimalSeparator == ".", "Run the simulator with a period as the decimal separator")
        #expect(store.products.map(\.id) == ["pro.monthly", "pro.yearly", "pro.lifetime", "coins.100"])
        let monthly = try #require(store.product(withID: "pro.monthly"))
        #expect(monthly.price == (try Money("4.99", .usd)), "price \(monthly.price), shown as \(monthly.displayPrice)")
        #expect(monthly.subscription?.period == SubscriptionPeriod(1, .month))
        #expect(monthly.subscription?.hasIntroductoryOffer == true)
        #expect(store.product(withID: "coins.100")?.kind == .consumable)
        store.stop()
    }

    @Test("a subscription purchase unlocks Pro with a signed transaction for the account")
    func subscription() async throws {
        let model = makeModel()
        let store = try await started(model)
        let product = try #require(store.product(withID: "pro.monthly"))
        guard case .purchased(let transaction) = try await store.purchase(product, options: model.purchaseOptions()) else {
            Issue.record("expected a purchase")
            return
        }
        #expect(store.hasEntitlement("pro"))
        #expect(transaction.environment == "Xcode")
        #expect(transaction.appAccountToken == model.appAccountToken)
        #expect(transaction.signedTransaction.split(separator: ".").count == 3)
        #expect(transaction.expirationDate != nil)
        store.stop()
    }

    @Test("coins are credited with the purchased quantity")
    func coins() async throws {
        let model = makeModel()
        let store = try await started(model)
        let coins = try #require(store.product(withID: "coins.100"))
        try await store.purchase(coins, options: model.purchaseOptions(quantity: 2))
        #expect(model.wallet.balance == 200)
        #expect(store.entitlements.isEmpty)
        store.stop()
    }

    @Test("a refund in StoreKit removes Pro")
    func refund() async throws {
        let model = makeModel()
        let store = try await started(model)
        let lifetime = try #require(store.product(withID: "pro.lifetime"))
        guard case .purchased(let transaction) = try await store.purchase(lifetime, options: model.purchaseOptions()) else {
            Issue.record("expected a purchase")
            return
        }
        #expect(store.hasEntitlement("pro"))
        try session.refundTransaction(identifier: UInt(transaction.id))
        #expect(await eventually { await store.refreshEntitlements(); return !store.hasEntitlement("pro") })
        store.stop()
    }

    @Test("an Ask to Buy purchase unlocks Pro once it is approved")
    func askToBuy() async throws {
        session.askToBuyEnabled = true
        let model = makeModel()
        let store = try await started(model)
        let yearly = try #require(store.product(withID: "pro.yearly"))
        #expect(try await store.purchase(yearly, options: model.purchaseOptions()) == .pending)
        #expect(!store.hasEntitlement("pro"))

        let pending = try #require(session.allTransactions().first { $0.pendingAskToBuyConfirmation })
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        #expect(await eventually { store.hasEntitlement("pro") })
        store.stop()
    }

    @Test("a subscription that runs out is removed when it expires, without a manual refresh")
    func expiry() async throws {
        // One day passes every second, so the monthly plan's free week ends after about 7 s.
        session.timeRate = .oneSecondIsOneDay
        let model = makeModel()
        let store = try await started(model)
        let monthly = try #require(store.product(withID: "pro.monthly"))
        guard case .purchased(let transaction) = try await store.purchase(monthly, options: model.purchaseOptions()) else {
            Issue.record("expected a purchase")
            return
        }
        try session.disableAutoRenewForTransaction(identifier: UInt(transaction.id))
        let expiration = try #require(transaction.expirationDate)
        #expect(expiration.timeIntervalSinceNow < 60, "the accelerated clock shortens the free week")
        #expect(store.entitlements.map(\.productID) == ["pro.monthly"])
        // Store schedules a refresh for the expiration date; nothing here calls refreshEntitlements().
        #expect(await eventually(timeout: .seconds(60)) { store.entitlements.isEmpty }, "entitlements: \(store.entitlements)")
        #expect(!store.hasEntitlement("pro"))
        store.stop()
    }

    @Test(
        "the receipt server verifies the purchase before it is finished",
        .enabled(if: ReceiptServerClient.fromEnvironment() != nil, "set PAYMENTLAB_SERVER_URL to run it")
    )
    func serverVerification() async throws {
        let model = makeModel(server: ReceiptServerClient.fromEnvironment())
        let store = try await started(model)
        let yearly = try #require(store.product(withID: "pro.yearly"))
        try await store.purchase(yearly, options: model.purchaseOptions())
        let answer = try #require(model.serverStatus.lastAnswer)
        #expect(answer.environment == "Xcode")
        #expect(answer.account == "token:\(model.appAccountToken.uuidString.lowercased())")
        #expect(answer.entitlements.map(\.name) == ["pro"])
        #expect(store.hasEntitlement("pro"))
        store.stop()
    }
}

@MainActor
func eventually(timeout: Duration = .seconds(10), _ condition: @MainActor () async -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while clock.now < deadline {
        if await condition() { return true }
        try? await Task.sleep(for: .milliseconds(100))
    }
    return await condition()
}
