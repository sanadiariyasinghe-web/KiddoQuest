import CoreData
import Foundation
import Testing
@testable import KiddoQuest

// MARK: - Scoring & Levels

@MainActor
struct GameScoringTests {
    @Test(arguments: [
        (correct: 0, total: 5, expected: 0),
        (correct: 1, total: 5, expected: 1),
        (correct: 2, total: 5, expected: 1),
        (correct: 3, total: 5, expected: 2),
        (correct: 4, total: 5, expected: 3),
        (correct: 5, total: 5, expected: 3)
    ])
    func liveStarsFollowFirstTryAccuracy(correct: Int, total: Int, expected: Int) {
        #expect(GameScoring.stars(correct: correct, total: total) == expected)
    }

    @Test func everyFinishedRoundEarnsAtLeastOneStar() {
        #expect(GameScoring.finalStars(correct: 0, total: 5) == 1)
        #expect(GameScoring.finalStars(correct: 5, total: 5) == 3)
    }

    @Test func noQuestionsMeansNoStars() {
        #expect(GameScoring.stars(correct: 0, total: 0) == 0)
    }
}

@MainActor
struct GameLevelsTests {
    @Test func choiceCountGrowsWithLevel() {
        #expect(GameLevels.choiceCount(forLevel: 1) == 2)
        #expect(GameLevels.choiceCount(forLevel: 2) == 3)
        #expect(GameLevels.choiceCount(forLevel: 3) == 4)
        // Out-of-range levels are clamped
        #expect(GameLevels.choiceCount(forLevel: 0) == 2)
        #expect(GameLevels.choiceCount(forLevel: 9) == 4)
    }

    @Test func onlyThreeStarRoundsMoveUpAndNeverPastMax() {
        #expect(GameLevels.nextLevel(after: 1, stars: 3) == 2)
        #expect(GameLevels.nextLevel(after: 1, stars: 2) == 1)
        #expect(GameLevels.nextLevel(after: 3, stars: 3) == 3)
    }

    @Test func storeRemembersLevelsPerGame() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = GameLevelStore(defaults: defaults)

        #expect(store.level(for: "num_1") == 1)
        #expect(store.recordRound(gameID: "num_1", stars: 3) == 2)
        #expect(store.recordRound(gameID: "num_1", stars: 1) == nil)
        #expect(store.level(for: "num_1") == 2)
        #expect(store.level(for: "shp_1") == 1)

        store.reset(gameIDs: ["num_1"])
        #expect(store.level(for: "num_1") == 1)
    }
}

// MARK: - Progress

@MainActor
struct ProgressSummaryTests {
    private func progress(_ gameID: String, stars: Int, category: String) -> GameProgress {
        GameProgress(gameID: gameID, category: category, completed: true, stars: stars)
    }

    @Test func islandAddsUpStarsFromItsGames() {
        let saved = [
            "num_1": progress("num_1", stars: 3, category: "Numbers"),
            "num_2": progress("num_2", stars: 1, category: "Numbers"),
            "let_1": progress("let_1", stars: 2, category: "Letters")
        ]
        let numbers = ProgressSummary.island(.numbers, progress: saved)

        #expect(numbers.stars == 4)
        #expect(numbers.maxStars == 6)
        #expect(numbers.percentage == 66)
    }

    @Test func unplayedIslandShowsZero() {
        let animals = ProgressSummary.island(.animals, progress: [:])
        #expect(animals.stars == 0)
        #expect(animals.percentage == 0)
    }

    @Test func gameCardsAreDecoratedFromSavedStars() throws {
        let game = try #require(GameInfo.sampleGames.first { $0.id == "shp_1" })
        let decorated = ProgressSummary.decorated(game, with: ["shp_1": progress("shp_1", stars: 2, category: "Shapes")])

        #expect(decorated.starsEarned == 2)
        #expect(decorated.completionPercentage == 66)
    }

