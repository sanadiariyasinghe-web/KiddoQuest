import SwiftUI

// MARK: - Game 4: Letter & Shape Hunt View
// Children find and bubble-pop target letters or shapes floating gently around the screen.

struct LetterShapeHuntGameView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel: LetterShapeHuntViewModel
    
    init(isShapeMode: Bool = false, navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
        self._viewModel = State(initialValue: LetterShapeHuntViewModel(isShapeMode: isShapeMode))
    }
    
    var body: some View {
        GameFlowContainer(
            instructions: .hunt(isShapeMode: viewModel.isShapeMode),
            navigationPath: $navigationPath,
            isFinished: viewModel.isCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = LetterShapeHuntViewModel(isShapeMode: viewModel.isShapeMode)
            }
        ) {
            gameContent
        }
        .navigationTitle(viewModel.isShapeMode ? "Shape Hunt" : "Letter Hunt")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.medium) {
                // Header Bar
                headerBar
                
                // Prompt Banner
                HStack(spacing: 12) {
                    Text(viewModel.targetPrompt)
                        .font(Theme.Typography.title(size: 24))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                
                // Found Counter Pill (Section 7 requirement: FOUND: 2 / 3)
                HStack(spacing: 6) {
                    Text("FOUND:")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                    Text("\(viewModel.foundCount) / \(viewModel.totalRequired)")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.lettersBlue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                
                Spacer()
                
                // Floating Bubble Arena
                floatingBubbleArena
                    .padding(.horizontal, Theme.Spacing.medium)
                
                Spacer()
                
                // Mascot Feedback
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 58
                )
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.large)
            }
            .padding(.top, Theme.Spacing.small)
            
            // Celebration Confetti
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    // MARK: - Floating Bubble Arena
    private var floatingBubbleArena: some View {
        let columns = [
            GridItem(.flexible(), spacing: 18),
            GridItem(.flexible(), spacing: 18),
            GridItem(.flexible(), spacing: 18)
        ]
        
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.ColorPalette.cardBackground.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    bubbleView(for: item, index: index)
                }
            }
            .padding(24)
        }
        .frame(minHeight: 280)
    }
    
    private func bubbleView(for item: HuntItem, index: Int) -> some View {
        Button {
            viewModel.tapItem(item)
        } label: {
            ZStack {
                Circle()
                    .fill(
                        item.isPopped
                        ? Theme.ColorPalette.successGreen.opacity(0.2)
                        : Theme.ColorPalette.lettersBlue.opacity(0.18)
                    )
                    .frame(width: 74, height: 74)
                    .overlay(
                        Circle()
                            .stroke(
                                item.isPopped
                                ? Theme.ColorPalette.successGreen
                                : Theme.ColorPalette.lettersBlue.opacity(0.5),
                                lineWidth: 2.5
                            )
                    )
                
                if item.isPopped {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.ColorPalette.successGreen)
                } else {
                    Text(item.symbol)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
            }
            .scaleEffect(item.isPopped ? 0.8 : 1.0)
            .floating(yOffset: 6, duration: 2.0 + Double(index % 3) * 0.3)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isPopped)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(item.isPopped)
        .accessibilityLabel(item.isPopped ? "Already popped" : "Bubble: \(item.symbol)")
        .hintTarget(item.id == viewModel.items.first(where: { $0.isTarget && !$0.isPopped })?.id)
    }
}
