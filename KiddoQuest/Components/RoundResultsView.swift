import SwiftUI

// MARK: - Round Results View
// Shown when every game round finishes: stars, correct answers, a positive message,
// and big, clear next actions (Home / More Games) so children always know what to do next.

struct RoundResultsView: View {
    let result: RoundResult
    var themeColor: Color = Theme.ColorPalette.animalsGreen
    /// The sticker earned for finishing this round (added to the sticker book).
    var sticker: Sticker? = nil
    let onHome: () -> Void
    let onMoreGames: () -> Void
    let onPlayAgain: () -> Void
    
    @State private var positiveMessage = ""
    @State private var revealedStars = 0
    @State private var showConfetti = false
    @State private var hasAppeared = false
    
    private static let positiveMessages = [
        "Great work!",
        "You are doing amazing!",
        "Keep learning!",
        "You are a super star!"
    ]
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.large) {
                    GameJourneyIndicator(phase: .results, themeColor: themeColor)
                    
                    // Buddy dances — a bigger dance for 3 stars
                    CelebratingOwlView(stars: result.stars)
                    
                    // Celebration headline
                    VStack(spacing: 8) {
                        Text("Great Job! 🎉")
                            .font(Theme.Typography.title(size: 38))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                            .scaleEffect(hasAppeared ? 1.0 : 0.6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5), value: hasAppeared)
                        
                        Text(positiveMessage)
                            .font(Theme.Typography.headline(size: 21))
                            .foregroundStyle(themeColor)
                    }
                    
                    roundSummaryCard
                    
                    if let sticker {
                        newStickerCard(sticker)
                    }
                    
                    // Next actions
                    VStack(spacing: 14) {
                        Text("What's next?")
                            .font(Theme.Typography.headline(size: 20))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                        
                        HStack(spacing: 14) {
                            nextActionButton(
                                emoji: "🏠",
                                title: "Home",
                                color: Theme.ColorPalette.lettersBlue,
                                action: onHome
                            )
                            nextActionButton(
                                emoji: "🎮",
                                title: "More Games",
                                color: Theme.ColorPalette.animalsGreen,
                                action: onMoreGames
                            )
                        }
                        
                        Button {
                            SoundService.shared.playButtonClick()
                            onPlayAgain()
                        } label: {
                            Label("Play Again", systemImage: "arrow.counterclockwise")
                                .font(Theme.Typography.headline(size: 18))
                                .foregroundStyle(Theme.ColorPalette.primaryText)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Theme.ColorPalette.cardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.ColorPalette.cardBorder, lineWidth: 1.5))
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel("Play this game again")
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: hasAppeared)
                }
                .padding(Theme.Spacing.large)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            
            ParticleBurstView(isEmitting: $showConfetti, particleCount: 36)
        }
        .onAppear {
            positiveMessage = Self.positiveMessages.randomElement() ?? "Great work!"
            hasAppeared = true
        }
        .task {
            // Celebrate, then reveal the stars one at a time
            try? await Task.sleep(for: .seconds(0.3))
            showConfetti = true
            for star in 0..<result.stars {
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                    revealedStars = star + 1
                }
            }
        }
    }
    
    // MARK: - New Sticker
    private func newStickerCard(_ sticker: Sticker) -> some View {
        HStack(spacing: 16) {
            Text(sticker.emoji)
                .font(.system(size: 54))
                .rotationEffect(.degrees(hasAppeared ? -8 : -40))
                .scaleEffect(hasAppeared ? 1 : 0.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(1.4), value: hasAppeared)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("New sticker!")
                    .font(Theme.Typography.title(size: 22))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                Text("It's in your sticker book.")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.ColorPalette.numbersYellow.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.ColorPalette.numbersYellow, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New sticker added to your sticker book")
    }
    
    // MARK: - Round Summary
    private var roundSummaryCard: some View {
        VStack(spacing: 16) {
            Text("This Round")
                .font(Theme.Typography.headline(size: 22))
                .foregroundStyle(Theme.ColorPalette.primaryText)
            
            summaryRow(icon: "star.circle.fill", iconColor: Theme.ColorPalette.starGold, label: "Stars") {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < revealedStars ? "star.fill" : "star")
                            .foregroundStyle(
                                index < revealedStars
                                ? Theme.ColorPalette.starGold
                                : Theme.ColorPalette.secondaryText.opacity(0.35)
                            )
                            .scaleEffect(index < revealedStars ? 1.15 : 0.9)
                    }
                }
            }
            .accessibilityLabel("Stars: \(result.stars) of 3")
            
            summaryRow(icon: "checkmark.circle.fill", iconColor: Theme.ColorPalette.successGreen, label: result.correctLabel) {
                Text("\(result.correctAnswers) / \(result.totalQuestions)")
            }
            
            if let newLevel = result.newLevel {
                summaryRow(icon: "arrow.up.circle.fill", iconColor: Theme.ColorPalette.lettersBlue, label: "Level up!") {
                    Text("Level \(newLevel)")
                }
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .stroke(themeColor.opacity(0.4), lineWidth: 3)
        )
        .shadow(color: themeColor.opacity(0.15), radius: 12, y: 6)
    }
    
    private func summaryRow<Value: View>(
        icon: String,
        iconColor: Color,
        label: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32)
            
            Text(label)
                .font(Theme.Typography.headline(size: 20))
                .foregroundStyle(Theme.ColorPalette.secondaryText)
            
            Spacer()
            
            value()
                .font(Theme.Typography.title(size: 26))
                .foregroundStyle(Theme.ColorPalette.primaryText)
        }
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Next Action Button
    private func nextActionButton(
        emoji: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SoundService.shared.playButtonClick()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 42))
                Text(LocalizedStringKey(title))
                    .font(Theme.Typography.title(size: 22))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(title)
    }
}

#Preview {
    RoundResultsView(
        result: RoundResult(score: 80, stars: 3, correctAnswers: 4, totalQuestions: 5),
        sticker: Sticker(emoji: "🦄", gameTitle: "Counting Pop", earnedDate: Date()),
        onHome: { },
        onMoreGames: { },
        onPlayAgain: { }
    )
}
