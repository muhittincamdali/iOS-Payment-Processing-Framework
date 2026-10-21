<!-- i18n-source: README.md@e68f0b6794c4c529511beeda5aad2fd7d9ceea51 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="CI 상태"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="최신 버전: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="지원 플랫폼: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="언어 버전: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="라이선스: MIT"></picture></a>
</p>

<p align="center">
<a href="#빠른-시작"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-ko-light.svg" alt="시작하기"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-ko-light.svg" alt="문서"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ko-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ko-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-ko-light.svg" alt="예제"></picture></a>
</p>

> 이 문서는 영어 README의 번역본입니다. 내용이 다를 경우 영어 버전이 최신입니다.

<!-- brand:end -->

PaymentKit은 Apple 플랫폼 앱의 결제 코드를 위한 Swift 패키지입니다. StoreKit 2로 인앱 구매를 판매하고, Apple Pay를 받으며, 금액과 카드 정보를 다룹니다. 조용히 실패하기 쉬운 부분을 바로잡아 줍니다. 콘텐츠를 전달하기 전에 끝낸 구매는 사라지고, `19.99` 같은 `Decimal` 리터럴은 사실 `19.98999999999999488`이며, 앱이 꺼져 있는 동안 도착한 환불은 접근 권한을 회수하지 못하고, 카드 번호가 `print`를 통해 로그에 남습니다. 저장소에는 iOS 예제 앱과, Apple의 App Store Server Library로 구매를 검증하는 Node 서버도 들어 있습니다. 이 패키지는 Apple SDK 외의 의존성이 없습니다.

## 주요 기능

- **전달한 뒤에 완료하는 구매** — `Store`는 StoreKit의 서명을 확인하고, 검증된 각 트랜잭션을 `deliver` 클로저에 넘기며, 그 클로저가 반환된 뒤에야 트랜잭션을 완료합니다. 전달에 실패한 트랜잭션은 다음 실행 때 다시 도착합니다. 환불은 새 구매가 아니라 `.revoked`로 도착합니다.
- **코인은 정확히 한 번만 지급** — 지급량이 정의된 소모성 상품은 원장에 기록됩니다. 원장은 잔액과 처리된 트랜잭션을 한 번의 원자적 쓰기로 저장하므로, 중복 전달, `finish()` 이전의 재시작, 환불이 있어도 두 번 지급되지 않습니다.
- **App Store를 따라가는 접근 권한** — 갱신, 환불, Ask to Buy 승인, 다른 기기에서의 구매가 `entitlements`에 자동으로 반영됩니다. 앱이 실행 중일 때 만료되는 구독은 만료 시각에 제거되고, App Store가 갱신하지 못한 구독은 Billing Grace Period가 끝날 때까지 접근 권한을 유지합니다.
- **정확한 금액** — `Money`는 ISO 4217 통화의 최소 단위로 금액을 저장합니다. 소수 자릿수가 너무 많거나, `NaN`, 오버플로, 서로 다른 통화가 섞이면 반올림하거나 크래시하는 대신 오류를 던지며, 금액을 나눠도 1센트도 사라지지 않습니다.
- **검증된 Apple Pay 요청** — `ApplePayRequest`는 PassKit이 요청을 받기 전에 판매자, 통화, 레이블, 합계를 검증하고, `ApplePayController`는 결제 결과를 async/await로 알려 줍니다.
- **유출되지 않는 카드 정보** — `CardNumber`, `CardSecurityCode`, `CardForm`은 입력(브랜드, 길이, Luhn, 유효 기간)을 검증하며, 로그, `dump`, 디버거에서는 `•••• 4242`로 출력됩니다.
- **엔드 투 엔드 테스트** — macOS와 iPhone 시뮬레이터에서 Swift Testing 테스트 134개, 예제 앱에서 StoreKit 테스트 10개와 UI 테스트 4개(Xcode를 통한 실제 StoreKit과 실제 Apple Pay 시트), 영수증 서버 테스트 38개를 실행합니다.

## 빠른 시작

**1. 패키지 추가**

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

`PaymentKit` 라이브러리를 앱 타깃에 추가하세요.

**2. 모듈 가져오기**

```swift
import PaymentKit
```

**3. 사용하기**

새 iOS 앱의 `ContentView.swift`를 다음 내용으로 바꾸세요.

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

App Store Connect에 상품이 아직 없는 상태에서 시뮬레이터로 구매해 보려면, StoreKit 구성 파일(**File › New › File from Template… › StoreKit Configuration File**)을 추가하고 자동 갱신 구독 `pro.monthly`와 비소모성 상품 `pro.lifetime`을 만든 다음, **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration**에서 선택하세요. 앱을 실행하고 상품을 탭하면 구매 후 텍스트가 **Pro is unlocked**로 바뀝니다.

## 설치

### Swift Package Manager

Xcode에서 **File › Add Package Dependencies…**를 선택하고 저장소 URL을 입력하세요.

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

또는 `Package.swift`의 `dependencies`에 추가하세요.

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

