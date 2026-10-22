import PaymentKit
import SwiftUI

/// In-app purchases through `Store`: subscriptions, a lifetime unlock and coins.
struct StoreScreen: View {
    let model: LabModel
    @State private var message: String?

    private var store: Store { model.store }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AccessCard(entitlement: store.entitlements.first { $0.name == "pro" }, coins: store.balance(of: "coins"))
                        .listRowInsets(EdgeInsets())
                }

                Section("Pro") {
                    ForEach(store.products.filter { $0.kind != .consumable }) { product in
                        ProductRow(product: product, isOwned: store.entitlements.contains { $0.productID == product.id }) {
                            await buy(product)
                        }
                    }
                }

                Section {
                    ForEach(store.products.filter { $0.kind == .consumable }) { product in
                        ProductRow(product: product, isOwned: false) { await buy(product) }
                    }
                } header: {
                    Text("Coins")
                } footer: {
                    Text("Coins are credited once per transaction, before StoreKit finishes it.")
                }

                Section("Receipt server") {
                    ServerRow(server: model.server, answer: model.serverStatus.lastAnswer)
                }

                Section {
                    Button("Restore Purchases") {
                        Task {
                            do {
                                try await store.restorePurchases()
                            } catch {
                                message = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .navigationTitle("Store")
            .overlay {
                if store.products.isEmpty {
                    ContentUnavailableView(
                        "No products",
                        systemImage: "bag.badge.questionmark",
                        description: Text("Run the app from Xcode with the PaymentLab scheme; it uses Products.storekit.")
                    )
                }
            }
            .alert("Purchase", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: store.lastError) { _, error in
                if let error { message = error.localizedDescription }
            }
        }
    }

    private func buy(_ product: StoreProduct) async {
        do {
            switch try await store.purchase(product, options: model.purchaseOptions()) {
            case .purchased, .cancelled:
                break
            case .pending:
                message = "The purchase is waiting for approval. It unlocks as soon as it is approved."
            }
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct AccessCard: View {
    let entitlement: Entitlement?
    let coins: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: entitlement == nil ? "lock.fill" : "checkmark.seal.fill")
                    .font(.title2)
                Text(entitlement == nil ? "Pro is locked" : "Pro is unlocked")
                    .font(.title3.bold())
                    .accessibilityIdentifier("status.pro")
                Spacer()
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Label("\(coins) coins", systemImage: "circle.hexagongrid.fill")
                .font(.headline)
                .accessibilityIdentifier("status.coins")
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0, green: 0.443, blue: 0.89), Color(red: 0, green: 0.345, blue: 0.83)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var detail: String {
        guard let entitlement else { return "Subscribe or buy Pro Lifetime to unlock it." }
        guard let end = entitlement.expirationDate else { return "Lifetime access from \(entitlement.productID)." }
        return "Through \(end.formatted(date: .abbreviated, time: .shortened)) with \(entitlement.productID)."
    }
}

private struct ProductRow: View {
    let product: StoreProduct
    let isOwned: Bool
    let buy: () async -> Void
    @State private var isBuying = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if isOwned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Owned")
            } else {
                Button {
                    isBuying = true
                    Task {
                        await buy()
                        isBuying = false
                    }
                } label: {
                    Text(product.displayPrice).monospacedDigit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBuying)
                .accessibilityIdentifier("buy.\(product.id)")
            }
        }
    }

    private var subtitle: String {
        if let subscription = product.subscription {
            let trial = subscription.hasIntroductoryOffer ? " · free trial" : ""
            return "Every \(subscription.period)\(trial)"
        }
        return product.kind == .consumable ? "Consumable" : "One-time purchase"
    }
}

private struct ServerRow: View {
    let server: ReceiptServerClient?
    let answer: ReceiptServerClient.Answer?

    var body: some View {
        if let server {
            VStack(alignment: .leading, spacing: 4) {
                Label(server.baseURL.absoluteString, systemImage: "server.rack")
                if let answer {
                    Text("Verified in \(answer.environment): \(answer.entitlements.map(\.name).joined(separator: ", ").nilIfEmpty ?? "no entitlements"), \(answer.coins) coins")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("server.answer")
                } else {
                    Text("Purchases are verified here before they are finished.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text("Not configured. Start Examples/ReceiptServer and set PAYMENTLAB_SERVER_URL in the scheme to verify purchases on a server.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
