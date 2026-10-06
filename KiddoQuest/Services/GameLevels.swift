import Foundation

// MARK: - Gentle Levels
// Choice-based games start easy and grow with the child:
// Level 1 → 2 choices, Level 2 → 3 choices, Level 3 → 4 choices.
// A child moves up one level after a 3-star round (never down — no pressure).

enum GameLevels {
    static let maxLevel = 3
    
    /// How many answers to show at a level.
    static func choiceCount(forLevel level: Int) -> Int {
        min(maxLevel, max(1, level)) + 1
    }
    
    /// The level for next time, after finishing a round with `stars`.
    static func nextLevel(after level: Int, stars: Int) -> Int {
        stars >= 3 ? min(maxLevel, level + 1) : level
    }
}

/// Remembers each game's level in UserDefaults.
final class GameLevelStore {
    static let shared = GameLevelStore()
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    private func key(for gameID: String) -> String { "game_level_\(gameID)" }
    
    func level(for gameID: String) -> Int {
        let saved = defaults.integer(forKey: key(for: gameID))
        return min(GameLevels.maxLevel, max(1, saved))
    }
    
    /// Saves the result of a finished round. Returns the new level if the child moved up.
    @discardableResult
    func recordRound(gameID: String, stars: Int) -> Int? {
        let current = level(for: gameID)
        let next = GameLevels.nextLevel(after: current, stars: stars)
        defaults.set(next, forKey: key(for: gameID))
        return next > current ? next : nil
    }
    
    func reset(gameIDs: [String]) {
        gameIDs.forEach { defaults.removeObject(forKey: key(for: $0)) }
    }
}
