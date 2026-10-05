import SwiftUI

// MARK: - Game Instructions View
// Shown at the start of every game: what is the goal, what to tap, and a big "Let's Play!" button.
// Steps appear one at a time with big icons so children who can't read yet can still follow.

struct GameInstructionsView: View {
    let instructions: GameInstructions
    let onStart: () -> Void
    
    @State private var hasAppeared = false
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.large) {
                GameJourneyIndicator(phase: .instructions, themeColor: instructions.themeColor)
                
                // Game identity
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(instructions.themeColor.opacity(0.25))
                            .frame(width: 110, height: 110)
                        Text(instructions.emoji)
                            .font(.system(size: 60))
                    }
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55), value: hasAppeared)
                    .accessibilityHidden(true)
                    
                    Text(instructions.title)
                        .font(Theme.Typography.title(size: 30))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Numbered steps
                VStack(spacing: 12) {
                    ForEach(Array(instructions.steps.enumerated()), id: \.element.id) { index, step in
                        stepRow(number: index + 1, step: step)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 18)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(index) * 0.6),
                                value: hasAppeared
                            )
                    }
                }
                
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
            }
            .padding(Theme.Spacing.large)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, Theme.Spacing.large)
        }
        .onAppear {
            hasAppeared = true
            isPulsing = true
        }
    }
    
    private func stepRow(number: Int, step: InstructionStep) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(Theme.Typography.title(size: 22))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(instructions.themeColor))
            
            Image(systemName: step.icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(instructions.themeColor)
                .frame(width: 30)
            
            Text(step.text)
                .font(Theme.Typography.headline(size: 21))
                .foregroundStyle(Theme.ColorPalette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(instructions.themeColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
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
