import Testing
@testable import KiddoQuest_TV

/// Score, star, progress and reward calculations.
@MainActor
struct TVScoreTests {

    // MARK: - Points

    @Test func firstTryEarnsFullPoints() {
        #expect(TVScoring.points(forAttempt: 1) == TVScoring.firstTryPoints)
    }

    @Test func retriesStillEarnPositivePoints() {
        #expect(TVScoring.points(forAttempt: 2) == TVScoring.retryPoints)
        #expect(TVScoring.points(forAttempt: 5) == TVScoring.retryPoints)
        #expect(TVScoring.retryPoints > 0)
    }

    @Test func trackerAddsPointsAndNeverSubtractsForMistakes() {
        var tracker = TVRoundTracker()
        tracker.registerMistake()
        #expect(tracker.points == 0)
        let awarded = tracker.registerCorrect()
        #expect(awarded == TVScoring.retryPoints)
        tracker.startNextRound()
        #expect(tracker.registerCorrect() == TVScoring.firstTryPoints)
        #expect(tracker.points == TVScoring.retryPoints + TVScoring.firstTryPoints)
        #expect(tracker.correctAnswers == 2)
        #expect(tracker.mistakes == 1)
    }

    // MARK: - Stars

    @Test(arguments: [
        (correct: 5, mistakes: 0, stars: 3),
        (correct: 4, mistakes: 1, stars: 3),
        (correct: 5, mistakes: 3, stars: 2),
        (correct: 5, mistakes: 5, stars: 2),
        (correct: 2, mistakes: 9, stars: 1),
        (correct: 0, mistakes: 0, stars: 0)
    ])
    func sessionStars(correct: Int, mistakes: Int, stars: Int) {
        #expect(TVScoring.sessionStars(correct: correct, mistakes: mistakes) == stars)
    }

    @Test func finishingAlwaysEarnsAtLeastOneStar() {
        #expect(TVScoring.sessionStars(correct: 1, mistakes: 100) >= 1)
    }

    // MARK: - Progress

    @Test func percentIsClampedAndRoundedDown() {
        #expect(TVScoring.percent(correct: 17, target: 20) == 85)
        #expect(TVScoring.percent(correct: 40, target: 20) == 100)
        #expect(TVScoring.percent(correct: -3, target: 20) == 0)
        #expect(TVScoring.percent(correct: 5, target: 0) == 0)
    }

    @Test func ratingMatchesTheCategoryCardExamples() {
        #expect(TVScoring.rating(forPercent: 85) == 4)
        #expect(TVScoring.rating(forPercent: 70) == 3)
        #expect(TVScoring.rating(forPercent: 60) == 3)
        #expect(TVScoring.rating(forPercent: 90) == 5)
        #expect(TVScoring.rating(forPercent: 0) == 0)
    }

    @Test func progressRecordsSessionsPerCategory() {
        var progress = TVGameProgress()
        progress.record(correctAnswers: 5, stars: 3, in: .numbers, game: .countingPop)
        progress.record(correctAnswers: 3, stars: 2, in: .numbers, game: .dragToMatch)
        #expect(progress.progress(for: .numbers).stars == 5)
        #expect(progress.progress(for: .numbers).gamesPlayed == 2)
        #expect(progress.percent(for: .numbers) == 40)
        #expect(progress.percent(for: .letters) == 0)
        #expect(progress.totalStars == 5)
        #expect(progress.completedGames == [.countingPop, .dragToMatch])
        #expect(progress.strongestCategory == .numbers)
    }

    @Test func emptyProgressHasSafeDefaults() {
        let progress = TVGameProgress()
        #expect(progress.totalStars == 0)
        #expect(progress.totalGames == 0)
        #expect(progress.overallPercent == 0)
        #expect(progress.strongestCategory == nil)
        #expect(progress.completedCategories.isEmpty)
    }

    @Test func demoAvaMatchesTheBriefExample() throws {
        let ava = try #require(TVGameDataService.demoPlayers().first)
        #expect(ava.name == "Ava")
        #expect(ava.progress.percent(for: .numbers) == 85)
        #expect(ava.progress.percent(for: .letters) == 70)
        #expect(ava.progress.percent(for: .shapes) == 60)
        #expect(ava.progress.percent(for: .animals) == 90)
        #expect(ava.progress.totalGames == 24)
        #expect(ava.totalStars == 72)
    }

    // MARK: - Rewards

    @Test func categoryBadgeUnlocksAtThreshold() {
        var player = TVPlayer(name: "Test", avatar: "🙂", color: .sky)
        #expect(!TVRewardRules.isEarned(.shapeMaster, by: player))
        player.progress.record(correctAnswers: 5, stars: TVRewardRules.starsPerCategoryBadge, in: .shapes, game: .shapeHunt)
        #expect(TVRewardRules.isEarned(.shapeMaster, by: player))
        #expect(TVRewardRules.newRewards(for: player) == [.shapeMaster])
    }

    @Test func familyLearnerNeedsAFamilyChallenge() {
        var player = TVPlayer(name: "Test", avatar: "🙂", color: .sky)
        #expect(!TVRewardRules.isEarned(.familyLearner, by: player))
        player.familyChallengesPlayed = 1
        #expect(TVRewardRules.isEarned(.familyLearner, by: player))
    }

    @Test func alreadyRecordedBadgesAreNotNewAgain() {
        var player = TVPlayer(name: "Test", avatar: "🙂", color: .sky)
        player.progress.record(correctAnswers: 10, stars: 12, in: .numbers, game: .countingPop)
        player.earnedRewards = [.numberExplorer]
        #expect(TVRewardRules.newRewards(for: player).isEmpty)
    }

    @Test func starsRemainingCountsDown() {
        var player = TVPlayer(name: "Test", avatar: "🙂", color: .sky)
        player.progress.record(correctAnswers: 4, stars: 7, in: .letters, game: .dragToMatch)
        #expect(TVRewardRules.starsRemaining(for: .letterExplorer, player: player) == 3)
        #expect(TVRewardRules.starsRemaining(for: .familyLearner, player: player) == 0)
    }

    @Test func rewardsViewModelMarksNewAndLockedBadges() throws {
        var player = try #require(TVGameDataService.demoPlayers().first)
        player.progress.record(correctAnswers: 3, stars: 3, in: .shapes, game: .shapeHunt)
        var result = TVSessionResult(gameKind: .shapeHunt, category: .shapes, tracker: TVRoundTracker())
        result.newRewards = [.shapeMaster]
        let model = TVRewardsViewModel(player: player, result: result, familyStars: 10)
        let shapeBadge = try #require(model.badges.first { $0.kind == .shapeMaster })
        #expect(shapeBadge.isNew)
        #expect(shapeBadge.isEarned)
        #expect(model.earnedBadgeCount == 5)
    }
}
