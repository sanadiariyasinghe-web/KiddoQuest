import SwiftUI

// MARK: - Game 6: Shape Sort View
// Children drag or sort falling shapes into labelled bottom bins (TRIANGLE, CIRCLE, SQUARE).

struct ShapeSortGameView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ShapeSortViewModel()
    
    var body: some View {
        GameFlowContainer(
            instructions: .shapeSort,
            navigationPath: $navigationPath,
            isFinished: viewModel.isGameCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = ShapeSortViewModel()
            }
        ) {
            gameContent
        }
        .navigationTitle("Shape Sort")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.medium) {
                // Header Bar
                HStack {
                    ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
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
                
                // Instructions
                HStack(spacing: 12) {
                    Text("Where does it go?")
                        .font(Theme.Typography.title(size: 26))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                
                Spacer()
                
                // Active Shape To Sort
                if let currentShape = viewModel.currentShape {
                    VStack(spacing: 8) {
                        Text(currentShape.symbol)
                            .font(.system(size: 76, weight: .heavy))
                            .foregroundStyle(currentShape.color)
                            .floating(yOffset: 6, duration: 1.8)
                        
                        Text("Tap the matching box ⬇︎")
                            .font(Theme.Typography.headline(size: 15))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                    }
                    .frame(width: 170, height: 160)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                }
                
                Spacer()
                
                // Mascot Feedback
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 56
                )
                .padding(.horizontal, Theme.Spacing.medium)
                
                // Bottom Bins (TRIANGLE, CIRCLE, SQUARE)
                binsRowView
                    .padding(.horizontal, Theme.Spacing.medium)
            }
            .padding(.top, Theme.Spacing.small)
            .padding(.bottom, Theme.Spacing.large)
            
            // Sparkle / Confetti Effect
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Bins Row
    private var binsRowView: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.bins) { bin in
                let isBouncing = viewModel.bouncingBinId == bin.id
                
                Button {
                    viewModel.dropShape(into: bin)
                } label: {
                    VStack(spacing: 8) {
                        Text(bin.symbol)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(bin.color)
                        
                        Text(bin.name)
                            .font(Theme.Typography.headline(size: 13))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .background(bin.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(bin.color, lineWidth: 2)
                    )
                    .scaleEffect(isBouncing ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isBouncing)
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("\(bin.name) bin")
            }
        }
    }
}
