import Foundation

/// The shared score the whole household builds together.
nonisolated struct TVFamilyScore: Codable, Hashable {
    /// Every star earned by any player also lands in the family jar.
    var familyStars: Int = 0
    var challengesCompleted: Int = 0
    var gamesCompleted: Int = 0

    mutating func addSoloGame(stars: Int) {
        familyStars += max(0, stars)
        gamesCompleted += 1
    }

    mutating func addFamilyChallenge(stars: Int) {
        familyStars += max(0, stars)
        challengesCompleted += 1
        gamesCompleted += 1
    }
}

/// User-controlled preferences.
nonisolated struct TVSettings: Codable, Hashable {
    var soundEnabled = true
    var musicEnabled = false
}
