import XCTest

// MARK: - KiddoQuest UI Tests
// End-to-end checks of the child's journey:
// Home → Island → Game → Instructions → Play → Results → Home / More Games.
// The app is launched with "-uiTesting" so it starts fresh (in-memory data, intro skipped,
// no time limit, Calm Mode on so nothing floats while tapping).

final class KiddoQuestUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    // MARK: - Tests

    func testHomeShowsAllIslandsWithFreshProgress() {
        XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 10))
        for island in ["Numbers Island", "Letters Island", "Shapes Island", "Animals Island"] {
            XCTAssertTrue(button(startingWith: island).exists, "\(island) should be on Home")
        }
        XCTAssertTrue(button(startingWith: "Numbers Island, 0 percent complete").exists)
    }

    func testFinishingLetterHuntShowsResultsAndHomeReturnsHome() {
        openLetterHuntAndStart()
        finishLetterHunt()

        XCTAssertTrue(app.staticTexts["Great Job! 🎉"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["This Round"].exists)
        XCTAssertTrue(app.staticTexts["New sticker!"].exists)
        XCTAssertTrue(app.buttons["More Games"].exists)

        app.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 5))
        // Progress is real now: Letters Island has earned stars
        XCTAssertFalse(button(startingWith: "Letters Island, 0 percent complete").exists)
    }

    func testMoreGamesReturnsToTheIslandGameList() {
        openLetterHuntAndStart()
        finishLetterHunt()

        XCTAssertTrue(app.buttons["More Games"].waitForExistence(timeout: 10))
        app.buttons["More Games"].tap()
        XCTAssertTrue(app.staticTexts["Choose a Mini-Game"].waitForExistence(timeout: 5))
        XCTAssertTrue(button(startingWith: "Letter Hunt").exists)
    }

    func testBigHomeButtonAsksBeforeLeavingAGame() {
        openLetterHuntAndStart()

        let homeButton = app.buttons["game.home"]
        XCTAssertTrue(homeButton.waitForExistence(timeout: 5))
        homeButton.tap()
        XCTAssertTrue(app.staticTexts["Go home?"].waitForExistence(timeout: 3))

        app.buttons["game.keepPlaying"].tap()
        XCTAssertFalse(app.staticTexts["Go home?"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Find all the'")).firstMatch.exists)

        homeButton.tap()
        app.buttons["game.confirmHome"].tap()
        XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 5))
    }

    func testRewardsShowTheStickerBook() {
        XCTAssertTrue(button(startingWith: "Total stars").waitForExistence(timeout: 10))
        button(startingWith: "Total stars").tap()
        XCTAssertTrue(app.staticTexts["My Sticker Book"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func button(startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Home → Letters Island → Play Island Games → Letter Hunt → Let's Play!
    private func openLetterHuntAndStart() {
        let letters = button(startingWith: "Letters Island")
        XCTAssertTrue(letters.waitForExistence(timeout: 10))
        letters.tap()

        let playIsland = app.buttons["Play Island Games"]
        XCTAssertTrue(playIsland.waitForExistence(timeout: 5))
        playIsland.tap()

        let letterHunt = button(startingWith: "Letter Hunt")
        XCTAssertTrue(letterHunt.waitForExistence(timeout: 5))
        letterHunt.tap()

        let play = app.buttons["instructions.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Instructions should appear before playing")
        play.tap()
    }

    /// Reads the target letter from "Find all the X letters!" and pops every matching bubble.
    private func finishLetterHunt() {
        let prompt = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Find all the'")).firstMatch
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        let words = prompt.label.split(separator: " ")
        guard words.count > 3 else {
            XCTFail("Unexpected prompt: \(prompt.label)")
            return
        }
        let letter = String(words[3])

        for _ in 0..<3 {
            let bubble = app.buttons["Bubble: \(letter)"].firstMatch
            XCTAssertTrue(bubble.waitForExistence(timeout: 5))
            bubble.tap()
        }
    }
}
