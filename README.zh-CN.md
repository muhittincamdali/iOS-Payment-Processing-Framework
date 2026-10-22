<!-- i18n-source: README.md@818f579670e5e23eaab254ece2280c4cb457830b status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="CI 状态"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="最新版本: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="支持的平台: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="语言版本: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="许可证: MIT"></picture></a>
</p>

<p align="center">
<a href="#快速开始"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-zh-CN-light.svg" alt="开始使用"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-zh-CN-light.svg" alt="文档"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-zh-CN-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-zh-CN-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-zh-CN-light.svg" alt="示例"></picture></a>
</p>

> 本文是英文 README 的译文。如两者内容不一致，以英文版为准。

<!-- brand:end -->

PaymentKit 是一个 Swift 软件包，用于处理 Apple 平台应用中的支付代码。它通过 StoreKit 2 销售应用内购买，支持 Apple Pay，并负责处理金额和银行卡信息。它修复了那些悄无声息出错的环节：内容尚未交付就完成的购买会丢失；像 `19.99` 这样的 `Decimal` 字面量实际上是 `19.98999999999999488`；应用关闭期间到达的退款永远不会收回访问权限；银行卡号还会通过 `print` 出现在日志里。仓库中还包含一个 iOS 示例应用，以及一个使用 Apple 的 App Store Server Library 验证购买的 Node 服务器。除 Apple 的 SDK 之外，该软件包没有任何依赖。

## 亮点

- **先交付，再完成** — `Store` 会检查 StoreKit 的签名，把每笔通过验证的交易交给你的 `deliver` 闭包，并且只有在它返回之后才完成该交易；交付失败的交易会在下次启动时再次送达。退款以 `.revoked` 的形式到达，绝不会被当作一次新购买。
- **代币只入账一次** — 定义了入账数量的消耗型商品会进入账本，账本把余额和已处理的交易放在一次原子写入中保存，因此重复投递、`finish()` 之前的重启以及退款都不会造成重复入账。
- **访问权限跟随 App Store** — 续订、退款、Ask to Buy 批准以及在其他设备上的购买都会自动更新 `entitlements`；应用运行期间到期的订阅会在到期时刻被移除，App Store 未能续订的订阅会保留访问权限，直到其 Billing Grace Period 结束。
- **精确的金额** — `Money` 以 ISO 4217 货币的最小单位存储；小数位过多、`NaN`、溢出和混用货币都会抛出错误，而不是四舍五入或崩溃，分摊时也不会丢掉一分钱。
- **经过检查的 Apple Pay 请求** — `ApplePayRequest` 会在 PassKit 接触请求之前验证商户、货币、标签和总额，`ApplePayController` 则通过 async/await 报告支付结果。
- **不泄露的银行卡信息** — `CardNumber`、`CardSecurityCode` 和 `CardForm` 会校验输入（卡品牌、长度、Luhn、有效期），并在日志、`dump` 和调试器中显示为 `•••• 4242`。
- **端到端测试** — 在 macOS 和 iPhone 模拟器上运行 141 个 Swift Testing 测试，示例应用中有 11 个 StoreKit 测试和 4 个 UI 测试（通过 Xcode 使用真实的 StoreKit 和真实的 Apple Pay 面板），收据服务器另有 38 个测试。

## 快速开始

**1. 添加软件包**

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

把 `PaymentKit` 库添加到你的应用 target。

**2. 导入模块**

```swift
import PaymentKit
```

**3. 开始使用**

把新建 iOS 应用中的 `ContentView.swift` 替换为：

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

如果商品还没有在 App Store Connect 中创建，想先在模拟器里购买，可以添加一个 StoreKit 配置文件（**File › New › File from Template… › StoreKit Configuration File**），在其中加入自动续订订阅 `pro.monthly` 和非消耗型商品 `pro.lifetime`，然后在 **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration** 中选中它。运行应用并点按一个商品：购买完成后，文字会变为 **Pro is unlocked**。

## 安装

### Swift Package Manager

在 Xcode 中选择 **File › Add Package Dependencies…**，然后输入仓库地址：

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

或者将其添加到 `Package.swift` 的 `dependencies` 中：

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

