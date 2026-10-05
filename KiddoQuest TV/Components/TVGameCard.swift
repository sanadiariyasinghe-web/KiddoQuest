import SwiftUI

/// Focusable game library card. Always shows whether the game is a full
/// game or a prototype so the library never over-promises.
struct TVGameCard: View {
    let game: TVGame
    var tint: Color? = nil
    var hasPlayed = false
    let action: () -> Void

    private var cardTint: Color { tint ?? game.primaryCategory.color }

    var body: some View {
        TVFocusCard(tint: cardTint, action: action) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Text(game.emoji)
                        .font(.system(size: 84))
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(cardTint.opacity(0.35)))
                        .accessibilityHidden(true)
                    Spacer()
                    statusBadge
                }

                Text(game.title)
                    .font(TVTheme.Typography.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(game.summary)
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
                    .lineLimit(3, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    ForEach(game.categories) { category in
                        Text(category.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(TVTheme.Palette.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(category.color))
                    }
                    Spacer(minLength: 0)
                    if hasPlayed {
                        Label("Played", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(TVTheme.Palette.success)
                    }
                }
            }
            .padding(34)
            .frame(width: 520, height: 470, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(game.title). \(game.availability == .playable ? "Full game" : "Prototype"). "
                + "\(game.summary) Categories: \(game.categories.map(\.title).joined(separator: ", "))."
        )
        .accessibilityHint("Starts the game")
        .accessibilityIdentifier("game.\(game.kind.rawValue)")
    }

    private var statusBadge: some View {
        Label(game.availability.label, systemImage: game.availability.symbolName)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(game.availability == .playable ? TVTheme.Palette.ink : TVTheme.Palette.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(game.availability == .playable ? TVTheme.Palette.success : TVTheme.Palette.subtle)
            )
            .overlay(Capsule().strokeBorder(TVTheme.Palette.muted, lineWidth: game.availability == .playable ? 0 : 2))
    }
}
