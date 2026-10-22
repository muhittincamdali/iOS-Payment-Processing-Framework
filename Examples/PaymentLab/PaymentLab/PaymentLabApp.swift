import PaymentKit
import SwiftUI

@main
struct PaymentLabApp: App {
    @State private var model: LabModel

    init() {
        // UI tests start with no coins and a new account each time.
        let reset = ProcessInfo.processInfo.arguments.contains("-resetState")
        _model = State(initialValue: LabModel(
            ledger: reset ? ConsumableLedger(fileURL: nil) : .standard,
            defaults: reset ? Self.freshDefaults() : .standard
        ))
    }

    var body: some Scene {
        WindowGroup {
            LabView(model: model)
                .tint(.labBlue)
                // Start listening for transactions as soon as the app runs.
                .task {
                    guard Self.startsStore(in: ProcessInfo.processInfo.environment) else { return }
                    await model.store.start()
                }
        }
    }

    /// Whether the app starts its store when it launches: not when it only hosts the unit tests.
    ///
    /// The tests run in the app's process, so the app's store would receive their transactions
    /// from `Transaction.updates` too, deliver them and finish them, such as a refund that a
    /// test waits for or a purchase that a test leaves unfinished.
    static func startsStore(in environment: [String: String]) -> Bool {
        environment[hostedTestsKey] == nil
    }

    /// Set in a process that hosts unit tests; not in the app that the UI tests launch.
    private static let hostedTestsKey = "XCTestConfigurationFilePath"

    private static func freshDefaults() -> UserDefaults {
        let name = "PaymentLab.UITests"
        UserDefaults().removePersistentDomain(forName: name)
        return UserDefaults(suiteName: name) ?? .standard
    }
}

struct LabView: View {
    let model: LabModel

    var body: some View {
        TabView {
            StoreScreen(model: model)
                .tabItem { Label("Store", systemImage: "bag") }
            CheckoutScreen()
                .tabItem { Label("Checkout", systemImage: "cart") }
            CardScreen()
                .tabItem { Label("Card", systemImage: "creditcard") }
        }
    }
}

extension Color {
    /// The blue of the repository's graphics, #0071E3, lighter in dark mode (#0A84FF).
    static let labBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1)
            : UIColor(red: 0.0, green: 0.443, blue: 0.89, alpha: 1)
    })
}
