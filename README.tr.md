<!-- i18n-source: README.md@98fd5d725c83d31c454fd5f95f5236619ebe7f14 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/banner-light.svg" alt="PaymentKit: Sell in-app purchases with StoreKit 2, take Apple Pay and keep money exact on Apple platforms."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/actions/workflows/ci.yml/badge.svg" alt="CI durumu"></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-version-light.svg" alt="Son sürüm: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-platforms-light.svg" alt="Desteklenen platformlar: iOS 17+ · macOS 14+ · watchOS 10+ · visionOS 1+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-language-light.svg" alt="Dil sürümü: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/badge-license-light.svg" alt="Lisans: MIT"></picture></a>
</p>

<p align="center">
<a href="#hızlı-başlangıç"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-start-tr-light.svg" alt="Başlayın"></picture></a>
<a href="https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-docs-tr-light.svg" alt="Dokümantasyon"></picture></a>
<a href="https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/tree/master/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/iOS-Payment-Processing-Framework/master/.github/brand/button-examples-tr-light.svg" alt="Örnekler"></picture></a>
</p>

> Bu belge İngilizce README'nin çevirisidir. İkisi arasında fark varsa güncel olan İngilizce sürümdür.

<!-- brand:end -->

PaymentKit, Apple platformlarındaki uygulamaların ödeme kodu için bir Swift paketidir. StoreKit 2 ile uygulama içi satın alma satar, Apple Pay'i kabul eder, tutarları ve kart bilgilerini yönetir. Sessizce başarısız olan kısımları düzeltir: içeriği teslim edilmeden bitirilen bir satın alma kaybolur, `19.99` gibi bir `Decimal` değişmezi aslında `19.98999999999999488`'dir, uygulama kapalıyken gelen bir iade erişimi hiçbir zaman geri almaz ve bir kart numarası `print` yoluyla log'a yazılır. Depoda ayrıca bir iOS örnek uygulaması ve satın almaları Apple'ın App Store Server Library'si ile doğrulayan bir Node sunucusu bulunur. Paketin Apple'ın SDK'sı dışında bağımlılığı yoktur.

## Öne çıkanlar

- **Satın almalar teslim edilir, sonra bitirilir** — `Store`, StoreKit'in imzasını denetler, doğrulanmış her işlemi `deliver` closure'ınıza verir ve işlemi yalnızca o closure döndükten sonra bitirir; başarısız bir teslimat bir sonraki açılışta tekrar gelir. İadeler yeni bir satın alma olarak değil, `.revoked` olarak gelir.
- **Jetonlar tam olarak bir kez eklenir** — kredisi tanımlanmış tüketilebilir ürünler, bakiyeyi ve işlenmiş işlemleri tek bir atomik yazımda kaydeden bir deftere gider; böylece tekrarlar, `finish()` öncesindeki yeniden başlatmalar ve iadeler hiçbir zaman iki kez kredi yazmaz.
- **App Store'u izleyen erişim** — yenilemeler, iadeler, Ask to Buy onayları ve diğer cihazlardaki satın almalar `entitlements` değerini kendiliğinden günceller; uygulama açıkken süresi dolan bir abonelik bitiş tarihinde kaldırılır, App Store'un yenileyemediği bir abonelik ise Billing Grace Period'u bitene kadar erişimini korur.
- **Kuruşu kuruşuna para** — `Money`, bir ISO 4217 para biriminin en küçük birimlerini saklar; fazla ondalık basamak, `NaN`, taşma ve karışık para birimleri yuvarlama ya da çökme yerine hata fırlatır; paylaştırmalarda tek kuruş kaybolmaz.
- **Denetlenen Apple Pay istekleri** — `ApplePayRequest`, satıcıyı, para birimini, etiketleri ve toplamları PassKit görmeden önce doğrular; `ApplePayController` ödemeyi async/await ile bildirir.
- **Sızmayan kart bilgileri** — `CardNumber`, `CardSecurityCode` ve `CardForm` girdiyi (marka, uzunluk, Luhn, son kullanma tarihi) doğrular; log'larda, `dump` çıktısında ve hata ayıklayıcıda `•••• 4242` olarak yazdırılır.
- **Uçtan uca test edilmiş** — macOS'ta ve bir iPhone simülatöründe 141 Swift Testing testi, örnek uygulamada 11 StoreKit testi ve 4 UI testi (Xcode üzerinden gerçek StoreKit, gerçek Apple Pay sayfası) ve makbuz sunucusu için 38 test.

