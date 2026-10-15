<!-- i18n-source: README.md@557b21218b732640768f41f7ee39df183686f509 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="État de la CI"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Dernière version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Plateformes prises en charge: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Version du langage: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Licence: MIT"></picture></a>
</p>

<p align="center">
<a href="#démarrage-rapide"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-fr-light.svg" alt="Commencer"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-fr-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-fr-light.svg" alt="Exemples"></picture></a>
</p>

> Ceci est une traduction du README anglais. En cas de différence, la version anglaise fait foi.

<!-- brand:end -->

PaymentKit est un paquet Swift pour le code de paiement des apps sur les plateformes Apple. Il vend des achats intégrés avec StoreKit 2, accepte Apple Pay et gère les montants et les données de carte. Il corrige les points qui échouent en silence : un achat terminé avant que son contenu soit livré est perdu, un littéral `Decimal` comme `19.99` vaut en réalité `19.98999999999999488`, un remboursement reçu pendant que l’app est fermée ne retire jamais l’accès, et un numéro de carte se retrouve dans un journal via `print`. Le dépôt contient aussi une app d’exemple iOS et un serveur Node qui vérifie les achats avec l’App Store Server Library d’Apple. Le paquet n’a aucune dépendance en dehors du SDK d’Apple.

## Points forts

- **Achats livrés, puis terminés** — `Store` vérifie la signature de StoreKit, transmet chaque transaction vérifiée à votre closure `deliver` et ne la termine qu’une fois celle-ci revenue ; une livraison qui échoue revient au lancement suivant. Les remboursements arrivent sous la forme `.revoked`, jamais comme un nouvel achat.
- **Pièces créditées une seule fois** — les consommables définis avec un crédit passent par un registre qui enregistre le solde et les transactions traitées en une seule écriture atomique ; les répétitions, les redémarrages avant `finish()` et les remboursements ne créditent donc jamais deux fois.
- **Un accès qui suit l’App Store** — les renouvellements, les remboursements, les approbations Ask to Buy et les achats faits sur d’autres appareils mettent à jour `entitlements` d’eux-mêmes, et un abonnement qui expire pendant que l’app est ouverte est retiré à sa date d’expiration.
- **Des montants exacts** — `Money` stocke les unités mineures d’une devise ISO 4217 ; trop de décimales, `NaN`, un dépassement ou des devises mélangées lèvent une erreur au lieu d’arrondir ou de planter, et les répartitions ne perdent jamais un centime.
- **Des requêtes Apple Pay vérifiées** — `ApplePayRequest` valide le marchand, la devise, les libellés et les totaux avant que PassKit ne les voie, et `ApplePayController` signale le paiement avec async/await.
- **Des données de carte qui ne fuient pas** — `CardNumber`, `CardSecurityCode` et `CardForm` valident la saisie (marque, longueur, Luhn, expiration) et s’affichent sous la forme `•••• 4242` dans les journaux, avec `dump` et dans le débogueur.
- **Testé de bout en bout** — 116 tests Swift Testing sur macOS et sur un simulateur d’iPhone, 7 tests StoreKit et 4 tests d’interface dans l’app d’exemple (le vrai StoreKit via Xcode, la vraie feuille Apple Pay) et 25 tests pour le serveur de reçus.

## Démarrage rapide

**1. Ajouter le paquet**

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Ajoutez la bibliothèque `PaymentKit` à la cible de votre app.

**2. Importer le module**

```swift
import PaymentKit
```

**3. L’utiliser**

Remplacez le `ContentView.swift` d’une nouvelle app iOS par :

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

Pour acheter dans le simulateur avant que les produits n’existent dans App Store Connect, ajoutez un fichier de configuration StoreKit (**File › New › File from Template… › StoreKit Configuration File**) contenant un abonnement à renouvellement automatique `pro.monthly` et un produit non consommable `pro.lifetime`, puis sélectionnez-le dans **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**. Lancez l’app et touchez un produit : après l’achat, le texte devient **Pro is unlocked**.

## Installation

### Swift Package Manager

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Ou ajoutez-le aux `dependencies` de votre `Package.swift` :

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

## Utilisation

Les exemples ci-dessous sont copiés depuis
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
que l’app d’exemple et les tests du paquet compilent.

