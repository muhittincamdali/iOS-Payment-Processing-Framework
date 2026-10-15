#if canImport(PassKit)
import Foundation
import PassKit
#if os(macOS)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

extension ApplePayRequest {
    /// The PassKit request for this payment, after ``validate()``.
    ///
    /// The total line uses ``merchantName`` and is pending when any item is.
    public func makePaymentRequest() throws(ApplePayRequestError) -> PKPaymentRequest {
        try validate()
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.countryCode = countryCode
        request.currencyCode = currency.code
        request.supportedNetworks = supportedNetworks.map(\.passKitNetwork)
        request.merchantCapabilities = capabilities.passKitCapabilities
        request.requiredBillingContactFields = Set(requiredBillingFields.map(\.passKitField))
        request.requiredShippingContactFields = Set(requiredShippingFields.map(\.passKitField))
        request.shippingMethods = shippingMethods.map(\.passKitMethod)
        request.paymentSummaryItems = try summaryItems(shippingMethodID: nil)
        return request
    }

    /// The summary lines PassKit shows for a shipping choice, ending with the total.
    func summaryItems(shippingMethodID: String?) throws(ApplePayRequestError) -> [PKPaymentSummaryItem] {
        var lines = items.map { item in
            PKPaymentSummaryItem(label: item.label, amount: item.amount.decimalNumber, type: item.isPending ? .pending : .final)
        }
        if let shipping = try shippingMethod(withID: shippingMethodID) {
            lines.append(PKPaymentSummaryItem(label: shipping.label, amount: shipping.amount.decimalNumber))
        }
        let total = try total(shippingMethodID: shippingMethodID)
        let isPending = items.contains(where: \.isPending)
        lines.append(PKPaymentSummaryItem(label: merchantName, amount: total.decimalNumber, type: isPending ? .pending : .final))
        return lines
    }
}

/// Shows the Apple Pay payment sheet and reports the payment with async/await.
///
/// ```swift
/// let controller = ApplePayController()
/// let outcome = try await controller.pay(request) { payment in
///     // Send the token to your server, which charges it through your payment provider.
///     do {
///         try await api.charge(payment.token.serverPayload())
///         return .success
///     } catch {
///         return .failure(message: "The card was declined.")
///     }
/// }
/// ```
///
/// Works in SwiftUI and UIKit apps alike: it uses `PKPaymentAuthorizationController`, which
/// needs no view controller.
@MainActor
public final class ApplePayController {
    private var session: Session?

    public init() {}

    /// Whether the device supports Apple Pay at all (parental controls can turn it off).
    public static func canMakePayments() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    /// Whether the person has a card of one of `networks` in Wallet. When this is `false`,
    /// show a Set Up Apple Pay button instead of a Buy with Apple Pay button.
    public static func canMakePayments(using networks: [ApplePayNetwork], capabilities: ApplePayCapabilities = .threeDSecure) -> Bool {
        PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: networks.map(\.passKitNetwork),
            capabilities: capabilities.passKitCapabilities
        )
    }

    /// Whether a payment sheet is showing.
    public var isPresenting: Bool { session != nil }

    /// Shows the payment sheet and waits until the person closes it.
    ///
    /// - Parameters:
    ///   - request: The payment; it is validated before the sheet shows.
    ///   - authorize: Called once the person authorizes. Charge the token here, through your
    ///     server and payment provider, and return the result for the sheet to show. If it
    ///     returns `.failure`, the person can try another card and `authorize` runs again.
    /// - Throws: ``ApplePayError/invalidRequest(_:)``, ``ApplePayError/couldNotPresent`` or
    ///   ``ApplePayError/paymentInProgress``.
    public func pay(
        _ request: ApplePayRequest,
        authorize: @escaping @MainActor (ApplePayPayment) async -> ApplePayAuthorizationResult
    ) async throws(ApplePayError) -> ApplePayOutcome {
        guard session == nil else { throw .paymentInProgress }
        let paymentRequest: PKPaymentRequest
        do {
            paymentRequest = try request.makePaymentRequest()
        } catch {
            throw .invalidRequest(error)
        }

        let session = Session(request: request, authorize: authorize)
        self.session = session
        defer { self.session = nil }

        let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        controller.delegate = session
        guard await controller.present() else { throw .couldNotPresent }
        return await session.outcome()
    }

    /// The delegate of one payment sheet; it resumes the caller exactly once.
    @MainActor
    final class Session: NSObject, @MainActor PKPaymentAuthorizationControllerDelegate {
        private let request: ApplePayRequest
        private let authorize: @MainActor (ApplePayPayment) async -> ApplePayAuthorizationResult
        private var lastPayment: ApplePayPayment?
        private var lastResult: ApplePayAuthorizationResult?
        private var continuation: CheckedContinuation<ApplePayOutcome, Never>?
        private var finishedOutcome: ApplePayOutcome?
        private var authorization: Task<Void, Never>?

        init(request: ApplePayRequest, authorize: @escaping @MainActor (ApplePayPayment) async -> ApplePayAuthorizationResult) {
            self.request = request
            self.authorize = authorize
        }

        func outcome() async -> ApplePayOutcome {
            if let finishedOutcome { return finishedOutcome }
            return await withCheckedContinuation { continuation = $0 }
        }

        func paymentAuthorizationController(
            _ controller: PKPaymentAuthorizationController,
            didAuthorizePayment payment: PKPayment,
            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
        ) {
            let value = ApplePayPayment(payment)
            authorization = Task { @MainActor in
                let result = await authorize(value)
                lastPayment = value
                lastResult = result
                completion(result.passKitResult)
            }
        }

        func paymentAuthorizationController(
            _ controller: PKPaymentAuthorizationController,
            didSelectShippingMethod shippingMethod: PKShippingMethod,
            handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
        ) {
            let items = (try? request.summaryItems(shippingMethodID: shippingMethod.identifier)) ?? []
            completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: items))
        }

        func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
            controller.dismiss()
            // The sheet can close before `authorize` returns (it times out after a while).
            // Wait for the charge, so a payment that went through is not reported as cancelled.
            let pending = authorization
            Task { @MainActor in
                await pending?.value
                finish(Self.outcome(payment: lastPayment, result: lastResult))
            }
        }

        #if os(macOS)
        func presentationWindow(for controller: PKPaymentAuthorizationController) -> NSWindow? {
            NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow
        }
        #elseif os(iOS) || os(visionOS)
        func presentationWindow(for controller: PKPaymentAuthorizationController) -> UIWindow? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .keyWindow
        }
        #endif

        private func finish(_ outcome: ApplePayOutcome) {
            guard finishedOutcome == nil else { return }
            finishedOutcome = outcome
            continuation?.resume(returning: outcome)
            continuation = nil
        }

        /// The outcome for the last authorization, if any, when the sheet closes.
        nonisolated static func outcome(payment: ApplePayPayment?, result: ApplePayAuthorizationResult?) -> ApplePayOutcome {
            guard let payment, let result else { return .cancelled }
            return result == .success ? .paid(payment) : .failed(payment)
        }
    }
}

