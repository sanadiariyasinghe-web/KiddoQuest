import Foundation

/// Presentation logic for the Home screen.
struct TVHomeViewModel {
    let activePlayer: TVPlayer?
    let hasSelectedPlayer: Bool
    let lastPlayedCategory: TVCategory?

    /// Buddy alternates between these lines on the Home screen.
    static let buddyMessages = [
        "Ready for a learning adventure?",
        "Let's learn together!"
    ]

    var continueSubtitle: String {
        guard hasSelectedPlayer, let activePlayer else { return "Pick a player first" }
        if let lastPlayedCategory {
            return "\(activePlayer.name) · \(lastPlayedCategory.title)"
        }
        return "as \(activePlayer.name)"
    }

    var playSubtitle: String { "Choose who's playing" }

    var welcomeLine: String {
        guard hasSelectedPlayer, let activePlayer else { return "Welcome, family!" }
        return "Welcome back, \(activePlayer.name)!"
    }

    static func buddyMessage(at index: Int) -> String {
        buddyMessages[abs(index) % buddyMessages.count]
    }
}
