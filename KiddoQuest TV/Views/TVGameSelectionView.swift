import SwiftUI

/// The full game library showing all seven KiddoQuest games.
struct TVGameSelectionView: View {
    let initialFilter: TVCategory?

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    @State private var filter: TVCategory?
    @State private var hasLoadedFilter = false

    private var games: [TVGame] { TVGameDataService.games(in: filter) }

    /// Games split into rows of three.
    private var rows: [[TVGame]] {
        stride(from: 0, to: games.count, by: 3).map { Array(games[$0..<min($0 + 3, games.count)]) }
    }

    var body: some View {
        let player = store.activePlayer
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 40) {
                TVScreenHeader(
                    title: "Game Library",
                    subtitle: "7 games to play with the remote. Family Challenge lives in the Learning World.",
                    icon: "🎮"
                )

                HStack(spacing: 24) {
                    filterChip(title: "All", tint: TVTheme.Palette.lettersBlue, isSelected: filter == nil) { filter = nil }
                        .accessibilityIdentifier("library.filter.all")
                    ForEach(TVCategory.allCases) { category in
                        filterChip(title: category.title, tint: category.color, isSelected: filter == category) {
                            filter = category
                        }
                        .accessibilityIdentifier("library.filter.\(category.rawValue)")
                    }
                }
                .focusSection()

                // Only seven cards, so build them eagerly; every card then exists for
                // the focus engine, VoiceOver and UI tests even before scrolling.
                VStack(alignment: .leading, spacing: 50) {
                    ForEach(rows, id: \.first?.kind) { row in
                        HStack(spacing: 50) {
                            ForEach(row) { game in
                                TVGameCard(
                                    game: game,
                                    hasPlayed: player?.progress.completedGames.contains(game.kind) ?? false
                                ) {
                                    sound.play(.select)
                                    router.push(.game(game.kind, game.launchCategory(preferred: filter)))
                                }
                            }
                        }
                    }
                }
                .focusSection()
            }
            .padding(TVTheme.Metrics.screenPadding)
        }
        .scrollClipDisabled()
        .tvScreenBackground()
        .onAppear {
            guard !hasLoadedFilter else { return }
            filter = initialFilter
            hasLoadedFilter = true
        }
    }

    private func filterChip(title: String, tint: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            sound.play(.select)
            withAnimation(TVTheme.Motion.gentle) { action() }
        } label: {
            HStack(spacing: 12) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .heavy))
                }
                Text(title)
                    .font(TVTheme.Typography.body)
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 18)
        }
        .tvCardButtonStyle(
            tint: tint,
            prominence: isSelected ? .filled : .card,
            cornerRadius: 40,
            focusScale: 1.08
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
