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
        return LabModel(ledger: ConsumableLedger(fileURL: nil), defaults: defaults, server: server)
    }

    private func started(_ model: LabModel) async throws -> Store {
        try await started(model.store)
    }

    private func started(_ store: Store) async throws -> Store {
        await store.start()
        try #require(
            store.products.count == 4,
            "Products.storekit has four products; loaded \(store.products.map(\.id)), error: \(String(describing: store.lastError))"
        )
        return store
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

    @Test("coins are credited with the purchased quantity and can be spent")
    func coins() async throws {
        let model = makeModel()
        let store = try await started(model)
        let coins = try #require(store.product(withID: "coins.100"))
        try await store.purchase(coins, options: model.purchaseOptions(quantity: 2))
        #expect(store.balance(of: "coins") == 200)
        #expect(store.entitlements.isEmpty)
        try await store.spend(150, of: "coins")
        #expect(store.balance(of: "coins") == 50)
        await #expect(throws: ConsumableLedger.Failure.insufficientBalance(account: "coins", balance: 50, requested: 51)) {
            try await store.spend(51, of: "coins")
        }
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

    // StoreKit does not tell the app about the refund of a finished consumable: it arrives
    // neither through Transaction.updates nor as unfinished, also not after a relaunch, while the
    // refund of a non-consumable made right after it does. Only the server learns of it, from a
    // REFUND notification. If this test fails, StoreKit has started sending these refunds, and
    // what the documentation says about coins and refunds must change.
    @Test("a refund of finished coins does not reach the app, so the ledger on the device keeps them")
    func coinsRefund() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        let delivered = DeliveredChanges()
        let deliver: Store.Delivery = { change in await delivered.append(change) }
        let store = try await started(Store(catalog: Catalog.products, client: AppStoreClient(), ledger: ledger, deliver: deliver))
        let coins = try #require(store.product(withID: "coins.100"))
        let lifetime = try #require(store.product(withID: "pro.lifetime"))
        guard case .purchased(let pack) = try await store.purchase(coins),
              case .purchased(let unlock) = try await store.purchase(lifetime)
        else {
            Issue.record("expected two purchases")
            return
        }
        #expect(store.balance(of: "coins") == 100)

        try session.refundTransaction(identifier: UInt(pack.id))
        try session.refundTransaction(identifier: UInt(unlock.id))
        #expect(session.allTransactions().first { $0.identifier == UInt(pack.id) }?.cancelDate != nil, "StoreKit refunded the coins")
        #expect(await eventually(timeout: .seconds(15)) { await delivered.revokedIDs.contains(unlock.id) })
        var unfinished: [UInt64] = []
        for await result in Transaction.unfinished { unfinished.append(result.unsafePayloadValue.id) }
        #expect(!unfinished.contains(pack.id))
        store.stop()

        let relaunched = Store(catalog: Catalog.products, client: AppStoreClient(), ledger: ledger, deliver: deliver)
        await relaunched.start()
        #expect(!relaunched.hasEntitlement("pro"))
        let coinsRefundArrived = await eventually(timeout: .seconds(3)) { await delivered.revokedIDs.contains(pack.id) }
        #expect(!coinsRefundArrived, "StoreKit now sends the refund of a finished consumable")
        #expect(relaunched.balance(of: "coins") == 100)
        relaunched.stop()
    }

    // The other side of the test above: while a pack is unfinished because its delivery failed,
    // StoreKit does send its refund, and the ledger then credits the pack nothing.
    @Test("a refund of coins whose delivery failed reaches the app and credits nothing")
    func unfinishedCoinsRefund() async throws {
        let delivered = DeliveredChanges()
        let deliver: Store.Delivery = { change in
            if case .granted = change { throw URLError(.notConnectedToInternet) } // the server is down
            await delivered.append(change)
        }
        let store = try await started(Store(catalog: Catalog.products, client: AppStoreClient(), ledger: ConsumableLedger(fileURL: nil), deliver: deliver))
        let coins = try #require(store.product(withID: "coins.100"))
        await #expect(throws: StoreError.self) { try await store.purchase(coins) }
        var unfinished: [UInt64] = []
        for await result in Transaction.unfinished { unfinished.append(result.unsafePayloadValue.id) }
        let pack = try #require(unfinished.first)

        try session.refundTransaction(identifier: UInt(pack))
        #expect(await eventually(timeout: .seconds(15)) { await delivered.revokedIDs.contains(pack) })
        unfinished = []
        for await result in Transaction.unfinished { unfinished.append(result.unsafePayloadValue.id) }
        #expect(unfinished.isEmpty, "the refund is finished, and the purchase with it")
        #expect(store.balance(of: "coins") == 0)
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
        session.timeRate = .monthlyRenewalEveryThirtySeconds
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

    @Test("a subscription the App Store could not renew keeps Pro through its Billing Grace Period")
    func billingGracePeriod() async throws {
        // The first paid renewal after the free week fails and the subscription enters StoreKit's
        // billing retry with a grace period; one day passes every second.
        session.timeRate = .monthlyRenewalEveryThirtySeconds
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        let model = makeModel()
        let store = try await started(model)
        let monthly = try #require(store.product(withID: "pro.monthly"))
        guard case .purchased(let transaction) = try await store.purchase(monthly, options: model.purchaseOptions()) else {
            Issue.record("expected a purchase")
            return
        }
        let expiration = try #require(transaction.expirationDate)
        let groupID = try #require(monthly.subscription?.groupID)

        // Wait until StoreKit reports the subscription in its grace period.
        var graceEnd: Date?
        let inGracePeriod = await eventually(timeout: .seconds(60)) {
            let statuses = (try? await Product.SubscriptionInfo.status(for: groupID)) ?? []
            graceEnd = statuses.first { $0.state == .inGracePeriod }.flatMap { try? $0.renewalInfo.payloadValue.gracePeriodExpirationDate }
            return graceEnd != nil
        }
        try #require(inGracePeriod, "StoreKit did not enter the grace period after \(expiration)")
        let end = try #require(graceEnd)
        await store.refreshEntitlements()
        #expect(Date() > expiration && Date() < end)
        #expect(store.hasEntitlement("pro"), "entitlements: \(store.entitlements)")
        #expect(store.entitlements.map(\.expirationDate) == [end], "access lasts until the grace period ends")

        // Store schedules a refresh for the end of the grace period; nothing here calls it.
        let wait = Duration.seconds(max(end.timeIntervalSinceNow, 0) + 10)
        #expect(await eventually(timeout: wait) { store.entitlements.isEmpty }, "grace period end \(end), entitlements: \(store.entitlements)")
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

/// The changes a test's `deliver` closure received.
actor DeliveredChanges {
    private(set) var changes: [TransactionChange] = []

    func append(_ change: TransactionChange) {
        changes.append(change)
    }

    var revokedIDs: Set<UInt64> {
        Set(changes.compactMap { if case .revoked(let transaction) = $0 { transaction.id } else { nil } })
    }
}
