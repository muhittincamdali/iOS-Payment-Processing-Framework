import Foundation

/// A payment the person authorized with Face ID, Touch ID or the side button.
public struct ApplePayPayment: Hashable, Sendable {
    /// The encrypted card data for your payment provider.
    public let token: ApplePayToken
    /// The billing contact, with the fields the request asked for.
    public let billingContact: ApplePayContact?
    /// The shipping contact, with the fields the request asked for.
    public let shippingContact: ApplePayContact?
    /// The identifier of the selected ``ApplePayShippingMethod``.
    public let shippingMethodID: String?

    public init(token: ApplePayToken, billingContact: ApplePayContact? = nil, shippingContact: ApplePayContact? = nil, shippingMethodID: String? = nil) {
        self.token = token
        self.billingContact = billingContact
        self.shippingContact = shippingContact
        self.shippingMethodID = shippingMethodID
    }
}

/// The payment token Apple Pay returns: encrypted card data that only your payment provider
/// (or your server, with your payment processing certificate) can decrypt.
///
/// Send ``serverPayload()`` to your server and pass the token on to your provider; never
/// log it. Its description shows only the card's display name and the data's size.
public struct ApplePayToken: Hashable, Sendable {
    /// The encrypted payment data: a JSON object with `version`, `data`, `signature` and
    /// `header`, as described in Apple's payment token format reference.
    public let paymentData: Data
    /// Apple Pay's identifier for this payment.
    public let transactionIdentifier: String
    /// The card's network, such as `"Visa"`.
    public let network: String?
    /// The card's name to show, such as `"Visa 0224"`.
    public let displayName: String?
    /// `"debit"`, `"credit"`, `"prepaid"`, `"store"`, `"eMoney"` or `"unknown"`.
    public let type: String

    public init(paymentData: Data, transactionIdentifier: String, network: String?, displayName: String?, type: String) {
        self.paymentData = paymentData
        self.transactionIdentifier = transactionIdentifier
        self.network = network
        self.displayName = displayName
        self.type = type
    }

    /// The token as JSON for your server, in the structure of Apple's `PKPaymentToken`:
    ///
    /// ```json
    /// {
    ///   "paymentData": "<base64 of paymentData>",
    ///   "paymentMethod": { "displayName": "Visa 0224", "network": "Visa", "type": "debit" },
    ///   "transactionIdentifier": "…"
    /// }
    /// ```
    ///
    /// Most providers take the base64 `paymentData` (or the JSON it decodes to) as their
    /// Apple Pay token parameter.
    public func serverPayload() -> Data {
        let payload = ServerPayload(
            paymentData: paymentData.base64EncodedString(),
            paymentMethod: .init(displayName: displayName, network: network, type: type),
            transactionIdentifier: transactionIdentifier
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        // Encoding strings and optionals into JSON cannot fail.
        return (try? encoder.encode(payload)) ?? Data()
    }

    private struct ServerPayload: Encodable {
        struct Method: Encodable {
            let displayName: String?
            let network: String?
            let type: String
        }

        let paymentData: String
        let paymentMethod: Method
        let transactionIdentifier: String
    }
}

extension ApplePayToken: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// `ApplePayToken(Visa 0224, 3 KB)`; the payment data never prints.
    public var description: String {
        let size = ByteCountFormatter.string(fromByteCount: Int64(paymentData.count), countStyle: .memory)
        return "ApplePayToken(\(displayName ?? network ?? "card"), \(size))"
    }

    public var debugDescription: String { description }

    public var customMirror: Mirror {
        Mirror(self, children: ["displayName": displayName as Any, "network": network as Any, "type": type], displayStyle: .struct)
    }
}

/// Contact details from the payment sheet.
public struct ApplePayContact: Hashable, Sendable {
    public var givenName: String?
    public var familyName: String?
    public var emailAddress: String?
    public var phoneNumber: String?
    public var postalAddress: PostalAddress?

    public init(givenName: String? = nil, familyName: String? = nil, emailAddress: String? = nil, phoneNumber: String? = nil, postalAddress: PostalAddress? = nil) {
        self.givenName = givenName
        self.familyName = familyName
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.postalAddress = postalAddress
    }

    /// A postal address from the payment sheet.
    public struct PostalAddress: Hashable, Sendable {
        public var street: String
        public var city: String
        public var state: String
        public var postalCode: String
        public var country: String
        /// The two-letter ISO 3166 country code.
        public var isoCountryCode: String

        public init(street: String, city: String, state: String, postalCode: String, country: String, isoCountryCode: String) {
            self.street = street
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
            self.isoCountryCode = isoCountryCode
        }
    }
}

/// What your `authorize` closure tells the payment sheet after it charged (or failed to
/// charge) the token.
public enum ApplePayAuthorizationResult: Hashable, Sendable {
    /// The payment went through; the sheet shows a check mark.
    case success
    /// The payment failed; the sheet shows the message and lets the person try another card.
    case failure(message: String?)
}

/// How an Apple Pay payment ended.
public enum ApplePayOutcome: Hashable, Sendable {
    /// The person authorized the payment and your `authorize` closure returned `.success`.
    case paid(ApplePayPayment)
    /// The person authorized the payment, your `authorize` closure returned `.failure`, and
    /// the person closed the sheet.
    case failed(ApplePayPayment)
    /// The person closed the sheet without authorizing a payment.
    case cancelled
}

/// Why the payment sheet could not be used.
public enum ApplePayError: Error, Hashable, Sendable {
    /// The request did not pass ``ApplePayRequest/validate()``.
    case invalidRequest(ApplePayRequestError)
    /// The device cannot make payments or the sheet could not be shown, for example because
    /// the merchant identifier is not in the app's entitlements.
    case couldNotPresent
    /// Another payment sheet is showing.
    case paymentInProgress
}

extension ApplePayError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let error): error.errorDescription
        case .couldNotPresent: "Apple Pay is not available right now."
        case .paymentInProgress: "Another payment is in progress."
        }
    }
}