    @Test func catalogueHasNoMadeUpProgress() {
        #expect(GameInfo.sampleGames.allSatisfy { $0.starsEarned == 0 && $0.completionPercentage == 0 })
    }
}

// MARK: - Daily Time Limit

@MainActor
struct PlayTimeTests {
    @Test func limitRules() {
        #expect(PlayTimeRules.isLimitReached(secondsPlayed: 20 * 60, limitMinutes: 20, isUnlockedByParent: false))
        #expect(!PlayTimeRules.isLimitReached(secondsPlayed: 19 * 60, limitMinutes: 20, isUnlockedByParent: false))
        #expect(!PlayTimeRules.isLimitReached(secondsPlayed: 99 * 60, limitMinutes: 0, isUnlockedByParent: false))
        #expect(!PlayTimeRules.isLimitReached(secondsPlayed: 99 * 60, limitMinutes: 20, isUnlockedByParent: true))
    }

    @Test func trackerShowsBreakAfterLimitAndParentCanUnlock() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(15, forKey: PlayTimeTracker.limitKey)
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let tracker = PlayTimeTracker(defaults: defaults, now: { now })

        tracker.appBecameActive()
        now.addTimeInterval(10 * 60)
        tracker.tick()
        #expect(!tracker.isLimitReached)
        #expect(tracker.minutesPlayedToday == 10)

        now.addTimeInterval(5 * 60)
        tracker.tick()
        #expect(tracker.isLimitReached)

        tracker.unlockForToday()
        #expect(!tracker.isLimitReached)
    }

    @Test func timeResetsOnANewDay() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(15, forKey: PlayTimeTracker.limitKey)
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let tracker = PlayTimeTracker(defaults: defaults, now: { now })

        tracker.appBecameActive()
        now.addTimeInterval(20 * 60)
        tracker.appBecameInactive()
        #expect(tracker.isLimitReached)

        now.addTimeInterval(24 * 60 * 60)
        tracker.appBecameActive()
        #expect(!tracker.isLimitReached)
        #expect(tracker.minutesPlayedToday == 0)
    }
}

// MARK: - Rewards & Parent Summary

@MainActor
struct StickerBookTests {
    @Test func newStickersPreferOnesNotCollected() {
        let pool = ["🦁", "🐼", "🦄"]
        for _ in 0..<20 {
            #expect(StickerBook.nextStickerEmoji(collected: ["🦁", "🐼"], pool: pool) == "🦄")
        }
    }

    @Test func fullBookStillGivesASticker() {
        let pool = ["🦁", "🐼"]
        #expect(pool.contains(StickerBook.nextStickerEmoji(collected: Set(pool), pool: pool)))
    }

    @Test func stickersAreSavedAndCanBeReset() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let book = StickerBook(defaults: defaults)
        book.awardSticker(for: "Counting Pop")
        book.awardSticker(for: "Shape Sort")

        let reopened = StickerBook(defaults: defaults)
        #expect(reopened.stickers.count == 2)
        #expect(reopened.collectedEmojis.count == 2)

        reopened.reset()
        #expect(StickerBook(defaults: defaults).stickers.isEmpty)
    }
}

@MainActor
struct WeeklyLearningSummaryTests {
    @Test func onlyThisWeeksFinishedGamesAreListed() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let progress = [
            "num_1": GameProgress(gameID: "num_1", category: "Numbers", completed: true, stars: 3, lastPlayed: now.addingTimeInterval(-3600)),
            "ani_1": GameProgress(gameID: "ani_1", category: "Animals", completed: true, stars: 2, lastPlayed: now.addingTimeInterval(-2 * 86_400)),
            "let_2": GameProgress(gameID: "let_2", category: "Letters", completed: true, stars: 1, lastPlayed: now.addingTimeInterval(-10 * 86_400)),
            "ar_x": GameProgress(gameID: "ar_x", category: "AR", completed: true, stars: 3, lastPlayed: now)
        ]

        let skills = WeeklyLearningSummary.skillsLearned(progress: progress, now: now)

