import SwiftUI

/// The Learning World hub: four category worlds plus family features.
struct TVWorldView: View {
    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    @FocusState private var focusedCategory: TVCategory?

    var body: some View {
        let player = store.activePlayer
        VStack(alignment: .leading, spacing: 44) {
            TVScreenHeader(
                title: "Learning World",
                subtitle: "Hi \(player?.name ?? "friend")! Pick a world to explore.",
                icon: "🌍"
            ) {
                if let player {
                    TVPlayerChip(player: player) {
                        router.push(.playerSelection(.switchPlayer))
                    }
                    .accessibilityIdentifier("world.switchPlayer")
                }
            }
            .focusSection()

            HStack(spacing: 44) {
                ForEach(TVCategory.allCases) { category in
                    TVCategoryCard(
                        category: category,
                        percent: player?.progress.percent(for: category) ?? 0,
                        rating: player?.progress.rating(for: category) ?? 0
                    ) {
                        sound.play(.select)
                        router.push(.category(category))
                    }
                    .focused($focusedCategory, equals: category)
                }
            }
            .frame(maxWidth: .infinity)
            .focusSection()

            HStack(spacing: 44) {
                featureCard(
                    emoji: "👨‍👩‍👧‍👦",
                    title: "Family Challenge",
                    detail: "Take turns, win together!",
                    tint: TVTheme.Palette.familyCoral,
                    identifier: "world.familyChallenge"
                ) { router.push(.familyChallenge) }

                featureCard(
                    emoji: "🎮",
                    title: "Game Library",
                    detail: "All 6 KiddoQuest games",
                    tint: TVTheme.Palette.lettersBlue,
                    identifier: "world.gameLibrary"
                ) { router.push(.gameLibrary(nil)) }

                featureCard(
                    emoji: "🏆",
                    title: "My Rewards",
                    detail: "\(player?.totalStars ?? 0) stars collected",
                    tint: TVTheme.Palette.star,
                    identifier: "world.rewards"
                ) { router.push(.rewards) }
            }
            .frame(maxWidth: .infinity)
            .focusSection()
        }
        .padding(.horizontal, TVTheme.Metrics.screenPadding)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tvScreenBackground()
        .defaultFocus($focusedCategory, store.lastPlayedCategory ?? .numbers)
    }

    private func featureCard(
        emoji: String,
        title: String,
        detail: String,
        tint: Color,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        TVFocusCard(tint: tint, action: {
            sound.play(.select)
            action()
        }) {
            // Same layout as Part A's AR Learning banner.
            HStack(spacing: 24) {
                Text(emoji)
                    .font(.system(size: 58))
                    .frame(width: 100, height: 100)
                    .background(Circle().fill(tint.opacity(0.2)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TVTheme.Typography.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(detail)
                        .font(TVTheme.Typography.caption)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 30)
            .frame(width: 520, height: 150)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(detail)")
        .accessibilityIdentifier(identifier)
    }
}
