import Foundation

/// Gentle adaptive difficulty for the five choice games.
/// Level 1 shows 2 answers, level 2 shows 3 and level 3 shows 4.
/// A perfect (3-star) round moves a child up; a 1-star round moves them down,
/// so a struggling child gets an easier game next time instead of failing again.
nonisolated enum TVLevelRules {
    static let minLevel = 1
    static let maxLevel = 3
    /// New players start in the middle (the same 3 answers as before levels existed).
    static let startLevel = 2
    static let maxChoices = 4

    static func supports(_ kind: TVGameKind) -> Bool {
        switch kind {
        case .dragToMatch, .tapToReveal, .feedAnimals, .animalShadows, .shapeSort: return true
        case .countingPop, .shapeHunt: return false
        }
    }

    static func choiceCount(forLevel level: Int) -> Int {
        clamp(level) + 1
    }

    /// The level to use next time after a round with `stars`.
    static func nextLevel(after current: Int, stars: Int) -> Int {
        if stars >= TVScoring.maxSessionStars { return clamp(current + 1) }
        if stars <= 1 { return clamp(current - 1) }
        return clamp(current)
    }

    /// Keeps the correct answer and drops extra answers down to the level's choice count.
    static func trim(_ round: TVChoiceRound, toLevel level: Int) -> TVChoiceRound {
        let count = choiceCount(forLevel: level)
        guard round.options.count > count, let correct = round.correctOption else { return round }
        let keptDistractors = round.options.filter { $0.id != correct.id }.prefix(count - 1)
        let kept = Set(keptDistractors.map(\.id)).union([correct.id])
        return TVChoiceRound(
            id: round.id, prompt: round.prompt, subject: round.subject,
            options: round.options.filter { kept.contains($0.id) },
            correctOptionID: round.correctOptionID, successMessage: round.successMessage
        )
    }

    private static func clamp(_ level: Int) -> Int {
        min(max(level, minLevel), maxLevel)
    }
}
