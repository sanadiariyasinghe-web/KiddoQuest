import Foundation

/// Summary of one finished solo game, passed to the Results screen.
nonisolated struct TVSessionResult: Hashable, Codable {
    let gameKind: TVGameKind
    let category: TVCategory
    var playerID: UUID?
    let correctAnswers: Int
    let mistakes: Int
    let points: Int
    let stars: Int
    /// Filled in by the store when the session is recorded.
    var newRewards: [TVRewardKind] = []
    /// The sticker added to the player's sticker book for finishing this game.
    var newSticker: String?

    init(gameKind: TVGameKind, category: TVCategory, tracker: TVRoundTracker, playerID: UUID? = nil) {
        self.gameKind = gameKind
        self.category = category
        self.playerID = playerID
        self.correctAnswers = tracker.correctAnswers
        self.mistakes = tracker.mistakes
        self.points = tracker.points
        self.stars = tracker.sessionStars
    }
}

/// Summary of a finished Family Challenge.
nonisolated struct TVFamilyChallengeOutcome: Hashable {
    let challengeID: String
    let category: TVCategory
    /// Correct answers by each participating player.
    let scores: [UUID: Int]
    let familyStars: Int
}