## Hızlı başlangıç

**1. Paketi ekleyin**

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

`PaymentKit` kütüphanesini uygulama hedefinize ekleyin.

**2. Modülü içe aktarın**

```swift
import PaymentKit
```

**3. Kullanın**

Yeni bir iOS uygulamasının `ContentView.swift` dosyasının içeriğini şununla değiştirin:

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

Ürünler App Store Connect'te henüz yokken simülatörde satın alma yapmak için bir StoreKit yapılandırma dosyası ekleyin (**File › New › File from Template… › StoreKit Configuration File**); içine otomatik yenilenen bir `pro.monthly` aboneliği ve tüketilemeyen bir `pro.lifetime` ürünü koyun, ardından dosyayı **Product › Scheme › Edit Scheme… › Run › Options › StoreKit Configuration** altından seçin. Uygulamayı çalıştırıp bir ürüne dokunun: satın almadan sonra metin **Pro is unlocked** olur.

## Kurulum

### Swift Package Manager

Xcode'da **File › Add Package Dependencies…** menüsünü seçin ve depo adresini girin:

```text
https://github.com/muhittincamdali/iOS-Payment-Processing-Framework.git
```

Ya da `Package.swift` dosyanızdaki `dependencies` listesine ekleyin:

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

## Kullanım

Aşağıdaki örnekler
[`Examples/PaymentLab/PaymentLab/ReadmeSamples.swift`](Examples/PaymentLab/PaymentLab/ReadmeSamples.swift)
dosyasından alınmıştır; örnek uygulama ve paketin testleri bu dosyayı derler.

### Uygulama içi satın alma satışı

Uygulama açıldığında tek bir `Store` oluşturun ve hemen `start()` çağırın. Doğrulanmış her yeni işlem ve her iade, StoreKit onu bitirmeden önce `deliver` içinden geçer; orada hata fırlatmak işlemi bitirilmemiş bırakır ve StoreKit onu bir sonraki açılışta yeniden teslim eder. Bir iadenin erişimi ve jetonları `deliver` çalışmadan önce geri alınır, çünkü satın alması bitirilirken gelen bir iade onunla birlikte bitirilir ve bir daha gelmez.

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

`store.hasEntitlement("pro")`, Pro'nun şu an açık olup olmadığını söyler. Her değişiklikten sonra StoreKit'in doğrulanmış işlemlerinden yeniden hesaplanır; bu yüzden bir iade, bir süre sonu ya da bir yükseltme erişimi geri alır, değer hiçbir zaman toplanarak oluşturulmaz. StoreKit'in doğrulayamadığı işlemler ne teslim edilir ne de bitirilir.

Jetonlar, StoreKit işlemi kaç kez gönderirse göndersin işlem başına bir kez `ConsumableLedger` tarafından eklenir. Jetonları `try await store.spend(30, of: "coins")` ile harcayın. Defter cihazdadır ve yalnızca StoreKit'in gönderdiği iadeleri görür: henüz bitirilmemiş bir paketin iadesi gelir ve paket hiç jeton eklemez, ancak StoreKit bitirilmiş bir paketin iadesini uygulamaya göndermez, bu yüzden o jetonlar defterde kalır. Bu iadeyi yalnızca sunucu, bir `REFUND` App Store Server Notification ile öğrenir; değer taşıyan her şey için doğruluk kaynağı sunucudur.

### Satın alma işlemini yönetme

`purchase(_:options:)` türü belirli bir `StoreError` fırlatır:

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

### Satın almaları sunucuda doğrulama

Her işlem, App Store'un imzaladığı JWS olan `signedTransaction` değerini taşır. Bunu `deliver` içinden (yukarıdaki `makeStore` gibi), Apple'ın App Store Server Library'si ile doğrulayan bir sunucuya gönderin. [`Examples/ReceiptServer`](Examples/ReceiptServer) Node 24 üzerinde çalışan böyle bir sunucudur:

```sh
cd Examples/ReceiptServer
npm ci
BUNDLE_ID=com.example.shop APPLE_ENVIRONMENT=Sandbox npm start
```