## 사용법

아래 예제는
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift)
에서 가져온 것이며, 예제 앱과 패키지 테스트가 이 파일을 컴파일합니다.

### 인앱 구매 판매하기

앱이 시작될 때 `Store`를 하나 만들고 바로 `start()`를 호출하세요. 검증된 새 트랜잭션과 환불은 모두 StoreKit이 완료하기 전에 `deliver`를 거칩니다. 여기서 오류를 던지면 트랜잭션이 완료되지 않은 상태로 남고, StoreKit은 다음 실행 때 다시 전달합니다.

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

`store.hasEntitlement("pro")`는 지금 Pro가 잠금 해제되어 있는지 알려 줍니다. 이 값은 변경이 있을 때마다 StoreKit이 검증한 트랜잭션으로부터 다시 계산되므로, 환불, 만료, 업그레이드가 있으면 접근 권한이 회수되며 값을 누적해서 만들지 않습니다. StoreKit이 검증하지 못한 트랜잭션은 전달되지도, 완료되지도 않습니다.

코인은 StoreKit이 같은 트랜잭션을 몇 번 보내더라도 `ConsumableLedger`가 트랜잭션당 한 번만 지급합니다. 코인은 `try await store.spend(30, of: "coins")`로 사용합니다. 원장은 기기에 있고 StoreKit이 보내는 환불만 볼 수 있습니다. 아직 완료되지 않은 팩의 환불은 도착하며 그 팩은 아무것도 지급하지 않지만, 완료된 팩의 환불은 StoreKit이 앱에 보내지 않으므로 그 코인은 원장에 남습니다. 그 환불은 서버만 `REFUND` App Store Server Notification으로 알게 되므로, 가치가 있는 것은 서버를 기준으로 삼아야 합니다.

### 구매 처리하기

`purchase(_:options:)`는 타입이 지정된 `StoreError`를 던집니다.

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

### 서버에서 구매 검증하기

각 트랜잭션에는 App Store가 서명한 JWS인 `signedTransaction`이 들어 있습니다. 이것을 (위의 `makeStore`처럼) `deliver`에서 Apple의 App Store Server Library로 검증하는 서버에 보내세요. [`Examples/ReceiptServer`](Examples/ReceiptServer)가 그런 서버이며 Node 24에서 동작합니다.

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

이 서버는 Apple Root CA - G3까지의 인증서 체인, 번들 식별자, 환경을 확인하고, app account token별 접근 권한을 재시작해도 사라지지 않는 파일에 보관하며, 환불이 접근 권한을 회수하고 Billing Grace Period 동안에는 접근 권한이 유지되도록 App Store Server Notifications를 받고, 소모성 상품은 한 번만 지급하며, 모든 요청을 제한합니다. Xcode에서 StoreKit 구성 파일로 만든 트랜잭션은 App Store가 서명하지 않습니다. 서버는 `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1`일 때만 이를 받아들이며, `NODE_ENV=production`에서는 절대 받아들이지 않습니다.

### 금액

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

금액은 문자열이나 최소 단위로 쓰세요. `Decimal` 리터럴 `19.99`는 `Double`을 거치기 때문에, `Money`는 `19.98999999999999488`을 청구하는 대신 이를 거부합니다.

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

### 카드 정보

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

카드 번호를 직접 만든 입력란에서 받으면 앱이 PCI DSS 적용 범위에 들어갑니다. 가능하면 Apple Pay나 결제 서비스 제공업체의 카드 입력란을 사용하세요.

### 테스트

`TestStoreClient`는 상품과 트랜잭션을 메모리에 보관하고, 환불, 갱신, 업그레이드, Family Sharing, 반복 전달, Ask to Buy 승인, 다른 기기에서의 구매를 시뮬레이션합니다. 그래서 구매 로직을 일반 단위 테스트에서 실행할 수 있습니다.

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

## 데모

| 스토어 | 결제 | Apple Pay 시트 | 카드 입력 폼 |
| ------ | ---- | -------------- | ------------ |
| ![구독 후 Pro가 잠금 해제된 화면, 라이트](docs/images/store-light.png) | ![배송 옵션이 있는 장바구니, 라이트](docs/images/checkout-light.png) | ![장바구니 합계가 표시된 Apple Pay 시트, 라이트](docs/images/apple-pay-light.png) | ![각 필드 아래에 오류가 표시된 카드 입력 폼, 라이트](docs/images/card-light.png) |
| ![구독 후 Pro가 잠금 해제된 화면, 다크](docs/images/store-dark.png) | ![배송 옵션이 있는 장바구니, 다크](docs/images/checkout-dark.png) | ![장바구니 합계가 표시된 Apple Pay 시트, 다크](docs/images/apple-pay-dark.png) | ![각 필드 아래에 오류가 표시된 카드 입력 폼, 다크](docs/images/card-dark.png) |

