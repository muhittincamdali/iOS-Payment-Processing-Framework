import Foundation
import Testing
@testable import PaymentKit

@MainActor
@Suite("Store")
struct StoreTests {
    let clock = ManualClock()
    let recorder = DeliveryRecorder()
    let client: TestStoreClient

    init() {
        let clock = clock
        client = TestStoreClient(products: Fixtures.products) { clock.now }
    }

    func makeStore(catalog: [ProductDefinition] = Fixtures.catalog) -> Store {
        let clock = clock
        let recorder = recorder
        return Store(catalog: catalog, client: client, now: { clock.now }) { try recorder.deliver($0) }
    }

    @Test("start loads the catalog's products in catalog order")
    func loadsProducts() async {
        let store = makeStore(catalog: [.consumable("coins.100"), .nonConsumable("pro.lifetime", unlocks: "pro"), .consumable("missing")])
        await store.start()
        #expect(store.products.map(\.id) == ["coins.100", "pro.lifetime"])
        #expect(store.product(withID: "coins.100")?.price == (try? Money("0.99", .usd)))
        #expect(store.entitlements.isEmpty)
        store.stop()
    }

    @Test("a subscription purchase is delivered, finished and grants its entitlement until it expires")
    func subscriptionPurchase() async throws {
        let store = makeStore()
        await store.start()
        let outcome = try await store.purchase(Fixtures.monthly)
        guard case .purchased(let transaction) = outcome else {
            Issue.record("expected a purchase, got \(outcome)")
            return
        }
        #expect(store.hasEntitlement("pro"))
        #expect(store.entitlements.map(\.productID) == ["pro.monthly"])
        #expect(await client.finishedTransactionIDs == [transaction.id])
        #expect(recorder.transactions.map(\.id) == [transaction.id])

        let expiration = try #require(transaction.expirationDate)
        clock.advance(by: expiration.timeIntervalSince(clock.now))
        #expect(!store.hasEntitlement("pro"), "access ends at the expiration date even before a refresh")
        await store.refreshEntitlements()
        #expect(store.entitlements.isEmpty)
        store.stop()
    }

    @Test("a consumable is delivered with its quantity and grants no entitlement")
    func consumablePurchase() async throws {
        let store = makeStore()
        await store.start()
        try await store.purchase(Fixtures.coins, options: PurchaseOptions(quantity: 3))
        #expect(recorder.transactions.map(\.purchasedQuantity) == [3])
        #expect(store.entitlements.isEmpty)
        #expect(await client.unfinishedTransactionIDs.isEmpty)
        store.stop()
    }

