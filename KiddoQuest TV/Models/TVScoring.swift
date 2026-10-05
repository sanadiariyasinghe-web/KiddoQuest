import Foundation

/// Pure scoring rules shared by every game.
///
/// The rules are intentionally gentle for ages 3–7: a wrong answer never
/// removes points, and finishing a game always earns at least one star.
nonisolated enum TVScoring {
    static let firstTryPoints = 10
    static let retryPoints = 5
    static let maxSessionStars = 3
    static let maxRating = 5

    /// Points for a correct answer on the given 1-based attempt.
    static func points(forAttempt attempt: Int) -> Int {
        attempt <= 1 ? firstTryPoints : retryPoints
    }

    /// Stars (1–3) for a finished session. Returns 0 only when nothing was answered.
    static func sessionStars(correct: Int, mistakes: Int) -> Int {
        guard correct > 0 else { return 0 }
        let accuracy = Double(correct) / Double(correct + max(0, mistakes))
        switch accuracy {
        case 0.8...: return 3
        case 0.5..<0.8: return 2
        default: return 1
        }
    }

    /// Whole-number completion percentage, clamped to 0...100.
    static func percent(correct: Int, target: Int) -> Int {
        guard target > 0 else { return 0 }
        let value = Double(max(0, correct)) / Double(target) * 100
        return min(100, Int(value.rounded(.down)))
    }

    /// Converts a completion percentage into a 0–5 star rating for cards.
    static func rating(forPercent percent: Int) -> Int {
        switch percent {
        case 90...: return 5
        case 75..<90: return 4
        case 50..<75: return 3
        case 25..<50: return 2
        case 1..<25: return 1
        default: return 0
        }
    }
}

/// Tracks answers within one play session. Used by every game view model
/// so the scoring behaviour is identical (and unit-testable) everywhere.
nonisolated struct TVRoundTracker: Hashable {
    private(set) var correctAnswers = 0
    private(set) var mistakes = 0
    private(set) var points = 0
    private(set) var attemptsThisRound = 0

    /// Records a correct answer and returns the points awarded.
    @discardableResult
    mutating func registerCorrect() -> Int {
        attemptsThisRound += 1
        let awarded = TVScoring.points(forAttempt: attemptsThisRound)
        points += awarded
        correctAnswers += 1
        return awarded
    }

    mutating func registerMistake() {
        attemptsThisRound += 1
        mistakes += 1
    }

    mutating func startNextRound() {
        attemptsThisRound = 0
    }

    var sessionStars: Int {
        TVScoring.sessionStars(correct: correctAnswers, mistakes: mistakes)
    }
}

/// Result of evaluating a single answer.
nonisolated enum TVAnswerOutcome: Equatable {
    case correct(points: Int)
    case incorrect
    /// Input arrived while feedback was showing or the game was finished.
    case ignored
}
