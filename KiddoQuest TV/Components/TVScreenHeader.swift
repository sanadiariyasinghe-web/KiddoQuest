import SwiftUI

/// Consistent title row for every screen.
struct TVScreenHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var icon: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 30) {
            if let icon {
                Text(icon)
                    .font(.system(size: 84))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(TVTheme.Typography.screenTitle)
                    .foregroundStyle(TVTheme.Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(TVTheme.Typography.body)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 20)
            trailing()
        }
    }
}

extension TVScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.init(title: title, subtitle: subtitle, icon: icon) { EmptyView() }
    }
}

/// Header strip shown above every game: title, round, score and player.
struct TVGameHeader: View {
    let title: String
    let roundLabel: String
    let points: Int
    let starsThisGame: Int
    let player: TVPlayer?
    var isPrototype = false

    var body: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 18) {
                    Text(title)
                        .font(TVTheme.Typography.title)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                    if isPrototype {
                        Label("PROTOTYPE", systemImage: "hammer.fill")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(TVTheme.Palette.subtle))
                            .accessibilityIdentifier("game.prototypeBadge")
                    }
                }
                Text(roundLabel)
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }
            Spacer()
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                Text("\(points)")
                    .contentTransition(.numericText(value: Double(points)))
                Text("pts").opacity(0.75)
            }
            .font(TVTheme.Typography.headline)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Capsule().fill(TVTheme.Palette.card).shadow(color: .black.opacity(0.08), radius: 8, y: 4))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Score \(points) points")
            .accessibilityIdentifier("game.score")

            TVStarCounterView(count: starsThisGame, size: 40)
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .background(Capsule().fill(TVTheme.Palette.card).shadow(color: .black.opacity(0.08), radius: 8, y: 4))

            if let player {
                HStack(spacing: 14) {
                    TVAvatarView(player: player, size: 64)
                    Text(player.name)
                        .font(TVTheme.Typography.body)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(player.name) is playing")
            }
        }
        .foregroundStyle(TVTheme.Palette.textPrimary)
        .animation(TVTheme.Motion.pop, value: points)
    }
}

/// Friendly fallback when content is missing or navigation lands somewhere unexpected.
struct TVEmptyStateView: View {
    let title: String
    let message: String
    var buttonTitle = "Go Back"
    let action: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            TVMascotView(mood: .tryAgain, message: title, size: 240)
            Text(message)
                .font(TVTheme.Typography.body)
                .foregroundStyle(TVTheme.Palette.textSecondary)
                .multilineTextAlignment(.center)
            TVPrimaryButton(title: buttonTitle, systemImage: "arrow.uturn.backward", minWidth: 420, action: action)
                .accessibilityIdentifier("emptyState.back")
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tvScreenBackground()
    }
}
