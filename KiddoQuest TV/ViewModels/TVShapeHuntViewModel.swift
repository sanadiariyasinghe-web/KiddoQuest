import Foundation
import Observation

/// Game logic for Shape Hunt TV (and its letter variant).
@Observable
final class TVShapeHuntViewModel {
    enum Feedback: Equatable {
        case none
        case found(itemID: Int)
        case notThis(itemID: Int)
        case alreadyFound(itemID: Int)
        case challengeComplete
    }

    enum Outcome: Equatable {
        case found
        case alreadyFound
        case notTarget
        case ignored
    }

    let category: TVCategory
    let challenges: [TVHuntChallenge]
    private(set) var challengeIndex = 0
    private(set) var foundItemIDs: Set<Int> = []
    private(set) var feedback: Feedback = .none
    private(set) var tracker = TVRoundTracker()
    private(set) var isFinished = false

    init(category: TVCategory, challenges: [TVHuntChallenge]? = nil) {
        self.category = category
        // Keep only challenges that actually contain something to find.
        self.challenges = (challenges ?? TVGameDataService.huntChallenges(for: category))
            .filter { $0.targetCount > 0 }
        isFinished = self.challenges.isEmpty
    }

    var currentChallenge: TVHuntChallenge? {
        challenges.indices.contains(challengeIndex) ? challenges[challengeIndex] : nil
    }

    var foundCount: Int { foundItemIDs.count }

    var targetCount: Int { currentChallenge?.targetCount ?? 0 }

    var foundLabel: String { "Found: \(foundCount) / \(targetCount)" }

    var isChallengeComplete: Bool { targetCount > 0 && foundCount >= targetCount }

    var isLastChallenge: Bool { challengeIndex >= challenges.count - 1 }

    var challengeLabel: String {
        guard !challenges.isEmpty else { return "" }
        return "Challenge \(challengeIndex + 1) of \(challenges.count)"
    }

    /// Stars for the challenge just completed, shown on the "Great job!" card.
    private(set) var challengeStars = 0
    @ObservationIgnored private var mistakesAtChallengeStart = 0

    var mascotMood: TVMascotMood {
        switch feedback {
        case .none, .alreadyFound: return .idle
        case .found: return .happy
        case .notThis: return .tryAgain
        case .challengeComplete: return .correct
        }
    }

    var feedbackMessage: String? {
        guard let challenge = currentChallenge else { return nil }
        switch feedback {
        case .none:
            return nil
        case .found:
            return "Found!"
        case .alreadyFound:
            return "You already found that one!"
        case .notThis(let itemID):
            let name = challenge.items.first { $0.id == itemID }?.content.spokenName ?? "That one"
            return "That's a \(name.lowercased()). Almost! Try again!"
        case .challengeComplete:
            return "Great job!"
        }
    }

    func isFound(_ item: TVHuntItem) -> Bool {
        foundItemIDs.contains(item.id)
    }

    @discardableResult
    func select(_ item: TVHuntItem) -> Outcome {
        guard !isFinished, !isChallengeComplete,
              let challenge = currentChallenge,
              challenge.items.contains(where: { $0.id == item.id }) else {
            return .ignored
        }
        if foundItemIDs.contains(item.id) {
            feedback = .alreadyFound(itemID: item.id)
            return .alreadyFound
        }
        guard item.isTarget else {
            tracker.registerMistake()
            feedback = .notThis(itemID: item.id)
            return .notTarget
        }

        tracker.registerCorrect()
        tracker.startNextRound()
        foundItemIDs.insert(item.id)
        if isChallengeComplete {
            let mistakes = tracker.mistakes - mistakesAtChallengeStart
            challengeStars = TVScoring.sessionStars(correct: targetCount, mistakes: mistakes)
            feedback = .challengeComplete
        } else {
            feedback = .found(itemID: item.id)
        }
        return .found
    }

    /// "Next Challenge" — loads the next hunt or finishes the game.
    func nextChallenge() {
        guard isChallengeComplete else { return }
        if isLastChallenge {
            isFinished = true
        } else {
            challengeIndex += 1
            foundItemIDs = []
            feedback = .none
            challengeStars = 0
            mistakesAtChallengeStart = tracker.mistakes
        }
    }

    func restart() {
        challengeIndex = 0
        foundItemIDs = []
        feedback = .none
        tracker = TVRoundTracker()
        challengeStars = 0
        mistakesAtChallengeStart = 0
        isFinished = challenges.isEmpty
    }

    func makeResult() -> TVSessionResult {
        TVSessionResult(gameKind: .shapeHunt, category: category, tracker: tracker)
    }
}
