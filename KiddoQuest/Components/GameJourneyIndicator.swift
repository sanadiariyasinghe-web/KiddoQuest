import SwiftUI

// MARK: - Game Journey Indicator
// A simple "Learn → Play → Stars" trail that shows children where they are in every game.

struct GameJourneyIndicator: View {
    let phase: GamePhase
    var themeColor: Color = Theme.ColorPalette.animalsGreen
    
    private struct JourneyStep {
        let phase: GamePhase
        let icon: String
        let label: String
    }
    
    private let steps: [JourneyStep] = [
        JourneyStep(phase: .instructions, icon: "lightbulb.fill", label: "Learn"),
        JourneyStep(phase: .playing, icon: "gamecontroller.fill", label: "Play"),
        JourneyStep(phase: .results, icon: "star.fill", label: "Stars")
    ]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Theme.ColorPalette.secondaryText.opacity(0.5))
                }
                stepPill(for: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private func stepPill(for step: JourneyStep) -> some View {
        let isCurrent = step.phase == phase
        let isDone = step.phase < phase
        
        return HStack(spacing: 5) {
            Image(systemName: isDone ? "checkmark.circle.fill" : step.icon)
                .font(.system(size: 13, weight: .bold))
            Text(step.label)
                .font(Theme.Typography.caption(size: 13))
        }
        .foregroundStyle(
            isCurrent ? .white : (isDone ? Theme.ColorPalette.successGreen : Theme.ColorPalette.secondaryText)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(isCurrent ? themeColor : Theme.ColorPalette.cardBorder.opacity(0.6))
        )
        .scaleEffect(isCurrent ? 1.08 : 1.0)
    }
    
    private var accessibilityDescription: String {
        switch phase {
        case .instructions: return "Step 1 of 3: Learn how to play"
        case .playing: return "Step 2 of 3: Play"
        case .results: return "Step 3 of 3: Your stars"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GameJourneyIndicator(phase: .instructions)
        GameJourneyIndicator(phase: .playing)
        GameJourneyIndicator(phase: .results)
    }
    .padding()
}