스크린샷은 iPhone 시뮬레이터에서 실행한 예제 앱의 UI 테스트에서 가져온 것이며, [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh)가 실행합니다. Xcode의 StoreKit 테스트로 구매한 구독, 장바구니와 합계가 표시된 실제 Apple Pay 시트, 잘못 입력한 카드를 확인한 뒤의 카드 입력 폼입니다.

직접 사용해 보려면 [`Examples/PaymentLab`](Examples/PaymentLab)에서 `PaymentLab.xcodeproj`를 열고, iPhone 시뮬레이터를 선택한 다음 **Run**을 누르세요. 영수증 서버와 함께 실행하는 방법은 [Examples/README.md](Examples/README.md)에 있습니다.

## 문서

API 레퍼런스와 문서:

- [API 레퍼런스](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC, `master`에서 GitHub Pages로 게시)
- 로컬에서는 Xcode의 **Product › Build Documentation**으로 빌드하거나 명령줄에서 빌드하세요.

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## 가이드

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — 패키지 추가, 상품 목록 표시, 시뮬레이터에서 구매하기
  ([소스](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — 모든 트랜잭션이 거치는 경로, 환불과 반복 전달, 코인 잔액, 접근 권한 확인, 구매 복원
  ([소스](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — 서명된 트랜잭션 보내기, 예제 서버, Xcode 트랜잭션
  ([소스](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — 요청, 요청 검증, 시트, 결제 서비스 제공업체에 넘길 토큰
  ([소스](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — 검증하는 항목, 입력 중 서식 지정, 마스킹
  ([소스](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — 어떤 이니셜라이저를 쓸지, 오류, 정확한 분할
  ([소스](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient`와 Xcode의 StoreKit 테스트
  ([소스](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## 요구 사항

| 플랫폼   | 최소 버전             |
| -------- | --------------------- |
| iOS      | 17                    |
| macOS    | 14                    |
| watchOS  | 10                    |
| visionOS | 1                     |
| 툴체인   | Swift 6.2 · Xcode 26+ |

Apple Pay는 네 플랫폼 모두에서 사용할 수 있으며, visionOS의 인앱 구매는 앱의 활성 창에 표시됩니다. `Money`, `Currency`, 카드 관련 타입은 Foundation만 사용합니다. CI는 GitHub `macos-26` 러너 이미지의 기본 Xcode로 빌드하며, 패키지는 Xcode 27로 개발합니다. 영수증 서버에는 Node 24가 필요합니다.

## 아키텍처

- `Sources/PaymentKit`은 역할별로 나뉩니다. `Money/`(`Money`, `Currency`, 파싱과 인코딩), `Cards/`(번호, 브랜드, 유효 기간, 보안 코드, 폼), `Store/`(store, 접근 권한, App Store 클라이언트와 테스트 클라이언트), `ApplePay/`(요청, 결제 값, 컨트롤러)입니다.
- `Store`는 `@MainActor`가 붙은 `@Observable` 클래스입니다. App Store에는 `StoreClient` 프로토콜을 통해서만 접근합니다. `AppStoreClient`는 StoreKit 2를 감싸고, `TestStoreClient`는 상태를 메모리에 보관합니다. `EntitlementResolver`는 트랜잭션을 접근 권한으로 바꾸는 순수 타입이며 StoreKit 없이 테스트됩니다. `ConsumableLedger`는 소모성 트랜잭션마다 한 번만 지급하고 잔액과 처리된 트랜잭션을 한 번의 원자적 쓰기로 디스크에 저장하는 actor입니다.
- 외부에서 들어오는 입력은 범위가 제한되고 범위 검사를 거칩니다. 금액과 카드 필드의 텍스트 길이, 스케일링 전과 `Int64`로 변환하기 전의 `Decimal` 값, `Duration`이 되기 전의 유효 기간 갱신 지연, 구매 수량, Apple Pay 요청의 항목 수와 레이블 길이, StoreKit 객체와 처리된 트랜잭션의 캐시, 원장 파일(크기, 항목, 계정 이름, `Int64` 오버플로)이 해당됩니다.
- `Examples/PaymentLab`은 앱에서 호스팅하는 StoreKit 테스트(`SKTestSession`)와 UI 테스트를 갖춘 iOS 앱이며, `Examples/ReceiptServer`는 Apple의 App Store Server Library를 사용하는 Node 서버입니다.

로컬에서 테스트를 실행합니다.

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## 로드맵

- 패키지를 Swift Package Index에 추가하기. `.spi.yml`은 이미 저장소에 있습니다.
- 결제 재시도와 유예 기간 메시지를 위해, 접근 권한과 함께 구독 상태와 갱신 정보(`Product.SubscriptionInfo.Status`) 제공하기.
- 영수증 서버가 서명하는 오퍼 코드와 프로모션 오퍼.

## 기여하기

기여를 환영합니다. pull request를 열기 전에 [기여 가이드](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md)와 [행동 강령](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)을 읽어 주세요. 보안 문제는 [보안 정책](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md)에 따라 비공개로 제보해 주세요.

## 라이선스

MIT 라이선스로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
