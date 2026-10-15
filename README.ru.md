<!-- i18n-source: README.md@557b21218b732640768f41f7ee39df183686f509 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="Статус CI"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Последняя версия: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Поддерживаемые платформы: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Версия языка: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Лицензия: MIT"></picture></a>
</p>

<p align="center">
<a href="#быстрый-старт"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ru-light.svg" alt="Начать"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ru-light.svg" alt="Документация"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ru-light.svg" alt="Примеры"></picture></a>
</p>

> Это перевод README на английском языке. Если они расходятся, актуальна английская версия.

<!-- brand:end -->

PaymentKit — это Swift-пакет для платёжного кода приложений на платформах Apple. Он продаёт встроенные покупки через StoreKit 2, принимает Apple Pay и работает с суммами и данными карт. Он устраняет то, что ломается незаметно: покупка, завершённая до доставки контента, теряется; литерал `Decimal`, такой как `19.99`, на самом деле равен `19.98999999999999488`; возврат, пришедший при закрытом приложении, никогда не отзывает доступ; а номер карты попадает в лог через `print`. В репозитории есть также пример приложения для iOS и сервер на Node, который проверяет покупки с помощью App Store Server Library от Apple. У пакета нет зависимостей, кроме SDK от Apple.

## Основные возможности

- **Сначала доставка, затем завершение покупки** — `Store` проверяет подпись StoreKit, передаёт каждую проверенную транзакцию вашему замыканию `deliver` и завершает её только после того, как оно вернётся; неудавшаяся доставка повторяется при следующем запуске. Возвраты приходят как `.revoked`, а не как новая покупка.
- **Монеты начисляются ровно один раз** — расходуемые товары с заданным начислением попадают в журнал, который сохраняет баланс и обработанные транзакции одной атомарной записью, поэтому повторы, перезапуски до `finish()` и возвраты никогда не приводят к двойному начислению.
- **Доступ, следующий за App Store** — продления, возвраты, одобрения Ask to Buy и покупки на других устройствах сами обновляют `entitlements`, а подписка, истёкшая при открытом приложении, снимается в момент окончания срока.
- **Точные суммы** — `Money` хранит минимальные единицы валюты по ISO 4217; слишком много знаков после запятой, `NaN`, переполнение и смешанные валюты приводят к ошибке, а не к округлению или падению, а при разделении суммы не теряется ни одного цента.
- **Проверенные запросы Apple Pay** — `ApplePayRequest` проверяет продавца, валюту, подписи и итоговые суммы до того, как их увидит PassKit, а `ApplePayController` сообщает о платеже через async/await.
- **Данные карты, которые не утекают** — `CardNumber`, `CardSecurityCode` и `CardForm` проверяют ввод (платёжную систему, длину, алгоритм Луна, срок действия) и выводятся как `•••• 4242` в логах, в `dump` и в отладчике.
- **Сквозное тестирование** — 116 тестов Swift Testing на macOS и в симуляторе iPhone, 7 тестов StoreKit и 4 UI-теста в примере приложения (настоящий StoreKit через Xcode, настоящий лист Apple Pay) и 25 тестов для сервера квитанций.

## Быстрый старт

**1. Добавьте пакет**

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Добавьте библиотеку `PaymentKit` в таргет вашего приложения.

**2. Импортируйте модуль**

```swift
import PaymentKit
```

**3. Используйте**

Замените `ContentView.swift` в новом iOS-приложении на следующий код:

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

Чтобы покупать в симуляторе, пока товары ещё не созданы в App Store Connect, добавьте файл конфигурации StoreKit (**File › New › File from Template… › StoreKit Configuration File**) с автопродлеваемой подпиской `pro.monthly` и неисчерпаемым товаром `pro.lifetime` и выберите его в **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**. Запустите приложение и нажмите на товар: после покупки текст изменится на **Pro is unlocked**.

## Установка

### Swift Package Manager

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Или добавьте его в `dependencies` вашего `Package.swift`:

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

## Использование