        #expect(skills.map(\.gameID) == ["num_1", "ani_1"])
        #expect(skills.first?.skill == "Counting objects")
    }

    @Test func everyCatalogueGameHasASkill() {
        #expect(GameInfo.sampleGames.allSatisfy { WeeklyLearningSummary.skill(forGameID: $0.id) != nil })
    }
}

// MARK: - Game Content

@MainActor
struct GameContentTests {
    @Test(arguments: [AnimalPictureGame.feedAnimals, .animalShadows], [2, 3, 4])
    func animalRoundsHaveTheAnswerAndUniqueChoices(game: AnimalPictureGame, choiceCount: Int) {
        let rounds = game.makeRounds(count: 5, choiceCount: choiceCount)

        #expect(rounds.count == 5)
        for round in rounds {
            #expect(round.choices.count == choiceCount)
            #expect(round.choices.contains(round.answer))
            #expect(Set(round.choices).count == round.choices.count)
        }
    }

    @Test func shapeSortQueueHasEveryShape() {
        for _ in 0..<10 {
            let queue = ShapeSortViewModel.makeQueue()
            #expect(queue.count == 6)
            #expect(Set(queue.map(\.targetBinId)) == ["triangle", "circle", "square"])
        }
    }

    @Test func letterHuntHasThreeOfTheTargetLetter() {
        let viewModel = LetterShapeHuntViewModel()
        let targets = viewModel.items.filter(\.isTarget)

        #expect(targets.count == 3)
        #expect(targets.allSatisfy { $0.symbol == viewModel.targetSymbol })
        #expect(viewModel.items.filter { !$0.isTarget }.allSatisfy { $0.symbol != viewModel.targetSymbol })
    }

    @Test func letterHuntCountsOnlyFirstTryFinds() throws {
        let viewModel = LetterShapeHuntViewModel()
        let distractor = try #require(viewModel.items.first { !$0.isTarget })
        viewModel.tapItem(distractor)

        for target in viewModel.items.filter(\.isTarget) {
            viewModel.tapItem(target)
        }

        #expect(viewModel.isCompleted)
        #expect(viewModel.correctAnswers == 2)
        #expect(viewModel.result.totalQuestions == 3)
        #expect(viewModel.result.stars == 2)
    }

    @Test func countingPopOptionsAlwaysIncludeTheAnswer() {
        for _ in 0..<10 {
            let viewModel = CountingPopViewModel()
            #expect(viewModel.options.contains(viewModel.targetCount))
            #expect(viewModel.options.count == GameLevels.choiceCount(forLevel: viewModel.level))
            #expect(viewModel.items.count == viewModel.targetCount)
        }
    }
}

// MARK: - Core Data

@MainActor
struct CoreDataManagerTests {
    private func makeManager() -> CoreDataManager {
        CoreDataManager(context: PersistenceController(inMemory: true).container.viewContext)
    }

    @Test func newProfileStartsWithNoStars() {
        let manager = makeManager()
        #expect(manager.currentProfile.totalStars == 0)
        #expect(manager.progressByGame.isEmpty)
    }

    @Test func savingProgressKeepsBestStarsAndAddsToProfile() {
        let manager = makeManager()
        manager.saveGameProgress(gameID: "num_1", category: "Numbers", stars: 3, score: 100)
        manager.saveGameProgress(gameID: "num_1", category: "Numbers", stars: 1, score: 20)

        #expect(manager.progressByGame["num_1"]?.stars == 3)
        #expect(manager.progressByGame["num_1"]?.completed == true)
        #expect(manager.currentProfile.totalStars == 4)
    }

    @Test func finishingAGameUnlocksBadges() {
        let manager = makeManager()
        manager.saveGameProgress(gameID: "ani_1", category: "Animals", stars: 2, score: 80)

        let unlocked = Set(manager.badges.filter(\.isUnlocked).map(\.name))
        #expect(unlocked.contains("First Game"))
        #expect(unlocked.contains("Animal Friend"))
    }

