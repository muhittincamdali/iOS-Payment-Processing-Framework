import StoreKitTest
import XCTest

/// The three screens of Payment Lab on a simulator: purchases through StoreKit testing in
/// Xcode (Products.storekit, with an `SKTestSession` that starts each test without
/// transactions and confirms purchases without the sheet), and the real Apple Pay sheet.
///
/// `scripts/capture-screenshots.sh` runs them with `SCREENSHOT_DIR` set to save the README
/// screenshots in light and dark appearance.
@MainActor
final class PaymentLabUITests: XCTestCase {
    private var app: XCUIApplication!
    private var session: SKTestSession!

    override func setUp() async throws {
        continueAfterFailure = false
        session = try SKTestSession(configurationFileNamed: "Products")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        app = XCUIApplication()
        app.launchArguments = ["-resetState"]
        app.launch()
    }

    func testSubscribingUnlocksPro() throws {
        let buy = app.buttons["buy.pro.monthly"]
        XCTAssertTrue(buy.waitForExistence(timeout: 20), "Products did not load\n\(app.debugDescription)")
        XCTAssertTrue(waitForText("Pro is locked", timeout: 5))
        buy.tap()
        XCTAssertTrue(waitForText("Pro is unlocked", timeout: 20))
        XCTAssertTrue(waitForText("pro.monthly", timeout: 5))
        save("store")
    }

    func testCoinsAreCredited() throws {
        let buy = app.buttons["buy.coins.100"]
        XCTAssertTrue(buy.waitForExistence(timeout: 20), "Products did not load\n\(app.debugDescription)")
        XCTAssertTrue(waitForText("0 coins", timeout: 5))
        buy.tap()
        XCTAssertTrue(waitForText("100 coins", timeout: 20))
        buy.tap()
        XCTAssertTrue(waitForText("200 coins", timeout: 20))
    }

    func testApplePaySheetShowsTheCart() throws {
        app.tabBars.buttons["Checkout"].tap()
        XCTAssertTrue(waitForText("$27.49", timeout: 5), "Total of the cart with standard delivery")
        element("shipping.pickup").tap()
        XCTAssertTrue(waitForText("$22.50", timeout: 5))
        element("shipping.standard").tap()
        XCTAssertTrue(waitForText("$27.49", timeout: 5))
        save("checkout")

        let pay = app.buttons["checkout.applePay"]
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        // The sheet runs in another process; it shows the merchant name on the total line.
        let sheet = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        let total = sheet.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Payment Lab'")).firstMatch
        if total.waitForExistence(timeout: 20) {
            Thread.sleep(forTimeInterval: 1) // let the sheet finish sliding in
            save("apple-pay", screen: true)
            let cancel = sheet.buttons.matching(NSPredicate(format: "label == 'Cancel' OR label == 'Close'")).firstMatch
            if cancel.exists { cancel.tap() }
        } else {
            XCTFail("The Apple Pay sheet did not appear\n\(sheet.debugDescription)")
        }
    }

    func testCardFormReportsErrorsAndAcceptsAValidCard() throws {
        app.tabBars.buttons["Card"].tap()
        let number = app.textFields["card.number"]
        XCTAssertTrue(number.waitForExistence(timeout: 5))
        enter("4242424242424241", into: number)
        enter("13/30", into: app.textFields["card.expiry"])
        enter("12", into: app.textFields["card.code"])
        app.buttons["card.check"].tap()
        XCTAssertTrue(waitForText("Check the card number for a typo.", timeout: 5))
        XCTAssertTrue(waitForText("The expiry month must be 01 to 12.", timeout: 5))
        XCTAssertTrue(waitForText("The security code has 3 digits.", timeout: 5))
        XCTAssertEqual(number.value as? String, "4242 4242 4242 4241")
        save("card")

        clear(number)
        enter("378282246310005", into: number)
        XCTAssertEqual(number.value as? String, "3782 822463 10005")
        clear(app.textFields["card.expiry"])
        enter("09/30", into: app.textFields["card.expiry"])
        clear(app.textFields["card.code"])
        enter("1234", into: app.textFields["card.code"])
        app.buttons["card.check"].tap()
        XCTAssertTrue(waitForText("americanExpress •••• 0005 09/30", timeout: 5))
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    /// Types into a field one key at a time and waits until the field has taken each one. The
    /// form formats as you type, and `typeText` with a whole string loses the keys that arrive
    /// while a slow simulator is still showing the keyboard or reformatting the text: the first
    /// field of a run on GitHub's macos-26 image kept "4242 4242 42" of a 16-digit number.
    private func enter(_ text: String, into field: XCUIElement) {
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 20), "The keyboard did not appear")
        for character in text {
            let before = field.value as? String
            field.typeText(String(character))
            // A "/" that the field added itself changes nothing, so the wait has a limit.
            let deadline = Date().addingTimeInterval(2)
            while (field.value as? String) == before, Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
        }
    }

    private func clear(_ field: XCUIElement) {
        // A tap in the middle can put the cursor inside the text, so deleting from there leaves
        // the characters before it; tap at the trailing edge instead.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        // The field formats as you type, so a deleted space can come back; delete until empty.
        for _ in 0..<4 {
            let text = field.value as? String ?? ""
            guard !text.isEmpty, text != field.placeholderValue else { return }
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count * 2))
        }
        XCTFail("Could not clear the field; it still shows \(String(describing: field.value))")
    }

    /// Waits for any text in the app whose label contains `text`.
    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let found = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.waitForExistence(timeout: timeout)
        if !found { print("Text not found: \(text)\n\(app.debugDescription)") }
        return found
    }

    /// Saves a screenshot for the README when SCREENSHOT_DIR is set, and attaches it to the
    /// test result either way.
    private func save(_ name: String, screen: Bool = false) {
        let screenshot = screen ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment["SCREENSHOT_DIR"] else { return }
        let appearance = environment["APPEARANCE"] ?? "light"
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name)-\(appearance).png")
        try? screenshot.pngRepresentation.write(to: url)
    }
}
