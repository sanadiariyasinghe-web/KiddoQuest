import SwiftUI

/// The "Learn → Play → Stars" trail shown on the instructions and results
/// screens, so children always know where they are in a game.
struct TVJourneyTrail: View {
    enum Step: Int, CaseIterable {
        case learn, play, stars

        var title: String {
            switch self {
            case .learn: return "Learn"
            case .play: return "Play"
            case .stars: return "Stars"
            }
        }

        var symbol: String {
            switch self {
            case .learn: return "lightbulb.fill"
            case .play: return "gamecontroller.fill"
            case .stars: return "star.fill"
            }
        }
    }

    let current: Step
    var tint: Color = TVTheme.Palette.animalsGreen

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Step.allCases, id: \.self) { step in
                if step != .learn {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(TVTheme.Palette.muted)
                }
                pill(for: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current.rawValue + 1) of 3: \(current.title)")
    }

    private func pill(for step: Step) -> some View {
        let isCurrent = step == current
        let isDone = step.rawValue < current.rawValue
        return Label(step.title, systemImage: isDone ? "checkmark.circle.fill" : step.symbol)
            .font(TVTheme.Typography.caption)
            .foregroundStyle(isCurrent ? TVTheme.Palette.ink : (isDone ? TVTheme.Palette.success : TVTheme.Palette.textSecondary))
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(Capsule().fill(isCurrent ? tint : TVTheme.Palette.subtle))
    }
}
