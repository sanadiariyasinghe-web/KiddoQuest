import Foundation

// MARK: - Progress Summary
// Pure helpers that turn saved Core Data progress into what children and parents see:
// stars per game, and stars + completion per island.

struct IslandProgress: Equatable {
    var stars: Int
    var maxStars: Int
    var percentage: Int
}

enum ProgressSummary {
    /// Every game awards up to 3 stars.
    static let maxStarsPerGame = 3
    
    /// Best stars saved for a game (0 if never finished).
    static func stars(forGameID gameID: String, in progress: [String: GameProgress]) -> Int {
        min(maxStarsPerGame, max(0, progress[gameID]?.stars ?? 0))
    }
    
    /// Share of available stars collected, as a whole percentage (0–100).
    static func percentage(stars: Int, maxStars: Int) -> Int {
        guard maxStars > 0 else { return 0 }
        return min(100, max(0, stars * 100 / maxStars))
    }
    
    /// Returns the game with its stars and completion filled in from saved progress.
    static func decorated(_ game: GameInfo, with progress: [String: GameProgress]) -> GameInfo {
        var game = game
        game.starsEarned = stars(forGameID: game.id, in: progress)
        game.completionPercentage = percentage(stars: game.starsEarned, maxStars: maxStarsPerGame)
        return game
    }
    
    /// Total stars and completion across all games on an island.
    static func island(
        _ category: IslandCategory,
        games: [GameInfo] = GameInfo.sampleGames,
        progress: [String: GameProgress]
    ) -> IslandProgress {
        let islandGames = games.filter { $0.category == category }
        let stars = islandGames.reduce(0) { $0 + Self.stars(forGameID: $1.id, in: progress) }
        let maxStars = islandGames.count * maxStarsPerGame
        return IslandProgress(
            stars: stars,
            maxStars: maxStars,
            percentage: percentage(stars: stars, maxStars: maxStars)
        )
    }
}
