import SwiftUI

/// Results / Rewards screen.
///
/// With a `result` it is the post-game Results screen (session stars,
/// newly earned badges and next actions). Without one it is the player's
/// rewards cabinet. Both show total stars and all five badges.
struct TVRewardView: View {
    let result: TVSessionResult?

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router

    private enum Focus: Hashable {
        case playAgain
        case badge(TVRewardKind)
    }
    @FocusState private var focus: Focus?
    @State private var celebrationTrigger = 0

    private var player: TVPlayer? {
        result?.playerID.flatMap(store.player(withID:)) ?? store.activePlayer
    }

    private var model: TVRewardsViewModel {
        TVRewardsViewModel(player: player, result: result, familyStars: store.family.familyStars)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 50) {
                if let result {
                    sessionSummary(result)
                } else {
                    TVScreenHeader(title: model.headline, subtitle: "Collect stars to unlock every badge!", icon: "🏆")
                }

                totalStars

                VStack(alignment: .leading, spacing: 24) {
                    Text("BADGES · \(model.earnedBadgeCount) of \(TVRewardKind.allCases.count)")
                        .font(TVTheme.Typography.headline)
                    HStack(spacing: 36) {
                        ForEach(model.badges) { badge in
                            TVRewardCard(badge: badge)
                                .focused($focus, equals: .badge(badge.kind))
                        }
                    }
                    .focusSection()
                }
            }
            .padding(TVTheme.Metrics.screenPadding)
        }
        .scrollClipDisabled()
        .tvScreenBackground(animated: result != nil)
        .defaultFocus($focus, result == nil ? .badge(TVRewardKind.allCases.first ?? .numberExplorer) : .playAgain)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            celebrationTrigger += 1
        }
    }

    // MARK: - Results

    private func sessionSummary(_ result: TVSessionResult) -> some View {
        VStack(spacing: 34) {
            HStack(spacing: 50) {
                TVMascotView(mood: .correct, message: result.newRewards.isEmpty ? "Awesome!" : "New badge!", size: 200)
                VStack(alignment: .leading, spacing: 12) {
                    Text(model.headline)
                        .font(TVTheme.Typography.hero)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("results.headline")
                    Text("\(TVGameDataService.game(for: result.gameKind)?.title ?? "Game") · \(result.category.title)")
                        .font(TVTheme.Typography.title)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                    HStack(spacing: 40) {
                        Label("\(result.points) points", systemImage: "sparkles")
                        Label("\(result.correctAnswers) correct", systemImage: "checkmark.circle.fill")
                    }
                    .font(TVTheme.Typography.headline)
                }
                Spacer(minLength: 0)
            }

            ZStack {
                TVStarRowView(count: result.stars, slots: TVScoring.maxSessionStars, size: 110, animationTrigger: celebrationTrigger)
                TVSparkleBurst(trigger: celebrationTrigger, distance: 380)
            }
            .accessibilityIdentifier("results.sessionStars")

            HStack(spacing: 40) {
                TVPrimaryButton(title: "Play Again", systemImage: "arrow.clockwise", tint: TVTheme.Palette.numbersYellow, minWidth: 400) {
                    router.replaceTop(with: .game(result.gameKind, result.category))
                }
                .focused($focus, equals: .playAgain)
                .accessibilityIdentifier("results.playAgain")

                TVPrimaryButton(title: "More Games", systemImage: "square.grid.2x2.fill", tint: TVTheme.Palette.animalsGreen, minWidth: 400) {
                    router.pop()
                }
                .accessibilityIdentifier("results.moreGames")

                TVPrimaryButton(title: "Home", systemImage: "house.fill", tint: TVTheme.Palette.lettersBlue, prominence: .card, minWidth: 320) {
                    router.popToRoot()
                }
                .accessibilityIdentifier("results.home")
            }
            .focusSection()
        }
    }

    private var totalStars: some View {
        VStack(spacing: 16) {
            Text("TOTAL STARS")
                .font(TVTheme.Typography.headline)
                .foregroundStyle(TVTheme.Palette.textSecondary)
            TVStarRowView(count: model.totalStars, maxVisible: 10, size: 64)
            Text("Family jar: \(model.familyStars) stars")
                .font(TVTheme.Typography.caption)
                .foregroundStyle(TVTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total stars: \(model.totalStars). Family stars: \(model.familyStars).")
        .accessibilityIdentifier("rewards.totalStars")
    }
}
