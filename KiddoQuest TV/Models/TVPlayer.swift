import SwiftUI

nonisolated enum TVPlayerRole: String, Codable, Hashable {
    case child
    case parent
}

/// Avatar colours offered to profiles. Each one is paired with an emoji
/// avatar so players are never identified by colour alone.
nonisolated enum TVPlayerColor: String, Codable, Hashable, CaseIterable {
    case coral, sky, mint, sunshine, lavender

    var color: Color {
        switch self {
        case .coral: return TVTheme.Palette.familyCoral
        case .sky: return TVTheme.Palette.lettersBlue
        case .mint: return TVTheme.Palette.animalsGreen
        case .sunshine: return TVTheme.Palette.numbersYellow
        case .lavender: return TVTheme.Palette.shapesPurple
        }
    }
}

/// A local, on-device family member profile. No accounts are involved.
nonisolated struct TVPlayer: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var avatar: String
    var color: TVPlayerColor
    var role: TVPlayerRole
    var points: Int = 0
    var familyChallengesPlayed: Int = 0
    var progress = TVGameProgress()
    var earnedRewards: Set<TVRewardKind> = []
    /// Stickers collected in this player's sticker book (one per finished game).
    var stickers: [String] = []

    init(
        id: UUID = UUID(),
        name: String,
        avatar: String,
        color: TVPlayerColor,
        role: TVPlayerRole = .child,
        points: Int = 0,
        familyChallengesPlayed: Int = 0,
        progress: TVGameProgress = TVGameProgress(),
        earnedRewards: Set<TVRewardKind> = [],
        stickers: [String] = []
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.color = color
        self.role = role
        self.points = points
        self.familyChallengesPlayed = familyChallengesPlayed
        self.progress = progress
        self.earnedRewards = earnedRewards
        self.stickers = stickers
    }

    /// Decodes saved profiles, including ones saved before stickers existed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decode(String.self, forKey: .avatar)
        color = try container.decode(TVPlayerColor.self, forKey: .color)
        role = try container.decode(TVPlayerRole.self, forKey: .role)
        points = try container.decodeIfPresent(Int.self, forKey: .points) ?? 0
        familyChallengesPlayed = try container.decodeIfPresent(Int.self, forKey: .familyChallengesPlayed) ?? 0
        progress = try container.decodeIfPresent(TVGameProgress.self, forKey: .progress) ?? TVGameProgress()
        earnedRewards = try container.decodeIfPresent(Set<TVRewardKind>.self, forKey: .earnedRewards) ?? []
        stickers = try container.decodeIfPresent([String].self, forKey: .stickers) ?? []
    }

    var totalStars: Int { progress.totalStars }

    var isParent: Bool { role == .parent }

    /// Overall 0–5 star rating used on player cards.
    var rating: Int { TVScoring.rating(forPercent: progress.overallPercent) }

    /// The same profile with all learning progress cleared.
    func resettingProgress() -> TVPlayer {
        TVPlayer(id: id, name: name, avatar: avatar, color: color, role: role)
    }
}