## 使用方法

下面的示例复制自
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift)，
示例应用和软件包的测试都会编译这个文件。

### 销售应用内购买

应用启动时创建一个 `Store`，并立即调用 `start()`。每一笔新的已验证交易和每一次退款，都会先经过 `deliver`，StoreKit 才会完成它；在其中抛出错误会让交易保持未完成状态，StoreKit 会在下次启动时再次送达。退款对应的访问权限和代币会在 `deliver` 运行之前收回，因为在其购买正被完成时到达的退款会随该购买一起完成，之后不会再次送达。

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

`store.hasEntitlement("pro")` 回答 Pro 当前是否已解锁。每次变化之后，它都会根据 StoreKit 已验证的交易重新计算，因此退款、到期或升级都会收回访问权限；它从来不是累加出来的。StoreKit 无法验证的交易既不会被交付，也不会被完成。

代币由 `ConsumableLedger` 按每笔交易入账一次，无论 StoreKit 重复发送多少次。用 `try await store.spend(30, of: "coins")` 来消费代币。账本保存在设备上，只能看到 StoreKit 发来的退款：尚未完成的代币包的退款会送达，该代币包不会入账；但已完成的代币包的退款，StoreKit 不会发给应用，因此这些代币会留在账本里。只有服务器会通过 `REFUND` App Store Server Notification 得知这笔退款；凡是有价值的东西，都应以服务器为准。

### 处理一次购买

`purchase(_:options:)` 会抛出带类型的 `StoreError`：

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

### 在服务器上验证购买

每笔交易都带有 `signedTransaction`，即 App Store 签名的 JWS。在 `deliver` 中（像上面的 `makeStore` 那样）把它发送给用 Apple 的 App Store Server Library 验证它的服务器。[`Examples/ReceiptServer`](Examples/ReceiptServer) 就是这样一个服务器，运行在 Node 24 上：

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

它会检查直至 Apple Root CA - G3 的证书链、bundle identifier 和环境，按 app account token 将各自的权益保存在重启后不会丢失的文件中，接收 App Store Server Notifications 以便退款后撤销访问权限、在 Billing Grace Period 内保留访问权限，对消耗型商品只入账一次，并限制每个请求。在 Xcode 中使用 StoreKit 配置文件产生的交易不是由 App Store 签名的；服务器只有在设置 `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1` 时才会接受它们，设置 `NODE_ENV=production` 时绝不接受。

### 金额

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

请用字符串或最小单位来书写金额：把 `19.99` 写成 `Decimal` 字面量会经过 `Double`，`Money` 会拒绝它，而不是去收取 `19.98999999999999488`。

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

### 银行卡信息

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

在自己的输入框中收集银行卡号会让应用落入 PCI DSS 的适用范围；在条件允许时，请优先使用 Apple Pay 或支付服务商提供的银行卡输入控件。

### 测试

`TestStoreClient` 把商品和交易保存在内存中，并可以模拟退款、续订、升级、Family Sharing、重复投递、Ask to Buy 批准以及在其他设备上的购买，因此购买逻辑可以在普通的单元测试中运行：

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

## 演示

| 商店 | 结账 | Apple Pay 面板 | 银行卡表单 |
| ---- | ---- | -------------- | ---------- |
| ![订阅后已解锁 Pro，浅色](docs/images/store-light.png) | ![带配送选项的购物车，浅色](docs/images/checkout-light.png) | ![显示购物车总额的 Apple Pay 面板，浅色](docs/images/apple-pay-light.png) | ![每个字段下方都有错误提示的银行卡表单，浅色](docs/images/card-light.png) |
| ![订阅后已解锁 Pro，深色](docs/images/store-dark.png) | ![带配送选项的购物车，深色](docs/images/checkout-dark.png) | ![显示购物车总额的 Apple Pay 面板，深色](docs/images/apple-pay-dark.png) | ![每个字段下方都有错误提示的银行卡表单，深色](docs/images/card-dark.png) |

这些截图来自示例应用在 iPhone 模拟器上的 UI 测试，由 [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh) 运行：通过 Xcode 中的 StoreKit 测试购买的订阅、购物车和显示总额的真实 Apple Pay 面板，以及输错银行卡信息并检查之后的银行卡表单。

