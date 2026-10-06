import XCTest

/// Siri Remote helpers. Rather than tapping (tvOS has no touch screen),
/// tests move focus with directional presses and press Select, exactly
/// like a person on the sofa.
extension XCTestCase {

    @MainActor
    func launchKiddoQuestTV(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // In-memory demo family, sound off, no ambient looping motion.
        app.launchArguments = ["-uiTesting"] + extraArguments
        app.launch()
        return app
    }

    @MainActor
    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    func focusedElement(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "hasFocus == true")).firstMatch
    }

    /// Moves focus step by step towards `target` using the remote.
    @MainActor
    func moveFocus(
        to target: XCUIElement,
        in app: XCUIApplication,
        maxPresses: Int = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(target.waitForExistence(timeout: 8), "Missing element: \(target)", file: file, line: line)
        let remote = XCUIRemote.shared
        for _ in 0..<maxPresses {
            if target.hasFocus { return }
            let focused = focusedElement(in: app)
            guard focused.exists else {
                remote.press(.down)
                continue
            }
            let from = focused.frame
            let to = target.frame
            let dx = to.midX - from.midX
            let dy = to.midY - from.midY
            if abs(dy) > 40 && abs(dy) >= abs(dx) * 0.5 {
                remote.press(dy > 0 ? .down : .up)
            } else {
                remote.press(dx > 0 ? .right : .left)
            }
        }
        XCTAssertTrue(target.hasFocus, "Could not move focus to \(target)", file: file, line: line)
    }

    /// Focuses an element and presses Select on the remote.
    @MainActor
    func select(
        _ identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let target = element(identifier, in: app)
        moveFocus(to: target, in: app, file: file, line: line)
        XCUIRemote.shared.press(.select)
    }

    /// Presses the remote's Back (Menu) button.
    @MainActor
    func pressBack() {
        XCUIRemote.shared.press(.menu)
    }

    @MainActor
    func waitFor(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element(identifier, in: app).waitForExistence(timeout: timeout), "Timed out waiting for \(identifier)", file: file, line: line)
    }

    /// Waits until an element's label contains the given text.
    @MainActor
    func waitForLabel(
        of identifier: String,
        containing text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let target = element(identifier, in: app)
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: target)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "\(identifier) label never contained \"\(text)\" (was \"\(target.label)\")", file: file, line: line)
    }

    /// Every game opens with the picture instructions; press Let's Play! to start.
    @MainActor
    func startGameFromInstructions(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let play = element("instructions.play", in: app)
        guard play.waitForExistence(timeout: 5) else { return }
        moveFocus(to: play, in: app, file: file, line: line)
        XCUIRemote.shared.press(.select)
    }

    /// Home → PLAY → pick Ava → Learning World.
    @MainActor
    func goToLearningWorld(in app: XCUIApplication, player: String = "Ava") {
        select("home.play", in: app)
        select("player.\(player)", in: app)
        waitFor("category.numbers", in: app)
    }
}