Приведённые ниже примеры скопированы из
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift),
который компилируют пример приложения и тесты пакета.

### Продажа встроенных покупок

Создайте один `Store` при запуске приложения и сразу вызовите `start()`. Каждая новая проверенная транзакция и каждый возврат проходят через `deliver`, прежде чем StoreKit их завершит; если там выбросить ошибку, транзакция останется незавершённой, и StoreKit доставит её снова при следующем запуске.

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

`store.hasEntitlement("pro")` отвечает, разблокирован ли Pro сейчас. Значение пересчитывается по проверенным транзакциям StoreKit после каждого изменения, поэтому возврат, истечение срока или апгрейд отзывают доступ; оно никогда не накапливается. Транзакции, которые StoreKit не может проверить, не доставляются и не завершаются.

Монеты начисляет `ConsumableLedger` один раз за транзакцию, сколько бы раз StoreKit её ни присылал, а возврат списывает их обратно тоже один раз (баланс может уйти ниже нуля, если монеты уже потрачены). Тратьте их через `try await store.spend(30, of: "coins")`. Журнал хранится на устройстве; для всего, что имеет ценность, источником истины остаётся сервер.

### Обработка покупки

`purchase(_:options:)` выбрасывает типизированную `StoreError`:

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

### Проверка покупок на сервере

Каждая транзакция содержит `signedTransaction` — JWS, подписанный App Store. Отправляйте его из `deliver` (как это делает `makeStore` выше) на сервер, который проверяет его с помощью App Store Server Library от Apple. [`Examples/ReceiptServer`](Examples/ReceiptServer) — именно такой сервер на Node 24:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Он проверяет цепочку сертификатов до Apple Root CA - G3, идентификатор бандла и окружение, хранит права доступа для каждого app account token, принимает App Store Server Notifications, чтобы возвраты отзывали доступ, начисляет расходуемый товар один раз и ограничивает каждый запрос. Транзакции, созданные с файлом конфигурации StoreKit в Xcode, App Store не подписывает; сервер принимает их только при `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1` и никогда при `NODE_ENV=production`.

### Денежные суммы

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

Записывайте суммы строками или в минимальных единицах: литерал `Decimal` `19.99` проходит через `Double`, и `Money` отклоняет его, а не списывает `19.98999999999999488`.

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

### Данные карты

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

Если вы собираете номера карт в собственных полях, приложение попадает в сферу действия PCI DSS; по возможности используйте Apple Pay или поле для карты от вашего платёжного провайдера.

### Тестирование

`TestStoreClient` хранит товары и транзакции в памяти и имитирует возвраты, продления, апгрейды, Family Sharing, повторные доставки, одобрения Ask to Buy и покупки на других устройствах, так что логика покупок запускается в обычных модульных тестах:

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

## Демо

| Магазин | Оформление заказа | Лист Apple Pay | Форма карты |
| ------- | ----------------- | -------------- | ----------- |
| ![Pro разблокирован после подписки, светлая тема](docs/images/store-light.png) | ![Корзина с вариантами доставки, светлая тема](docs/images/checkout-light.png) | ![Лист Apple Pay с итоговой суммой корзины, светлая тема](docs/images/apple-pay-light.png) | ![Форма карты с ошибкой под каждым полем, светлая тема](docs/images/card-light.png) |
| ![Pro разблокирован после подписки, тёмная тема](docs/images/store-dark.png) | ![Корзина с вариантами доставки, тёмная тема](docs/images/checkout-dark.png) | ![Лист Apple Pay с итоговой суммой корзины, тёмная тема](docs/images/apple-pay-dark.png) | ![Форма карты с ошибкой под каждым полем, тёмная тема](docs/images/card-dark.png) |

Скриншоты сделаны в UI-тестах примера приложения в симуляторе iPhone, которые запускает [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh): подписка, купленная через StoreKit testing в Xcode, корзина и настоящий лист Apple Pay с итоговой суммой, а также форма карты после проверки неверно введённой карты.