### Vendre des achats intégrés

Créez un seul `Store` au lancement de l’app et appelez `start()` tout de suite. Chaque nouvelle transaction vérifiée et chaque remboursement passent par `deliver` avant que StoreKit ne les termine ; lever une erreur à cet endroit les laisse inachevés, et StoreKit les livre de nouveau au lancement suivant.

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

`store.hasEntitlement("pro")` indique si Pro est débloqué à l’instant. La valeur est recalculée à partir des transactions vérifiées de StoreKit après chaque changement, si bien qu’un remboursement, une expiration ou une mise à niveau retire l’accès ; elle n’est jamais cumulée. Les transactions que StoreKit ne peut pas vérifier ne sont jamais livrées ni terminées.

Les pièces sont créditées par un `ConsumableLedger` une seule fois par transaction, quel que soit le nombre de fois où StoreKit l’envoie, et un remboursement les reprend une seule fois (le solde peut passer sous zéro si elles ont été dépensées). Dépensez-les avec `try await store.spend(30, of: "coins")`. Le registre est sur l’appareil ; pour tout ce qui a de la valeur, la source de vérité est le serveur.

### Traiter un achat

`purchase(_:options:)` lève une `StoreError` typée :

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

### Vérifier les achats sur un serveur

Chaque transaction porte `signedTransaction`, le JWS signé par l’App Store. Envoyez-le depuis `deliver` (comme le fait `makeStore` plus haut) à un serveur qui le vérifie avec l’App Store Server Library d’Apple. [`Examples/ReceiptServer`](Examples/ReceiptServer) est un serveur de ce type, sous Node 24 :

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Il vérifie la chaîne jusqu’à Apple Root CA - G3, l’identifiant du bundle et l’environnement, conserve les droits d’accès de chaque app account token, reçoit les App Store Server Notifications pour que les remboursements retirent l’accès, crédite un consommable une seule fois et limite chaque requête. Les transactions faites avec un fichier de configuration StoreKit dans Xcode ne sont pas signées par l’App Store ; le serveur ne les accepte qu’avec `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`, jamais avec `NODE_ENV=production`.

### Montants

```swift
func moneySamples() throws {
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
}
```

Écrivez les montants sous forme de chaînes ou en unités mineures : `19.99` en littéral `Decimal` passe par `Double`, et `Money` le refuse plutôt que de facturer `19.98999999999999488`.

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

### Données de carte

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

Collecter des numéros de carte dans vos propres champs place l’app dans le périmètre de PCI DSS ; privilégiez Apple Pay ou le champ de carte de votre prestataire de paiement quand c’est possible.

### Tests

`TestStoreClient` garde les produits et les transactions en mémoire et simule les remboursements, les renouvellements, les mises à niveau, Family Sharing, les livraisons répétées, les approbations Ask to Buy et les achats faits sur d’autres appareils : la logique d’achat s’exécute ainsi dans de simples tests unitaires :

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

## Démo

| Boutique | Paiement | Feuille Apple Pay | Formulaire de carte |
| -------- | -------- | ----------------- | ------------------- |
| ![Pro débloqué après un abonnement, clair](docs/images/store-light.png) | ![Panier avec choix de livraison, clair](docs/images/checkout-light.png) | ![Feuille Apple Pay avec le total du panier, clair](docs/images/apple-pay-light.png) | ![Formulaire de carte avec une erreur sous chaque champ, clair](docs/images/card-light.png) |
| ![Pro débloqué après un abonnement, sombre](docs/images/store-dark.png) | ![Panier avec choix de livraison, sombre](docs/images/checkout-dark.png) | ![Feuille Apple Pay avec le total du panier, sombre](docs/images/apple-pay-dark.png) | ![Formulaire de carte avec une erreur sous chaque champ, sombre](docs/images/card-dark.png) |

Les captures d’écran proviennent des tests d’interface de l’app d’exemple sur un simulateur d’iPhone, lancés par [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh) : un abonnement acheté avec les tests StoreKit dans Xcode, le panier et la vraie feuille Apple Pay avec son total, et le formulaire de carte après la vérification d’une carte mal saisie.

