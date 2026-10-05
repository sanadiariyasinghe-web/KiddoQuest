import Foundation

/// Why the player picker is being shown, which decides where it goes next.
nonisolated enum TVPlayerSelectionMode: Hashable {
    /// Coming from PLAY: picking a player continues into the Learning World.
    case startPlaying
    /// Switching player from another screen: picking a player returns back.
    case switchPlayer
}

/// Every destination in the KiddoQuest TV navigation stack.
nonisolated enum TVRoute: Hashable {
    case playerSelection(TVPlayerSelectionMode)
    case world
    case category(TVCategory)
    /// The full six-game library, optionally pre-filtered to a category.
    case gameLibrary(TVCategory?)
    case game(TVGameKind, TVCategory)
    case familyChallenge
    case results(TVSessionResult)
    case rewards
    case familyProgress
    case settings
}