// MARK: - PassKit mapping

extension ApplePayNetwork {
    var passKitNetwork: PKPaymentNetwork {
        switch self {
        case .visa: .visa
        case .masterCard: .masterCard
        case .amex: .amex
        case .discover: .discover
        case .jcb: .JCB
        case .chinaUnionPay: .chinaUnionPay
        case .maestro: .maestro
        case .interac: .interac
        case .eftpos: .eftpos
        case .mada: .mada
        case .cartesBancaires: .cartesBancaires
        case .girocard: .girocard
        case .elo: .elo
        case .mir: .mir
        }
    }
}

extension ApplePayCapabilities {
    var passKitCapabilities: PKMerchantCapability {
        var result: PKMerchantCapability = []
        if contains(.threeDSecure) { result.insert(.threeDSecure) }
        if contains(.emv) { result.insert(.emv) }
        if contains(.credit) { result.insert(.credit) }
        if contains(.debit) { result.insert(.debit) }
        return result
    }
}

extension ApplePayContactField {
    var passKitField: PKContactField {
        switch self {
        case .name: .name
        case .postalAddress: .postalAddress
        case .emailAddress: .emailAddress
        case .phoneNumber: .phoneNumber
        }
    }
}

extension ApplePayShippingMethod {
    var passKitMethod: PKShippingMethod {
        let method = PKShippingMethod(label: label, amount: amount.decimalNumber)
        method.identifier = id
        method.detail = detail
        return method
    }
}

extension ApplePayAuthorizationResult {
    var passKitResult: PKPaymentAuthorizationResult {
        switch self {
        case .success:
            return PKPaymentAuthorizationResult(status: .success, errors: nil)
        case .failure(let message):
            let errors = message.map { [NSError(domain: PKPaymentErrorDomain, code: PKPaymentError.Code.unknownError.rawValue, userInfo: [NSLocalizedDescriptionKey: $0])] }
            return PKPaymentAuthorizationResult(status: .failure, errors: errors)
        }
    }
}

extension ApplePayPayment {
    init(_ payment: PKPayment) {
        let token = payment.token
        self.init(
            token: ApplePayToken(
                paymentData: token.paymentData,
                transactionIdentifier: token.transactionIdentifier,
                network: token.paymentMethod.network?.rawValue,
                displayName: token.paymentMethod.displayName,
                type: token.paymentMethod.type.name
            ),
            billingContact: payment.billingContact.map(ApplePayContact.init),
            shippingContact: payment.shippingContact.map(ApplePayContact.init),
            shippingMethodID: payment.shippingMethod?.identifier
        )
    }
}

extension ApplePayContact {
    init(_ contact: PKContact) {
        self.init(
            givenName: contact.name?.givenName,
            familyName: contact.name?.familyName,
            emailAddress: contact.emailAddress,
            phoneNumber: contact.phoneNumber?.stringValue,
            postalAddress: contact.postalAddress.map { address in
                PostalAddress(
                    street: address.street, city: address.city, state: address.state,
                    postalCode: address.postalCode, country: address.country, isoCountryCode: address.isoCountryCode
                )
            }
        )
    }
}

extension PKPaymentMethodType {
    var name: String {
        switch self {
        case .debit: "debit"
        case .credit: "credit"
        case .prepaid: "prepaid"
        case .store: "store"
        case .eMoney: "eMoney"
        default: "unknown"
        }
    }
}
#endif
