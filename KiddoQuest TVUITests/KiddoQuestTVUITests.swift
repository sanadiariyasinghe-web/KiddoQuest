import XCTest

/// End-to-end tvOS UI tests driven entirely by the Siri Remote.
final class KiddoQuestTVUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Home

    @MainActor
    func testHomeShowsBrandAndLargeActions() {
        let app = launchKiddoQuestTV()
        waitFor("home.title", in: app)
        for id in ["home.play", "home.continue", "home.familyProgress", "home.settings"] {
            XCTAssertTrue(element(id, in: app).exists, "\(id) missing")
        }
        XCTAssertTrue(app.staticTexts["Learn Together. Play Together."].exists)
        XCTAssertTrue(element("buddy", in: app).exists, "Buddy should greet the family")
    }

    @MainActor
    func testHomeDefaultFocusIsPlayAndFocusMovesWithRemote() {
        let app = launchKiddoQuestTV()
        let play = element("home.play", in: app)
        XCTAssertTrue(play.waitForExistence(timeout: 8))
        XCTAssertTrue(play.hasFocus, "PLAY should be focused when Home appears")
        XCUIRemote.shared.press(.down)
        XCTAssertTrue(element("home.continue", in: app).hasFocus, "Swiping down should focus CONTINUE")
        XCUIRemote.shared.press(.up)
        XCTAssertTrue(play.hasFocus)
    }

    // MARK: - Player selection

    @MainActor
    func testPlayerSelectionShowsProfilesAndSwitchesPlayer() {
        let app = launchKiddoQuestTV()
        select("home.play", in: app)
        waitFor("player.Ava", in: app)
        XCTAssertTrue(element("player.Liam", in: app).exists)
        XCTAssertTrue(element("player.Parent", in: app).exists)

        select("player.Liam", in: app)
        waitFor("category.numbers", in: app)
        XCTAssertTrue(app.staticTexts["Hi Liam! Pick a world to explore."].exists)

        // Switch player from the Learning World header.
        select("world.switchPlayer", in: app)
        select("player.Ava", in: app)
        XCTAssertTrue(app.staticTexts["Hi Ava! Pick a world to explore."].waitForExistence(timeout: 8))
    }

    @MainActor
    func testContinueWithoutSavedPlayerAsksWhoIsPlaying() {
        let app = launchKiddoQuestTV(extraArguments: ["-uiTestingNoSelectedPlayer"])
        select("home.continue", in: app)
        waitFor("player.Ava", in: app)
    }

    // MARK: - Learning World, category and library

    @MainActor
    func testLearningWorldShowsFourCategories() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        for category in ["numbers", "letters", "shapes", "animals"] {
            XCTAssertTrue(element("category.\(category)", in: app).exists, "\(category) card missing")
        }
        let numbers = element("category.numbers", in: app)
        XCTAssertTrue(numbers.label.contains("85 percent"), "Ava's Numbers card should show 85%")
        XCTAssertTrue(element("world.familyChallenge", in: app).exists)
    }

    @MainActor
    func testCategoryShowsItsGamesAndBackReturnsToWorld() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.shapes", in: app)
        waitFor("categoryView.title", in: app)
        for game in ["shapeHunt", "tapToReveal", "shapeSort"] {
            XCTAssertTrue(element("game.\(game)", in: app).exists, "\(game) missing in Shapes")
        }
        pressBack()
        waitFor("category.shapes", in: app)
    }

    @MainActor
    func testGameLibraryListsAllSevenGames() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("world.gameLibrary", in: app)
        for game in ["countingPop", "dragToMatch", "tapToReveal", "shapeHunt", "feedAnimals", "animalShadows", "shapeSort"] {
            XCTAssertTrue(element("game.\(game)", in: app).waitForExistence(timeout: 5), "\(game) missing from library")
        }
        XCTAssertTrue(element("game.dragToMatch", in: app).label.contains("Full game"))
        XCTAssertTrue(element("game.feedAnimals", in: app).label.contains("Full game"))
    }

    // MARK: - Games

    @MainActor
    func testCountingPopIncorrectThenCorrectAnswer() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.numbers", in: app)
        select("game.countingPop", in: app)
        startGameFromInstructions(in: app)
        waitForLabel(of: "countingPop.question", containing: "How many apples?", in: app)

        select("countingPop.option.3", in: app)
        waitForLabel(of: "feedback.banner", containing: "Almost! Try again!", in: app)

        select("countingPop.option.5", in: app)
        waitForLabel(of: "feedback.banner", containing: "Great job!", in: app)
        // The next round loads automatically.
        waitForLabel(of: "countingPop.question", containing: "How many bananas?", in: app)
    }

    @MainActor
    func testCountingPopCompletesAndShowsResults() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.numbers", in: app)
        select("game.countingPop", in: app)
        startGameFromInstructions(in: app)
        let answers = [("apples", 5), ("bananas", 3), ("strawberries", 7), ("oranges", 4), ("grapes", 6)]
        for (object, answer) in answers {
            waitForLabel(of: "countingPop.question", containing: object, in: app)
            select("countingPop.option.\(answer)", in: app)
        }
        waitFor("results.headline", in: app, timeout: 10)
        waitForLabel(of: "results.headline", containing: "Great job, Ava!", in: app)
        XCTAssertTrue(element("results.playAgain", in: app).exists)
        XCTAssertTrue(element("rewards.totalStars", in: app).exists)
        XCTAssertTrue(element("results.newSticker", in: app).exists, "Finishing a game should give a sticker")
    }

    @MainActor
    func testShapeHuntFindsBothTriangles() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.shapes", in: app)
        select("game.shapeHunt", in: app)
        startGameFromInstructions(in: app)
        waitForLabel(of: "shapeHunt.prompt", containing: "TRIANGLES", in: app)
        waitForLabel(of: "shapeHunt.foundCount", containing: "Found: 0 / 2", in: app)

        // Items 0 and 3 are the triangles in the first hunt; item 1 is a circle.
        select("shapeHunt.item.1", in: app)
        waitForLabel(of: "feedback.banner", containing: "Try again", in: app)

        select("shapeHunt.item.0", in: app)
        waitForLabel(of: "shapeHunt.foundCount", containing: "Found: 1 / 2", in: app)

        select("shapeHunt.item.3", in: app)
        waitForLabel(of: "shapeHunt.foundCount", containing: "Found: 2 / 2", in: app)
        waitFor("shapeHunt.greatJob", in: app)
        let next = element("shapeHunt.next", in: app)
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        moveFocus(to: next, in: app)
        XCUIRemote.shared.press(.select)
        waitForLabel(of: "shapeHunt.prompt", containing: "CIRCLES", in: app)
    }

    @MainActor
    func testEveryGameStartsWithPictureInstructions() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.animals", in: app)
        select("game.animalShadows", in: app)
        waitForLabel(of: "instructions.title", containing: "Animal Shadows", in: app)
        XCTAssertTrue(element("instructions.pictures", in: app).exists)
        XCTAssertTrue(element("instructions.play", in: app).hasFocus, "Let's Play! should already have focus")
        XCUIRemote.shared.press(.select)
        waitForLabel(of: "choice.prompt", containing: "shadow", in: app)
    }

    @MainActor
    func testFeedTheAnimalsAcceptsTheRightFood() {
        // Same animal → food pairs as TVGameDataService.animalFoods
        let foods = [
            "bunny": "carrots", "dog": "bones", "monkey": "bananas", "cat": "fish",
            "mouse": "cheese", "panda": "bamboo", "bee": "flowers", "hen": "corn"
        ]
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.animals", in: app)
        select("game.feedAnimals", in: app)
        startGameFromInstructions(in: app)

        let prompt = element("choice.prompt", in: app)
        XCTAssertTrue(prompt.waitForExistence(timeout: 5))
        let animal = foods.keys.first { prompt.label.contains("the \($0) eat") }
        guard let animal, let food = foods[animal] else {
            XCTFail("Unexpected prompt: \(prompt.label)")
            return
        }
        select("choice.option.\(food)", in: app)
        waitForLabel(of: "feedback.banner", containing: "loves \(food)", in: app)
    }

    @MainActor
    func testFamilyChallengeTakesTurns() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("world.familyChallenge", in: app)
        select("familyChallenge.challenge.shape-squad", in: app)
        waitForLabel(of: "familyChallenge.turn", containing: "Ava", in: app)
        waitForLabel(of: "familyChallenge.question", containing: "CIRCLE", in: app)

        select("familyChallenge.option.circle", in: app)
        waitForLabel(of: "familyChallenge.familyScore", containing: "1 of 5", in: app)
        waitForLabel(of: "familyChallenge.turn", containing: "Liam", in: app)
    }

    // MARK: - Rewards, progress and settings

    @MainActor
    func testRewardsShowTotalStarsAndAllBadges() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("world.rewards", in: app)
        waitFor("rewards.totalStars", in: app)
        XCTAssertTrue(element("rewards.stickerBook", in: app).exists)
        for reward in ["numberExplorer", "letterExplorer", "shapeMaster", "animalFriend", "familyLearner"] {
            XCTAssertTrue(element("reward.\(reward)", in: app).exists, "\(reward) badge missing")
        }
        // Badges are focusable so they can be browsed with the remote.
        moveFocus(to: element("reward.familyLearner", in: app), in: app)
    }

    @MainActor
    func testFamilyProgressShowsEveryPlayer() {
        let app = launchKiddoQuestTV()
        select("home.familyProgress", in: app)
        waitFor("familyProgress.player.Ava", in: app)
        XCTAssertTrue(element("familyProgress.player.Liam", in: app).exists)
        XCTAssertTrue(element("familyProgress.player.Ava", in: app).label.contains("Numbers 85 percent"))
        let familyStars = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Family Stars")).firstMatch
        XCTAssertTrue(familyStars.exists, "Family Stars tile missing")
    }

    @MainActor
    func testSettingsToggleSoundAndMusic() {
        let app = launchKiddoQuestTV()
        select("home.settings", in: app)
        let sound = element("settings.sound", in: app)
        XCTAssertTrue(sound.waitForExistence(timeout: 8))
        XCTAssertEqual(sound.value as? String, "Off")
        select("settings.sound", in: app)
        XCTAssertEqual(element("settings.sound", in: app).value as? String, "On")
        XCTAssertTrue(element("settings.players", in: app).exists)
        XCTAssertTrue(element("settings.reset", in: app).exists)
    }

    @MainActor
    func testResetProgressAsksForConfirmation() {
        let app = launchKiddoQuestTV()
        select("home.settings", in: app)
        select("settings.reset", in: app)
        // tvOS nests the alert's button inside another button element.
        let resetButton = app.alerts.buttons["Reset"].firstMatch
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5), "Reset should ask for confirmation")
        moveFocus(to: resetButton, in: app)
        XCUIRemote.shared.press(.select)
        waitForLabel(of: "settings.status", containing: "Progress was reset", in: app)
    }

    // MARK: - Back navigation

    @MainActor
    func testBackNavigationUnwindsToHome() {
        let app = launchKiddoQuestTV()
        goToLearningWorld(in: app)
        select("category.letters", in: app)
        waitFor("categoryView.title", in: app)
        pressBack()
        waitFor("category.letters", in: app)
        pressBack()
        waitFor("player.Ava", in: app)
        pressBack()
        let play = element("home.play", in: app)
        XCTAssertTrue(play.waitForExistence(timeout: 8))
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTesting"]
            app.launch()
        }
    }
}
