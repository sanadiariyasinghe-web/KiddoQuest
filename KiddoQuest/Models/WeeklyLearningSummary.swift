import Foundation

// MARK: - Weekly Learning Summary
// Builds the parent's "What my child learned this week" list from saved game progress.

struct LearnedSkill: Identifiable, Equatable {
    var id: String { gameID }
    let gameID: String
    let skill: String
    let stars: Int
    let lastPlayed: Date
}

enum WeeklyLearningSummary {
    /// The plain-language skill each game practises.
    static func skill(forGameID gameID: String) -> String? {
        switch gameID {
        case "num_1": return "Counting objects"
        case "num_2": return "Matching numbers to groups"
        case "let_1": return "Big and small letters"
        case "let_2": return "Finding letters"
        case "shp_1": return "Colours and shapes"
        case "shp_2": return "Sorting shapes"
        case "shp_3": return "Finding colours and things at home"
        case "ani_1": return "What animals eat"
        case "ani_2": return "Recognising animals by their shape"
        default: return nil
        }
    }

    /// Skills from games finished in the 7 days up to `now`, most recent first.
    static func skillsLearned(
        progress: [String: GameProgress],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [LearnedSkill] {
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
        return progress.values
            .filter { $0.completed && $0.lastPlayed >= weekStart && $0.lastPlayed <= now }
            .compactMap { item in
                skill(forGameID: item.gameID).map {
                    LearnedSkill(gameID: item.gameID, skill: $0, stars: item.stars, lastPlayed: item.lastPlayed)
                }
            }
            .sorted { $0.lastPlayed > $1.lastPlayed }
    }
}
