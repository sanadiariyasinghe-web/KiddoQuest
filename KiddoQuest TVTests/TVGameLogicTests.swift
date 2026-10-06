import Foundation
import Testing
@testable import KiddoQuest_TV

/// Answer validation for Counting Pop, Shape Hunt and the choice games.
@MainActor
struct TVGameLogicTests {

    // MARK: - Counting Pop

    @Test func countingPopFirstRoundAsksAboutFiveApples() throws {
        let model = TVCountingPopViewModel(category: .numbers)
        let round = try #require(model.currentRound)
        #expect(round.question == "How many apples?")
        #expect(round.count == 5)
        #expect(round.options == [3, 5, 7, 9])
    }

    @Test func countingPopCorrectAnswerScoresAndCelebrates() {
        let model = TVCountingPopViewModel(category: .numbers)
        let outcome = model.select(5)
        #expect(outcome == .correct(points: TVScoring.firstTryPoints))
        #expect(model.feedback == .correct(points: TVScoring.firstTryPoints))
        #expect(model.mascotMood == .correct)
        #expect(model.feedbackMessage?.hasPrefix("Great job!") == true)
        #expect(model.tracker.points == TVScoring.firstTryPoints)
    }

    @Test func countingPopIncorrectAnswerIsGentleAndAllowsRetry() {
        let model = TVCountingPopViewModel(category: .numbers)
        #expect(model.select(3) == .incorrect)
        #expect(model.feedback == .tryAgain)
        #expect(model.feedbackMessage == "Almost! Try again!")
        #expect(model.mascotMood == .tryAgain)
        #expect(model.tracker.points == 0)
        #expect(model.triedOptions == [3])
        // Same round, can still answer correctly.
        #expect(model.roundIndex == 0)
        #expect(model.select(5) == .correct(points: TVScoring.retryPoints))
    }

    @Test func countingPopIgnoresInputWhileCelebrating() {
        let model = TVCountingPopViewModel(category: .numbers)
        model.select(5)
        #expect(model.select(5) == .ignored)
        #expect(model.tracker.correctAnswers == 1)
    }

    @Test func countingPopFinishesAfterAllRounds() {
        let model = TVCountingPopViewModel(category: .numbers)
        for round in model.rounds {
            #expect(model.select(round.count) != .ignored)
            model.advance()
        }
        #expect(model.isFinished)
        let result = model.makeResult()
        #expect(result.correctAnswers == model.rounds.count)
        #expect(result.stars == 3)
        #expect(result.gameKind == .countingPop)
    }

    @Test func countingPopRestartResetsEverything() {
        let model = TVCountingPopViewModel(category: .numbers)
        model.select(3)
        model.select(5)
        model.advance()
        model.restart()
        #expect(model.roundIndex == 0)
        #expect(model.tracker == TVRoundTracker())
        #expect(model.feedback == .none)
        #expect(!model.isFinished)
    }

    @Test func countingPopWithEmptyContentDoesNotCrash() {
        let model = TVCountingPopViewModel(category: .numbers, rounds: [])
        #expect(model.isFinished)
        #expect(model.currentRound == nil)
        #expect(model.select(1) == .ignored)
        model.advance()
        #expect(model.roundLabel.isEmpty)
    }

    @Test func everyCountingRoundIncludesItsAnswer() {
        for category in TVCategory.allCases {
            for round in TVGameDataService.countingRounds(for: category) {
                #expect(round.options.contains(round.count), "Round \(round.id) in \(category) is missing its answer")
            }
        }
    }

    // MARK: - Shape Hunt

    @Test func shapeHuntStartsWithTrianglesAndZeroFound() throws {
        let model = TVShapeHuntViewModel(category: .shapes)
        let challenge = try #require(model.currentChallenge)
        #expect(challenge.prompt == "Find all the TRIANGLES!")
        #expect(model.foundLabel == "Found: 0 / 2")
    }

    @Test func shapeHuntCountsFoundTriangles() throws {
        let model = TVShapeHuntViewModel(category: .shapes)
        let challenge = try #require(model.currentChallenge)
        let triangles = challenge.items.filter(\.isTarget)
        #expect(triangles.count == 2)

        #expect(model.select(triangles[0]) == .found)
        #expect(model.foundLabel == "Found: 1 / 2")
        #expect(model.feedbackMessage == "Found!")

        #expect(model.select(triangles[1]) == .found)
        #expect(model.foundLabel == "Found: 2 / 2")
        #expect(model.isChallengeComplete)
        #expect(model.feedbackMessage == "Great job!")
        #expect(model.challengeStars == 3)
    }

    @Test func shapeHuntRejectsWrongShapeGently() throws {
        let model = TVShapeHuntViewModel(category: .shapes)
        let circle = try #require(model.currentChallenge?.items.first { !$0.isTarget })
        #expect(model.select(circle) == .notTarget)
        #expect(model.foundCount == 0)
        #expect(model.tracker.mistakes == 1)
        #expect(model.feedbackMessage?.contains("Almost! Try again!") == true)
    }

    @Test func shapeHuntDoesNotDoubleCountTheSameShape() throws {
        let model = TVShapeHuntViewModel(category: .shapes)
        let triangle = try #require(model.currentChallenge?.items.first { $0.isTarget })
        model.select(triangle)
        #expect(model.select(triangle) == .alreadyFound)
        #expect(model.foundCount == 1)
    }

