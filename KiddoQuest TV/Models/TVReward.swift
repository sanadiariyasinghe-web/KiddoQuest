import Foundation

/// Badges a player can earn.
nonisolated enum TVRewardKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case numberExplorer
    case letterExplorer
    case shapeMaster
    case animalFriend
    case familyLearner

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .numberExplorer: return "🏆"
        case .letterExplorer: return "🔤"
        case .shapeMaster: return "🔷"
        case .animalFriend: return "🦁"
        case .familyLearner: return "🌟"
        }
    }

    var title: String {
        switch self {
        case .numberExplorer: return "Number Explorer"
        case .letterExplorer: return "Letter Explorer"
        case .shapeMaster: return "Shape Master"
        case .animalFriend: return "Animal Friend"
        case .familyLearner: return "Family Learner"
        }
    }

    /// The category whose stars unlock this badge, if any.
    var category: TVCategory? {
        switch self {
        case .numberExplorer: return .numbers
        case .letterExplorer: return .letters
        case .shapeMaster: return .shapes
        case .animalFriend: return .animals
        case .familyLearner: return nil
        }
    }

    var requirement: String {
        if let category {
            return "Collect \(TVRewardRules.starsPerCategoryBadge) \(category.title) stars"
        }
        return "Finish a Family Challenge"
    }
}

/// Stickers for the sticker book. Every finished game gives one, preferring
/// stickers the player doesn't have yet (the same set as the iOS app).
nonisolated enum TVStickerRules {
    static let allStickers = [
        "🦁", "🐼", "🦄", "🌈", "⭐", "🐬", "🦋", "🍓",
        "🚀", "🌻", "🐢", "🎈", "🐙", "🍦", "🦖", "🐝"
    ]

    static func nextSticker(collected: Set<String>, pool: [String] = allStickers) -> String {
        let missing = pool.filter { !collected.contains($0) }
        return (missing.isEmpty ? pool : missing).randomElement() ?? "⭐"
    }
}

/// Rules that decide which badges a player has earned.
nonisolated enum TVRewardRules {
    static let starsPerCategoryBadge = 10

    static func isEarned(_ reward: TVRewardKind, by player: TVPlayer) -> Bool {
        if let category = reward.category {
            return player.progress.progress(for: category).stars >= starsPerCategoryBadge
        }
        return player.familyChallengesPlayed >= 1
    }

    static func earnedRewards(for player: TVPlayer) -> Set<TVRewardKind> {
        Set(TVRewardKind.allCases.filter { isEarned($0, by: player) })
    }

    /// Badges earned now that were not recorded on the player before, in display order.
    static func newRewards(for player: TVPlayer) -> [TVRewardKind] {
        let earned = earnedRewards(for: player)
        return TVRewardKind.allCases.filter { earned.contains($0) && !player.earnedRewards.contains($0) }
    }

    /// Stars still needed for a category badge (0 once earned).
    static func starsRemaining(for reward: TVRewardKind, player: TVPlayer) -> Int {
        guard let category = reward.category else { return 0 }
        return max(0, starsPerCategoryBadge - player.progress.progress(for: category).stars)
    }
}
