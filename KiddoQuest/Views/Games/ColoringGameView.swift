import SwiftUI

// MARK: - Game 3: Tap-to-Reveal Coloring View
// Children learn shapes and colors by filling an unpainted outline with the correct color paint.

struct ColoringGameView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ColoringViewModel()
    
    var body: some View {
        GameFlowContainer(
            instructions: .coloring,
            navigationPath: $navigationPath,
            isFinished: viewModel.isGameCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = ColoringViewModel()
            }
        ) {
            gameContent
        }
        .navigationTitle("Tap-to-Reveal Coloring")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.large) {
                // Header
                HStack {
                    ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
                    Spacer()
                    Text("Shape \(viewModel.currentTaskIndex + 1)/\(viewModel.tasks.count)")
                        .font(Theme.Typography.headline(size: 15))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                    Spacer()
                    Text("Score: \(viewModel.score)")
                        .font(Theme.Typography.headline(size: 16))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.ColorPalette.cardBackground)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Theme.Spacing.medium)
                
                // Instructions / Question
                HStack(spacing: 12) {
                    Text("Paint the \(viewModel.currentTask.shapeName) \(viewModel.currentTask.targetColorName)!")
                        .font(Theme.Typography.title(size: 26))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.medium)
                
                Spacer()
                
                // Shape Canvas
                shapeCanvasView
                
                Spacer()
                
                // Mascot Feedback
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 58
                )
                .padding(.horizontal, Theme.Spacing.medium)
                
                // Color Paint Palette Buttons
                colorPaletteView
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.bottom, Theme.Spacing.large)
            }
            .padding(.top, Theme.Spacing.small)
            
            // Celebration Confetti
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Shape Canvas
    private var shapeCanvasView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.ColorPalette.cardBackground)
                .frame(width: 220, height: 220)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
            
            // Outline / Empty shape
            Image(systemName: viewModel.currentTask.shapeSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .foregroundStyle(
                    viewModel.isFilled
                    ? (viewModel.filledColor ?? .clear)
                    : Theme.ColorPalette.secondaryText.opacity(0.25)
                )
                .scaleEffect(viewModel.isFilled ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isFilled)
                .animatedFeedback(isSuccess: viewModel.isCorrect, isGentleRetry: viewModel.isGentleRetry)
        }
    }
    
    // MARK: - Color Palette
    private var colorPaletteView: some View {
        HStack(spacing: 14) {
            ForEach(viewModel.colorOptions) { option in
                Button {
                    viewModel.selectColor(option)
                } label: {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(option.color)
                            .frame(width: 52, height: 52)
                            .shadow(color: option.color.opacity(0.4), radius: 6, y: 3)
                        
                        Text(option.name)
                            .font(Theme.Typography.headline(size: 14))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Theme.ColorPalette.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(viewModel.isFilled)
                .accessibilityLabel("Paint \(option.name)")
            }
        }
    }
}
