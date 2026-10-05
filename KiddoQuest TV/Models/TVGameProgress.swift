import Foundation

/// Learning progress inside one category for one player.
nonisolated struct TVCategoryProgress: Codable, Hashable {
    var stars: Int = 0
    var correctAnswers: Int = 0
    var gamesPlayed: Int = 0
}

/// A player's progress across every category and game.
nonisolated struct TVGameProgress: Codable, Hashable {
    /// Correct answers needed in a category to reach 100% mastery.
    static let answersForMastery = 20
    /// A category counts as "completed" on the dashboard at this percentage.
    static let completionThreshold = 80

    private(set) var categories: [TVCategory: TVCategoryProgress] = [:]
    private(set) var completedGames: Set<TVGameKind> = []

    init(categories: [TVCategory: TVCategoryProgress] = [:], completedGames: Set<TVGameKind> = []) {
        self.categories = categories
        self.completedGames = completedGames
    }

    func progress(for category: TVCategory) -> TVCategoryProgress {
        categories[category] ?? TVCategoryProgress()
    }

    func percent(for category: TVCategory) -> Int {
        TVScoring.percent(correct: progress(for: category).correctAnswers, target: Self.answersForMastery)
    }

    /// 0–5 star rating shown on category cards.
    func rating(for category: TVCategory) -> Int {
        TVScoring.rating(forPercent: percent(for: category))
    }

    var totalStars: Int {
        categories.values.reduce(0) { $0 + $1.stars }
    }

    var totalGames: Int {
        categories.values.reduce(0) { $0 + $1.gamesPlayed }
    }

    /// Average completion across all four categories.
    var overallPercent: Int {
        let total = TVCategory.allCases.reduce(0) { $0 + percent(for: $1) }
        return total / TVCategory.allCases.count
    }

    var completedCategories: [TVCategory] {
        TVCategory.allCases.filter { percent(for: $0) >= Self.completionThreshold }
    }

    /// The category with the highest completion, or nil when nothing has been played.
    var strongestCategory: TVCategory? {
        let best = TVCategory.allCases.max { percent(for: $0) < percent(for: $1) }
        guard let best, percent(for: best) > 0 else { return nil }
        return best
    }

    /// Adds the outcome of a finished session.
    mutating func record(correctAnswers: Int, stars: Int, in category: TVCategory, game: TVGameKind?) {
        var entry = progress(for: category)
        entry.correctAnswers += max(0, correctAnswers)
        entry.stars += max(0, stars)
        entry.gamesPlayed += 1
        categories[category] = entry
        if let game {
            completedGames.insert(game)
        }
    }
}
