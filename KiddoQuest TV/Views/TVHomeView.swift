import SwiftUI

/// Welcome screen: brand, Buddy and the four main actions.
struct TVHomeView: View {
    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router

    private enum Focus: Hashable {
        case play, continueJourney, familyProgress, settings
    }

    @FocusState private var focus: Focus?
    @State private var buddyMessageIndex = 0
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var model: TVHomeViewModel {
        TVHomeViewModel(
            activePlayer: store.activePlayer,
            hasSelectedPlayer: store.selectedPlayer != nil,
            lastPlayedCategory: store.lastPlayedCategory
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 80) {
            VStack(alignment: .leading, spacing: 34) {
                title

                VStack(alignment: .leading, spacing: 26) {
                    TVPrimaryButton(
                        title: "PLAY",
                        subtitle: model.playSubtitle,
                        systemImage: "play.fill",
                        tint: TVTheme.Palette.numbersYellow
                    ) {
                        router.push(.playerSelection(.startPlaying))
                    }
                    .focused($focus, equals: .play)
                    .accessibilityIdentifier("home.play")

                    TVPrimaryButton(
                        title: "CONTINUE",
                        subtitle: model.continueSubtitle,
                        systemImage: "arrow.forward.circle.fill",
                        tint: TVTheme.Palette.animalsGreen
                    ) {
                        router.continueJourney(hasPlayer: store.selectedPlayer != nil, lastCategory: store.lastPlayedCategory)
                    }
                    .focused($focus, equals: .continueJourney)
                    .accessibilityIdentifier("home.continue")

                    TVPrimaryButton(
                        title: "FAMILY PROGRESS",
                        systemImage: "chart.bar.fill",
                        tint: TVTheme.Palette.familyCoral
                    ) {
                        router.push(.familyProgress)
                    }
                    .focused($focus, equals: .familyProgress)
                    .accessibilityIdentifier("home.familyProgress")

                    TVPrimaryButton(
                        title: "SETTINGS",
                        systemImage: "gearshape.fill",
                        tint: TVTheme.Palette.lettersBlue,
                        prominence: .card
                    ) {
                        router.push(.settings)
                    }
                    .focused($focus, equals: .settings)
                    .accessibilityIdentifier("home.settings")
                }
                .focusSection()
            }
            .offset(x: hasAppeared || reduceMotion ? 0 : -60)
            .opacity(hasAppeared || reduceMotion ? 1 : 0)

            Spacer(minLength: 0)

            VStack(spacing: 30) {
                TVMascotView(
                    mood: buddyMessageIndex.isMultiple(of: 2) ? .idle : .happy,
                    message: TVHomeViewModel.buddyMessage(at: buddyMessageIndex),
                    size: 360
                )
                Text(model.welcomeLine)
                    .font(TVTheme.Typography.headline)
                    .foregroundStyle(TVTheme.Palette.textPrimary)
                    .accessibilityIdentifier("home.welcome")
            }
            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.85)
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tvScreenBackground(animated: true)
        .defaultFocus($focus, .play)
        .onAppear {
            withAnimation(TVTheme.Motion.entrance) { hasAppeared = true }
        }
        .task {
            // Buddy alternates his greeting every few seconds while Home is visible.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                buddyMessageIndex += 1
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 10) {
            // One Text with coloured runs so the wordmark never truncates piecewise.
            Text("\(Text("KIDDOQUEST").foregroundStyle(TVTheme.Palette.textPrimary))\(Text(" TV").foregroundStyle(TVTheme.Palette.lettersBlue))")
            .font(TVTheme.Typography.hero)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("KiddoQuest TV")
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("home.title")

            Text("Learn Together. Play Together.")
                .font(TVTheme.Typography.title)
                .foregroundStyle(TVTheme.Palette.textSecondary)
        }
    }
}
