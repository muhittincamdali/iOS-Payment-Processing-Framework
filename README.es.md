<!-- i18n-source: README.md@ee71fbf6fb030e9bf7a2312c9fafe86ddc13c391 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="Estado de CI"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Última versión: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Plataformas compatibles: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Versión del lenguaje: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Licencia: MIT"></picture></a>
</p>

<p align="center">
<a href="#inicio-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-es-light.svg" alt="Empezar"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-es-light.svg" alt="Documentación"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-es-light.svg" alt="Ejemplos"></picture></a>
</p>

> Esta es una traducción del README en inglés. Si hay diferencias, la versión en inglés es la vigente.

<!-- brand:end -->

PaymentKit es un paquete de Swift para el código de pagos de las apps en plataformas Apple. Vende compras dentro de la app con StoreKit 2, acepta Apple Pay y gestiona importes y datos de tarjeta. Corrige las partes que fallan en silencio: una compra finalizada antes de entregar su contenido se pierde, un literal `Decimal` como `19.99` en realidad es `19.98999999999999488`, un reembolso que llega con la app cerrada nunca retira el acceso y un número de tarjeta acaba en un registro a través de `print`. El repositorio también incluye una app de ejemplo para iOS y un servidor Node que verifica las compras con la App Store Server Library de Apple. El paquete no tiene dependencias fuera del SDK de Apple.

## Lo más destacado

- **Compras entregadas y luego finalizadas** — `Store` comprueba la firma de StoreKit, entrega cada transacción verificada a tu closure `deliver` y la finaliza solo cuando este termina; una entrega fallida vuelve a llegar en el siguiente arranque. Los reembolsos llegan como `.revoked`, nunca como una compra nueva.
- **Monedas abonadas una sola vez** — los consumibles definidos con un crédito pasan a un libro que guarda el saldo y las transacciones gestionadas en una única escritura atómica, de modo que las repeticiones, los reinicios antes de `finish()` y los reembolsos nunca abonan dos veces.
- **Acceso que sigue a la App Store** — las renovaciones, los reembolsos, las aprobaciones de Ask to Buy y las compras en otros dispositivos actualizan `entitlements` por sí solos, una suscripción que caduca con la app abierta se retira en su fecha de vencimiento, y una que la App Store no pudo renovar conserva el acceso hasta que termina su Billing Grace Period.
- **Dinero exacto** — `Money` guarda las unidades menores de una divisa ISO 4217; demasiados decimales, `NaN`, desbordamientos y divisas mezcladas lanzan un error en lugar de redondear o fallar, y los repartos nunca pierden un céntimo.
- **Solicitudes de Apple Pay comprobadas** — `ApplePayRequest` valida el comercio, la divisa, las etiquetas y los totales antes de que PassKit los vea, y `ApplePayController` informa del pago con async/await.
- **Datos de tarjeta que no se filtran** — `CardNumber`, `CardSecurityCode` y `CardForm` validan la entrada (marca, longitud, Luhn, caducidad) y se imprimen como `•••• 4242` en los registros, en `dump` y en el depurador.
- **Probado de extremo a extremo** — 129 pruebas de Swift Testing en macOS y en un simulador de iPhone, 8 pruebas de StoreKit y 4 pruebas de UI en la app de ejemplo (StoreKit real a través de Xcode, la hoja real de Apple Pay) y 37 pruebas para el servidor de recibos.

## Inicio rápido

**1. Añade el paquete**

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Añade la biblioteca `PaymentKit` al target de tu app.

**2. Importa el módulo**

```swift
import PaymentKit
```

**3. Úsalo**

Sustituye el `ContentView.swift` de una app de iOS nueva por esto:

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

Para comprar en el simulador antes de que los productos existan en App Store Connect, añade un archivo de configuración de StoreKit (**File › New › File from Template… › StoreKit Configuration File**) con una suscripción de renovación automática `pro.monthly` y un producto no consumible `pro.lifetime`, y selecciónalo en **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**. Ejecuta la app y toca un producto: tras la compra, el texto pasa a decir **Pro is unlocked**.

## Instalación

### Swift Package Manager

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

