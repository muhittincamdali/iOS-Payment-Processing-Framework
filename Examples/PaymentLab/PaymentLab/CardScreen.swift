import PaymentKit
import SwiftUI

/// A card form checked with `CardForm`: live grouping, brand detection and per-field errors.
struct CardScreen: View {
    @State private var form = CardForm()
    @State private var errors = CardFormErrors()
    @State private var accepted: CardDetails?
    @FocusState private var focusedField: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CardPreview(form: form)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    field("Card number", text: $form.number, error: errors.number, identifier: "card.number")
                        .onChange(of: form.number) { _, typed in
                            let formatted = CardNumber.formatForEntry(typed)
                            if formatted != typed { form.number = formatted }
                        }
                    field("MM/YY", text: $form.expiry, error: errors.expiry, identifier: "card.expiry")
                    field("Security code", text: $form.securityCode, error: errors.securityCode, identifier: "card.code")
                }

                Section {
                    Button("Check Card") { check() }
                        .accessibilityIdentifier("card.check")
                } footer: {
                    Text("In an app, pass the checked details to your payment provider's tokenization API; never send or store the number yourself.")
                }

                if let accepted {
                    Section("Ready for tokenization") {
                        Label(accepted.description, systemImage: "checkmark.seal.fill")
                            .accessibilityIdentifier("card.accepted")
                    }
                }
            }
            .navigationTitle("Card")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, error: CardValidationError?, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: text)
                .focused($focusedField, equals: identifier)
                .keyboardType(.numberPad)
                .textContentType(identifier == "card.number" ? .creditCardNumber : nil)
                .monospacedDigit()
                .accessibilityIdentifier(identifier)
            if let error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("\(identifier).error")
            }
        }
    }

    private func check() {
        focusedField = nil
        switch form.validate() {
        case .success(let details):
            errors = CardFormErrors()
            accepted = details
        case .failure(let fieldErrors):
            errors = fieldErrors
            accepted = nil
        }
    }
}

private struct CardPreview: View {
    let form: CardForm

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(form.detectedBrand.displayName)
                    .font(.headline)
                    .accessibilityIdentifier("card.brand")
                Spacer()
                Image(systemName: "wave.3.right")
            }
            Text(maskedNumber)
                .font(.title3.monospaced())
            HStack {
                Text("VALID THRU").font(.caption2)
                Text(form.expiry.isEmpty ? "MM/YY" : form.expiry).font(.callout.monospaced())
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(red: 0.04, green: 0.16, blue: 0.32), Color(red: 0, green: 0.443, blue: 0.89)], startPoint: .bottomLeading, endPoint: .topTrailing))
    }

    /// The preview never shows more than the last four digits, like a receipt.
    private var maskedNumber: String {
        let digits = form.number.filter(\.isWholeNumber)
        guard !digits.isEmpty else { return "•••• •••• •••• ••••" }
        return "•••• " + String(digits.suffix(4))
    }
}
