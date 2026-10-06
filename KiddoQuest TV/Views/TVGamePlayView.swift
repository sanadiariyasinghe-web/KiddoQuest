import SwiftUI

/// Hosts whichever game was chosen and handles the shared "game finished"
/// flow: save progress, then swap the game for the Results screen.
struct TVGamePlayView: View {
    let kind: TVGameKind
    let category: TVCategory

    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    var body: some View {
        if let game = TVGameDataService.game(for: kind) {
            let launchCategory = game.launchCategory(preferred: category)
            switch kind {
            case .countingPop:
                TVCountingPopView(category: launchCategory, player: store.activePlayer, onFinish: finish)
            case .shapeHunt:
                TVShapeHuntView(category: launchCategory, player: store.activePlayer, onFinish: finish)
            case .dragToMatch, .tapToReveal, .feedAnimals, .animalShadows, .shapeSort:
                TVChoiceGameView(game: game, category: launchCategory, player: store.activePlayer, onFinish: finish)
            }
        } else {
            TVEmptyStateView(title: "Oops!", message: "This game isn't available right now.") {
                router.pop()
            }
        }
    }

    private func finish(_ result: TVSessionResult) {
        let recorded = store.recordSession(result)
        sound.play(recorded.newRewards.isEmpty ? .correct : .reward)
        router.replaceTop(with: .results(recorded))
    }
}
