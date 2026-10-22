# Contributing

Thanks for taking the time to improve PaymentKit.

## Reporting bugs

Open an issue with:

- the product type, amount, currency or card brand involved (never a real card number, security
  code, payment token or signed transaction from a production purchase),
- what you expected and what happened,
- platform and OS version (simulator or device), Xcode version, and whether StoreKit ran with a
  StoreKit configuration file, in the sandbox or in production.

Report security issues privately, as described in the
[security policy](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md), not in an
issue. That includes anything that unlocks content without a verified purchase, keeps access or
coins after a refund, credits a purchase twice, prints a card
number or payment data in full, or lets an amount, a transaction or a request to the receipt
server make the app or the server crash, hang or grow without limit.

## Pull requests

1. Fork the repository and branch from `master`.
2. Keep each pull request focused on one change.
3. Run the tests on macOS and on an iOS simulator:

    ```sh
    swift test
    xcodebuild test -scheme PaymentKit \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
    ```

4. If you change money, card, entitlement or store logic, add or update a test in `Tests/`.
   Store tests use `TestStoreClient` and a manual clock, so they do not depend on StoreKit or the
   time of day.
5. Code that reads input from outside the app (typed text, decoded JSON, transactions, payment
   data, requests to the server) must bound how much memory and time it can use, and must
   range-check a `Decimal` or `Double` before turning it into an integer or a `Duration`. Add a
   test with hostile input.
6. If you change a README code sample, change the copy in
   `Examples/PaymentLab/PaymentLab/ReadmeSamples.swift` as well. That file is what gets compiled:
   by the example app, and by `swift test` through the symlink
   `Tests/PaymentKitTests/ReadmeExamples.swift`.
7. If you change the store, Apple Pay or the example app, run PaymentLab's StoreKit and UI tests
   ([Examples/README.md](Examples/README.md) shows how, with the simulator in English (US)), and
   regenerate the screenshots with `scripts/capture-screenshots.sh`.
8. If you change the receipt server, run `npm test` in `Examples/ReceiptServer`.
9. `README.md` will have translations (`README.<language>.md`). Each one records the version of
   `README.md` it follows, and CI fails while a translation is behind. If you change `README.md`
   and cannot update the translations, say so in the pull request.

## Code style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- The package builds in the Swift 6 language mode; new code should not add warnings.
- Document public API with DocC comments (`///`), and keep `xcodebuild docbuild` free of
  warnings.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `ci:`, `chore:`).

## License

By contributing you agree that your contributions are licensed under the MIT License.
