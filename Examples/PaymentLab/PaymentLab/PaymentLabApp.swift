import PaymentKit
import SwiftUI

@main
struct PaymentLabApp: App {
    @State private var model: LabModel

    init() {
        // UI tests start from an empty wallet and a new account each time.
        let arguments = ProcessInfo.processInfo.arguments
        let defaults = arguments.contains("-resetState") ? Self.freshDefaults() : .standard
        _model = State(initialValue: LabModel(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            LabView(model: model)
                .tint(.labBlue)
                // Start listening for transactions as soon as the app runs.
                .task { await model.store.start() }
        }
    }

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
