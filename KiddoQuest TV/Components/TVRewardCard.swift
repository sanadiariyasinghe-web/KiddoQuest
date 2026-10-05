import SwiftUI

/// Badge card. Newly earned badges scale in, sparkle and glow once.
struct TVRewardCard: View {
    let badge: TVRewardsViewModel.Badge

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasCelebrated = false
    @State private var sparkleTrigger = 0

    private var tint: Color { badge.isEarned ? TVTheme.Palette.star : TVTheme.Palette.lettersBlue }

    var body: some View {
        TVFocusCard(tint: tint) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(badge.isEarned ? AnyShapeStyle(TVTheme.Palette.star.gradient) : AnyShapeStyle(TVTheme.Palette.subtle))
                        .frame(width: 150, height: 150)
                        .shadow(color: badge.isNew && hasCelebrated ? TVTheme.Palette.star : .clear, radius: 40)
                    Text(badge.kind.emoji)
                        .font(.system(size: 80))
                        .grayscale(badge.isEarned ? 0 : 1)
                        .opacity(badge.isEarned ? 1 : 0.45)
                    if !badge.isEarned {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(TVTheme.Palette.textPrimary)
                            .offset(x: 52, y: 52)
                    }
                    TVSparkleBurst(trigger: sparkleTrigger, distance: 150)
                }

                Text(badge.kind.title)
                    .font(TVTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)

                Text(badge.isNew ? "NEW!" : badge.progressText)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(badge.isNew ? TVTheme.Palette.ink : TVTheme.Palette.textSecondary)
                    .padding(.horizontal, badge.isNew ? 18 : 0)
                    .padding(.vertical, badge.isNew ? 6 : 0)
                    .background(Capsule().fill(badge.isNew ? TVTheme.Palette.star : .clear))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(26)
            .frame(width: 300, height: 380)
        }
        .scaleEffect(badge.isNew && !hasCelebrated && !reduceMotion ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.accessibilityLabel)
        .accessibilityIdentifier("reward.\(badge.kind.rawValue)")
        .task {
            guard badge.isNew, !hasCelebrated else { return }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(TVTheme.Motion.pop) { hasCelebrated = true }
            sparkleTrigger += 1
        }
    }
}
