import SwiftUI

// MARK: - Game Instructions View
// Shown at the start of every game: what is the goal, what to tap, and a big "Let's Play!" button.
// A picture sentence (e.g. 🐰 → 👆 → 🥕) explains the game to children who can't read yet;
// short text steps underneath help grown-ups read along.

struct GameInstructionsView: View {
    let instructions: GameInstructions
    let onStart: () -> Void
    
    @State private var hasAppeared = false
    @State private var isPulsing = false
    @CalmModeEnabled private var isCalm

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.large) {
                GameJourneyIndicator(phase: .instructions, themeColor: instructions.themeColor)
                
                Text(instructions.title)
                    .font(Theme.Typography.title(size: 30))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                    .multilineTextAlignment(.center)
                
                pictureStory
                
                // Short text steps for grown-ups reading along
                VStack(spacing: 8) {
                    ForEach(Array(instructions.steps.enumerated()), id: \.element.id) { index, step in
                        stepRow(number: index + 1, step: step)
                    }
                }
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(1.4), value: hasAppeared)
                
                // Clear next action
                PrimaryChildButton(
                    title: "Let's Play!",
                    iconName: "play.fill",
                    backgroundColor: Theme.ColorPalette.successGreen,
                    minHeight: 72
                ) {
                    SoundService.shared.playButtonClick()
                    onStart()
                }
                .scaleEffect(isPulsing ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
                .accessibilityIdentifier("instructions.play")
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.Layout.maxCardWidth)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, Theme.Spacing.large)
        }
        .onAppear {
            hasAppeared = true
            isPulsing = !isCalm
        }
    }
    
    // MARK: - Picture Sentence
    /// Big pictures joined by arrows, appearing one after another.
    private var pictureStory: some View {
        HStack(spacing: 8) {
            ForEach(Array(instructions.pictureStory.enumerated()), id: \.offset) { index, picture in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(instructions.themeColor)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(Double(index) * 0.45), value: hasAppeared)
                }
                pictureTile(picture)
                    .scaleEffect(hasAppeared ? 1 : 0.4)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.6).delay(0.15 + Double(index) * 0.45),
                        value: hasAppeared
                    )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(instructions.themeColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(instructions.steps.map(\.text).joined(separator: " "))
    }
    
    private func pictureTile(_ picture: PictureStep) -> some View {
        Text(picture.symbol)
            .font(.system(size: 44, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.ColorPalette.primaryText)
            .colorMultiply(picture.isShadow ? .black : .white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(minWidth: 64, minHeight: 64)
            .padding(6)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.minimum))
    }
    
    private func stepRow(number: Int, step: InstructionStep) -> some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(Theme.Typography.headline(size: 15))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(instructions.themeColor))
            
            Text(step.text)
                .font(Theme.Typography.body(size: 17))
                .foregroundStyle(Theme.ColorPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number): \(step.text)")
    }
}

#Preview {
    ZStack {
        Theme.ColorPalette.mainBackground.ignoresSafeArea()
        GameInstructionsView(instructions: .feedAnimals) { }
    }
}
