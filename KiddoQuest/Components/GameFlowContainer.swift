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
    @State private var isShowingHint = false
    @State private var lastInteraction = ContinuousClock.now
    
    /// Short pause so the child sees the success celebration before the results appear.
    private let celebrationDelay: Duration = .seconds(1.4)
    /// The pointing hand appears shortly after play starts...
    private let firstHintDelay: Duration = .seconds(0.8)
    /// ...and again whenever the child hasn't tapped anything for this long.
    private let idleHintDelay: Duration = .seconds(8)
    private let hintDuration: Duration = .seconds(2.2)
    
    var body: some View {
        ZStack {
            content()
                .overlayPreferenceValue(HintTargetKey.self) { anchor in
                    GeometryReader { proxy in
                        if isShowingHint, phase == .playing, !isFinished, let anchor {
                            let target = proxy[anchor]
                            HintHandView(color: instructions.themeColor)
                                .position(x: target.midX, y: target.midY)
                                .transition(.opacity)
                        }
                    }
                }
                .simultaneousGesture(TapGesture().onEnded { childInteracted() })
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
        .task(id: phase) {
            await runHintLoop()
        }
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
    
    // MARK: - Pointing-Hand Hints
    /// Shows the hint once at the start of play, then again after each idle period.
    private func runHintLoop() async {
        guard phase == .playing else { return }
        try? await Task.sleep(for: firstHintDelay)
        await showHint()
        while !Task.isCancelled, phase == .playing {
            try? await Task.sleep(for: .seconds(1))
            if ContinuousClock.now - lastInteraction >= idleHintDelay {
                await showHint()
            }
        }
    }
    
    private func showHint() async {
        guard !Task.isCancelled, !isFinished else { return }
        withAnimation(.easeIn(duration: 0.25)) { isShowingHint = true }
        try? await Task.sleep(for: hintDuration)
        withAnimation(.easeOut(duration: 0.25)) { isShowingHint = false }
        lastInteraction = .now
    }
    
    /// Any tap counts as activity and hides a hint that's on screen.
    private func childInteracted() {
        lastInteraction = .now
        if isShowingHint {
            withAnimation(.easeOut(duration: 0.2)) { isShowingHint = false }
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
