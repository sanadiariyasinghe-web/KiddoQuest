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
    /// Choices for the daily play-time limit, in minutes (0 = no limit).
    static let dailyLimitChoices = [0, 15, 20, 30]

    var soundEnabled = true
    var musicEnabled = false
    /// Calm Mode: no confetti and no ambient motion.
    var calmMode = false
    /// Daily play-time limit in minutes; 0 means no limit.
    var dailyLimitMinutes = 0

    init(soundEnabled: Bool = true, musicEnabled: Bool = false, calmMode: Bool = false, dailyLimitMinutes: Int = 0) {
        self.soundEnabled = soundEnabled
        self.musicEnabled = musicEnabled
        self.calmMode = calmMode
        self.dailyLimitMinutes = dailyLimitMinutes
    }

    /// Decodes saved settings, including ones saved before Calm Mode and the time limit existed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        musicEnabled = try container.decodeIfPresent(Bool.self, forKey: .musicEnabled) ?? false
        calmMode = try container.decodeIfPresent(Bool.self, forKey: .calmMode) ?? false
        dailyLimitMinutes = try container.decodeIfPresent(Int.self, forKey: .dailyLimitMinutes) ?? 0
    }

    /// The next limit when the parent presses the setting: No limit → 15 → 20 → 30 → No limit.
    var nextDailyLimit: Int {
        let choices = Self.dailyLimitChoices
        let index = choices.firstIndex(of: dailyLimitMinutes) ?? 0
        return choices[(index + 1) % choices.count]
    }

    var dailyLimitLabel: String {
        dailyLimitMinutes == 0 ? "No limit" : "\(dailyLimitMinutes) min"
    }
}
