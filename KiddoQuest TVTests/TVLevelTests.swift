import Foundation
import Testing
@testable import KiddoQuest_TV

/// Adaptive levels: more answers after a perfect round, fewer after a hard one.
@MainActor
struct TVLevelTests {

    private func tracker(correct: Int, mistakes: Int) -> TVRoundTracker {
        var tracker = TVRoundTracker()
        for _ in 0..<mistakes { tracker.registerMistake() }
        for round in 0..<correct {
            if round > 0 { tracker.startNextRound() }
            tracker.registerCorrect()
        }
        return tracker
    }

    @Test(arguments: [(1, 2), (2, 3), (3, 4)])
    func levelSetsTheNumberOfAnswers(level: Int, choices: Int) {
        #expect(TVLevelRules.choiceCount(forLevel: level) == choices)
        let model = TVChoiceGameViewModel(kind: .feedAnimals, category: .animals, level: level)
        for round in model.rounds {
            #expect(round.options.count == choices)
            #expect(round.correctOption != nil, "Trimming must keep the right answer")
        }
    }

    @Test func levelsMoveGentlyAndStayInRange() {
        #expect(TVLevelRules.nextLevel(after: 2, stars: 3) == 3)
        #expect(TVLevelRules.nextLevel(after: 3, stars: 3) == 3)
        #expect(TVLevelRules.nextLevel(after: 2, stars: 2) == 2)
        #expect(TVLevelRules.nextLevel(after: 2, stars: 1) == 1)
        #expect(TVLevelRules.nextLevel(after: 1, stars: 0) == 1)
    }

    @Test func perfectRoundLevelsUpThePlayerAndIsSaved() throws {
        let persistence = TVInMemoryPersistence(snapshot: nil)
        let store = TVAppStore(persistence: persistence)
        let player = try #require(store.activePlayer)
        #expect(player.level(for: .animalShadows) == TVLevelRules.startLevel)

        let perfect = TVSessionResult(gameKind: .animalShadows, category: .animals, tracker: tracker(correct: 5, mistakes: 0))
        let recorded = store.recordSession(perfect)
        #expect(recorded.newLevel == 3)
        #expect(store.activePlayer?.level(for: .animalShadows) == 3)

        let relaunched = TVAppStore(persistence: persistence)
        #expect(relaunched.players.first { $0.id == player.id }?.level(for: .animalShadows) == 3)
    }

    @Test func gamesWithoutChoicesDoNotChangeLevel() throws {
        let store = TVAppStore(persistence: TVInMemoryPersistence(snapshot: nil))
        let result = TVSessionResult(gameKind: .countingPop, category: .numbers, tracker: tracker(correct: 5, mistakes: 0))
        #expect(store.recordSession(result).newLevel == nil)
        #expect(store.activePlayer?.levels.isEmpty == true)
    }

    @Test func oldSavedPlayersDecodeWithStartLevel() throws {
        let json = #"{"id":"\#(UUID().uuidString)","name":"Ava","avatar":"🦊","color":"coral","role":"child"}"#
        let player = try JSONDecoder().decode(TVPlayer.self, from: Data(json.utf8))
        #expect(player.level(for: .shapeSort) == TVLevelRules.startLevel)
    }
}