Sunucu Apple Root CA - G3'e kadar uzanan zinciri, bundle identifier'ı ve ortamı denetler, her app account token'ın hak ettiği erişimleri yeniden başlatmada kaybolmayan bir dosyada tutar, iadelerin erişimi kaldırması ve Billing Grace Period'un erişimi koruması için App Store Server Notifications'ı alır, tüketilebilir bir ürünün kredisini bir kez yazar ve her isteği sınırlar. Xcode'da bir StoreKit yapılandırma dosyasıyla yapılan işlemler App Store tarafından imzalanmaz; sunucu bunları yalnızca `APPLE_ENVIRONMENT=Xcode ALLOW_UNVERIFIED_TRANSACTIONS=1` ile kabul eder, `NODE_ENV=production` ile asla.

### Para tutarları

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
    } catch {
        print("US dollars have two decimals: \(error)") // never rounded silently
    }
    return (total, shares)
}
```

Tutarları metin ya da en küçük birim olarak yazın: `Decimal` değişmezi olarak `19.99` `Double` üzerinden geçer ve `Money`, `19.98999999999999488` tahsil etmek yerine onu reddeder.

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

### Kart bilgileri

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

Kart numaralarını kendi alanlarınızda toplamak uygulamayı PCI DSS kapsamına sokar; mümkün olduğunda Apple Pay'i ya da ödeme sağlayıcınızın kart alanını tercih edin.

### Test etme

`TestStoreClient`, ürünleri ve işlemleri bellekte tutar; iadeleri, yenilemeleri, yükseltmeleri, Family Sharing'i, tekrarlanan teslimatları, Ask to Buy onaylarını ve diğer cihazlardaki satın almaları taklit eder. Böylece satın alma mantığı sıradan birim testlerinde çalışır:

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

| Mağaza | Ödeme | Apple Pay sayfası | Kart formu |
| ------ | ----- | ----------------- | ---------- |
| ![Abonelikten sonra Pro açık, açık tema](docs/images/store-light.png) | ![Teslimat seçenekleriyle sepet, açık tema](docs/images/checkout-light.png) | ![Sepet toplamını gösteren Apple Pay sayfası, açık tema](docs/images/apple-pay-light.png) | ![Her alanın altında bir hata olan kart formu, açık tema](docs/images/card-light.png) |
| ![Abonelikten sonra Pro açık, koyu tema](docs/images/store-dark.png) | ![Teslimat seçenekleriyle sepet, koyu tema](docs/images/checkout-dark.png) | ![Sepet toplamını gösteren Apple Pay sayfası, koyu tema](docs/images/apple-pay-dark.png) | ![Her alanın altında bir hata olan kart formu, koyu tema](docs/images/card-dark.png) |

Ekran görüntüleri, örnek uygulamanın bir iPhone simülatöründeki UI testlerinden alınır ve [`scripts/capture-screenshots.sh`](scripts/capture-screenshots.sh) ile çalıştırılır: Xcode'daki StoreKit testiyle satın alınan bir abonelik, sepet ve toplamıyla gerçek Apple Pay sayfası ve yanlış yazılmış bir kart denendikten sonraki kart formu.

Kendiniz denemek için [`Examples/PaymentLab`](Examples/PaymentLab) klasöründeki `PaymentLab.xcodeproj` dosyasını açın, bir iPhone simülatörü seçin ve **Run**'a basın. [Examples/README.md](Examples/README.md), uygulamayı makbuz sunucusuyla nasıl çalıştıracağınızı anlatır.

## Dokümantasyon

API başvuru belgeleri ve makaleler:

- [API başvurusu](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/)
  (DocC; `master` dalından GitHub Pages'e yayımlanır)
- Yerelde Xcode'da **Product › Build Documentation** ile ya da komut satırından derleyin:

```sh
xcodebuild docbuild -scheme PaymentKit -destination 'generic/platform=macOS'
```

## Rehberler

- [Getting Started](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/gettingstarted)
  — paketi ekleyin, ürünleri listeleyin ve simülatörde satın alın
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/GettingStarted.md)).
- [Selling In-App Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/sellinginapppurchases)
  — her işlemin izlediği yol, iadeler ve tekrarlar, jeton bakiyeleri, erişim denetimleri ve geri yükleme
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/SellingInAppPurchases.md)).
- [Verifying Purchases on Your Server](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/verifyingpurchasesonyourserver)
  — imzalı işlemleri göndermek, örnek sunucu ve Xcode işlemleri
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/VerifyingPurchasesOnYourServer.md)).
- [Accepting Apple Pay](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingapplepay)
  — istek, doğrulaması, ödeme sayfası ve ödeme sağlayıcınız için token
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/AcceptingApplePay.md)).
- [Accepting Cards](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/acceptingcards)
  — nelerin denetlendiği, yazarken biçimlendirme ve gizleme
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/AcceptingCards.md)).
- [Working with Money](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/workingwithmoney)
  — hangi başlatıcının kullanılacağı, hatalar ve tam paylaştırma
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/WorkingWithMoney.md)).
- [Testing Purchases](https://muhittincamdali.github.io/iOS-Payment-Processing-Framework/documentation/paymentkit/testingpurchases)
  — `TestStoreClient` ve Xcode'da StoreKit testi
  ([kaynak](Sources/PaymentKit/PaymentKit.docc/TestingPurchases.md)).

## Gereksinimler

| Platform  | En düşük sürüm        |
| --------- | --------------------- |
| iOS       | 17                    |
| macOS     | 14                    |
| watchOS   | 10                    |
| visionOS  | 1                     |
| Araç zinciri | Swift 6.2 · Xcode 26+ |

Apple Pay dört platformun hepsinde kullanılabilir; visionOS'ta uygulama içi satın almalar uygulamanın etkin penceresinde gösterilir. `Money`, `Currency` ve kart türleri yalnızca Foundation kullanır. CI, GitHub'ın `macos-26` runner imajındaki varsayılan Xcode ile derler; paket Xcode 27 ile geliştirilmiştir. Makbuz sunucusu Node 24 gerektirir.

## Mimari

- `Sources/PaymentKit` işe göre bölünmüştür: `Money/` (`Money`, `Currency`, ayrıştırma ve kodlama), `Cards/` (numara, marka, son kullanma tarihi, güvenlik kodu, form), `Store/` (store, entitlement'lar, App Store istemcisi ve test istemcisi) ve `ApplePay/` (istek, ödeme değerleri, controller).
- `Store`, `@MainActor` ile işaretli bir `@Observable` sınıftır. App Store'a yalnızca `StoreClient` protokolü üzerinden ulaşır: `AppStoreClient` StoreKit 2'yi sarar, `TestStoreClient` durumu bellekte tutar. `EntitlementResolver`, işlemleri erişime çeviren saf bir türdür ve StoreKit olmadan test edilir. `ConsumableLedger`, her tüketilebilir işlemin kredisini bir kez yazan ve bakiyeyi ile işlenmiş işlemleri diske tek bir atomik yazımla kaydeden bir actor'dür.
- Dışarıdan gelen girdi sınırlandırılır ve aralık denetiminden geçer: tutar ve kart alanlarının metin uzunlukları, ölçeklemeden ve `Int64`'e dönüştürmeden önce `Decimal` değerleri, `Duration` olmadan önce son kullanma yenileme gecikmeleri, satın alma adetleri, Apple Pay isteklerindeki öğe sayıları ve etiket uzunlukları, StoreKit nesnelerinin ve işlenmiş işlemlerin önbellekleri ve defter dosyası (boyut, kayıtlar, hesap adları, `Int64` taşması).
- `Examples/PaymentLab`, uygulama içinde çalışan StoreKit testlerine (`SKTestSession`) ve UI testlerine sahip bir iOS uygulamasıdır; `Examples/ReceiptServer`, Apple'ın App Store Server Library'si üzerine kurulu bir Node sunucusudur.

Testleri yerelde çalıştırın:

```sh
swift test                                    # macOS
xcodebuild test -scheme PaymentKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
(cd Examples/ReceiptServer && npm ci && npm test)
```

## Yol haritası

- Paketi Swift Package Index'e ekleyin; `.spi.yml` depoda zaten var.
- Yetkilendirmelerin yanında abonelik durumu ve yenileme bilgisi (`Product.SubscriptionInfo.Status`); faturalama yeniden denemesi ve ek süre mesajları için.
- Makbuz sunucusunun imzaladığı teklif kodları ve promosyon teklifleri.

## Katkıda bulunma

Katkılarınızı bekliyoruz. Pull request açmadan önce [katkı rehberini](https://github.com/muhittincamdali/iOS-Payment-Processing-Framework/blob/master/CONTRIBUTING.md) ve [davranış kurallarını](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) okuyun. Güvenlik açıklarını [güvenlik politikasında](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md) anlatıldığı gibi gizli olarak bildirin.

## Lisans

MIT lisansıyla yayımlanmıştır. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