Чтобы попробовать самостоятельно, откройте `PaymentLab.xcodeproj` в [`Examples/PaymentLab`](Examples/PaymentLab), выберите симулятор iPhone и нажмите **Run**. В [Examples/README.md](Examples/README.md) описано, как запустить его вместе с сервером квитанций.

## Документация

Справочник API и статьи:

- [Справочник API](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, публикуется в GitHub Pages из ветки `master`)
- Локально соберите его в Xcode через **Product › Build Documentation** или из командной строки:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Руководства

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — добавьте пакет, выведите список товаров и купите их в симуляторе
  ([исходник](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — путь каждой транзакции, возвраты и повторы, баланс монет, проверка доступа и восстановление покупок
  ([исходник](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — отправка подписанных транзакций, пример сервера и транзакции из Xcode
  ([исходник](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — запрос, его проверка, лист оплаты и токен для вашего платёжного провайдера
  ([исходник](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — что проверяется, форматирование при вводе и маскирование
  ([исходник](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — какой инициализатор выбрать, ошибки и точное разделение сумм
  ([исходник](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` и StoreKit testing в Xcode
  ([исходник](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Требования

| Платформа   | Минимальная версия    |
| ----------- | --------------------- |
| iOS         | 17                    |
| macOS       | 14                    |
| watchOS     | 10                    |
| visionOS    | 1                     |
| Инструменты | Swift 6.2 · Xcode 26+ |

Apple Pay доступен на всех четырёх платформах; встроенные покупки на visionOS отображаются в активном окне приложения. `Money`, `Currency` и типы для карт используют только Foundation. CI собирает проект с Xcode по умолчанию из образа раннера `macos-26` на GitHub; сам пакет разрабатывается в Xcode 27. Серверу квитанций нужен Node 24.

## Архитектура

- `Sources/PaymentKit` разделён по задачам: `Money/` (`Money`, `Currency`, разбор и кодирование), `Cards/` (номер, платёжная система, срок действия, код безопасности, форма), `Store/` (store, права доступа, клиент App Store и тестовый клиент) и `ApplePay/` (запрос, значения платежа, controller).
- `Store` — это класс `@Observable` с `@MainActor`. К App Store он обращается только через протокол `StoreClient`: `AppStoreClient` оборачивает StoreKit 2, а `TestStoreClient` хранит состояние в памяти. `EntitlementResolver` — чистый тип, который превращает транзакции в доступ и тестируется без StoreKit. `ConsumableLedger` — это actor, который начисляет каждую транзакцию расходуемого товара один раз и записывает баланс и обработанные транзакции на диск одной атомарной записью.
- Входные данные извне ограничены и проверяются по диапазону: длина текста для сумм и полей карты, значения `Decimal` до масштабирования и до преобразования в `Int64`, задержки обновления срока действия до превращения в `Duration`, количество товаров в покупке, число позиций и длина подписей в запросах Apple Pay, кэши объектов StoreKit и обработанных транзакций, а также файл журнала (размер, записи, имена аккаунтов, переполнение `Int64`).
- `Examples/PaymentLab` — iOS-приложение с тестами StoreKit, выполняемыми внутри приложения (`SKTestSession`), и UI-тестами; `Examples/ReceiptServer` — сервер на Node, построенный на App Store Server Library от Apple.

Запустите тесты локально:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## План развития

- Добавить пакет в Swift Package Index; `.spi.yml` уже есть в репозитории.
- Статус подписки и информация о продлении (`Product.SubscriptionInfo.Status`) рядом с правами доступа — для сообщений о повторной попытке списания и о льготном периоде.
- Коды предложений и промо-предложения, подписанные сервером квитанций.

## Участие в разработке

Мы рады вашему участию. Перед открытием pull request прочитайте [руководство для участников](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) и [кодекс поведения](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). О проблемах безопасности сообщайте конфиденциально, как описано в [политике безопасности](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Лицензия

Распространяется по лицензии MIT. Подробнее — в файле [LICENSE](LICENSE).
