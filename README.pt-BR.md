<!-- i18n-source: README.md@f9a69a80d1ecc14e285680c13d281ae25fadca12 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="Status da CI"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Versão mais recente: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Plataformas compatíveis: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Versão da linguagem: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Licença: MIT"></picture></a>
</p>

<p align="center">
<a href="#início-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-pt-BR-light.svg" alt="Começar"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-pt-BR-light.svg" alt="Documentação"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-pt-BR-light.svg" alt="Exemplos"></picture></a>
</p>

> Esta é uma tradução do README em inglês. Se houver diferença, vale a versão em inglês.

<!-- brand:end -->

O PaymentKit é um pacote Swift para o código de pagamento de apps nas plataformas Apple. Ele vende compras dentro do app com StoreKit 2, aceita Apple Pay e lida com valores e dados de cartão. Corrige os pontos que falham em silêncio: uma compra finalizada antes de o conteúdo ser entregue se perde, um literal `Decimal` como `19.99` na verdade é `19.98999999999999488`, um reembolso que chega com o app fechado nunca retira o acesso e um número de cartão vai parar em um log por meio do `print`. O repositório também tem um app de exemplo para iOS e um servidor Node que verifica as compras com a App Store Server Library da Apple. O pacote não tem dependências além do SDK da Apple.

## Destaques

- **Compras entregues e só então finalizadas** — o `Store` confere a assinatura do StoreKit, entrega cada transação verificada ao seu closure `deliver` e só a finaliza depois que ele retorna; uma entrega que falha volta na próxima abertura do app. Reembolsos chegam como `.revoked`, nunca como uma nova compra.
- **Moedas creditadas uma única vez** — consumíveis definidos com um crédito vão para um livro-razão que grava o saldo e as transações tratadas em uma única escrita atômica, de modo que repetições, reinícios antes de `finish()` e reembolsos nunca creditam duas vezes.
- **Acesso que acompanha a App Store** — renovações, reembolsos, aprovações do Ask to Buy e compras em outros dispositivos atualizam `entitlements` sozinhos, uma assinatura que expira com o app aberto é removida na data de vencimento, e uma que a App Store não conseguiu renovar mantém o acesso até o fim do seu Billing Grace Period.
- **Dinheiro exato** — o `Money` guarda as unidades menores de uma moeda ISO 4217; casas decimais demais, `NaN`, estouro e moedas misturadas lançam um erro em vez de arredondar ou travar, e as divisões nunca perdem um centavo.
- **Requisições de Apple Pay verificadas** — o `ApplePayRequest` valida o comerciante, a moeda, os rótulos e os totais antes que o PassKit os veja, e o `ApplePayController` informa o pagamento com async/await.
- **Dados de cartão que não vazam** — `CardNumber`, `CardSecurityCode` e `CardForm` validam a entrada (bandeira, tamanho, Luhn, validade) e aparecem como `•••• 4242` em logs, no `dump` e no depurador.
- **Testado de ponta a ponta** — 130 testes de Swift Testing no macOS e em um simulador de iPhone, 8 testes de StoreKit e 4 testes de UI no app de exemplo (StoreKit real pelo Xcode, a folha real do Apple Pay) e 38 testes para o servidor de recibos.

## Início rápido

**1. Adicione o pacote**

No Xcode, escolha **File › Add Package Dependencies…** e informe a URL do repositório:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Adicione a biblioteca `PaymentKit` ao target do seu app.

**2. Importe o módulo**

```swift
import PaymentKit
```

**3. Use**

Substitua o `ContentView.swift` de um novo app iOS por:

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

Para comprar no simulador antes de os produtos existirem no App Store Connect, adicione um arquivo de configuração do StoreKit (**File › New › File from Template… › StoreKit Configuration File**) com uma assinatura de renovação automática `pro.monthly` e um produto não consumível `pro.lifetime`, e selecione-o em **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**. Execute o app e toque em um produto: depois da compra, o texto passa a ser **Pro is unlocked**.

## Instalação

### Swift Package Manager

No Xcode, escolha **File › Add Package Dependencies…** e informe a URL do repositório:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Ou adicione-o às `dependencies` do seu `Package.swift`:

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

