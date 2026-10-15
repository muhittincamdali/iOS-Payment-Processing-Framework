import Foundation
import Testing
@testable import PaymentKit

@Suite("Entitlement resolver")
struct EntitlementResolverTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let resolver = EntitlementResolver(catalog: Fixtures.catalog)

    func transaction(
        _ id: UInt64,
        _ productID: String,
        _ kind: StoreProduct.Kind,
        purchased: TimeInterval = -3_600,
        expires: TimeInterval? = nil,
        revoked: Bool = false,
        upgraded: Bool = false,
        family: Bool = false
    ) -> TransactionEvent {
        TransactionEvent(
            transaction: StoreTransaction(
                id: id, productID: productID, productKind: kind,
                purchaseDate: now.addingTimeInterval(purchased),
                expirationDate: expires.map { now.addingTimeInterval($0) },
                revocationDate: revoked ? now : nil,
                isUpgraded: upgraded, isFamilyShared: family
            ),
            verification: .verified
        )
    }

    @Test("active subscriptions and lifetime purchases grant access")
    func grants() {
        let result = resolver.entitlements(from: [
            transaction(1, "pro.monthly", .autoRenewable, expires: 600),
            transaction(2, "season.pass", .nonRenewable, purchased: -86_400)
        ], at: now)
        #expect(result.map(\.name) == ["pro", "season"])
        #expect(result[0].expirationDate == now.addingTimeInterval(600))
        let seasonEnd = Calendar(identifier: .gregorian).date(byAdding: .month, value: 3, to: now.addingTimeInterval(-86_400))
        #expect(result[1].expirationDate == seasonEnd)
    }

    @Test("expired, revoked, upgraded, unverified, consumable and unknown transactions grant nothing")
    func excluded() {
        let unverified = TransactionEvent(
            transaction: StoreTransaction(id: 9, productID: "pro.lifetime", productKind: .nonConsumable, purchaseDate: now),
            verification: .unverified(reason: "invalidSignature")
        )
        let result = resolver.entitlements(from: [
            transaction(1, "pro.monthly", .autoRenewable, expires: 0),
            transaction(2, "pro.monthly", .autoRenewable, expires: -1),
            transaction(3, "pro.lifetime", .nonConsumable, revoked: true),
            transaction(4, "pro.yearly", .autoRenewable, expires: 9_999, upgraded: true),
            transaction(5, "coins.100", .consumable),
            transaction(6, "unknown.product", .nonConsumable),
            transaction(7, "pro.monthly", .autoRenewable, expires: nil),
            transaction(8, "season.pass", .nonRenewable, purchased: -200 * 86_400),
            unverified
        ], at: now)
        #expect(result.isEmpty)
    }

    @Test("a lifetime purchase wins over a subscription, then the later expiry wins")
    func bestTransactionWins() {
        let lifetime = resolver.entitlements(from: [
            transaction(1, "pro.monthly", .autoRenewable, expires: 600),
            transaction(2, "pro.lifetime", .nonConsumable),
            transaction(3, "pro.yearly", .autoRenewable, expires: 90_000)
        ], at: now)
        #expect(lifetime.map(\.transactionID) == [2])

        let later = resolver.entitlements(from: [
            transaction(1, "pro.yearly", .autoRenewable, expires: 90_000),
            transaction(2, "pro.monthly", .autoRenewable, expires: 600)
        ], at: now)
        #expect(later.map(\.transactionID) == [1])
    }

    @Test("an own purchase wins over a family-shared one")
    func ownBeatsFamily() {
        let result = resolver.entitlements(from: [
            transaction(1, "pro.lifetime", .nonConsumable, family: true),
            transaction(2, "pro.lifetime", .nonConsumable)
        ], at: now)
        #expect(result.map(\.transactionID) == [2])
        #expect(result.first?.isFamilyShared == false)
    }

    @Test("a non-renewing product without a duration grants nothing")
    func nonRenewingNeedsDuration() {
        let resolver = EntitlementResolver(catalog: [.autoRenewable("season.pass", unlocks: "season")])
        #expect(resolver.entitlements(from: [transaction(1, "season.pass", .nonRenewable)], at: now).isEmpty)
    }

    @Test("the first definition of a product identifier wins")
    func duplicateDefinitions() {
        let resolver = EntitlementResolver(catalog: [.nonConsumable("pro", unlocks: "a"), .nonConsumable("pro", unlocks: "b")])
        #expect(resolver.entitlements(from: [transaction(1, "pro", .nonConsumable)], at: now).map(\.name) == ["a"])
    }

    @Test("transaction quantities stay within StoreKit's limit", arguments: [(0, 1), (-7, 1), (3, 3), (10, 10), (11, 10), (Int.max, 10)])
    func quantities(input: Int, stored: Int) {
        let transaction = StoreTransaction(id: 1, productID: "coins.100", productKind: .consumable, purchaseDate: now, purchasedQuantity: input)
        #expect(transaction.purchasedQuantity == stored)
        #expect(100 * transaction.purchasedQuantity <= 1_000)
    }

    @Test("subscription periods are clamped, also when decoded")
    func periods() throws {
        #expect(SubscriptionPeriod(0, .day).value == 1)
        #expect(SubscriptionPeriod(-5, .day).value == 1)
        #expect(SubscriptionPeriod(.max, .year).value == SubscriptionPeriod.maximumValue)
        let decoded = try JSONDecoder().decode(SubscriptionPeriod.self, from: Data(#"{"value":9223372036854775807,"unit":"year"}"#.utf8))
        #expect(decoded.value == SubscriptionPeriod.maximumValue)
        #expect(SubscriptionPeriod(.max, .year).date(after: now) != nil)
        #expect(SubscriptionPeriod(2, .week).description == "2 weeks")
        #expect(SubscriptionPeriod(1, .month).description == "1 month")
    }
}
