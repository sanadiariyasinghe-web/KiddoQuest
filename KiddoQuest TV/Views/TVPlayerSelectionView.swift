import SwiftUI

/// "Who's Playing?" — pick or switch the active family member.
struct TVPlayerSelectionView: View {
    let mode: TVPlayerSelectionMode

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    @FocusState private var focusedPlayerID: UUID?
    @State private var hasAppeared = false

    private var model: TVPlayerSelectionViewModel {
        TVPlayerSelectionViewModel(players: store.players, selectedPlayerID: store.selectedPlayerID, mode: mode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TVTheme.Metrics.sectionSpacing) {
            TVScreenHeader(title: "Who's Playing?", subtitle: model.subtitle, icon: "👨‍👩‍👧‍👦") {
                TVMascotView(mood: .happy, message: "Pick your player!", size: 150)
            }

            if model.cards.isEmpty {
                Text("No players yet. Ask a grown-up to load the demo family in Settings.")
                    .font(TVTheme.Typography.body)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }

            HStack(spacing: 60) {
                ForEach(Array(model.cards.enumerated()), id: \.element.id) { index, card in
                    TVPlayerCard(card: card) {
                        choose(card.player)
                    }
                    .focused($focusedPlayerID, equals: card.id)
                    .offset(y: hasAppeared ? 0 : 80)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(TVTheme.Motion.entrance.delay(Double(index) * 0.08), value: hasAppeared)
                }
            }
            .frame(maxWidth: .infinity)
            .focusSection()

            Spacer(minLength: 0)
        }
        .padding(TVTheme.Metrics.screenPadding)
        .tvScreenBackground()
        .defaultFocus($focusedPlayerID, model.initialFocusID)
        .onAppear { hasAppeared = true }
    }

    private func choose(_ player: TVPlayer) {
        sound.play(.select)
        store.selectPlayer(player.id)
        switch mode {
        case .startPlaying:
            router.push(.world)
        case .switchPlayer:
            router.pop()
        }
    }
}