Os exemplos abaixo foram copiados de
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
que o app de exemplo e os testes do pacote compilam.

### Vendendo compras dentro do app

Crie um único `Store` quando o app iniciar e chame `start()` logo em seguida. Toda nova transação verificada e todo reembolso passam por `deliver` antes de o StoreKit finalizá-los; lançar um erro ali mantém a transação sem finalizar, e o StoreKit a entrega de novo na próxima abertura do app.

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

`store.hasEntitlement("pro")` responde se o Pro está desbloqueado agora. Ele é recalculado a partir das transações verificadas do StoreKit depois de cada mudança, então um reembolso, uma expiração ou um upgrade retiram o acesso; o valor nunca é acumulado. Transações que o StoreKit não consegue verificar nunca são entregues nem finalizadas.

As moedas são creditadas por um `ConsumableLedger` uma vez por transação, por mais vezes que o StoreKit a envie. Gaste-as com `try await store.spend(30, of: "coins")`. O livro-razão fica no dispositivo e só vê os reembolsos que o StoreKit envia: o reembolso de um pacote ainda não finalizado chega, e o pacote não credita nada, mas o StoreKit não envia ao app o reembolso de um pacote finalizado, então essas moedas ficam no livro-razão. Só o servidor fica sabendo desse reembolso, por uma App Store Server Notification `REFUND`; para qualquer coisa de valor, a fonte da verdade é o servidor.

### Tratando uma compra

`purchase(_:options:)` lança um `StoreError` tipado:

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

### Verificando compras em um servidor

Cada transação traz `signedTransaction`, o JWS assinado pela App Store. Envie-o de `deliver` (como o `makeStore` acima faz) para um servidor que o verifique com a App Store Server Library da Apple. [`Examples/ReceiptServer`](Examples/ReceiptServer) é um servidor assim, em Node 24:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Ele confere a cadeia até a Apple Root CA - G3, o bundle identifier e o ambiente, guarda os direitos de acesso de cada app account token em um arquivo que sobrevive a uma reinicialização, recebe as App Store Server Notifications para que os reembolsos retirem o acesso e um Billing Grace Period o mantenha, credita um consumível uma única vez e limita cada requisição. As transações feitas com um arquivo de configuração do StoreKit no Xcode não são assinadas pela App Store; o servidor só as aceita com `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`, nunca com `NODE_ENV=production`.

### Dinheiro

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

Escreva os valores como strings ou em unidades menores: `19.99` como literal `Decimal` passa por `Double`, e o `Money` o rejeita em vez de cobrar `19.98999999999999488`.

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

### Dados do cartão

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

Coletar números de cartão nos seus próprios campos coloca o app no escopo do PCI DSS; sempre que puder, prefira o Apple Pay ou o campo de cartão do seu provedor de pagamentos.

### Testes

O `TestStoreClient` mantém produtos e transações na memória e simula reembolsos, renovações, upgrades, Family Sharing, entregas repetidas, aprovações do Ask to Buy e compras em outros dispositivos, de modo que a lógica de compra roda em testes de unidade comuns:

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

## Demonstração

| Loja | Checkout | Folha do Apple Pay | Formulário do cartão |
| ---- | -------- | ------------------ | -------------------- |
| ![Pro desbloqueado após uma assinatura, claro](docs/images/store-light.png) | ![Carrinho com opções de entrega, claro](docs/images/checkout-light.png) | ![Folha do Apple Pay com o total do carrinho, claro](docs/images/apple-pay-light.png) | ![Formulário do cartão com um erro abaixo de cada campo, claro](docs/images/card-light.png) |
| ![Pro desbloqueado após uma assinatura, escuro](docs/images/store-dark.png) | ![Carrinho com opções de entrega, escuro](docs/images/checkout-dark.png) | ![Folha do Apple Pay com o total do carrinho, escuro](docs/images/apple-pay-dark.png) | ![Formulário do cartão com um erro abaixo de cada campo, escuro](docs/images/card-dark.png) |