想自己试一试，请打开 [`Examples/PaymentLab`](Examples/PaymentLab) 中的 `PaymentLab.xcodeproj`，选择一个 iPhone 模拟器并点击 **Run**。[Examples/README.md](Examples/README.md) 介绍了如何让它配合收据服务器运行。

## 文档

API 参考文档与文章：

- [API 参考](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  （DocC，从 `master` 发布到 GitHub Pages）
- 在 Xcode 中通过 **Product › Build Documentation** 在本地构建，或在命令行中构建：

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## 指南

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — 添加软件包、列出商品并在模拟器中购买
  （[源文件](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)）。
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — 每笔交易所经过的路径、退款与重复投递、代币余额、访问权限检查以及恢复购买
  （[源文件](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)）。
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — 发送已签名的交易、示例服务器以及 Xcode 中的交易
  （[源文件](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)）。
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — 请求、请求的验证、支付面板，以及交给支付服务商的 token
  （[源文件](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)）。
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — 会检查哪些内容、输入时的格式化以及脱敏显示
  （[源文件](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)）。
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — 该用哪个初始化方法、各种错误以及精确分摊
  （[源文件](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)）。
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` 与 Xcode 中的 StoreKit 测试
  （[源文件](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)）。

## 系统要求

| 平台      | 最低版本              |
| --------- | --------------------- |
| iOS       | 17                    |
| macOS     | 14                    |
| watchOS   | 10                    |
| visionOS  | 1                     |
| 工具链    | Swift 6.2 · Xcode 26+ |

Apple Pay 在这四个平台上都可用；visionOS 上的应用内购买会显示在应用当前的活动窗口中。`Money`、`Currency` 和银行卡相关类型只使用 Foundation。CI 使用 GitHub `macos-26` 运行器镜像中的默认 Xcode 构建；该软件包本身使用 Xcode 27 开发。收据服务器需要 Node 24。

## 架构

- `Sources/PaymentKit` 按职责划分：`Money/`（`Money`、`Currency`、解析与编码）、`Cards/`（卡号、卡品牌、有效期、安全码、表单）、`Store/`（store、权益、App Store 客户端和测试客户端）以及 `ApplePay/`（请求、支付值、controller）。
- `Store` 是一个 `@MainActor` 的 `@Observable` 类。它只通过 `StoreClient` 协议访问 App Store：`AppStoreClient` 封装 StoreKit 2，`TestStoreClient` 把状态保存在内存中。`EntitlementResolver` 是一个纯类型，负责把交易转换为访问权限，无需 StoreKit 即可测试。`ConsumableLedger` 是一个 actor，它让每笔消耗型交易只入账一次，并通过一次原子写入把余额和已处理的交易写到磁盘。
- 来自外部的输入都有边界并经过范围检查：金额和银行卡字段的文本长度、缩放前和转换为 `Int64` 前的 `Decimal` 值、变成 `Duration` 之前的有效期刷新延迟、购买数量、Apple Pay 请求中的条目数量和标签长度、StoreKit 对象与已处理交易的缓存，以及账本文件（大小、条目、账户名称、`Int64` 溢出）。
- `Examples/PaymentLab` 是一个 iOS 应用，带有由应用托管的 StoreKit 测试（`SKTestSession`）和 UI 测试；`Examples/ReceiptServer` 是基于 Apple 的 App Store Server Library 的 Node 服务器。

在本地运行测试：

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## 路线图

- 把软件包提交到 Swift Package Index；仓库中已经有 `.spi.yml`。
- 在 entitlements 之外提供订阅状态和续订信息（`Product.SubscriptionInfo.Status`），用于账单重试和宽限期提示。
- 由收据服务器签名的优惠码和促销优惠。

## 参与贡献

欢迎参与贡献。提交 pull request 之前，请先阅读[贡献指南](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md)和[行为准则](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)。如发现安全问题，请按照[安全策略](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md)私下报告。

## 许可证

基于 MIT 许可证发布。详见 [LICENSE](LICENSE)。
