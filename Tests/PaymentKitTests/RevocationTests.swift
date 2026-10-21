import Foundation
import Testing
@testable import PaymentKit

/// A refund or revocation is final: a copy of the same transaction read or sent before it, and
/// handed over after it, must not grant anything again.
@MainActor
@Suite("Revocations")
struct RevocationTests {
    let clock = ManualClock()
    let recorder = DeliveryRecorder()
    let client = ScriptedClient()

    func makeStore() -> Store {
        let clock = clock
        let recorder = recorder
        return Store(catalog: Fixtures.catalog, client: client, ledger: ConsumableLedger(fileURL: nil), now: { clock.now }) { try recorder.deliver($0) }
    }

    @Test("a copy from before a refund that arrives after it is not delivered, credited or finished")
    func lateCopyAfterRefund() async throws {
        let store = makeStore()
        await store.start()
        let lifetime = StoreTransaction(id: 7, productID: "pro.lifetime", productKind: .nonConsumable, purchaseDate: clock.now)
        let coins = StoreTransaction(id: 8, productID: "coins.100", productKind: .consumable, purchaseDate: clock.now, purchasedQuantity: 2)
        let refunds = [lifetime.revoked(at: clock.now), coins.revoked(at: clock.now)]

        for refund in refunds { await client.send(refund) }
        for copy in [lifetime, coins] { await client.send(copy) } // read by StoreKit before the refunds
        let season = StoreTransaction(id: 9, productID: "season.pass", productKind: .nonRenewable, purchaseDate: clock.now)
        await client.send(season) // updates are handled in order, so this one is handled last
        #expect(await eventually { await client.finishedTransactionIDs.contains(season.id) })

        #expect(recorder.changes == [.revoked(refunds[0]), .revoked(refunds[1]), .granted(season)])
        #expect(store.balance(of: "coins") == 0)
        #expect(!store.hasEntitlement("pro"))
        #expect(await client.finishedTransactionIDs == [7, 8, 9])
        store.stop()
    }

    @Test("a refunded transaction grants nothing while StoreKit still lists the copy from before the refund")
    func staleEntitlementsList() async throws {
        let store = makeStore()
        await store.start()
        let lifetime = StoreTransaction(id: 7, productID: "pro.lifetime", productKind: .nonConsumable, purchaseDate: clock.now)
        await client.setEntitlements([lifetime])
        await store.refreshEntitlements()
        #expect(store.hasEntitlement("pro"))

        await client.send(lifetime.revoked(at: clock.now))
        #expect(await eventually { recorder.changes.count == 1 })
        await store.refreshEntitlements()
        #expect(!store.hasEntitlement("pro"))
        #expect(store.entitlements.isEmpty)
        store.stop()
    }

    @Test("a refund ends access at once even when its delivery fails, and is delivered when it comes again")
    func refundWhoseDeliveryFails() async throws {
        let clock = clock
        let appStore = TestStoreClient(products: Fixtures.products) { clock.now }
        let recorder = recorder
        let store = Store(catalog: Fixtures.catalog, client: appStore, ledger: ConsumableLedger(fileURL: nil), now: { clock.now }) { try recorder.deliver($0) }
        await store.start()
        guard case .purchased(let lifetime) = try await store.purchase(Fixtures.lifetime),
              case .purchased(let yearly) = try await store.purchase(Fixtures.yearly)
        else {
            Issue.record("expected two purchases")
            return
        }
        #expect(store.entitlements.map(\.transactionID) == [lifetime.id])

        recorder.setFailing(true) // the receipt server cannot be reached
        let refunded = try await appStore.refund(lifetime.id)
        #expect(await eventually { store.lastError == .deliveryFailed(transactionID: lifetime.id, reason: "The wallet service is offline.") })
        #expect(store.entitlements.map(\.transactionID) == [yearly.id], "a refund whose delivery failed must not keep the lifetime purchase's access")
        #expect(await appStore.finishedTransactionIDs == [lifetime.id, yearly.id], "the refund is not finished, so it comes again")

        try await appStore.refund(yearly.id)
        #expect(await eventually { store.entitlements.isEmpty })
        #expect(!store.hasEntitlement("pro"))

        recorder.setFailing(false)
        try await appStore.redeliver(lifetime.id)
        #expect(await eventually { await appStore.finishedTransactionIDs == [lifetime.id, yearly.id, lifetime.id] })
        #expect(recorder.changes == [.granted(lifetime), .granted(yearly), .revoked(refunded)])
        #expect(!store.hasEntitlement("pro"))
        store.stop()
    }

