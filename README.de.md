<!-- i18n-source: README.md@ee71fbf6fb030e9bf7a2312c9fafe86ddc13c391 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="CI-Status"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Aktuelle Version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Unterstützte Plattformen: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Sprachversion: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Lizenz: MIT"></picture></a>
</p>

<p align="center">
<a href="#schnellstart"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-de-light.svg" alt="Loslegen"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-de-light.svg" alt="Dokumentation"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-de-light.svg" alt="Beispiele"></picture></a>
</p>

> Dies ist eine Übersetzung der englischen README. Bei Abweichungen gilt die englische Fassung.

<!-- brand:end -->

PaymentKit ist ein Swift-Paket für den Zahlungscode von Apps auf Apple-Plattformen. Es verkauft In-App-Käufe mit StoreKit 2, nimmt Apple Pay entgegen und verarbeitet Beträge und Kartendaten. Es behebt die Stellen, an denen Fehler unbemerkt bleiben: Ein Kauf, der abgeschlossen wurde, bevor der Inhalt geliefert war, geht verloren; ein `Decimal`-Literal wie `19.99` ist in Wirklichkeit `19.98999999999999488`; eine Rückerstattung, die bei geschlossener App eintrifft, entzieht den Zugriff nie; und eine Kartennummer landet per `print` im Log. Das Repository enthält außerdem eine iOS-Beispiel-App und einen Node-Server, der Käufe mit Apples App Store Server Library verifiziert. Das Paket hat keine Abhängigkeiten außer Apples SDK.

## Highlights

- **Käufe erst liefern, dann abschließen** — `Store` prüft die Signatur von StoreKit, übergibt jede verifizierte Transaktion an deinen `deliver`-Closure und schließt sie erst ab, wenn dieser zurückgekehrt ist; eine fehlgeschlagene Lieferung kommt beim nächsten Start erneut an. Rückerstattungen treffen als `.revoked` ein, nie als neuer Kauf.
- **Münzen genau einmal gutgeschrieben** — Verbrauchbare Produkte mit definierter Gutschrift laufen über ein Ledger, das den Kontostand und die verarbeiteten Transaktionen in einem atomaren Schreibvorgang sichert. So werden Wiederholungen, Neustarts vor `finish()` und Rückerstattungen nie doppelt gutgeschrieben.
- **Zugriff, der dem App Store folgt** — Verlängerungen, Rückerstattungen, Ask-to-Buy-Genehmigungen und Käufe auf anderen Geräten aktualisieren `entitlements` von selbst; ein Abonnement, das bei geöffneter App abläuft, wird zum Ablaufzeitpunkt entfernt, und eines, das der App Store nicht verlängern konnte, behält den Zugriff bis zum Ende seiner Billing Grace Period.
- **Exakte Beträge** — `Money` speichert die kleinste Einheit einer ISO-4217-Währung; zu viele Nachkommastellen, `NaN`, Überlauf und gemischte Währungen werfen einen Fehler, statt zu runden oder abzustürzen, und bei Aufteilungen geht nie ein Cent verloren.
- **Geprüfte Apple-Pay-Anfragen** — `ApplePayRequest` validiert Händler, Währung, Beschriftungen und Summen, bevor PassKit sie sieht, und `ApplePayController` meldet die Zahlung per async/await.
- **Kartendaten, die nicht durchsickern** — `CardNumber`, `CardSecurityCode` und `CardForm` validieren Eingaben (Marke, Länge, Luhn, Ablaufdatum) und werden in Logs, bei `dump` und im Debugger als `•••• 4242` ausgegeben.
- **Durchgängig getestet** — 129 Swift-Testing-Tests unter macOS und in einem iPhone-Simulator, 8 StoreKit-Tests und 4 UI-Tests in der Beispiel-App (echtes StoreKit über Xcode, das echte Apple-Pay-Sheet) sowie 37 Tests für den Receipt-Server.

## Schnellstart

