import Foundation
import Testing
@testable import KiddoQuest_TV

/// Turn-taking and the shared family score.
@MainActor
struct TVFamilyChallengeTests {

    private let players = TVGameDataService.demoPlayers()

    private var shapeSquad: TVFamilyChallenge {
        TVGameDataService.familyChallenges[0]
    }

    private func startedModel(participants: [String] = ["Ava", "Liam"]) -> TVFamilyChallengeViewModel {
        let model = TVFamilyChallengeViewModel(players: players)
        for player in players where !participants.contains(player.name) {
            model.toggleParticipant(player)
        }
        model.start(shapeSquad)
        return model
    }

    private func answerCorrectly(_ model: TVFamilyChallengeViewModel) {
        guard let question = model.currentQuestion else { return }
        model.answer(optionID: question.correctOptionID)
        model.advanceTurn()
    }

    @Test func everyoneJoinsByDefault() {
        let model = TVFamilyChallengeViewModel(players: players)
        #expect(model.participants.count == 3)
        #expect(model.canStart)
        #expect(model.phase == .setup)
    }

    @Test func needsAtLeastTwoPlayers() throws {
        let model = TVFamilyChallengeViewModel(players: players)
        model.toggleParticipant(players[1])
        model.toggleParticipant(players[2])
        #expect(model.participants.map(\.name) == ["Ava"])
        #expect(!model.canStart)
        #expect(!model.start(shapeSquad))
        #expect(model.phase == .setup)
    }

    @Test func toggledPlayersKeepHouseholdOrder() {
        let model = TVFamilyChallengeViewModel(players: players)
        model.toggleParticipant(players[0])
        model.toggleParticipant(players[0])
        #expect(model.participants.map(\.name) == ["Ava", "Liam", "Parent"])
    }

    @Test func turnsAlternateBetweenPlayers() {
        let model = startedModel()
        #expect(model.turnTitle == "AVA'S TURN")
        answerCorrectly(model)
        #expect(model.turnTitle == "LIAM'S TURN")
        answerCorrectly(model)
        #expect(model.turnTitle == "AVA'S TURN")
    }

    @Test func correctAnswersFeedPlayerAndFamilyScores() throws {
        let model = startedModel()
        let ava = players[0], liam = players[1]
        answerCorrectly(model) // Ava
        answerCorrectly(model) // Liam
        answerCorrectly(model) // Ava
        #expect(model.score(for: ava) == 2)
        #expect(model.score(for: liam) == 1)
        #expect(model.familyStars == 3)
    }

    @Test func wrongAnswerKeepsTheTurnAndScore() throws {
        let model = startedModel()
        let question = try #require(model.currentQuestion)
        let wrong = try #require(question.options.first { !question.isCorrect($0.id) })
        #expect(model.answer(optionID: wrong.id) == .incorrect)
        #expect(model.feedbackMessage == "Almost! Try again!")
        #expect(model.familyStars == 0)
        #expect(model.currentPlayer?.name == "Ava")
        // advanceTurn only moves on after a correct answer.
        model.advanceTurn()
        #expect(model.currentPlayer?.name == "Ava")
    }

    @Test func reachingTheGoalCelebratesAndBuildsOutcome() throws {
        let model = startedModel()
        for _ in 0..<shapeSquad.goal {
            answerCorrectly(model)
        }
        #expect(model.phase == .celebrating)
        #expect(model.familyStars == shapeSquad.goal)
        let outcome = try #require(model.makeOutcome())
        #expect(outcome.familyStars == 5)
        #expect(outcome.scores[players[0].id] == 3)
        #expect(outcome.scores[players[1].id] == 2)
        #expect(model.topScorers.map(\.name) == ["Ava"])
        // No further answers after the goal.
        #expect(model.answer(optionID: "circle") == .ignored)
    }

    @Test func storeRecordsFamilyChallengeForEveryParticipant() throws {
        let persistence = TVInMemoryPersistence()
        let store = TVAppStore(persistence: persistence)
        let liam = try #require(store.players.first { $0.name == "Liam" })
        let ava = try #require(store.players.first { $0.name == "Ava" })
        let familyBefore = store.family

        let outcome = TVFamilyChallengeOutcome(
            challengeID: "shape-squad", category: .shapes,
            scores: [ava.id: 3, liam.id: 2], familyStars: 5
        )
        let unlocked = store.recordFamilyChallenge(outcome)

        #expect(store.family.familyStars == familyBefore.familyStars + 5)
        #expect(store.family.challengesCompleted == familyBefore.challengesCompleted + 1)
        // Liam's first family challenge unlocks Family Learner; Ava already had it.
        #expect(unlocked[liam.id]?.contains(.familyLearner) == true)
        #expect(unlocked[ava.id]?.contains(.familyLearner) != true)
        #expect(store.player(withID: liam.id)?.familyChallengesPlayed == 1)
        #expect(persistence.snapshot?.family.challengesCompleted == store.family.challengesCompleted)
    }

    @Test func familyScoreAccumulates() {
        var family = TVFamilyScore()
        family.addSoloGame(stars: 3)
        family.addFamilyChallenge(stars: 5)
        family.addSoloGame(stars: -2) // Negative input is ignored.
        #expect(family.familyStars == 8)
        #expect(family.challengesCompleted == 1)
        #expect(family.gamesCompleted == 3)
    }

    @Test func playAgainResetsScoresButKeepsPlayers() {
        let model = startedModel()
        for _ in 0..<shapeSquad.goal { answerCorrectly(model) }
        model.markOutcomeRecorded()
        model.playAgain()
        #expect(model.phase == .playing)
        #expect(model.familyStars == 0)
        #expect(!model.hasRecordedOutcome)
        #expect(model.participants.count == 2)
    }

    @Test func emptyChallengesAreFilteredOut() {
        let empty = TVFamilyChallenge(id: "x", title: "X", emoji: "❓", goalPrompt: "?", category: .numbers, goal: 3, questions: [])
        let model = TVFamilyChallengeViewModel(players: players, challenges: [empty])
        #expect(model.challenges.isEmpty)
        #expect(!model.start(empty))
    }

    @Test func familyProgressSummarisesTheHousehold() {
        let model = TVFamilyProgressViewModel(players: players, family: TVGameDataService.demoFamilyScore)
        #expect(model.totalGames == 24 + 16)
        // Numbers, Letters and Animals tie in the demo data (11 games each).
        #expect(model.mostPlayedCategory != nil)
        #expect(model.mostPlayedCategory != .shapes)
        let ava = model.summaries[0]
        #expect(ava.categoriesCompleted == 2) // Numbers 85% and Animals 90%.
        let empty = TVFamilyProgressViewModel(players: [], family: TVFamilyScore())
        #expect(empty.mostPlayedCategory == nil)
        #expect(empty.mostPlayedText == "Not yet")
    }
}