O añádelo a las `dependencies` de tu `Package.swift`:

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

## Uso

Los ejemplos de abajo están copiados de
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
que compilan la app de ejemplo y las pruebas del paquete.

### Vender compras dentro de la app

Crea un único `Store` cuando arranque la app y llama a `start()` enseguida. Cada transacción verificada nueva y cada reembolso pasan por `deliver` antes de que StoreKit los finalice; si lanzas un error ahí, la transacción queda sin finalizar y StoreKit la entrega de nuevo en el siguiente arranque.

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

`store.hasEntitlement("pro")` responde si Pro está desbloqueado ahora. Se vuelve a calcular a partir de las transacciones verificadas de StoreKit después de cada cambio, de modo que un reembolso, una caducidad o una mejora retiran el acceso; nunca se va sumando. Las transacciones que StoreKit no puede verificar jamás se entregan ni se finalizan.

Las monedas las abona un `ConsumableLedger` una vez por transacción, por muchas veces que StoreKit la envíe, y un reembolso las retira una sola vez (el saldo puede quedar por debajo de cero si ya se gastaron). Gástalas con `try await store.spend(30, of: "coins")`. El libro está en el dispositivo; para cualquier cosa de valor, la fuente de verdad es el servidor.

### Gestionar una compra

`purchase(_:options:)` lanza un `StoreError` tipado:

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

### Verificar compras en un servidor

Cada transacción lleva `signedTransaction`, el JWS firmado por la App Store. Envíalo desde `deliver` (como hace `makeStore` más arriba) a un servidor que lo verifique con la App Store Server Library de Apple. [`Examples/ReceiptServer`](Examples/ReceiptServer) es uno de esos servidores, sobre Node 24:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Comprueba la cadena hasta Apple Root CA - G3, el identificador del bundle y el entorno, guarda los derechos de acceso de cada app account token en un archivo que sobrevive a un reinicio, recibe App Store Server Notifications para que los reembolsos retiren el acceso y un Billing Grace Period lo conserve, abona un consumible una sola vez y limita cada solicitud. Las transacciones hechas con un archivo de configuración de StoreKit en Xcode no las firma la App Store; el servidor solo las acepta con `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`, nunca con `NODE_ENV=production`.

### Dinero

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

Escribe los importes como cadenas o en unidades menores: `19.99` como literal `Decimal` pasa por `Double`, y `Money` lo rechaza en lugar de cobrar `19.98999999999999488`.

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

### Datos de tarjeta

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

Recoger números de tarjeta en tus propios campos incluye la app en el ámbito de PCI DSS; siempre que puedas, usa Apple Pay o el campo de tarjeta de tu proveedor.

### Pruebas

`TestStoreClient` guarda productos y transacciones en memoria y simula reembolsos, renovaciones, mejoras, Family Sharing, entregas repetidas, aprobaciones de Ask to Buy y compras en otros dispositivos, de modo que la lógica de compra se ejecuta en pruebas unitarias normales:

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

| Tienda | Pago | Hoja de Apple Pay | Formulario de tarjeta |
| ------ | ---- | ----------------- | --------------------- |
| ![Pro desbloqueado tras una suscripción, claro](docs/images/store-light.png) | ![Carrito con opciones de entrega, claro](docs/images/checkout-light.png) | ![Hoja de Apple Pay con el total del carrito, claro](docs/images/apple-pay-light.png) | ![Formulario de tarjeta con un error bajo cada campo, claro](docs/images/card-light.png) |
| ![Pro desbloqueado tras una suscripción, oscuro](docs/images/store-dark.png) | ![Carrito con opciones de entrega, oscuro](docs/images/checkout-dark.png) | ![Hoja de Apple Pay con el total del carrito, oscuro](docs/images/apple-pay-dark.png) | ![Formulario de tarjeta con un error bajo cada campo, oscuro](docs/images/card-dark.png) |

Las capturas proceden de las pruebas de UI de la app de ejemplo en un simulador de iPhone, ejecutadas con [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh): una suscripción comprada mediante las pruebas de StoreKit en Xcode, el carrito y la hoja real de Apple Pay con su total, y el formulario de tarjeta tras comprobar una tarjeta mal escrita.