**1. Paket hinzufügen**

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Füge die Bibliothek `PaymentKit` deinem App-Target hinzu.

**2. Modul importieren**

```swift
import PaymentKit
```

**3. Verwenden**

Ersetze die `ContentView.swift` einer neuen iOS-App durch:

```swift
import PaymentKit
import SwiftUI

struct ContentView: View {
    @State private var store = Store(catalog: [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro")
    ])

    var body: some View {
        List(store.products) { product in
            Button("\(product.displayName) · \(product.displayPrice)") {
                Task { try? await store.purchase(product) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text(store.hasEntitlement("pro") ? "Pro is unlocked" : "Pro is locked")
        }
        .task { await store.start() } // loads products, listens for renewals and refunds
    }
}
```

Um im Simulator zu kaufen, bevor die Produkte in App Store Connect existieren, füge eine StoreKit-Konfigurationsdatei hinzu (**File › New › File from Template… › StoreKit Configuration File**) mit einem automatisch verlängernden Abonnement `pro.monthly` und einem nicht verbrauchbaren Produkt `pro.lifetime`, und wähle sie unter **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration** aus. Starte die App und tippe auf ein Produkt: Nach dem Kauf lautet der Text **Pro is unlocked**.

## Installation

### Swift Package Manager

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Oder füge es zu den `dependencies` in deiner `Package.swift` hinzu:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git", from: "2.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "PaymentKit", package: "iOS-Payment-Processing-Framework")
    ])
]
```

## Verwendung

Die folgenden Beispiele stammen aus
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
das die Beispiel-App und die Tests des Pakets kompilieren.

### In-App-Käufe verkaufen

Erstelle genau einen `Store`, wenn die App startet, und rufe sofort `start()` auf. Jede neue verifizierte Transaktion und jede Rückerstattung läuft durch `deliver`, bevor StoreKit sie abschließt; wirft `deliver` einen Fehler, bleibt die Transaktion unabgeschlossen, und StoreKit liefert sie beim nächsten Start erneut aus.

```swift
@MainActor
func makeStore(server: URL) -> Store {
    Store(catalog: [
        .autoRenewable("pro.monthly", unlocks: "pro"),
        .autoRenewable("pro.yearly", unlocks: "pro"),
        .nonConsumable("pro.lifetime", unlocks: "pro"),
        .consumable("coins.100", credits: 100, to: "coins") // store.balance(of: "coins")
    ]) { change in
        // Runs for each new verified transaction (.granted) and each refund (.revoked) before
        // StoreKit finishes it. Throwing keeps it unfinished and StoreKit sends it again on the
        // next launch, so the server must accept repeats of the same transaction.
        try await sendToServer(change.transaction.signedTransaction, server: server)
    }
}
```

`store.hasEntitlement("pro")` beantwortet, ob Pro gerade freigeschaltet ist. Der Wert wird nach jeder Änderung aus den verifizierten Transaktionen von StoreKit neu berechnet, sodass eine Rückerstattung, ein Ablauf oder ein Upgrade den Zugriff entzieht; er wird nie aufaddiert. Transaktionen, die StoreKit nicht verifizieren kann, werden weder geliefert noch abgeschlossen.

Münzen schreibt ein `ConsumableLedger` pro Transaktion genau einmal gut, egal wie oft StoreKit sie sendet, und eine Rückerstattung bucht sie ebenfalls nur einmal ab (der Kontostand kann unter null fallen, wenn sie schon ausgegeben wurden). Gib sie mit `try await store.spend(30, of: "coins")` aus. Das Ledger liegt auf dem Gerät; für alles, was einen Wert hat, ist der Server die maßgebliche Quelle.

### Einen Kauf abwickeln

`purchase(_:options:)` wirft einen typisierten `StoreError`:

```swift
@MainActor
func buy(_ product: StoreProduct, in store: Store, account: UUID) async -> String {
    do {
        switch try await store.purchase(product, options: PurchaseOptions(appAccountToken: account)) {
        case .purchased(let transaction):
            return "Bought \(transaction.productID)"
        case .pending:
            return "Waiting for approval (Ask to Buy)"
        case .cancelled:
            return "Cancelled"
        }
    } catch .verificationFailed {
        return "The App Store could not verify the purchase; nothing was unlocked."
    } catch {
        return error.localizedDescription
    }
}
```

### Käufe auf einem Server verifizieren

Jede Transaktion enthält `signedTransaction`, das vom App Store signierte JWS. Sende es aus `deliver` (wie `makeStore` oben) an einen Server, der es mit Apples App Store Server Library verifiziert. [`Examples/ReceiptServer`](Examples/ReceiptServer) ist ein solcher Server auf Basis von Node 24:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Er prüft die Kette bis zu Apple Root CA - G3, die Bundle-ID und die Umgebung, speichert die Berechtigungen pro App-Account-Token in einer Datei, die einen Neustart übersteht, nimmt App Store Server Notifications entgegen, damit Rückerstattungen den Zugriff entziehen und eine Billing Grace Period ihn erhält, schreibt ein verbrauchbares Produkt genau einmal gut und begrenzt jede Anfrage. Transaktionen, die in Xcode mit einer StoreKit-Konfigurationsdatei entstehen, sind nicht vom App Store signiert; der Server akzeptiert sie nur mit `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`, niemals mit `NODE_ENV=production`.

### Geldbeträge

```swift
func moneySamples() throws -> (total: Money, shares: [Money]) {
    let price = try Money("19.99", .usd)
    let tax = try price.multiplied(by: Decimal(8) / 100) // 1.60, rounded half to even
    let total = try price.adding(tax)                    // 21.59 USD
    print(total.minorUnits)                              // 2159, what payment APIs expect
    print(total.formatted(locale: Locale(identifier: "en_US"))) // $21.59

    let typed = try Money(parsing: "1.234,50", currency: .eur, locale: Locale(identifier: "de_DE"))
    let shares = try typed.split(into: 3)                // 411.50, 411.50, 411.50 EUR
    print(shares.map(\.description))

    do {
        _ = try Money("10.999", .usd)
    } catch MoneyError.tooManyFractionDigits {
        print("US dollars have two decimals") // never rounded silently
    }
    return (total, shares)
}
```

Schreibe Beträge als Strings oder in der kleinsten Einheit: Ein `Decimal`-Literal `19.99` läuft über `Double`, und `Money` lehnt es ab, statt `19.98999999999999488` abzubuchen.

### Apple Pay

```swift
func makeApplePayRequest() throws -> ApplePayRequest {
    var request = ApplePayRequest(
        merchantIdentifier: "merchant.com.example.shop",
        merchantName: "Example Shop",
        countryCode: "US",
        currency: .usd,
        items: [
            ApplePaySummaryItem("Coffee beans", try Money("18.00", .usd)),
            ApplePaySummaryItem("Discount", try Money("-2.00", .usd))
        ]
    )
    request.shippingMethods = [
        ApplePayShippingMethod(id: "standard", label: "Standard", detail: "3–5 days", amount: try Money("4.99", .usd))
    ]
    request.requiredShippingFields = [.name, .postalAddress]
    try request.validate() // currency, labels, merchant ID, total ≥ 0
    return request
}
```

```swift
struct CheckoutButton: View {
    let request: ApplePayRequest
    let server: URL
    @State private var controller = ApplePayController()

