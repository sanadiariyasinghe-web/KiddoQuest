import Foundation
import Observation

/// Shared engine for the five choice games
/// (Tap-to-Match, Tap-to-Reveal, Feed the Animals, Animal Shadows and Shape Sort).
@Observable
final class TVChoiceGameViewModel {
    enum Feedback: Equatable {
        case none
        case correct(points: Int)
        case tryAgain(optionID: String)
    }

    let kind: TVGameKind
    let category: TVCategory
    let rounds: [TVChoiceRound]
    private(set) var roundIndex = 0
    private(set) var feedback: Feedback = .none
    private(set) var tracker = TVRoundTracker()
    private(set) var isFinished = false

    init(kind: TVGameKind, category: TVCategory, rounds: [TVChoiceRound]? = nil) {
        self.kind = kind
        self.category = category
        self.rounds = rounds ?? TVGameDataService.choiceRounds(for: kind, category: category)
        isFinished = self.rounds.isEmpty
    }

    var currentRound: TVChoiceRound? {
        rounds.indices.contains(roundIndex) ? rounds[roundIndex] : nil
    }

    var isShowingSuccess: Bool {
        if case .correct = feedback { return true }
        return false
    }

    var roundLabel: String {
        guard !rounds.isEmpty else { return "" }
        return "Round \(min(roundIndex + 1, rounds.count)) of \(rounds.count)"
    }

    var mascotMood: TVMascotMood {
        switch feedback {
        case .none: return .idle
        case .correct: return .correct
        case .tryAgain: return .tryAgain
        }
    }

    var feedbackMessage: String? {
        switch feedback {
        case .none: return nil
        case .correct: return currentRound?.successMessage ?? "Great job!"
        case .tryAgain: return "Almost! Try again!"
        }
    }

    @discardableResult
    func select(optionID: String) -> TVAnswerOutcome {
        guard !isFinished, !isShowingSuccess, let round = currentRound else { return .ignored }
        if round.isCorrect(optionID) {
            let points = tracker.registerCorrect()
            feedback = .correct(points: points)
            return .correct(points: points)
        }
        tracker.registerMistake()
        feedback = .tryAgain(optionID: optionID)
        return .incorrect
    }

    func advance() {
        guard isShowingSuccess else { return }
        if roundIndex >= rounds.count - 1 {
            isFinished = true
        } else {
            roundIndex += 1
            feedback = .none
            tracker.startNextRound()
        }
    }

    func restart() {
        roundIndex = 0
        feedback = .none
        tracker = TVRoundTracker()
        isFinished = rounds.isEmpty
    }

    func makeResult() -> TVSessionResult {
        TVSessionResult(gameKind: kind, category: category, tracker: tracker)
    }
}
