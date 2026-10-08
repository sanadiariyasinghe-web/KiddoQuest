import SwiftUI

// MARK: - Animals Island Picture Games View
// Shared view for "Feed the Animals" and "Animal Shadows":
// a big picture at the top and three large picture buttons to choose from.

struct AnimalPictureGameView: View, CompactAdaptable {
    let game: AnimalPictureGame
    @Binding var navigationPath: NavigationPath
    @State private var viewModel: AnimalPictureGameViewModel
    
    init(game: AnimalPictureGame, navigationPath: Binding<NavigationPath>) {
        self.game = game
        self._navigationPath = navigationPath
        self._viewModel = State(initialValue: AnimalPictureGameViewModel(game: game))
    }
    
    var body: some View {
        GameFlowContainer(
            instructions: game.instructions,
            navigationPath: $navigationPath,
            isFinished: viewModel.isGameCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = AnimalPictureGameViewModel(game: game)
            }
        ) {
            CompactLayoutReader { compact($0).gameContent }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false

    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            GameScreenLayout(spacing: Theme.Spacing.medium) {
                headerBar
                
                Text(viewModel.questionText)
                    .font(Theme.Typography.title(size: 26))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.medium)
                
                Spacer(minLength: 8)
                
                promptCard
                    .padding(.horizontal, Theme.Spacing.large)
                
                Spacer(minLength: 8)
                
            } controls: {
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 58
                )
                .padding(.horizontal, Theme.Spacing.medium)
                
                choicesRow
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.bottom, isCompact ? Theme.Spacing.medium : Theme.Spacing.large)
            }
            .padding(.top, Theme.Spacing.small)
            
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
            Spacer()
            Text("Animal \(viewModel.currentRoundIndex + 1)/\(viewModel.totalRounds)")
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
    
    // MARK: - Prompt Card
    private var promptCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.ColorPalette.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
            
            switch game {
            case .feedAnimals:
                feedPrompt
            case .animalShadows:
                shadowPrompt
            }
        }
        .frame(height: AdaptiveMetric.size(230, compact: isCompact))
        .animatedFeedback(isSuccess: viewModel.isCorrect, isGentleRetry: viewModel.isGentleRetry)
    }
    
    /// The hungry animal; its food appears next to it once the child picks correctly.
    private var feedPrompt: some View {
        HStack(spacing: 18) {
            Text(viewModel.currentRound.animal.emoji)
                .font(.system(size: AdaptiveMetric.size(110, compact: isCompact)))
                .scaleEffect(viewModel.isCorrect ? 1.12 : 1.0)
            
            if viewModel.isCorrect {
                VStack(spacing: 4) {
                    Text(viewModel.currentRound.answer.emoji)
                        .font(.system(size: AdaptiveMetric.size(60, compact: isCompact)))
                    Text("Yum!")
                        .font(Theme.Typography.title(size: 24))
                        .foregroundStyle(Theme.ColorPalette.animalsGreen)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hungry \(viewModel.currentRound.animal.name)")
    }
    
    /// A dark silhouette that turns into the full-colour animal when matched.
    private var shadowPrompt: some View {
        Text(viewModel.currentRound.animal.emoji)
            .font(.system(size: AdaptiveMetric.size(130, compact: isCompact)))
            .colorMultiply(viewModel.isCorrect ? .white : .black)
            .opacity(viewModel.isCorrect ? 1.0 : 0.8)
            .scaleEffect(viewModel.isCorrect ? 1.12 : 1.0)
            .animation(.easeInOut(duration: 0.6), value: viewModel.isCorrect)
            .accessibilityLabel(viewModel.isCorrect ? viewModel.currentRound.animal.name : "Animal shadow")
    }
    
    // MARK: - Choices
    private var choicesRow: some View {
        HStack(spacing: 14) {
            ForEach(viewModel.currentRound.choices) { choice in
                choiceButton(for: choice)
            }
        }
        .id(viewModel.currentRoundIndex)
    }
    
    private func choiceButton(for choice: AnimalChoice) -> some View {
        let isWrong = viewModel.wrongChoiceIDs.contains(choice.id)
        let isAnswer = viewModel.isCorrect && choice == viewModel.currentRound.answer
        
        return Button {
            viewModel.choose(choice)
        } label: {
            Text(choice.emoji)
                .font(.system(size: AdaptiveMetric.size(56, compact: isCompact)))
                .frame(maxWidth: .infinity)
                .frame(height: AdaptiveMetric.size(112, compact: isCompact))
                .background(isAnswer ? Theme.ColorPalette.successGreen.opacity(0.25) : Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            isAnswer ? Theme.ColorPalette.successGreen : Theme.ColorPalette.animalsGreen.opacity(0.4),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                .opacity(isWrong ? 0.3 : 1.0)
                .scaleEffect(isWrong ? 0.9 : 1.0)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(isWrong || viewModel.isCorrect)
        .accessibilityLabel(choice.name)
        .hintTarget(choice == viewModel.currentRound.answer)
    }
}

#Preview("Feed the Animals") {
    NavigationStack {
        AnimalPictureGameView(game: .feedAnimals, navigationPath: .constant(NavigationPath()))
    }
}

#Preview("Animal Shadows") {
    NavigationStack {
        AnimalPictureGameView(game: .animalShadows, navigationPath: .constant(NavigationPath()))
    }
}
