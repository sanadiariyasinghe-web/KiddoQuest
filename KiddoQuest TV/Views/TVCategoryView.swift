import SwiftUI

/// A single learning world: progress summary and the games inside it.
struct TVCategoryView: View {
    let category: TVCategory

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    var body: some View {
        let player = store.activePlayer
        let progress = player?.progress.progress(for: category) ?? TVCategoryProgress()
        let percent = player?.progress.percent(for: category) ?? 0
        let games = TVGameDataService.games(in: category)

        HStack(alignment: .top, spacing: 70) {
            // Summary panel (informational, not focusable).
            VStack(alignment: .leading, spacing: 30) {
                Text(category.emoji)
                    .font(.system(size: 150))
                    .frame(width: 260, height: 260)
                    .background(Circle().fill(category.color.opacity(0.25)))
                    .accessibilityHidden(true)

                Text(category.islandTitle)
                    .font(TVTheme.Typography.screenTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("categoryView.title")
                Text(category.tagline)
                    .font(TVTheme.Typography.body)
                    .foregroundStyle(TVTheme.Palette.textSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    TVProgressBar(value: Double(percent) / 100, tint: category.color, height: 26)
                    Text("\(percent)% COMPLETE")
                        .font(TVTheme.Typography.headline)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(percent) percent complete")

                TVStarRatingView(rating: TVScoring.rating(forPercent: percent), size: 42)

                HStack(spacing: 30) {
                    statTile(value: "\(progress.stars)", label: "Stars", symbol: "star.fill")
                    statTile(value: "\(progress.gamesPlayed)", label: "Games", symbol: "gamecontroller.fill")
                }
            }
            .frame(width: 600, alignment: .leading)

            // Scrolls automatically as focus moves down through the games.
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 34) {
                    Text("Pick a game")
                        .font(TVTheme.Typography.title)

                    // At most three games per world, laid out two per row.
                    VStack(alignment: .leading, spacing: 50) {
                        ForEach(Array(stride(from: 0, to: games.count, by: 2)), id: \.self) { start in
                            HStack(spacing: 50) {
                                ForEach(games[start..<min(start + 2, games.count)]) { game in
                                    TVGameCard(
                                        game: game,
                                        tint: category.color,
                                        hasPlayed: player?.progress.completedGames.contains(game.kind) ?? false
                                    ) {
                                        sound.play(.select)
                                        router.push(.game(game.kind, category))
                                    }
                                }
                            }
                        }
                    }
                    .focusSection()

                    TVPrimaryButton(
                        title: "See all 6 games",
                        systemImage: "square.grid.2x2.fill",
                        tint: category.color,
                        prominence: .card,
                        minWidth: 480
                    ) {
                        router.push(.gameLibrary(category))
                    }
                    .accessibilityIdentifier("categoryView.allGames")
                }
                .padding(30)
            }
            .scrollClipDisabled()
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tvScreenBackground()
    }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(category.color)
            Text(value).font(TVTheme.Typography.title)
            Text(label).font(TVTheme.Typography.caption).foregroundStyle(TVTheme.Palette.textSecondary)
        }
        .frame(width: 220, height: 190)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(TVTheme.Palette.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}