    @Test("quantities are checked before the sheet shows", arguments: [0, -1, 11, Int.max])
    func invalidQuantity(quantity: Int) async {
        let store = makeStore()
        await #expect(throws: StoreError.invalidQuantity(quantity)) {
            try await store.purchase(Fixtures.coins, options: PurchaseOptions(quantity: quantity))
        }
        #expect(await client.purchaseCount == 0)
    }

    @Test("only consumables can be bought more than once at a time")
    func quantityForNonConsumable() async {
        let store = makeStore()
        await #expect(throws: StoreError.invalidQuantity(2)) {
            try await store.purchase(Fixtures.lifetime, options: PurchaseOptions(quantity: 2))
        }
    }

    @Test("products outside the catalog are refused")
    func notInCatalog() async {
        let store = makeStore(catalog: [.consumable("coins.100")])
        await #expect(throws: StoreError.productNotFound("pro.lifetime")) { try await store.purchase(Fixtures.lifetime) }
    }

    @Test("a cancelled purchase changes nothing")
    func cancelled() async throws {
        await client.setPurchaseBehavior(.cancel, for: "pro.lifetime")
        let store = makeStore()
        await store.start()
        #expect(try await store.purchase(Fixtures.lifetime) == .cancelled)
        #expect(store.entitlements.isEmpty)
        #expect(recorder.transactions.isEmpty)
        #expect(store.purchasingProductID == nil)
        store.stop()
    }

    @Test("an Ask to Buy purchase is granted when the approval arrives as an update")
    func pendingThenApproved() async throws {
        await client.setPurchaseBehavior(.pending, for: "pro.lifetime")
        let store = makeStore()
        await store.start()
        #expect(try await store.purchase(Fixtures.lifetime) == .pending)
        #expect(!store.hasEntitlement("pro"))

        let approved = try await client.approvePendingPurchase(of: "pro.lifetime")
        #expect(await eventually { store.hasEntitlement("pro") })
        #expect(store.entitlements.first?.expirationDate == nil)
        #expect(await client.finishedTransactionIDs == [approved.id])
        store.stop()
    }

    @Test("a transaction that fails verification is never delivered or finished")
    func unverifiedPurchase() async {
        await client.setPurchaseBehavior(.failVerification, for: "pro.lifetime")
        let store = makeStore()
        await store.start()
        await #expect(throws: StoreError.verificationFailed(productID: "pro.lifetime", reason: "invalidSignature")) {
            try await store.purchase(Fixtures.lifetime)
        }
        #expect(!store.hasEntitlement("pro"))
        #expect(recorder.transactions.isEmpty)
        #expect(await client.finishedTransactionIDs.isEmpty)
        store.stop()
    }

    @Test("an unverified update is reported and ignored")
    func unverifiedUpdate() async throws {
        let store = makeStore()
        await store.start()
        try await client.sendUnverifiedUpdate(for: "pro.lifetime")
        #expect(await eventually { store.lastError == .verificationFailed(productID: "pro.lifetime", reason: "invalidSignature") })
        #expect(!store.hasEntitlement("pro"))
        #expect(await client.finishedTransactionIDs.isEmpty)
        store.stop()
    }

    @Test("a failed delivery leaves the transaction unfinished and it is delivered on the next start")
    func redeliveryAfterFailure() async throws {
        recorder.setFailing(true)
        let first = makeStore()
        await first.start()
        await #expect(throws: StoreError.self) { try await first.purchase(Fixtures.coins) }
        let unfinished = await client.unfinishedTransactionIDs
        #expect(unfinished.count == 1)
        #expect(recorder.transactions.isEmpty)
        first.stop()

        recorder.setFailing(false)
        let relaunched = makeStore()
        await relaunched.start()
        #expect(recorder.transactions.map(\.id) == unfinished)
        #expect(await client.unfinishedTransactionIDs.isEmpty)
        relaunched.stop()
    }

    @Test("the purchase error for a failed delivery names the transaction")
    func deliveryFailureError() async throws {
        recorder.setFailing(true)
        let store = makeStore()
        await store.start()
        do {
            try await store.purchase(Fixtures.coins)
            Issue.record("expected the delivery to fail")
        } catch {
            let id = try #require(await client.unfinishedTransactionIDs.first)
            #expect(error == .deliveryFailed(transactionID: id, reason: "The wallet service is offline."))
        }
        store.stop()
    }

    @Test("a refund removes access and is delivered again with its revocation date")
    func refund() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.lifetime) else {
            Issue.record("expected a purchase")
            return
        }
        #expect(store.hasEntitlement("pro"))

        try await client.refund(purchase.id)
        #expect(await eventually { !store.hasEntitlement("pro") })
        #expect(recorder.transactions.map(\.id) == [purchase.id, purchase.id])
        #expect(recorder.transactions.last?.revocationDate != nil)
        store.stop()
    }

    @Test("renewals and purchases on other devices arrive as updates")
    func renewalAndOtherDevice() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let first) = try await store.purchase(Fixtures.monthly) else {
            Issue.record("expected a purchase")
            return
        }
        clock.advance(by: 20 * 86_400)
        let renewal = try await client.renew("pro.monthly")
        #expect(renewal.originalID == first.originalID)
        #expect(await eventually { store.entitlements.first?.transactionID == renewal.id })

        try await client.purchaseOnAnotherDevice("season.pass")
        #expect(await eventually { store.hasEntitlement("season") })
        #expect(recorder.transactions.count == 3)
        store.stop()
    }

    @Test("a transaction that is both unfinished and sent as an update is delivered once")
    func deliveredOnce() async throws {
        try await client.purchaseOnAnotherDevice("pro.lifetime") // unfinished and queued as an update
        let store = makeStore()
        await store.start()
        #expect(await eventually { store.hasEntitlement("pro") })
        try await Task.sleep(for: .milliseconds(100))
        #expect(recorder.transactions.count == 1)
        #expect(await client.finishedTransactionIDs.count == 1)
        store.stop()
    }

    @Test("a second purchase while the sheet shows is refused")
    func purchaseInProgress() async throws {
        let store = makeStore()
        await store.start()
        async let first = Result { () async throws(StoreError) in try await store.purchase(Fixtures.lifetime) }
        async let second = Result { () async throws(StoreError) in try await store.purchase(Fixtures.monthly) }
        let results = await [first, second]
        let refused = results.filter { if case .failure(.purchaseInProgress) = $0 { true } else { false } }
        #expect(refused.count == 1)
        #expect(await client.purchaseCount == 1)
        store.stop()
    }

    @Test("store and network errors are passed on")
    func clientErrors() async {
        await client.setPurchaseBehavior(.fail("The network connection was lost."), for: "coins.100")
        await client.failSync(with: "Sign in to restore purchases.")
        let store = makeStore()
        await #expect(throws: StoreError.storeKit("The network connection was lost.")) { try await store.purchase(Fixtures.coins) }
        await #expect(throws: StoreError.storeKit("Sign in to restore purchases.")) { try await store.restorePurchases() }
        #expect(await client.syncCount == 1)
    }

    @Test("restoring syncs and recomputes the entitlements")
    func restore() async throws {
        try await client.purchaseOnAnotherDevice("pro.yearly")
        let store = makeStore()
        try await store.restorePurchases()
        #expect(await client.syncCount == 1)
        #expect(store.hasEntitlement("pro"))
    }

    @Test("start is idempotent and stop ends the update listener")
    func startStop() async throws {
        let store = makeStore()
        await store.start()
        await store.start()
        store.stop()
        try await client.purchaseOnAnotherDevice("pro.lifetime")
        try await Task.sleep(for: .milliseconds(100))
        #expect(recorder.transactions.isEmpty)
    }
}