Para probarlo tú mismo, abre `PaymentLab.xcodeproj` en [`Examples/PaymentLab`](Examples/PaymentLab), elige un simulador de iPhone y pulsa **Run**. [Examples/README.md](Examples/README.md) explica cómo ejecutarlo con el servidor de recibos.

## Documentación

Referencia de la API y artículos:

- [Referencia de la API](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, publicada en GitHub Pages desde `master`)
- Compílala en local en Xcode con **Product › Build Documentation**, o desde la línea de comandos:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Guías

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — añade el paquete, lista productos y cómpralos en el simulador
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — el camino que sigue cada transacción, reembolsos y repeticiones, saldos de monedas, comprobaciones de acceso y restauración
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — envío de transacciones firmadas, el servidor de ejemplo y las transacciones de Xcode
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — la solicitud, su validación, la hoja y el token para tu proveedor de pagos
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — qué se comprueba, el formato mientras se escribe y la ocultación de datos
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — qué inicializador usar, los errores y el reparto exacto
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` y las pruebas de StoreKit en Xcode
  ([código fuente](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Requisitos

| Plataforma  | Versión mínima        |
| ----------- | --------------------- |
| iOS         | 17                    |
| macOS       | 14                    |
| watchOS     | 10                    |
| visionOS    | 1                     |
| Herramientas | Swift 6.2 · Xcode 26+ |

Apple Pay está disponible en las cuatro plataformas; las compras dentro de la app en visionOS se muestran en la ventana activa de la app. `Money`, `Currency` y los tipos de tarjeta usan solo Foundation. CI compila con el Xcode predeterminado de la imagen del runner `macos-26` de GitHub; el paquete se desarrolla con Xcode 27. El servidor de recibos necesita Node 24.

## Arquitectura

- `Sources/PaymentKit` se divide por función: `Money/` (`Money`, `Currency`, análisis y codificación), `Cards/` (número, marca, caducidad, código de seguridad, formulario), `Store/` (store, derechos de acceso, el cliente de la App Store y el cliente de pruebas) y `ApplePay/` (solicitud, valores del pago, controller).
- `Store` es una clase `@Observable` con `@MainActor`. Solo llega a la App Store a través del protocolo `StoreClient`: `AppStoreClient` envuelve StoreKit 2 y `TestStoreClient` guarda el estado en memoria. `EntitlementResolver` es un tipo puro que convierte transacciones en acceso y se prueba sin StoreKit. `ConsumableLedger` es un actor que abona cada transacción de consumible una sola vez y escribe en disco el saldo y las transacciones gestionadas en una única escritura atómica.
- Toda entrada externa está acotada y con el rango comprobado: la longitud de los textos de importes y campos de tarjeta, los valores `Decimal` antes de escalar y antes de convertir a `Int64`, los retrasos de actualización de caducidad antes de que pasen a ser un `Duration`, las cantidades de compra, el número de elementos y la longitud de las etiquetas en las solicitudes de Apple Pay, las cachés de objetos de StoreKit y de transacciones gestionadas, y el archivo del libro (tamaño, entradas, nombres de cuenta, desbordamiento de `Int64`).
- `Examples/PaymentLab` es una app de iOS con pruebas de StoreKit alojadas en la app (`SKTestSession`) y pruebas de UI; `Examples/ReceiptServer` es un servidor Node basado en la App Store Server Library de Apple.

Ejecuta las pruebas en local:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Hoja de ruta

- Añadir el paquete al Swift Package Index; `.spi.yml` ya está en el repositorio.
- Estado de la suscripción e información de renovación (`Product.SubscriptionInfo.Status`) junto a los derechos de acceso, para mensajes de reintento de cobro y de periodo de gracia.
- Códigos de oferta y ofertas promocionales firmados por el servidor de recibos.

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) y el [código de conducta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir una pull request. Informa de los problemas de seguridad de forma privada, como se describe en la [política de seguridad](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licencia

Publicado bajo la licencia MIT. Consulta [LICENSE](LICENSE).