    @Test func sessionTotalsCountRecentSessions() {
        let manager = makeManager()
        manager.recordSession(duration: 60, gamesPlayed: 1, starsEarned: 3)
        manager.recordSession(duration: 60, gamesPlayed: 1, starsEarned: 2)

        let totals = manager.sessionTotals(since: Date().addingTimeInterval(-3600))
        #expect(totals.gamesPlayed == 2)
        #expect(totals.starsEarned == 5)
    }
}

// MARK: - Find It! (Vision game)
@MainActor
struct FindItTests {
    @Test func roundHasFiveDifferentHuntsIncludingColours() {
        let round = FindItRules.makeRound()
        #expect(round.count == 5)
        #expect(Set(round).count == 5)
        let colours = round.filter { if case .color = $0 { return true } else { return false } }
        #expect(colours.count == 2)
    }

    @Test func matchingNeedsTheRightLabelAndEnoughConfidence() {
        let labels: Set<String> = ["chair", "armchair"]
        #expect(FindItRules.matches(labels: labels, observations: [("armchair", 0.6)]))
        #expect(!FindItRules.matches(labels: labels, observations: [("armchair", 0.05)]))
        #expect(!FindItRules.matches(labels: labels, observations: [("dog", 0.9)]))
    }

    @Test func bestGuessIsAFriendlyWord() {
        #expect(FindItRules.bestGuess(from: [("adult_cat", 0.8), ("dog", 0.3)]) == "adult cat")
        #expect(FindItRules.bestGuess(from: [("dog", 0.1)]) == nil)
    }

    @Test(arguments: [
        (0.9, 0.1, 0.1, FindItColor.red),
        (0.1, 0.3, 0.9, FindItColor.blue),
        (0.95, 0.85, 0.1, FindItColor.yellow),
        (0.1, 0.8, 0.2, FindItColor.green)
    ])
    func dominantColourNamesBrightColours(red: Double, green: Double, blue: Double, expected: FindItColor) {
        #expect(FindItRules.dominantColor(red: red, green: green, blue: blue) == expected)
    }

    @Test func greyAndDarkColoursAreNotGuessed() {
        #expect(FindItRules.dominantColor(red: 0.5, green: 0.5, blue: 0.5) == nil)
        #expect(FindItRules.dominantColor(red: 0.1, green: 0.05, blue: 0.05) == nil)
    }

    @Test func firstTryFindScoresFullPointsAndRetryScoresHalf() {
        let viewModel = FindItViewModel(targets: [.color(.red), .color(.blue)])
        viewModel.evaluate(matched: true, saw: nil)
        #expect(viewModel.score == GameScoring.firstTryPoints)
        #expect(viewModel.correctAnswers == 1)
        #expect(viewModel.isShowingSuccess)

        let retry = FindItViewModel(targets: [.color(.red)])
        retry.evaluate(matched: false, saw: "something blue")
        #expect(retry.mascotMessage.contains("something blue"))
        retry.evaluate(matched: true, saw: nil)
        #expect(retry.score == GameScoring.retryPoints)
        #expect(retry.correctAnswers == 0)
    }

    @Test func findItIsInTheCatalogue() {
        let game = GameInfo.sampleGames.first { $0.id == FindItViewModel.gameID }
        #expect(game?.gameType == .findIt)
        #expect(game?.category == .shapes)
    }
}

// MARK: - Siri & Shortcuts
@MainActor
struct ShortcutTests {
    @Test func everySiriIslandOpensTheMatchingIsland() {
        let categories = ShortcutIsland.allCases.map(\.category)
        #expect(Set(categories) == Set(IslandCategory.allCases))
    }

    @Test func openIslandIntentQueuesTheIslandRoute() async throws {
        let intent = OpenIslandIntent()
        intent.island = .animals
        _ = try await intent.perform()
        #expect(ShortcutRouter.shared.pendingRoute == .category(.animals))
        ShortcutRouter.shared.pendingRoute = nil
    }
}
