import Foundation
import Testing
@testable import PaymentKit

/// Refunds, repeats and restarts must never grant, or grant twice, what was not paid for.
@MainActor
@Suite("Store integrity")
struct StoreIntegrityTests {
    let clock = ManualClock()
    let recorder = DeliveryRecorder()
    let client: TestStoreClient

    init() {
        let clock = clock
        client = TestStoreClient(products: Fixtures.products) { clock.now }
    }

    func makeStore(client: (any StoreClient)? = nil, ledger: ConsumableLedger = ConsumableLedger(fileURL: nil)) -> Store {
        let clock = clock
        let recorder = recorder
        return Store(catalog: Fixtures.catalog, client: client ?? self.client, ledger: ledger, now: { clock.now }) { try recorder.deliver($0) }
    }

    @Test("a consumable credits its balance once per transaction and a refund takes it back")
    func consumableCreditAndRefund() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.coins, options: PurchaseOptions(quantity: 3)) else {
            Issue.record("expected a purchase")
            return
        }
        #expect(store.balance(of: "coins") == 300)

        try await client.redeliver(purchase.id)
        try await Task.sleep(for: .milliseconds(50))
        #expect(store.balance(of: "coins") == 300, "a repeated update credits nothing")

        try await client.refund(purchase.id)
        #expect(await eventually { store.balance(of: "coins") == 0 })
        try await client.redeliver(purchase.id) // the refunded transaction again
        try await Task.sleep(for: .milliseconds(50))
        #expect(store.balance(of: "coins") == 0, "a repeated refund takes back nothing more")
        #expect(recorder.changes.map { if case .granted = $0 { "granted" } else { "revoked" } } == ["granted", "revoked"])
        store.stop()
    }

    @Test("a refund after the coins were spent leaves a negative balance")
    func refundAfterSpending() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.coins) else {
            Issue.record("expected a purchase")
            return
        }
        try await store.spend(70, of: "coins")
        #expect(store.balance(of: "coins") == 30)
        try await client.refund(purchase.id)
        #expect(await eventually { store.balance(of: "coins") == -70 })
        await #expect(throws: ConsumableLedger.Failure.insufficientBalance(account: "coins", balance: -70, requested: 1)) {
            try await store.spend(1, of: "coins")
        }
        store.stop()
    }

    @Test("an app that stops after crediting but before finishing credits nothing more on relaunch")
    func restartBeforeFinish() async throws {
        let url = temporaryLedgerURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let stopping = InterposingClient(client)
        await stopping.stopBeforeFinishing()

        let first = makeStore(client: stopping, ledger: ConsumableLedger(fileURL: url))
        await first.start()
        try await first.purchase(Fixtures.coins, options: PurchaseOptions(quantity: 2))
        #expect(first.balance(of: "coins") == 200)
        let unfinished = await client.unfinishedTransactionIDs
        #expect(unfinished.count == 1, "the app stopped before finish()")
        first.stop()

        let relaunched = makeStore(ledger: ConsumableLedger(fileURL: url))
        await relaunched.start()
        #expect(relaunched.balance(of: "coins") == 200)
        #expect(await client.unfinishedTransactionIDs.isEmpty, "the repeat is finished this time")
        #expect(recorder.transactions.map(\.id) == unfinished + unfinished, "deliver runs again, so it must be idempotent")
        relaunched.stop()
    }

    @Test("a ledger that cannot be saved leaves the purchase unfinished and uncredited")
    func unwritableLedger() async throws {
        let directory = temporaryLedgerURL().deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blocker = directory.appending(path: "blocker")
        try Data("not a directory".utf8).write(to: blocker)

        let store = makeStore(ledger: ConsumableLedger(fileURL: blocker.appending(path: "ledger.json")))
        await store.start()
        await #expect(throws: StoreError.self) { try await store.purchase(Fixtures.coins) }
        #expect(store.balance(of: "coins") == 0)
        #expect(await client.unfinishedTransactionIDs.count == 1)
        store.stop()
    }

    @Test("an upgrade moves access to the higher subscription")
    func upgrade() async throws {
        let store = makeStore()
        await store.start()
        try await store.purchase(Fixtures.monthly)
        let yearly = try await client.upgrade(from: "pro.monthly", to: "pro.yearly")
        #expect(await eventually { store.entitlements.map(\.productID) == ["pro.yearly"] })
        #expect(store.entitlements.first?.transactionID == yearly.id)

        try await client.refund(yearly.id)
        #expect(await eventually { store.entitlements.isEmpty }, "the upgraded monthly subscription does not come back")
        #expect(!store.hasEntitlement("pro"))
        store.stop()
    }

    @Test("access shared by a family member ends when the sharing is revoked")
    func familySharingRevoked() async throws {
        let store = makeStore()
        await store.start()
        let shared = try await client.shareFromFamily("pro.lifetime")
        #expect(await eventually { store.entitlements.first?.isFamilyShared == true })
        try await client.refund(shared.id)
        #expect(await eventually { !store.hasEntitlement("pro") })
        store.stop()
    }

    @Test("an expired subscription grants nothing, even when it arrives again")
    func expiredRepeat() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.monthly) else {
            Issue.record("expected a purchase")
            return
        }
        clock.advance(by: 40 * 86_400)
        try await client.redeliver(purchase.id)
        #expect(await eventually { store.entitlements.isEmpty })
        #expect(!store.hasEntitlement("pro"))
        store.stop()
    }

    @Test("an unverified repeat of a refunded purchase grants nothing")
    func unverifiedRepeat() async throws {
        let store = makeStore()
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.lifetime) else {
            Issue.record("expected a purchase")
            return
        }
        try await client.refund(purchase.id)
        #expect(await eventually { !store.hasEntitlement("pro") })
        try await client.sendUnverifiedUpdate(for: "pro.lifetime")
        #expect(await eventually { store.lastError == .verificationFailed(productID: "pro.lifetime", reason: "invalidSignature") })
        await store.refreshEntitlements()
        #expect(!store.hasEntitlement("pro"))
        store.stop()
    }

    @Test("a refresh that read the transactions before a refund cannot bring the access back")
    func staleRefresh() async throws {
        let gated = InterposingClient(client)
        let store = makeStore(client: gated)
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.lifetime) else {
            Issue.record("expected a purchase")
            return
        }

        await gated.holdNextEntitlementsRead()
        let staleRefresh = Task { await store.refreshEntitlements() } // reads "pro" and waits
        #expect(await eventually { await gated.isHoldingRead })

        try await client.refund(purchase.id)
        #expect(await eventually { !store.hasEntitlement("pro") })

        await gated.releaseHeldRead()
        await staleRefresh.value
        #expect(!store.hasEntitlement("pro"))
        #expect(store.entitlements.isEmpty)
        store.stop()
    }

    @Test("a refresh returns with what it read even while a newer refresh is still reading")
    func overlappingRefreshes() async throws {
        let gated = InterposingClient(client)
        let store = makeStore(client: gated)
        await store.start()
        guard case .purchased(let purchase) = try await store.purchase(Fixtures.lifetime) else {
            Issue.record("expected a purchase")
            return
        }
        store.stop() // no update listener: only the two refreshes below read the refund
        try await client.refund(purchase.id)
        #expect(store.hasEntitlement("pro"))

        await gated.holdNextEntitlementsRead()
        await gated.holdNextEntitlementsRead()
        let first = Task { await store.refreshEntitlements() }
        #expect(await eventually { await gated.heldReadCount == 1 })
        let second = Task { await store.refreshEntitlements() }
        #expect(await eventually { await gated.heldReadCount == 2 })

        await gated.releaseHeldRead() // the first refresh ends while the second is still reading
        await first.value
        #expect(!store.hasEntitlement("pro"))
        await gated.releaseHeldRead()
        await second.value
        #expect(store.entitlements.isEmpty)
    }

    @Test("after any order of purchases, repeats, refunds, upgrades and renewals, access and coins match what was paid for and not refunded", arguments: 0..<25)
    func randomHistories(seed: UInt64) async throws {
        var generator = SeededGenerator(seed: seed)
        let store = makeStore()
        await store.start()

        for _ in 0..<30 {
            let transactions = await client.transactions
            switch Int.random(in: 0..<9, using: &generator) {
            case 0:
                _ = try? await store.purchase(Fixtures.coins, options: PurchaseOptions(quantity: Int.random(in: 1...10, using: &generator)))
            case 1:
                try await client.purchaseOnAnotherDevice([Fixtures.monthly, Fixtures.lifetime, Fixtures.coins, Fixtures.season].randomElement(using: &generator)!.id)
            case 2, 3:
                if let target = transactions.randomElement(using: &generator) { try await client.refund(target.id) }
            case 4, 5:
                if let target = transactions.randomElement(using: &generator) { try await client.redeliver(target.id) }
            case 6:
                _ = try? await client.upgrade(from: "pro.monthly", to: "pro.yearly")
            case 7:
                _ = try? await client.renew("pro.monthly")
            default:
                clock.advance(by: Double(Int.random(in: 0...(20 * 86_400), using: &generator)))
            }
        }

        let final = await client.transactions
        let date = clock.now
        let expectedCoins = final
            .filter { $0.productID == "coins.100" && $0.revocationDate == nil }
            .reduce(Int64(0)) { $0 + 100 * Int64($1.purchasedQuantity) }
        let grantsPro = final.contains { transaction in
            ["pro.monthly", "pro.yearly", "pro.lifetime"].contains(transaction.productID)
                && transaction.revocationDate == nil && !transaction.isUpgraded
                && (transaction.expirationDate.map { $0 > date } ?? true)
        }

        let settled = await eventually {
            await client.unfinishedTransactionIDs.isEmpty && store.balance(of: "coins") == expectedCoins
        }
        #expect(settled, "seed \(seed): coins \(store.balance(of: "coins")), expected \(expectedCoins)")
        try await Task.sleep(for: .milliseconds(50))
        await store.refreshEntitlements()
        #expect(store.balance(of: "coins") == expectedCoins, "seed \(seed)")
        #expect(store.hasEntitlement("pro") == grantsPro, "seed \(seed)")
        for change in recorder.changes {
            if case .granted(let transaction) = change { #expect(transaction.revocationDate == nil) }
            if case .revoked(let transaction) = change { #expect(transaction.revocationDate != nil) }
        }
        store.stop()
    }
}
