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
