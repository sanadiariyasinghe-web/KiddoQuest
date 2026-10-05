import SwiftUI

// MARK: - Game 2: Drag-to-Match View
// Children drag or connect items from the left column to the corresponding target on the right.

struct DragMatchGameView: View {
    let category: IslandCategory
    @Binding var navigationPath: NavigationPath
    @State private var viewModel: DragMatchViewModel
    
    // Tap-matching state for accessible child interaction
    @State private var selectedSourceId: String? = nil
    
    init(category: IslandCategory, navigationPath: Binding<NavigationPath>) {
        self.category = category
        self._navigationPath = navigationPath
        self._viewModel = State(initialValue: DragMatchViewModel(category: category))
    }
    
    var body: some View {
        GameFlowContainer(
            instructions: .dragMatch(for: category),
            navigationPath: $navigationPath,
            isFinished: viewModel.isCompleted,
            result: viewModel.result,
            onPlayAgain: {
                selectedSourceId = nil
                viewModel = DragMatchViewModel(category: category)
            }
        ) {
            gameContent
        }
        .navigationTitle(category == .numbers ? "Number Match" : "Letter Match")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.large) {
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
                
                // Mascot Banner
                MascotView(
                    mood: viewModel.mascotMood,
                    customMessage: viewModel.mascotMessage,
                    size: 60
                )
                .padding(.horizontal, Theme.Spacing.medium)
                
                Spacer()
                
                // Matching Columns (Left: Sources, Right: Targets)
                HStack(spacing: 36) {
                    // LEFT COLUMN: Sources
                    VStack(spacing: 20) {
                        Text("1 · Tap")
                            .font(Theme.Typography.headline(size: 18))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                        
                        ForEach(viewModel.pairs) { pair in
                            sourceItemView(for: pair)
                        }
                    }
                    
                    // Center separator / visual clue
                    VStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.ColorPalette.lettersBlue.opacity(0.4))
                    }
                    
                    // RIGHT COLUMN: Targets
                    VStack(spacing: 20) {
                        Text("2 · Match")
                            .font(Theme.Typography.headline(size: 18))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                        
                        ForEach(viewModel.targetOrder) { pair in
                            targetItemView(for: pair)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                
                Spacer()
            }
            .padding(.top, Theme.Spacing.small)
            
            // Particle Burst Overlay
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }
    
    // MARK: - Source Item (Left)
    private func sourceItemView(for pair: MatchPair) -> some View {
        let isMatched = viewModel.matchedPairIds.contains(pair.id)
        let isSelected = selectedSourceId == pair.id
        
        return Button {
            guard !isMatched else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedSourceId = isSelected ? nil : pair.id
            }
            SoundService.shared.playButtonClick()
            if !isSelected {
                viewModel.didSelectSource()
            }
        } label: {
            HStack {
                Text(pair.sourceDisplay)
                    .font(.system(size: category == .numbers ? 24 : 32, weight: .bold, design: .rounded))
                    .foregroundStyle(isMatched ? Theme.ColorPalette.successGreen : Theme.ColorPalette.primaryText)
            }
            .frame(width: 120, height: 72)
            .background(
                isMatched
                ? Theme.ColorPalette.successGreen.opacity(0.15)
                : (isSelected ? Theme.ColorPalette.numbersYellow.opacity(0.3) : Theme.ColorPalette.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isMatched
                        ? Theme.ColorPalette.successGreen
                        : (isSelected ? Theme.ColorPalette.numbersYellow : Theme.ColorPalette.cardBorder),
                        lineWidth: isSelected || isMatched ? 3 : 1.5
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
            .scaleEffect(isSelected ? 1.06 : 1.0)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(isMatched)
        .accessibilityLabel("\(pair.sourceDisplay), \(isMatched ? "already matched" : "tap to select")")
    }
    
    // MARK: - Target Item (Right)
    private func targetItemView(for pair: MatchPair) -> some View {
        let isMatched = viewModel.matchedPairIds.contains(pair.id)
        
        return Button {
            guard !isMatched else { return }
            if let selected = selectedSourceId {
                if selected == pair.id {
                    // Correct match
                    withAnimation(.spring()) {
                        viewModel.registerMatch(pairId: pair.id)
                        selectedSourceId = nil
                    }
                } else {
                    // Fail match
                    withAnimation(.spring()) {
                        viewModel.registerFail(sourceId: selected)
                        selectedSourceId = nil
                    }
                }
            } else {
                viewModel.remindFirstStep()
            }
        } label: {
            HStack {
                Text(pair.targetDisplay)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(isMatched ? .white : Theme.ColorPalette.primaryText)
            }
            .frame(width: 120, height: 72)
            .background(
                isMatched
                ? Theme.ColorPalette.successGreen
                : Theme.ColorPalette.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isMatched ? Theme.ColorPalette.successGreen : Theme.ColorPalette.cardBorder,
                        lineWidth: isMatched ? 3 : 1.5
                    )
            )
            .shadow(color: isMatched ? Theme.ColorPalette.successGreen.opacity(0.3) : Color.black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(isMatched)
        .accessibilityLabel("Match target: \(pair.targetDisplay)")
    }
}