    @Test func shapeHuntNextChallengeAdvancesThenFinishes() {
        let model = TVShapeHuntViewModel(category: .shapes)
        for _ in model.challenges {
            for item in model.currentChallenge?.items.filter(\.isTarget) ?? [] {
                model.select(item)
            }
            model.nextChallenge()
        }
        #expect(model.isFinished)
        #expect(model.makeResult().gameKind == .shapeHunt)
    }

    @Test func letterHuntUsesTheSameEngine() throws {
        let model = TVShapeHuntViewModel(category: .letters)
        let challenge = try #require(model.currentChallenge)
        #expect(challenge.target == .letter("A"))
        #expect(model.targetCount == 2)
    }

    @Test func shapeHuntFiltersChallengesWithNothingToFind() {
        let empty = TVHuntChallenge(id: 9, prompt: "Find nothing", target: .shape(.star), items: [
            TVHuntItem(id: 0, content: .shape(.circle), isTarget: false, paletteIndex: 0)
        ])
        let model = TVShapeHuntViewModel(category: .shapes, challenges: [empty])
        #expect(model.challenges.isEmpty)
        #expect(model.isFinished)
        #expect(model.foundLabel == "Found: 0 / 0")
    }

    // MARK: - Choice games

    @Test(arguments: [TVGameKind.dragToMatch, .tapToReveal, .feedAnimals, .animalShadows, .shapeSort])
    func choiceGamesHaveFiveValidRounds(kind: TVGameKind) throws {
        let game = try #require(TVGameDataService.game(for: kind))
        #expect(game.availability == .playable)
        for category in game.categories {
            let rounds = TVGameDataService.choiceRounds(for: kind, category: category)
            #expect(rounds.count == TVGameDataService.choiceRoundCount)
            #expect(rounds.map(\.id) == Array(0..<rounds.count))
            for round in rounds {
                #expect(round.correctOption != nil, "\(kind) round \(round.id) has no correct option")
                #expect(Set(round.options.map(\.id)).count == round.options.count, "\(kind) has duplicate options")
            }
        }
    }

    @Test func choiceCorrectAndIncorrectAnswers() throws {
        let model = TVChoiceGameViewModel(kind: .shapeSort, category: .shapes)
        let round = try #require(model.currentRound)
        let wrong = try #require(round.options.first { !round.isCorrect($0.id) })
        #expect(model.select(optionID: wrong.id) == .incorrect)
        #expect(model.feedback == .tryAgain(optionID: wrong.id))
        #expect(model.select(optionID: round.correctOptionID) == .correct(points: TVScoring.retryPoints))
        #expect(model.feedbackMessage == round.successMessage)
    }

    @Test func tapToMatchAnswerIsTheGroupSize() throws {
        let model = TVChoiceGameViewModel(kind: .dragToMatch, category: .numbers)
        let round = try #require(model.currentRound)
        guard case .group(_, let count) = round.subject else {
            Issue.record("Expected a group to count")
            return
        }
        #expect(round.correctOptionID == "\(count)")
        #expect(model.select(optionID: "\(count)") == .correct(points: TVScoring.firstTryPoints))
    }

    @Test func feedTheAnimalsOffersTheRightFood() throws {
        let rounds = TVGameDataService.choiceRounds(for: .feedAnimals, category: .animals)
        for round in rounds {
            guard case .hungryAnimal(_, let name, let food) = round.subject else {
                Issue.record("Expected a hungry animal")
                continue
            }
            let pair = try #require(TVGameDataService.animalFoods.first { $0.name == name })
            #expect(pair.food == food)
            #expect(round.correctOptionID == pair.foodName)
        }
    }

    @Test func animalShadowsAnswerIsTheShadowAnimal() {
        for round in TVGameDataService.choiceRounds(for: .animalShadows, category: .animals) {
            guard case .animalShadow(_, let name) = round.subject else {
                Issue.record("Expected an animal shadow")
                continue
            }
            #expect(round.correctOptionID == name)
        }
    }

    @Test func shapeSortUsesEveryShape() {
        for _ in 0..<10 {
            let rounds = TVGameDataService.choiceRounds(for: .shapeSort, category: .shapes)
            #expect(Set(rounds.map(\.correctOptionID)) == ["triangle", "circle", "square"])
        }
    }

    @Test func libraryContainsAllSevenFullGames() {
        #expect(TVGameDataService.games.count == 7)
        #expect(Set(TVGameDataService.games.map(\.kind)) == Set(TVGameKind.allCases))
        #expect(TVGameDataService.games.allSatisfy { $0.availability == .playable })
        #expect(TVGameDataService.games(in: .animals).map(\.kind).contains(.feedAnimals))
        #expect(TVGameDataService.games(in: .animals).map(\.kind).contains(.animalShadows))
    }

    @Test func savedAnimalMatchProgressLoadsAsFeedTheAnimals() throws {
        let data = Data(#"["animalMatch","countingPop"]"#.utf8)
        let kinds = try JSONDecoder().decode([TVGameKind].self, from: data)
        #expect(kinds == [.feedAnimals, .countingPop])
    }

    @Test func everyCategoryHasAtLeastOneGame() {
        for category in TVCategory.allCases {
            #expect(!TVGameDataService.games(in: category).isEmpty)
        }
    }

    @Test func launchCategoryFallsBackToPrimary() throws {
        let game = try #require(TVGameDataService.game(for: .feedAnimals))
        #expect(game.launchCategory(preferred: .numbers) == .animals)
        #expect(game.launchCategory(preferred: nil) == .animals)
        #expect(game.launchCategory(preferred: .animals) == .animals)
    }
}
