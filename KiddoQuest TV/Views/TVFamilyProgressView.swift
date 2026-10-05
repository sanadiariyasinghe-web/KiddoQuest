import SwiftUI

/// Parent-friendly dashboard for the whole household, readable from the sofa.
struct TVFamilyProgressView: View {
    @Environment(TVAppStore.self) private var store

    private var model: TVFamilyProgressViewModel {
        TVFamilyProgressViewModel(players: store.players, family: store.family)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 46) {
                TVScreenHeader(title: "Family Progress", subtitle: "How everyone is learning together", icon: "📊")

                HStack(spacing: 30) {
                    summaryTile(symbol: "star.fill", value: "\(model.family.familyStars)", label: "Family Stars", tint: TVTheme.Palette.star)
                    summaryTile(symbol: "person.3.fill", value: "\(model.family.challengesCompleted)", label: "Challenges Won", tint: TVTheme.Palette.familyCoral)
                    summaryTile(symbol: "gamecontroller.fill", value: "\(model.totalGames)", label: "Games Played", tint: TVTheme.Palette.lettersBlue)
                    summaryTile(symbol: "flame.fill", value: model.mostPlayedText, label: "Most Played", tint: TVTheme.Palette.animalsGreen)
                }
                .accessibilityIdentifier("familyProgress.summary")

                HStack(alignment: .top, spacing: 40) {
                    ForEach(model.summaries) { summary in
                        playerPanel(summary)
                    }
                }
                .focusSection()
            }
            .padding(TVTheme.Metrics.screenPadding)
        }
        .scrollClipDisabled()
        .tvScreenBackground()
    }

    private func summaryTile(symbol: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(TVTheme.Typography.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 400, height: 150)
        .background(RoundedRectangle(cornerRadius: 34, style: .continuous).fill(TVTheme.Palette.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private func playerPanel(_ summary: TVFamilyProgressViewModel.PlayerSummary) -> some View {
        TVFocusCard(tint: summary.player.color.color, focusScale: 1.04) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 20) {
                    TVAvatarView(player: summary.player, size: 100)
                    Text(summary.player.name.uppercased())
                        .font(TVTheme.Typography.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                ForEach(TVCategory.allCases) { category in
                    let percent = summary.percent(for: category)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(category.emoji) \(category.title)")
                            Spacer()
                            Text("\(percent)%")
                        }
                        .font(TVTheme.Typography.body)
                        TVProgressBar(value: Double(percent) / 100, tint: category.color, height: 16)
                    }
                }

                Divider().overlay(TVTheme.Palette.cardStroke)

                HStack(spacing: 24) {
                    stat(value: summary.totalGames, label: "Games")
                    stat(value: summary.totalStars, label: "Stars")
                    stat(value: summary.categoriesCompleted, label: "Mastered")
                }
                Text("Mastered = \(TVGameProgress.completionThreshold)%+ in a category")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }
            .padding(36)
            .frame(width: 520, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary.accessibilityLabel)
        .accessibilityIdentifier("familyProgress.player.\(summary.player.name)")
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(TVTheme.Typography.title)
            Text(label)
                .font(TVTheme.Typography.caption)
                .foregroundStyle(TVTheme.Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}