    var body: some View {
        PayWithApplePayButton(.buy) {
            Task {
                do {
                    let outcome = try await controller.pay(request) { payment in
                        // Charge the token through your server and payment provider.
                        do {
                            try await chargeOnServer(payment.token.serverPayload(), server: server)
                            return .success
                        } catch {
                            return .failure(message: "The payment did not go through.")
                        }
                    }
                    if case .paid(let payment) = outcome {
                        print("Paid with", payment.token.displayName ?? "Apple Pay")
                    }
                } catch {
                    print("Apple Pay could not start:", error.localizedDescription)
                }
            }
        }
        .frame(height: 48)
    }
}
```

### Kartendaten

```swift
func checkCard(number: String, expiry: String, securityCode: String) -> String {
    let form = CardForm(number: number, expiry: expiry, securityCode: securityCode)
    switch form.validate() {
    case .success(let card):
        // print(card.number) shows "•••• 4242"; hand card.number.unmaskedDigits to your
        // payment provider's tokenization API and nowhere else.
        return "\(card.number.brand.displayName) \(card.number) is valid"
    case .failure(let errors):
        return [errors.number, errors.expiry, errors.securityCode]
            .compactMap { $0?.localizedDescription }
            .joined(separator: "\n")
    }
}
```

Wenn du Kartennummern in eigenen Feldern erfasst, fällt die App in den Geltungsbereich von PCI DSS; verwende nach Möglichkeit Apple Pay oder das Kartenfeld deines Zahlungsanbieters.

### Testen

`TestStoreClient` hält Produkte und Transaktionen im Speicher und simuliert Rückerstattungen, Verlängerungen, Upgrades, Family Sharing, wiederholte Lieferungen, Ask-to-Buy-Genehmigungen und Käufe auf anderen Geräten, sodass sich die Kauflogik in gewöhnlichen Unit-Tests ausführen lässt:

```swift
@MainActor
func refundRemovesPro() async throws -> Bool {
    let client = TestStoreClient(products: [.preview(id: "pro.lifetime", kind: .nonConsumable)])
    let store = Store(catalog: [.nonConsumable("pro.lifetime", unlocks: "pro")], client: client)
    await store.start()

    guard case .purchased(let transaction) = try await store.purchase(store.products[0]) else { return false }
    let unlocked = store.hasEntitlement("pro")         // true
    try await client.refund(transaction.id)            // as if Apple refunded it
    await store.refreshEntitlements()
    return unlocked && !store.hasEntitlement("pro")    // access is gone
}
```

## Demo

| Store | Kasse | Apple-Pay-Sheet | Kartenformular |
| ----- | ----- | --------------- | -------------- |
| ![Pro nach einem Abonnement freigeschaltet, hell](docs/images/store-light.png) | ![Warenkorb mit Lieferoptionen, hell](docs/images/checkout-light.png) | ![Apple-Pay-Sheet mit der Warenkorbsumme, hell](docs/images/apple-pay-light.png) | ![Kartenformular mit einem Fehler unter jedem Feld, hell](docs/images/card-light.png) |
| ![Pro nach einem Abonnement freigeschaltet, dunkel](docs/images/store-dark.png) | ![Warenkorb mit Lieferoptionen, dunkel](docs/images/checkout-dark.png) | ![Apple-Pay-Sheet mit der Warenkorbsumme, dunkel](docs/images/apple-pay-dark.png) | ![Kartenformular mit einem Fehler unter jedem Feld, dunkel](docs/images/card-dark.png) |

Die Screenshots stammen aus den UI-Tests der Beispiel-App auf einem iPhone-Simulator, ausgeführt von [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh): ein per StoreKit-Testing in Xcode gekauftes Abonnement, der Warenkorb und das echte Apple-Pay-Sheet mit seiner Summe sowie das Kartenformular nach der Prüfung einer falsch eingegebenen Karte.

Zum Ausprobieren öffnest du `PaymentLab.xcodeproj` in [`Examples/PaymentLab`](Examples/PaymentLab), wählst einen iPhone-Simulator und drückst **Run**. [Examples/README.md](Examples/README.md) zeigt, wie du die App mit dem Receipt-Server ausführst.

## Dokumentation

API-Referenz und Artikel:

- [API-Referenz](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, von `master` auf GitHub Pages veröffentlicht)
- Lokal baust du sie in Xcode mit **Product › Build Documentation** oder auf der Kommandozeile:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Anleitungen

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — das Paket hinzufügen, Produkte auflisten und im Simulator kaufen
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — der Weg jeder Transaktion, Rückerstattungen und Wiederholungen, Münzstände, Zugriffsprüfungen und Wiederherstellen
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — signierte Transaktionen senden, der Beispiel-Server und Xcode-Transaktionen
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — die Anfrage, ihre Validierung, das Sheet und das Token für deinen Zahlungsanbieter
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — was geprüft wird, Formatierung während der Eingabe und Schwärzung
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — welcher Initializer passt, die Fehler und exakte Aufteilung
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` und StoreKit-Testing in Xcode
  ([Quelle](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Voraussetzungen

| Plattform | Mindestversion        |
| --------- | --------------------- |
| iOS       | 17                    |
| macOS     | 14                    |
| watchOS   | 10                    |
| visionOS  | 1                     |
| Toolchain | Swift 6.2 · Xcode 26+ |

Apple Pay ist auf allen vier Plattformen verfügbar; In-App-Käufe werden unter visionOS im aktiven Fenster der App angezeigt. `Money`, `Currency` und die Kartentypen verwenden nur Foundation. CI baut mit dem Standard-Xcode des `macos-26`-Runner-Images von GitHub; das Paket wird mit Xcode 27 entwickelt. Der Receipt-Server benötigt Node 24.

## Architektur

- `Sources/PaymentKit` ist nach Aufgaben gegliedert: `Money/` (`Money`, `Currency`, Parsing und Kodierung), `Cards/` (Nummer, Marke, Ablaufdatum, Sicherheitscode, Formular), `Store/` (Store, Berechtigungen, der App-Store-Client und der Test-Client) und `ApplePay/` (Anfrage, Zahlungswerte, Controller).
- `Store` ist eine `@MainActor`-Klasse mit `@Observable`. Den App Store erreicht sie nur über das Protokoll `StoreClient`: `AppStoreClient` kapselt StoreKit 2, `TestStoreClient` hält den Zustand im Speicher. `EntitlementResolver` ist ein reiner Typ, der Transaktionen in Zugriff umwandelt und ohne StoreKit getestet wird. `ConsumableLedger` ist ein Actor, der jede Transaktion eines verbrauchbaren Produkts genau einmal gutschreibt und den Kontostand sowie die verarbeiteten Transaktionen in einem atomaren Schreibvorgang auf die Festplatte schreibt.
- Eingaben von außen sind begrenzt und bereichsgeprüft: Textlängen für Beträge und Kartenfelder, `Decimal`-Werte vor dem Skalieren und vor der Umwandlung in `Int64`, Verzögerungen der Ablaufaktualisierung, bevor sie zu einer `Duration` werden, Kaufmengen, Elementanzahl und Beschriftungslängen in Apple-Pay-Anfragen, die Caches der StoreKit-Objekte und verarbeiteten Transaktionen sowie die Ledger-Datei (Größe, Einträge, Kontonamen, `Int64`-Überlauf).
- `Examples/PaymentLab` ist eine iOS-App mit in der App gehosteten StoreKit-Tests (`SKTestSession`) und UI-Tests; `Examples/ReceiptServer` ist ein Node-Server auf Basis von Apples App Store Server Library.

Führe die Tests lokal aus:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Roadmap

- Das Paket zum Swift Package Index hinzufügen; `.spi.yml` liegt bereits im Repository.
- Abostatus und Verlängerungsinformationen (`Product.SubscriptionInfo.Status`) neben den Berechtigungen, für Hinweise bei erneutem Abbuchungsversuch und Kulanzfrist.
- Angebotscodes und Aktionsangebote, die der Receipt-Server signiert.

## Mitwirken

Beiträge sind willkommen. Lies vor einem Pull Request den [Leitfaden für Beiträge](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) und den [Verhaltenskodex](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). Sicherheitsprobleme meldest du vertraulich, wie in der [Sicherheitsrichtlinie](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md) beschrieben.

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