As capturas de tela vêm dos testes de UI do app de exemplo em um simulador de iPhone, executados por [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh): uma assinatura comprada por meio do teste do StoreKit no Xcode, o carrinho e a folha real do Apple Pay com o total, e o formulário do cartão depois de conferir um cartão digitado errado.

Para experimentar por conta própria, abra o `PaymentLab.xcodeproj` em [`Examples/PaymentLab`](Examples/PaymentLab), escolha um simulador de iPhone e clique em **Run**. [Examples/README.md](Examples/README.md) mostra como executá-lo com o servidor de recibos.

## Documentação

Referência da API e artigos:

- [Referência da API](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, publicada no GitHub Pages a partir de `master`)
- Gere-a localmente no Xcode com **Product › Build Documentation**, ou pela linha de comando:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Guias

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — adicione o pacote, liste os produtos e compre no simulador
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — o caminho que cada transação percorre, reembolsos e repetições, saldos de moedas, verificações de acesso e restauração
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — envio de transações assinadas, o servidor de exemplo e as transações do Xcode
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — a requisição, sua validação, a folha e o token para o seu provedor de pagamentos
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — o que é verificado, a formatação durante a digitação e a ocultação de dados
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — qual inicializador usar, os erros e a divisão exata
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` e testes do StoreKit no Xcode
  ([código-fonte](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Requisitos

| Plataforma  | Versão mínima         |
| ----------- | --------------------- |
| iOS         | 17                    |
| macOS       | 14                    |
| watchOS     | 10                    |
| visionOS    | 1                     |
| Ferramentas | Swift 6.2 · Xcode 26+ |

O Apple Pay está disponível nas quatro plataformas; as compras dentro do app no visionOS aparecem na janela ativa do app. `Money`, `Currency` e os tipos de cartão usam apenas o Foundation. O CI compila com o Xcode padrão da imagem de runner `macos-26` do GitHub; o pacote é desenvolvido com o Xcode 27. O servidor de recibos precisa do Node 24.

## Arquitetura

- `Sources/PaymentKit` é dividido por função: `Money/` (`Money`, `Currency`, análise e codificação), `Cards/` (número, bandeira, validade, código de segurança, formulário), `Store/` (store, direitos de acesso, o cliente da App Store e o cliente de teste) e `ApplePay/` (requisição, valores do pagamento, controller).
- `Store` é uma classe `@Observable` com `@MainActor`. Ela só alcança a App Store pelo protocolo `StoreClient`: `AppStoreClient` envolve o StoreKit 2 e `TestStoreClient` guarda o estado na memória. `EntitlementResolver` é um tipo puro que transforma transações em acesso, testado sem o StoreKit. `ConsumableLedger` é um actor que credita cada transação de consumível uma única vez e grava no disco o saldo e as transações tratadas em uma única escrita atômica.
- Toda entrada vinda de fora é limitada e tem o intervalo verificado: tamanhos de texto de valores e campos de cartão, valores `Decimal` antes de escalar e antes de converter para `Int64`, atrasos de atualização de validade antes de virarem uma `Duration`, quantidades de compra, número de itens e tamanho de rótulos em requisições de Apple Pay, os caches de objetos do StoreKit e de transações tratadas, e o arquivo do livro-razão (tamanho, entradas, nomes de conta, estouro de `Int64`).
- `Examples/PaymentLab` é um app iOS com testes de StoreKit hospedados no app (`SKTestSession`) e testes de UI; `Examples/ReceiptServer` é um servidor Node baseado na App Store Server Library da Apple.

Execute os testes localmente:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Roteiro

- Adicionar o pacote ao Swift Package Index; o `.spi.yml` já está no repositório.
- Status da assinatura e informações de renovação (`Product.SubscriptionInfo.Status`) ao lado dos direitos de acesso, para mensagens de nova tentativa de cobrança e de período de carência.
- Códigos de oferta e ofertas promocionais assinados pelo servidor de recibos.

## Como contribuir

Contribuições são bem-vindas. Leia o [guia de contribuição](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) e o [código de conduta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir um pull request. Relate problemas de segurança de forma privada, como descrito na [política de segurança](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licença

Publicado sob a licença MIT. Veja [LICENSE](LICENSE).
