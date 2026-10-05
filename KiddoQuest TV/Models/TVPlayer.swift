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

    init(
        id: UUID = UUID(),
        name: String,
        avatar: String,
        color: TVPlayerColor,
        role: TVPlayerRole = .child,
        points: Int = 0,
        familyChallengesPlayed: Int = 0,
        progress: TVGameProgress = TVGameProgress(),
        earnedRewards: Set<TVRewardKind> = []
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
