import SwiftUI

// MARK: - Game 3: Tap-to-Reveal Coloring View
// Children learn shapes and colors by filling an unpainted outline with the correct color paint.

struct ColoringGameView: View, CompactAdaptable {
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
            CompactLayoutReader { compact($0).gameContent }
        }
        .navigationTitle("Tap-to-Reveal Coloring")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false

    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            GameScreenLayout(spacing: isCompact ? Theme.Spacing.medium : Theme.Spacing.large) {
                // Header
                HStack {
                    ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
                    Spacer()
                    Text("Shape \(viewModel.currentTaskIndex + 1)/\(viewModel.tasks.count)")
                        .font(Theme.Typography.headline(size: 15))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                    Spacer()
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
                
            } controls: {
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
                    .padding(.bottom, isCompact ? Theme.Spacing.medium : Theme.Spacing.large)
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
                .frame(width: AdaptiveMetric.size(220, compact: isCompact), height: AdaptiveMetric.size(220, compact: isCompact))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
            
            // Outline / Empty shape
            Image(systemName: viewModel.currentTask.shapeSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: AdaptiveMetric.size(140, compact: isCompact), height: AdaptiveMetric.size(140, compact: isCompact))
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
                            .frame(width: AdaptiveMetric.size(52, compact: isCompact), height: AdaptiveMetric.size(52, compact: isCompact))
                            .shadow(color: option.color.opacity(0.4), radius: 6, y: 3)
                        
                        Text(option.name)
                            .font(Theme.Typography.headline(size: 14))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 8 : 12)
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
                .hintTarget(option.name == viewModel.currentTask.targetColorName)
            }
        }
    }
}
