import Foundation
import Observation

/// Game logic for Counting Pop TV.
@Observable
final class TVCountingPopViewModel {
    enum Feedback: Equatable {
        case none
        case correct(points: Int)
        case tryAgain
    }

    let category: TVCategory
    let rounds: [TVCountingRound]
    private(set) var roundIndex = 0
    private(set) var feedback: Feedback = .none
    private(set) var tracker = TVRoundTracker()
    private(set) var isFinished = false
    /// Wrong answers already tried this round, so the view can soften them.
    private(set) var triedOptions: Set<Int> = []

    init(category: TVCategory, rounds: [TVCountingRound]? = nil) {
        self.category = category
        self.rounds = rounds ?? TVGameDataService.countingRounds(for: category)
        // Empty content finishes immediately instead of crashing.
        isFinished = self.rounds.isEmpty
    }

    var currentRound: TVCountingRound? {
        rounds.indices.contains(roundIndex) ? rounds[roundIndex] : nil
    }

    var roundLabel: String {
        guard !rounds.isEmpty else { return "" }
        return "Round \(min(roundIndex + 1, rounds.count)) of \(rounds.count)"
    }

    var progress: Double {
        guard !rounds.isEmpty else { return 0 }
        let completed = Double(roundIndex) + (isShowingSuccess ? 1 : 0)
        return min(1, completed / Double(rounds.count))
    }

    var isShowingSuccess: Bool {
        if case .correct = feedback { return true }
        return false
    }

    var isLastRound: Bool { roundIndex >= rounds.count - 1 }

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
        case .correct(let points): return "Great job! +\(points)"
        case .tryAgain: return "Almost! Try again!"
        }
    }

    /// Evaluates an answer. Wrong answers never cost points or lives.
    @discardableResult
    func select(_ answer: Int) -> TVAnswerOutcome {
        guard !isFinished, !isShowingSuccess, let round = currentRound else { return .ignored }
        if round.isCorrect(answer) {
            let points = tracker.registerCorrect()
            feedback = .correct(points: points)
            return .correct(points: points)
        }
        tracker.registerMistake()
        triedOptions.insert(answer)
        feedback = .tryAgain
        return .incorrect
    }

    /// Moves to the next round after a correct answer, or finishes.
    func advance() {
        guard isShowingSuccess else { return }
        if isLastRound {
            isFinished = true
        } else {
            roundIndex += 1
            feedback = .none
            triedOptions = []
            tracker.startNextRound()
        }
    }

    func restart() {
        roundIndex = 0
        feedback = .none
        tracker = TVRoundTracker()
        triedOptions = []
        isFinished = rounds.isEmpty
    }

    func makeResult() -> TVSessionResult {
        TVSessionResult(gameKind: .countingPop, category: category, tracker: tracker)
    }
}
