import Foundation

/// Presentation logic for the parent-facing Family Progress dashboard.
struct TVFamilyProgressViewModel {
    struct PlayerSummary: Identifiable, Hashable {
        let player: TVPlayer
        var id: UUID { player.id }

        var totalGames: Int { player.progress.totalGames }
        var totalStars: Int { player.totalStars }
        var categoriesCompleted: Int { player.progress.completedCategories.count }

        func percent(for category: TVCategory) -> Int {
            player.progress.percent(for: category)
        }

        var accessibilityLabel: String {
            let categories = TVCategory.allCases
                .map { "\($0.title) \(percent(for: $0)) percent" }
                .joined(separator: ", ")
            return "\(player.name). \(totalGames) games, \(totalStars) stars. \(categories). "
                + "\(categoriesCompleted) categories completed."
        }
    }

    let players: [TVPlayer]
    let family: TVFamilyScore

    var summaries: [PlayerSummary] {
        players.map(PlayerSummary.init)
    }

    var totalGames: Int {
        players.reduce(0) { $0 + $1.progress.totalGames }
    }

    /// The category the household has played most, or nil before any play.
    var mostPlayedCategory: TVCategory? {
        let totals = TVCategory.allCases.map { category in
            (category, players.reduce(0) { $0 + $1.progress.progress(for: category).gamesPlayed })
        }
        guard let best = totals.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return best.0
    }

    var mostPlayedText: String {
        mostPlayedCategory.map { "\($0.emoji) \($0.title)" } ?? "Not yet"
    }
}
