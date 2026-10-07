import XCTest

// MARK: - Performance Tests
// Measures cold launch time and the memory/CPU used when opening a game,
// so the report has repeatable numbers (run on a real device for final evidence).

final class KiddoQuestPerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// App launch time (XCTApplicationLaunchMetric runs the launch several times and averages it).
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTesting"]
            app.launch()
        }
    }

    /// Memory and CPU while a child opens an island and starts a game.
    func testOpeningAGameUsesLittleMemoryAndCPU() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTMemoryMetric(application: app), XCTCPUMetric(application: app)], options: options) {
            let island = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Numbers Island'")).firstMatch
            XCTAssertTrue(island.waitForExistence(timeout: 10))
            island.tap()
            let playIsland = app.buttons["Play Island Games"]
            XCTAssertTrue(playIsland.waitForExistence(timeout: 10))
            playIsland.tap()
            let game = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Counting Pop'")).firstMatch
            XCTAssertTrue(game.waitForExistence(timeout: 10))
            game.tap()
            let play = app.buttons["instructions.play"]
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            play.tap()

            // Leave with the big 🏠 button (it asks first)
            let home = app.buttons["game.home"]
            XCTAssertTrue(home.waitForExistence(timeout: 10))
            home.tap()
            let confirm = app.buttons["game.confirmHome"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            confirm.tap()
            XCTAssertTrue(app.staticTexts["KiddoQuest World"].waitForExistence(timeout: 10))
        }
    }
}
