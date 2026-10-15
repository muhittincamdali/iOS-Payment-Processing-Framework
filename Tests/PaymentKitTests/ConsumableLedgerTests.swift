import Foundation
import Testing
@testable import PaymentKit

@Suite("Consumable ledger")
struct ConsumableLedgerTests {
    @Test("a transaction credits once, however often it arrives")
    func creditOnce() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        #expect(try await ledger.credit(100, to: "coins", for: 1))
        #expect(try await !ledger.credit(100, to: "coins", for: 1))
        #expect(try await !ledger.credit(500, to: "coins", for: 1), "a repeat with another amount is still a repeat")
        #expect(try await ledger.credit(300, to: "coins", for: 2))
        #expect(try await ledger.balances() == ["coins": 400])
    }

    @Test("a refund takes the credit back once, using the credited amount")
    func revokeOnce() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        try await ledger.credit(300, to: "coins", for: 1)
        #expect(try await ledger.revoke(1, from: "coins", for: 1))
        #expect(try await !ledger.revoke(300, from: "coins", for: 1))
        #expect(try await ledger.balances() == ["coins": 0])
        #expect(try await !ledger.credit(300, to: "coins", for: 1), "a refunded transaction never credits again")
        #expect(try await ledger.balances() == ["coins": 0])
    }

    @Test("a refund that arrives before its purchase makes the purchase credit nothing")
    func refundBeforePurchase() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        #expect(try await !ledger.revoke(100, from: "coins", for: 7))
        #expect(try await ledger.hasHandled(7))
        #expect(try await !ledger.credit(100, to: "coins", for: 7))
        #expect(try await ledger.balances()["coins", default: 0] == 0)
    }

    @Test("a refund after spending leaves a negative balance and blocks spending")
    func refundAfterSpending() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        try await ledger.credit(100, to: "coins", for: 1)
        try await ledger.spend(80, of: "coins")
        try await ledger.revoke(100, from: "coins", for: 1)
        #expect(try await ledger.balances() == ["coins": -80])
        await #expect(throws: ConsumableLedger.Failure.insufficientBalance(account: "coins", balance: -80, requested: 1)) {
            try await ledger.spend(1, of: "coins")
        }
    }

    @Test("spending more than the balance changes nothing")
    func overspend() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        try await ledger.credit(50, to: "coins", for: 1)
        await #expect(throws: ConsumableLedger.Failure.insufficientBalance(account: "coins", balance: 50, requested: 51)) {
            try await ledger.spend(51, of: "coins")
        }
        await #expect(throws: ConsumableLedger.Failure.insufficientBalance(account: "gems", balance: 0, requested: 1)) {
            try await ledger.spend(1, of: "gems")
        }
        try await ledger.spend(50, of: "coins")
        #expect(try await ledger.balances() == ["coins": 0], "an unknown account is not created by a failed spend")
    }

    @Test("amounts must be positive", arguments: [Int64(0), -1, .min])
    func invalidAmounts(amount: Int64) async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        await #expect(throws: ConsumableLedger.Failure.invalidAmount(amount)) { try await ledger.credit(amount, to: "coins", for: 1) }
        await #expect(throws: ConsumableLedger.Failure.invalidAmount(amount)) { try await ledger.revoke(amount, from: "coins", for: 1) }
        await #expect(throws: ConsumableLedger.Failure.invalidAmount(amount)) { try await ledger.spend(amount, of: "coins") }
        #expect(try await !ledger.hasHandled(1))
    }

    @Test("account names must have 1 to 64 characters")
    func invalidAccounts() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        let long = String(repeating: "c", count: 65)
        let manyBytes = String(repeating: "👨‍👩‍👧‍👦", count: 20) // 20 characters, 500 bytes
        for account in ["", long, manyBytes] {
            await #expect(throws: ConsumableLedger.Failure.invalidAccount(account)) { try await ledger.credit(1, to: account, for: 1) }
        }
        #expect(try await ledger.credit(1, to: String(repeating: "c", count: 64), for: 1))
    }

    @Test("a balance never wraps around")
    func overflow() async throws {
        let ledger = ConsumableLedger(fileURL: nil)
        try await ledger.credit(.max, to: "coins", for: 1)
        await #expect(throws: ConsumableLedger.Failure.overflow(account: "coins")) { try await ledger.credit(1, to: "coins", for: 2) }
        #expect(try await ledger.balances() == ["coins": .max])
        #expect(try await !ledger.hasHandled(2), "a failed credit is not remembered")
        try await ledger.spend(.max, of: "coins")
        try await ledger.revoke(.max, from: "coins", for: 1)
        #expect(try await ledger.balances() == ["coins": -.max])
    }

    @Test("balances and handled transactions survive a relaunch")
    func persistence() async throws {
        let url = temporaryLedgerURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let first = ConsumableLedger(fileURL: url)
        try await first.credit(100, to: "coins", for: 1)
        try await first.credit(5, to: "gems", for: 2)
        try await first.spend(30, of: "coins")

        let relaunched = ConsumableLedger(fileURL: url)
        #expect(try await relaunched.balances() == ["coins": 70, "gems": 5])
        #expect(try await !relaunched.credit(100, to: "coins", for: 1))
        try await relaunched.revoke(5, from: "gems", for: 2)
        #expect(try await ConsumableLedger(fileURL: url).balances() == ["coins": 70, "gems": 0])
    }

    @Test("a failed write changes nothing, so the transaction can be tried again")
    func unwritable() async throws {
        let directory = temporaryLedgerURL().deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blocker = directory.appending(path: "blocker")
        try Data("not a directory".utf8).write(to: blocker)
        let ledger = ConsumableLedger(fileURL: blocker.appending(path: "ledger.json"))

        await #expect(throws: ConsumableLedger.Failure.self) { try await ledger.credit(100, to: "coins", for: 1) }
        #expect(try await ledger.balances().isEmpty)
        #expect(try await !ledger.hasHandled(1))
    }

    @Test("damaged, inconsistent or oversized files are reported, not trusted")
    func damagedFiles() async throws {
        let url = temporaryLedgerURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let inconsistent = LedgerState(
            balances: ["coins": 100],
            records: [1: LedgerState.Record(account: "coins", amount: 100, isRevoked: false)],
            order: [1, 1]
        )
        let negative = LedgerState(
            balances: ["coins": 100],
            records: [1: LedgerState.Record(account: "coins", amount: -100, isRevoked: false)],
            order: [1]
        )
        let files: [Data] = [
            Data("{ not json".utf8),
            Data("[]".utf8),
            try JSONEncoder().encode(inconsistent),
            try JSONEncoder().encode(negative),
            Data(count: ConsumableLedger.maximumFileSize + 1)
        ]
        for data in files {
            try data.write(to: url)
            let ledger = ConsumableLedger(fileURL: url)
            await #expect(throws: ConsumableLedger.Failure.self) { try await ledger.balances() }
            await #expect(throws: ConsumableLedger.Failure.self) { try await ledger.credit(1, to: "coins", for: 2) }
            #expect(try Data(contentsOf: url) == data, "a damaged file is left for inspection, not overwritten")
        }
    }

    @Test("only the most recent transactions are remembered")
    func capacity() throws {
        var state = LedgerState()
        let record = LedgerState.Record(account: "coins", amount: 1, isRevoked: false)
        for id in 1...UInt64(ConsumableLedger.capacity + 2) {
            state.remember(id, record)
        }
        state.remember(5, record) // a repeat does not move or duplicate an entry
        #expect(state.records.count == ConsumableLedger.capacity)
        #expect(state.order.count == ConsumableLedger.capacity)
        #expect(state.records[1] == nil && state.records[2] == nil)
        #expect(state.order.first == 3)
        try state.validate()
    }

    @Test("the balance depends only on which transactions were refunded, not on the order or repeats of events")
    func orderIndependence() async throws {
        var generator = SeededGenerator(seed: 20_261_015)
        for _ in 0..<200 {
            let count = Int.random(in: 1...12, using: &generator)
            let amounts = (0..<count).map { _ in Int64.random(in: 1...1_000, using: &generator) }
            let refunded = Set((0..<count).filter { _ in Bool.random(using: &generator) })

            var events: [(index: Int, isRefund: Bool)] = []
            for index in 0..<count {
                // Every purchase arrives one to three times; refunds one or two times.
                for _ in 0..<Int.random(in: 1...3, using: &generator) { events.append((index, false)) }
                if refunded.contains(index) {
                    for _ in 0..<Int.random(in: 1...2, using: &generator) { events.append((index, true)) }
                }
            }
            events.shuffle(using: &generator)

            let ledger = ConsumableLedger(fileURL: nil)
            for event in events {
                let id = UInt64(event.index + 1)
                if event.isRefund {
                    try await ledger.revoke(amounts[event.index], from: "coins", for: id)
                } else {
                    try await ledger.credit(amounts[event.index], to: "coins", for: id)
                }
            }
            let expected = amounts.indices.filter { !refunded.contains($0) }.reduce(Int64(0)) { $0 + amounts[$1] }
            #expect(try await ledger.balances()["coins", default: 0] == expected, "events: \(events)")
        }
    }
}