Pour l’essayer vous-même, ouvrez `PaymentLab.xcodeproj` dans [`Examples/PaymentLab`](Examples/PaymentLab), choisissez un simulateur d’iPhone et appuyez sur **Run**. [Examples/README.md](Examples/README.md) explique comment l’exécuter avec le serveur de reçus.

## Documentation

Référence de l’API et articles :

- [Référence de l’API](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, publiée sur GitHub Pages depuis `master`)
- Générez-la en local dans Xcode avec **Product › Build Documentation**, ou en ligne de commande :

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Guides

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — ajouter le paquet, lister les produits et les acheter dans le simulateur
  ([source](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — le chemin de chaque transaction, remboursements et répétitions, soldes de pièces, contrôles d’accès et restauration
  ([source](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — envoyer les transactions signées, le serveur d’exemple et les transactions Xcode
  ([source](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — la requête, sa validation, la feuille et le jeton pour votre prestataire de paiement
  ([source](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — ce qui est vérifié, le formatage pendant la saisie et le masquage
  ([source](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — quel initialiseur utiliser, les erreurs et la répartition exacte
  ([source](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` et les tests StoreKit dans Xcode
  ([source](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Prérequis

| Plateforme      | Version minimale      |
| --------------- | --------------------- |
| iOS             | 17                    |
| macOS           | 14                    |
| watchOS         | 10                    |
| visionOS        | 1                     |
| Chaîne d’outils | Swift 6.2 · Xcode 26+ |

Apple Pay est disponible sur les quatre plateformes ; sur visionOS, les achats intégrés s’affichent dans la fenêtre active de l’app. `Money`, `Currency` et les types de carte n’utilisent que Foundation. L’intégration continue compile avec le Xcode par défaut de l’image de runner `macos-26` de GitHub ; le paquet est développé avec Xcode 27. Le serveur de reçus nécessite Node 24.

## Architecture

- `Sources/PaymentKit` est découpé par rôle : `Money/` (`Money`, `Currency`, analyse et encodage), `Cards/` (numéro, marque, expiration, code de sécurité, formulaire), `Store/` (store, droits d’accès, le client App Store et le client de test) et `ApplePay/` (requête, valeurs du paiement, controller).
- `Store` est une classe `@Observable` annotée `@MainActor`. Elle n’accède à l’App Store que par le protocole `StoreClient` : `AppStoreClient` enveloppe StoreKit 2, `TestStoreClient` garde l’état en mémoire. `EntitlementResolver` est un type pur qui transforme les transactions en accès, testé sans StoreKit. `ConsumableLedger` est un actor qui crédite chaque transaction de consommable une seule fois et écrit sur le disque le solde et les transactions traitées en une seule écriture atomique.
- Toute entrée venue de l’extérieur est bornée et contrôlée : longueurs de texte des montants et des champs de carte, valeurs `Decimal` avant la mise à l’échelle et avant la conversion en `Int64`, délais de rafraîchissement de l’expiration avant qu’ils ne deviennent une `Duration`, quantités d’achat, nombre d’éléments et longueur des libellés dans les requêtes Apple Pay, caches des objets StoreKit et des transactions traitées, et fichier du registre (taille, entrées, noms de compte, dépassement d’`Int64`).
- `Examples/PaymentLab` est une app iOS avec des tests StoreKit hébergés dans l’app (`SKTestSession`) et des tests d’interface ; `Examples/ReceiptServer` est un serveur Node reposant sur l’App Store Server Library d’Apple.

Lancez les tests en local :

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Feuille de route

- Ajouter le paquet au Swift Package Index ; `.spi.yml` est déjà dans le dépôt.
- État de l’abonnement et informations de renouvellement (`Product.SubscriptionInfo.Status`) à côté des droits d’accès, pour les messages de nouvelle tentative de facturation et de période de grâce.
- Codes d’offre et offres promotionnelles signés par le serveur de reçus.

## Contribuer

Les contributions sont les bienvenues. Lisez le [guide de contribution](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) et le [code de conduite](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) avant d’ouvrir une pull request. Signalez les problèmes de sécurité en privé, comme indiqué dans la [politique de sécurité](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licence

Publié sous licence MIT. Voir [LICENSE](LICENSE).
