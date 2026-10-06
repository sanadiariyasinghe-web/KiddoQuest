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
    @State private var earnedSticker: Sticker?
    @State private var isShowingHint = false
    @State private var lastInteraction = ContinuousClock.now
    @State private var isConfirmingHome = false

    /// Short pause so the child sees the success celebration before the results appear.
    private let celebrationDelay: Duration = .seconds(1.4)
    /// The pointing hand appears shortly after play starts...
    private let firstHintDelay: Duration = .seconds(0.8)
    /// ...and again whenever the child hasn't tapped anything for this long.
    private let idleHintDelay: Duration = .seconds(8)
    private let hintDuration: Duration = .seconds(2.2)
    
    var body: some View {
        ZStack {
            // Full-screen background so games can stay a comfortable width on iPad / landscape
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()

            content()
                .frame(maxWidth: Theme.Layout.maxContentWidth)
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
                    sticker: earnedSticker,
                    onHome: goHome,
                    onMoreGames: goToMoreGames,
                    onPlayAgain: playAgain
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if isConfirmingHome {
                homeConfirmation
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        // Children leave a game only through the big 🏠 button (or the results screen)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if phase != .results {
                ToolbarItem(placement: .topBarLeading) {
                    homeButton
                }
            }
        }
        .task(id: phase) {
            await runHintLoop()
        }
        .onChange(of: isFinished) { _, finished in
            guard finished, phase == .playing else { return }
            Task {
                try? await Task.sleep(for: celebrationDelay)
                // Every finished round adds a sticker to the child's sticker book
                earnedSticker = StickerBook.shared.awardSticker(for: instructions.title)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    phase = .results
                }
            }
        }
    }
    
    // MARK: - Big Home Button
    private var homeButton: some View {
        Button {
            SoundService.shared.playButtonClick()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isConfirmingHome = true
            }
        } label: {
            Text("🏠")
                .font(.system(size: 26))
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.ColorPalette.cardBackground))
                .overlay(Circle().stroke(instructions.themeColor, lineWidth: 2.5))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Home")
        .accessibilityIdentifier("game.home")
    }

    /// "Go home?" check with two big picture buttons, so a stray tap doesn't end the game.
    private var homeConfirmation: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismissHomeConfirmation() }

            VStack(spacing: Theme.Spacing.large) {
                Text("Go home?")
                    .font(Theme.Typography.title(size: 30))
                    .foregroundStyle(Theme.ColorPalette.primaryText)

                HStack(spacing: 16) {
                    confirmationButton(emoji: "🏠", title: "Home", color: Theme.ColorPalette.lettersBlue) {
                        isConfirmingHome = false
                        goHome()
                    }
                    .accessibilityIdentifier("game.confirmHome")

                    confirmationButton(emoji: "▶️", title: "Keep playing", color: Theme.ColorPalette.successGreen) {
                        dismissHomeConfirmation()
                    }
                    .accessibilityIdentifier("game.keepPlaying")
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxCardWidth)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, Theme.Spacing.large)
        }
    }

    private func confirmationButton(emoji: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            SoundService.shared.playButtonClick()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 40))
                Text(title)
                    .font(Theme.Typography.headline(size: 18))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(title)
    }

    private func dismissHomeConfirmation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isConfirmingHome = false
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
