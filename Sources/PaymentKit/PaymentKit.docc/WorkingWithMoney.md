# Working with Money

Keep amounts exact from the text field to the payment API.

## Overview

Payment APIs take amounts in minor units: `1999` cents for 19.99 US dollars, `500` yen for 500
yen, `1234` fils for 1.234 Kuwaiti dinars. ``Money`` stores exactly that, an `Int64` of minor
units next to a ``Currency`` that knows its ISO 4217 number of decimals, so every value is one
your payment provider accepts.

```swift
let price = try Money("19.99", .usd)
let tax = try price.multiplied(by: Decimal(8) / 100) // 1.60, rounded half to even
let total = try price.adding(tax)                    // 21.59 USD
print(total.minorUnits)                              // 2159, what payment APIs expect
print(total.formatted(locale: Locale(identifier: "en_US"))) // $21.59
```

### Create amounts

| Source                                      | Use                                    |
| ------------------------------------------- | -------------------------------------- |
| A literal or an API value such as `"19.99"` | ``Money/init(_:_:)-(String,_)``          |
| Minor units from a payment API              | ``Money/init(minorUnits:currency:)``     |
| What a person typed in their locale         | ``Money/init(parsing:currency:locale:)`` |
| A computed `Decimal` that must be exact     | ``Money/init(_:_:)-(Decimal,_)``         |
| A computed `Decimal` to round               | ``Money/init(rounding:_:rule:)``         |

Do not write amounts as floating-point literals. `19.99` as a `Decimal` literal goes through
`Double` and becomes `19.98999999999999488`; the exact initializer rejects it with
``MoneyError/tooManyFractionDigits(currency:)`` instead of charging a different amount.

### Errors instead of surprises

Every initializer and operation throws a ``MoneyError`` rather than rounding silently or
crashing:

- more decimals than the currency has: `10.999` dollars or `10.5` yen;
- `Decimal.nan` as an amount or a factor;
- more than ``Money/maximumMinorUnits`` minor units, which keeps amounts exact in `Int64` and in
  the 53-bit integers of JavaScript and JSON parsers;
- adding amounts in different currencies;
- text that is not a plain number: symbols, letters, exponents, a second decimal separator, or
  more than ``Money/maximumTextLength`` characters;
- typed text with a grouping separator that does not group digits, such as `12,50` in the
  United States or `0.99` in Germany, which would otherwise become 100 times the amount.

### Split without losing a cent

``Money/allocated(_:)`` splits an amount by integer ratios and gives the minor units that do not
divide evenly to the parts with the largest remainders, so the parts always add up to the total:

```swift
try Money("100", .usd).split(into: 3).map(\.minorUnits)      // [3334, 3333, 3333]
try Money("0.10", .usd).allocated([1, 2]).map(\.minorUnits)  // [3, 7]
```

### Encode for an API

``Money`` encodes as `{"amount": "19.99", "currency": "USD"}`, with the amount as a string so no
JSON parser turns it into a `Double`, and decoding checks the amount like the string
initializer. ``Money/minorUnits`` and ``Money/plainAmount`` give the forms most payment APIs ask
for.

## See Also

- ``Money``
- ``Currency``
- ``MoneyError``
