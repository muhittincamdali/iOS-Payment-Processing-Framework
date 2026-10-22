import Foundation
import Observation
import PaymentKit

/// The products Payment Lab sells; the IDs match Products.storekit and the receipt server.
enum Catalog {
    static let products: [ProductDefinition] = [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        // PaymentKit's ledger credits 100 coins per pack once per transaction. StoreKit sends
        // the app a pack's refund only while the pack is unfinished; the refund of a finished
        // pack reaches only the receipt server, whose balance leaves it out.
        .consumable("coins.100", credits: 100, to: "coins")
    ]
}

/// Sends transactions to Examples/ReceiptServer, which verifies them with Apple's App Store
/// Server Library and answers with the account's entitlements.
struct ReceiptServerClient: Sendable {
    struct Answer: Decodable, Sendable, Equatable {
        struct Entitlement: Decodable, Sendable, Equatable {
            let name: String
            let productId: String
        }

        let account: String
        let environment: String
        let entitlements: [Entitlement]
        let coins: Int
    }

    struct Failure: LocalizedError {
        let status: Int
        let message: String
        var errorDescription: String? { "The receipt server answered \(status): \(message)" }
    }

    let baseURL: URL
    var session: URLSession = .shared

    /// The server from the `PAYMENTLAB_SERVER_URL` environment variable, if it is set.
    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> ReceiptServerClient? {
        guard let text = environment["PAYMENTLAB_SERVER_URL"], let url = URL(string: text),
              let scheme = url.scheme, ["http", "https"].contains(scheme)
        else { return nil }
        return ReceiptServerClient(baseURL: url)
    }

    func verify(_ transaction: StoreTransaction) async throws -> Answer {
        var request = URLRequest(url: baseURL.appending(path: "v1/transactions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["signedTransaction": transaction.signedTransaction])
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["message"] ?? "no details"
            throw Failure(status: status, message: message)
        }
        return try JSONDecoder().decode(Answer.self, from: data)
    }
}

/// What the receipt server said about the last transaction.
@MainActor
@Observable
final class ServerStatus {
    private(set) var lastAnswer: ReceiptServerClient.Answer?

    func record(_ answer: ReceiptServerClient.Answer) {
        lastAnswer = answer
    }
}

/// Everything the screens share.
@MainActor
@Observable
final class LabModel {
    let store: Store
    let server: ReceiptServerClient?
    let serverStatus: ServerStatus
    /// Ties purchases to this installation's account on the server.
    let appAccountToken: UUID

    init(
        client: (any StoreClient)? = nil,
        ledger: ConsumableLedger = .standard,
        defaults: UserDefaults = .standard,
        server: ReceiptServerClient? = .fromEnvironment()
    ) {
        let status = ServerStatus()
        self.serverStatus = status
        self.server = server
        if let saved = defaults.string(forKey: "account.token").flatMap(UUID.init(uuidString:)) {
            appAccountToken = saved
        } else {
            appAccountToken = UUID()
            defaults.set(appAccountToken.uuidString, forKey: "account.token")
        }

        // Delivery runs before StoreKit finishes the transaction, for purchases and refunds
        // alike. If the server is unreachable it throws, nothing is credited, and the
        // transaction comes back on the next launch. The server ignores repeats.
        let deliver: Store.Delivery = { change in
            guard let server else { return }
            let answer = try await server.verify(change.transaction)
            await status.record(answer)
        }
        store = Store(catalog: Catalog.products, client: client ?? AppStoreClient(), ledger: ledger, deliver: deliver)
    }

    func purchaseOptions(quantity: Int = 1) -> PurchaseOptions {
        PurchaseOptions(appAccountToken: appAccountToken, quantity: quantity)
    }
}
