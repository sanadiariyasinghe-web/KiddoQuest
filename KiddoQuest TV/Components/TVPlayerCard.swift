import SwiftUI

/// Round avatar used for players everywhere in the app.
struct TVAvatarView: View {
    let player: TVPlayer
    var size: CGFloat = 180

    var body: some View {
        Text(player.avatar)
            .font(.system(size: size * 0.58))
            .frame(width: size, height: size)
            .background(Circle().fill(player.color.color.gradient))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: max(3, size * 0.03)))
            .accessibilityHidden(true)
    }
}

/// "Who's Playing?" profile card.
struct TVPlayerCard: View {
    let card: TVPlayerSelectionViewModel.Card
    let action: () -> Void

    private var player: TVPlayer { card.player }

    var body: some View {
        TVFocusCard(tint: player.color.color, action: action) {
            VStack(spacing: 22) {
                TVAvatarView(player: player, size: 200)

                Text(player.name.uppercased())
                    .font(TVTheme.Typography.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                TVStarRatingView(rating: player.rating, size: 34)

                Text(card.highlight)
                    .font(TVTheme.Typography.body)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                activeBadge
            }
            .padding(36)
            .frame(width: 420, height: 580)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.accessibilityLabel)
        .accessibilityHint("Selects this player")
        .accessibilityAddTraits(card.isActive ? .isSelected : [])
        .accessibilityIdentifier("player.\(player.name)")
    }

    @ViewBuilder
    private var activeBadge: some View {
        if card.isActive {
            Label("PLAYING NOW", systemImage: "checkmark.circle.fill")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(TVTheme.Palette.ink)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Capsule().fill(TVTheme.Palette.success))
        } else {
            // Reserve the same height so cards stay aligned.
            Text(" ")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .padding(.vertical, 8)
                .accessibilityHidden(true)
        }
    }
}

/// Small focusable "who is playing" chip for screen headers.
struct TVPlayerChip: View {
    let player: TVPlayer
    var action: (() -> Void)?

    var body: some View {
        TVFocusCard(tint: player.color.color, cornerRadius: 50, focusScale: 1.06, action: action) {
            HStack(spacing: 18) {
                TVAvatarView(player: player, size: 72)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(TVTheme.Typography.body)
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill").foregroundStyle(TVTheme.Palette.star)
                        Text("\(player.totalStars)")
                    }
                    .font(TVTheme.Typography.caption)
                }
                if action != nil {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.leading, 6)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 12)
            .padding(.leading, 14)
            .padding(.trailing, 30)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name) is playing, \(player.totalStars) stars")
        .accessibilityHint(action == nil ? "" : "Switch player")
        .accessibilityIdentifier("header.playerChip")
    }
}
