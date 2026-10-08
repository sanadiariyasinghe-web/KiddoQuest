import SwiftUI

// MARK: - Game 1: Counting Pop View
// Children learn to count objects by watching animated treats appear and selecting the correct number card.

struct CountingPopGameView: View, CompactAdaptable {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = CountingPopViewModel()
    
    var body: some View {
        GameFlowContainer(
            instructions: .countingPop,
            navigationPath: $navigationPath,
            isFinished: viewModel.isGameCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = CountingPopViewModel()
            }
        ) {
            CompactLayoutReader { compact($0).gameContent }
        }
        .navigationTitle("Counting Pop")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            GameScreenLayout(spacing: Theme.Spacing.medium) {
                // Top Game Header
                headerBar
                
                // Question Banner
                HStack(spacing: 12) {
                    Text(viewModel.questionText)
                        .font(Theme.Typography.title(size: 26))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                .padding(.top, 4)
                
                Spacer(minLength: 8)
                
                // Animated Objects Display
                objectsDisplayArea
                
                Spacer(minLength: 8)
                
            } controls: {
                // Mascot Feedback
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 60
                )
                .padding(.horizontal, Theme.Spacing.medium)
                
                // Answer Options Cards (4 Large touch targets)
                answerOptionsGrid
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.bottom, Theme.Spacing.large)
            }
            
            // Native SwiftUI Particle Burst Confetti Overlay
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
            
            Spacer()
            
            Text("Round \(viewModel.currentRound)/\(viewModel.totalRounds)")
                .font(Theme.Typography.headline(size: 15))
                .foregroundStyle(Theme.ColorPalette.secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(Capsule())
            
            Spacer()
            
        }
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Objects Display Area
    private var objectsDisplayArea: some View {
        let columns = [GridItem(.adaptive(minimum: 65, maximum: 90), spacing: 14)]
        
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.ColorPalette.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    Text(item.emoji)
                        .font(.system(size: AdaptiveMetric.size(48, compact: isCompact)))
                        .scaleEffect(viewModel.isCorrect ? 1.15 : 1.0)
                        .floating(yOffset: 5, duration: 2.0 + Double(index) * 0.2)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isCorrect)
                }
            }
            .padding(isCompact ? 16 : 24)
        }
        .frame(maxHeight: AdaptiveMetric.size(260, compact: isCompact))
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    // MARK: - Answer Options Grid
    private var answerOptionsGrid: some View {
        // Two big buttons per row on phones; wide screens (iPad) show up to four in one row
        let perRow = horizontalSizeClass == .regular ? min(max(viewModel.options.count, 2), 4) : 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: perRow)
        
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(viewModel.options, id: \.self) { option in
                answerButton(for: option)
            }
        }
    }
    
    private func answerButton(for option: Int) -> some View {
        let isThisSelected = viewModel.selectedAnswer == option
        let isOptionCorrect = isThisSelected && viewModel.isCorrect
        let isOptionRetry = isThisSelected && viewModel.isGentleRetry
        
        return Button {
            viewModel.checkAnswer(option)
        } label: {
            Text("\(option)")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(isOptionCorrect ? .white : Theme.ColorPalette.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveMetric.size(74, compact: isCompact))
                .background(
                    isOptionCorrect
                    ? Theme.ColorPalette.successGreen
                    : Theme.ColorPalette.cardBackground
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            isOptionCorrect ? Theme.ColorPalette.successGreen : Theme.ColorPalette.numbersYellow.opacity(0.4),
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: isOptionCorrect ? Theme.ColorPalette.successGreen.opacity(0.4) : Color.black.opacity(0.06),
                    radius: 6,
                    y: 3
                )
        }
        .buttonStyle(BouncyButtonStyle())
        .animatedFeedback(isSuccess: isOptionCorrect, isGentleRetry: isOptionRetry)
        .disabled(viewModel.isCorrect)
        .accessibilityLabel("Answer: \(option)")
        .hintTarget(option == viewModel.targetCount)
    }
}
