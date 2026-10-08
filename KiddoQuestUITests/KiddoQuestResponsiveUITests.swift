import XCTest

// MARK: - Responsive Layout UI Tests
// The child's main journey must stay usable in iPhone landscape and with very large text:
// key buttons have to be on screen (hittable) without scrolling.

final class KiddoQuestResponsiveUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testLetterHuntIsPlayableInLandscape() {
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft

        openLetterHunt()
        let play = app.buttons["instructions.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(app.windows.firstMatch.frame.contains(play.frame), "Let's Play! must be fully on screen in landscape")
        play.tap()
        attachScreenshot("Letter Hunt – landscape")

        // Every target bubble can be popped without scrolling
        popAllTargetBubbles(requireOnScreen: true)

        XCTAssertTrue(app.staticTexts["Great Job! 🎉"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
    }

    func testHomeAndBigHomeButtonWorkInLandscape() {
        app.launch()
        XCUIDevice.shared.orientation = .landscapeRight

        XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 10))
        openLetterHunt()
        let play = app.buttons["instructions.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()

        let home = app.buttons["game.home"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertTrue(home.isHittable)
        home.tap()
        let confirm = app.buttons["game.confirmHome"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        XCTAssertTrue(confirm.isHittable, "The Go home? buttons must fit in landscape")
        confirm.tap()
        XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 5))
    }

    func testVeryLargeTextKeepsTheGamePlayable() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        openLetterHunt()
        let play = app.buttons["instructions.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertTrue(app.windows.firstMatch.frame.contains(play.frame), "Let's Play! must be fully on screen with the largest text")
        play.tap()

        popAllTargetBubbles(requireOnScreen: false)
        XCTAssertTrue(app.staticTexts["Great Job! 🎉"].waitForExistence(timeout: 10))
    }

    // MARK: - Helpers

    /// Keeps a screenshot in the test results as layout evidence.
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func button(startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Home → Letters Island → Play Island Games → Letter Hunt (instructions card).
    private func openLetterHunt() {
        let letters = button(startingWith: "Letters Island")
        XCTAssertTrue(letters.waitForExistence(timeout: 10))
        letters.tap()

        let playIsland = app.buttons["Play Island Games"]
        XCTAssertTrue(playIsland.waitForExistence(timeout: 5))
        attachScreenshot("Island – \(XCUIDevice.shared.orientation.isLandscape ? "landscape" : "portrait")")
        playIsland.tap()

        let letterHunt = button(startingWith: "Letter Hunt")
        XCTAssertTrue(letterHunt.waitForExistence(timeout: 5))
        letterHunt.tap()
    }

    /// Reads the target letter from "Find all the X letters!" and pops every matching bubble.
    private func popAllTargetBubbles(requireOnScreen: Bool) {
        let prompt = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Find all the'")).firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        let words = prompt.label.split(separator: " ")
        guard words.count > 3 else {
            XCTFail("Unexpected prompt: \(prompt.label)")
            return
        }
        let letter = String(words[3])

        for index in 0..<3 {
            let bubble = app.buttons["Bubble: \(letter)"].firstMatch
            XCTAssertTrue(bubble.waitForExistence(timeout: 5))
            if requireOnScreen {
                // Fully visible without scrolling. (`isHittable` is false while the 👆 hint animates
                // nearby, although real taps pass through it, so the frame is checked instead.)
                let window = app.windows.firstMatch.frame
                XCTAssertTrue(
                    window.contains(bubble.frame),
                    "Bubble \(index) \(letter) must be fully on screen – bubble \(bubble.frame), window \(window)"
                )
            }
            bubble.tap()
        }
    }
}
