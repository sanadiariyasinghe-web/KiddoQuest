import Foundation

/// Presentation logic for the Results / Rewards screen.
struct TVRewardsViewModel {
    struct Badge: Identifiable, Hashable {
        let kind: TVRewardKind
        let isEarned: Bool
        let isNew: Bool
        let progressText: String

        var id: TVRewardKind { kind }

        var accessibilityLabel: String {
            if isNew { return "\(kind.title) badge, new! Just earned." }
            if isEarned { return "\(kind.title) badge, earned." }
            return "\(kind.title) badge, locked. \(progressText)."
        }
    }

    let player: TVPlayer?
    let result: TVSessionResult?
    let familyStars: Int

    var totalStars: Int { player?.totalStars ?? 0 }

    var playerName: String { player?.name ?? "Friend" }

    var headline: String {
        guard result != nil else { return "\(playerName)'s Rewards" }
        return "Great job, \(playerName)!"
    }

    var sessionStars: Int { result?.stars ?? 0 }

    var newRewards: [TVRewardKind] { result?.newRewards ?? [] }

    var badges: [Badge] {
        TVRewardKind.allCases.map { kind in
            let earned = player.map { $0.earnedRewards.contains(kind) || TVRewardRules.isEarned(kind, by: $0) } ?? false
            return Badge(
                kind: kind,
                isEarned: earned,
                isNew: newRewards.contains(kind),
                progressText: progressText(for: kind, earned: earned)
            )
        }
    }

    var earnedBadgeCount: Int { badges.filter(\.isEarned).count }

    private func progressText(for kind: TVRewardKind, earned: Bool) -> String {
        if earned { return "Earned!" }
        guard let player else { return kind.requirement }
        let remaining = TVRewardRules.starsRemaining(for: kind, player: player)
        if kind.category != nil, remaining > 0 {
            return "\(remaining) more \(remaining == 1 ? "star" : "stars") to go"
        }
        return kind.requirement
    }
}
