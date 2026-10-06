import SwiftUI

/// Hosts whichever game was chosen and handles the shared game flow:
/// picture instructions first, then the game (with pointing-hand hints),
/// then save progress and swap the game for the Results screen.
struct TVGamePlayView: View {
    let kind: TVGameKind
    let category: TVCategory

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    /// The game starts only after the child presses Let's Play!.
    @State private var hasStarted = false

    var body: some View {
        if let game = TVGameDataService.game(for: kind) {
            let launchCategory = game.launchCategory(preferred: category)
            if hasStarted {
                gameView(game, category: launchCategory)
                    .tvHintOverlay()
                    .transition(.opacity)
            } else {
                TVInstructionsView(
                    instructions: .instructions(for: kind, category: launchCategory),
                    tint: launchCategory.color
                ) {
                    withAnimation(TVTheme.Motion.entrance) { hasStarted = true }
                }
                .transition(.opacity)
            }
        } else {
            TVEmptyStateView(title: "Oops!", message: "This game isn't available right now.") {
                router.pop()
            }
        }
    }

    @ViewBuilder
    private func gameView(_ game: TVGame, category: TVCategory) -> some View {
        switch kind {
        case .countingPop:
            TVCountingPopView(category: category, player: store.activePlayer, onFinish: finish)
        case .shapeHunt:
            TVShapeHuntView(category: category, player: store.activePlayer, onFinish: finish)
        case .dragToMatch, .tapToReveal, .feedAnimals, .animalShadows, .shapeSort:
            TVChoiceGameView(game: game, category: category, player: store.activePlayer, onFinish: finish)
        }
    }

    private func finish(_ result: TVSessionResult) {
        let recorded = store.recordSession(result)
        sound.play(recorded.newRewards.isEmpty ? .correct : .reward)
        router.replaceTop(with: .results(recorded))
    }
}
