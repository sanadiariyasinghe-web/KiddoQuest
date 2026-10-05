import SwiftUI

// MARK: - Game Flow Container
// Wraps every mini-game in the same child-friendly journey:
// START → Clear Instructions → Gameplay → Round Results → Home OR More Games.

struct GameFlowContainer<Content: View>: View {
    let instructions: GameInstructions
    @Binding var navigationPath: NavigationPath
    /// Becomes true when the game's round is finished.
    let isFinished: Bool
    let result: RoundResult
    /// Called when the child taps "Play Again" on the results screen.
    let onPlayAgain: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var phase: GamePhase = .instructions
    
    /// Short pause so the child sees the success celebration before the results appear.
    private let celebrationDelay: Duration = .seconds(1.4)
    
    var body: some View {
        ZStack {
            content()
                .blur(radius: phase == .playing ? 0 : 6)
                .allowsHitTesting(phase == .playing)
                .accessibilityHidden(phase != .playing)
            
            if phase == .instructions {
                GameInstructionsView(instructions: instructions) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        phase = .playing
                    }
                }
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
            
            if phase == .results {
                RoundResultsView(
                    result: result,
                    themeColor: instructions.themeColor,
                    onHome: goHome,
                    onMoreGames: goToMoreGames,
                    onPlayAgain: playAgain
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(phase == .results)
        .onChange(of: isFinished) { _, finished in
            guard finished, phase == .playing else { return }
            Task {
                try? await Task.sleep(for: celebrationDelay)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    phase = .results
                }
            }
        }
    }
    
    // MARK: - Next Actions
    private func goHome() {
        navigationPath = NavigationPath()
    }
    
    /// Games are always opened from their island's game list, so stepping back returns there.
    private func goToMoreGames() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    private func playAgain() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            phase = .playing
        }
        onPlayAgain()
    }
}
