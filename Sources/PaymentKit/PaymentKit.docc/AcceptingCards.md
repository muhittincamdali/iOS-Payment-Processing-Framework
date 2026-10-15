# Accepting Cards

Check card details as people type them, and keep the number out of logs, files and crash
reports.

## Overview

Most apps should not collect card numbers in their own text fields: doing so puts the app in
scope for the Payment Card Industry Data Security Standard (PCI DSS). Prefer Apple Pay (see
<doc:AcceptingApplePay>) or your payment provider's own card field. When you do build the form,
``CardForm`` checks the three fields, and the validated values make the safe thing the easy one.

### Check a form

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

``CardForm/validate(at:calendar:)`` returns ``CardDetails`` or a ``CardFormErrors`` with one
error per bad field, so every field can show its own message.

### What is checked

- ``CardNumber`` accepts digits with spaces or dashes, up to ``CardNumber/maximumInputLength``
  characters. It detects the ``CardBrand`` from the first digits (Visa, Mastercard including
  the 2-series, American Express, Discover, JCB, Diners Club, UnionPay, Maestro, Mir), checks
  the lengths that brand issues and the Luhn check digit. UnionPay numbers are not
  Luhn-checked, because some have no check digit.
- ``CardExpiry`` parses `MM/YY`, `M/YY`, `MMYY` and `MM/YYYY`. A card is valid through the
  last moment of its month in the calendar you pass, and years more than
  ``CardExpiry/maximumYearsAhead`` years ahead are rejected as typos.
- ``CardSecurityCode`` has 4 digits for American Express and 3 for the other brands.

### Format while typing

``CardNumber/formatForEntry(_:)`` groups the digits the way the brand prints them and stops at
the brand's longest number:

```swift
CardNumber.formatForEntry("378282246310005") // "3782 822463 10005"
```

``CardForm/detectedBrand`` tells you which logo to show before the number is complete.

### Values that do not leak

``CardNumber``, ``CardSecurityCode`` and ``CardForm`` redact themselves in `description`,
`debugDescription`, string interpolation, `dump` and `Mirror`, which also covers the debugger
and most logging and crash-reporting tools. The number appears only through
``CardNumber/unmaskedDigits``, a name that stands out in code review. None of the card types are
`Codable`, so they cannot be written to disk or into a JSON body by accident, and
``CardValidationError`` never contains the digits that were entered.

## See Also

- ``CardForm``
- ``CardNumber``