    @Test("a purchase refunded while it is being delivered is neither credited nor finished when its delivery returns")
    func refundDuringDelivery() async throws {
        let clock = clock
        let appStore = TestStoreClient(products: Fixtures.products) { clock.now }
        let recorder = recorder
        let gate = DeliveryGate()
        let store = Store(catalog: Fixtures.catalog, client: appStore, ledger: ConsumableLedger(fileURL: nil), now: { clock.now }) { change in
            if case .granted = change { await gate.wait() } // the receipt server is slow
            try recorder.deliver(change)
        }
        await store.start()
        let purchasing = Task { try await store.purchase(Fixtures.coins) }
        #expect(await eventually { await gate.isWaiting })
        let pack = try #require(await appStore.unfinishedTransactions().first?.transaction)

        recorder.setFailing(true) // the refund cannot reach the server
        let refunded = try await appStore.refund(pack.id)
        #expect(await eventually { store.lastError == .deliveryFailed(transactionID: pack.id, reason: "The wallet service is offline.") })
        recorder.setFailing(false)
        await gate.open() // the purchase's delivery returns after the refund was handled
        _ = try await purchasing.value

        #expect(store.balance(of: "coins") == 0, "the refunded pack must not be credited")
        #expect(await appStore.finishedTransactionIDs.isEmpty, "finishing the purchase would finish the refund")
        #expect(await appStore.unfinishedTransactions().map(\.transaction) == [refunded])

        try await appStore.redeliver(pack.id) // StoreKit sends the refund again
        #expect(await eventually { await appStore.finishedTransactionIDs == [pack.id] })
        #expect(recorder.changes == [.granted(pack), .revoked(refunded)])
        #expect(store.balance(of: "coins") == 0)
        store.stop()
    }

    // An app update can drop a consumable from the catalog, leave it to `deliver`, or change
    // its credit; the coins its purchases credited are still in the ledger and must go back.
    @Test("a refund takes back what the ledger credited after an update changed the product", arguments: [
        [ProductDefinition](), // no longer sold
        [.consumable("coins.100")], // handed out by deliver now
        [.consumable("coins.100", credits: 0, to: "coins")], // a credit the ledger refuses
        [.consumable("coins.100", credits: 50, to: "gems")]
    ])
    func refundAfterCatalogChange(updatedCatalog: [ProductDefinition]) async throws {
        let url = temporaryLedgerURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let clock = clock
        let recorder = recorder
        let pack = StoreTransaction(id: 21, productID: "coins.100", productKind: .consumable, purchaseDate: clock.now, purchasedQuantity: 10)

        let firstVersion = Store(catalog: Fixtures.catalog, client: client, ledger: ConsumableLedger(fileURL: url), now: { clock.now }) { try recorder.deliver($0) }
        await firstVersion.start()
        await client.send(pack)
        #expect(await eventually { await client.finishedTransactionIDs == [pack.id] })
        #expect(firstVersion.balance(of: "coins") == 1_000)
        firstVersion.stop()

        let updatedClient = ScriptedClient()
        let updated = Store(catalog: updatedCatalog, client: updatedClient, ledger: ConsumableLedger(fileURL: url), now: { clock.now }) { try recorder.deliver($0) }
        await updated.start()
        let refund = pack.revoked(at: clock.now)
        await updatedClient.send(refund)
        await updatedClient.send(refund) // a repeat takes back nothing more
        let season = StoreTransaction(id: 22, productID: "season.pass", productKind: .nonRenewable, purchaseDate: clock.now)
        await updatedClient.send(season) // updates are handled in order, so this one is handled last
        #expect(await eventually { await updatedClient.finishedTransactionIDs.contains(season.id) })
        #expect(await updatedClient.finishedTransactionIDs == [pack.id, season.id])

        #expect(updated.lastError == nil)
        #expect(try await ConsumableLedger(fileURL: url).balances()["coins"] == 0, "the ledger file still holds the refunded coins")
        #expect(updated.balance(of: "coins") == 0)
        #expect(updated.balance(of: "gems") == 0)
        #expect(recorder.changes == [.granted(pack), .revoked(refund), .granted(season)])
        updated.stop()
    }
}

/// Holds a delivery until the test opens it.
actor DeliveryGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    var isWaiting: Bool { !waiters.isEmpty }

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

/// A client whose updates and entitlements the test sets by hand, so copies of one transaction
/// can arrive in any order, as when StoreKit hands over a copy it read before a refund.
actor ScriptedClient: StoreClient {
    private nonisolated let updates: AsyncStream<TransactionEvent>
    private nonisolated let continuation: AsyncStream<TransactionEvent>.Continuation
    private var entitlements: [StoreTransaction] = []
    private(set) var finishedTransactionIDs: [UInt64] = []

    init() {
        (updates, continuation) = AsyncStream.makeStream(of: TransactionEvent.self)
    }

    /// Sends a verified copy of `transaction` as an update.
    func send(_ transaction: StoreTransaction) {
        continuation.yield(TransactionEvent(transaction: transaction, verification: .verified))
    }

    /// Sets what `currentEntitlements()` returns from now on.
    func setEntitlements(_ transactions: [StoreTransaction]) {
        entitlements = transactions
    }

    func products(for ids: Set<String>) async throws -> [StoreProduct] {
        Fixtures.products.filter { ids.contains($0.id) }
    }

    func purchase(_ productID: String, options: PurchaseOptions) async throws -> PurchaseResult { .cancelled }

    func currentEntitlements() async -> [TransactionEvent] {
        entitlements.map { TransactionEvent(transaction: $0, verification: .verified) }
    }

    func unfinishedTransactions() async -> [TransactionEvent] { [] }
    nonisolated func transactionUpdates() -> AsyncStream<TransactionEvent> { updates }

    func finish(_ transaction: StoreTransaction) async {
        finishedTransactionIDs.append(transaction.id)
    }

    func sync() async throws {}
}
