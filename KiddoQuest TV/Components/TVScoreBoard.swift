import SwiftUI

/// Family Challenge scoreboard: each player's points, whose turn it is,
/// and the shared family star goal.
struct TVScoreBoard: View {
    struct Entry: Identifiable, Hashable {
        let player: TVPlayer
        let score: Int
        let isCurrentTurn: Bool
        var id: UUID { player.id }
    }

    let entries: [Entry]
    let familyStars: Int
    let goal: Int
    let challengesCompleted: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("SCOREBOARD")
                .font(TVTheme.Typography.caption)
                .foregroundStyle(TVTheme.Palette.textSecondary)

            ForEach(entries) { entry in
                HStack(spacing: 20) {
                    TVAvatarView(player: entry.player, size: 76)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(entry.player.name.uppercased())
                            .font(TVTheme.Typography.body)
                        Text("\(entry.score) \(entry.score == 1 ? "point" : "points")")
                            .font(TVTheme.Typography.caption)
                            .foregroundStyle(TVTheme.Palette.textSecondary)
                            .contentTransition(.numericText(value: Double(entry.score)))
                    }
                    Spacer()
                    if entry.isCurrentTurn {
                        Label("TURN", systemImage: "gamecontroller.fill")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .fixedSize()
                            .foregroundStyle(TVTheme.Palette.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(entry.player.color.color))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(entry.isCurrentTurn ? entry.player.color.color.opacity(0.25) : TVTheme.Palette.subtle)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(entry.isCurrentTurn ? entry.player.color.color : .clear, lineWidth: 4)
                )
                .animation(TVTheme.Motion.gentle, value: entry.isCurrentTurn)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(entry.player.name), \(entry.score) points\(entry.isCurrentTurn ? ", current turn" : "")")
            }

            Divider().overlay(TVTheme.Palette.cardStroke)

            VStack(alignment: .leading, spacing: 14) {
                Text("FAMILY SCORE")
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
                TVStarRowView(count: familyStars, slots: goal, size: 44)
                    .animation(TVTheme.Motion.pop, value: familyStars)
                Text("\(familyStars) of \(goal) family stars")
                    .font(TVTheme.Typography.caption)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Family score: \(familyStars) of \(goal) stars")
            .accessibilityIdentifier("familyChallenge.familyScore")

            Label("Family challenges completed: \(challengesCompleted)", systemImage: "trophy.fill")
                .font(TVTheme.Typography.caption)
                .foregroundStyle(TVTheme.Palette.textSecondary)
        }
        .padding(34)
        .frame(width: 560)
        .background(
            RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner, style: .continuous)
                .fill(TVTheme.Palette.card)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
    }
}