@Suite("Store timing helpers")
struct StoreTimingTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("expiry refresh delays are clamped and never trap", arguments: [
        (TimeInterval(30), Duration.seconds(30)),
        (0.0004, .seconds(1)),
        (-500, .seconds(1)),
        (1e300, .seconds(86_400)),
        (.infinity, .seconds(86_400)),
        (.nan, .seconds(86_400))
    ])
    func refreshDelay(offset: TimeInterval, expected: Duration) {
        let date = offset.isFinite ? now.addingTimeInterval(offset) : Date(timeIntervalSinceReferenceDate: offset)
        #expect(Store.refreshDelay(until: date, now: now) == expected)
    }

    @Test("distant dates use the longest delay")
    func distantDates() {
        #expect(Store.refreshDelay(until: .distantFuture, now: now) == .seconds(86_400))
        #expect(Store.refreshDelay(until: .distantPast, now: now) == .seconds(1))
    }

    @Test("the recent set forgets the oldest entries past its capacity")
    func recentSet() {
        var set = RecentSet<Int>(capacity: 3)
        for value in [1, 2, 3, 2, 4] { set.insert(value) }
        #expect(set.count == 3)
        #expect(!set.contains(1))
        #expect(set.contains(2) && set.contains(3) && set.contains(4))
        #expect(set.order == [2, 3, 4])
        var tiny = RecentSet<Int>(capacity: 0)
        tiny.insert(7)
        tiny.insert(8)
        #expect(tiny.count == 1)
    }
}
