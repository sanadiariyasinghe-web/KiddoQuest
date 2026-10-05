import SwiftUI

/// Buddy's emotional states.
nonisolated enum TVMascotMood: Equatable {
    case idle
    case happy
    case correct
    case tryAgain

    var defaultMessage: String {
        switch self {
        case .idle: return "Ready?"
        case .happy: return "Let's learn together!"
        case .correct: return "Great job!"
        case .tryAgain: return "Almost! Try again!"
        }
    }
}

/// Buddy, the KiddoQuest owl mascot. Matches the iOS app's `MascotView`
/// (Part A): an owl in a soft yellow circle with a card-style speech bubble
/// labelled "Buddy" — sized up and with extra moods for the TV.
struct TVMascotView: View {
    var mood: TVMascotMood = .idle
    var message: String?
    var size: CGFloat = 260
    var showsBubble = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tvAmbientMotionEnabled) private var ambientMotionEnabled
    @State private var isBobbing = false

    private var spokenText: String { message ?? mood.defaultMessage }

    var body: some View {
        VStack(spacing: size * 0.08) {
            if showsBubble {
                speechBubble
                    .id(spokenText)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            ZStack {
                Circle()
                    .fill(TVTheme.Palette.numbersYellow.opacity(0.25))
                Text("🦉")
                    .font(.system(size: size * 0.65))
                    .offset(y: isBobbing ? -size * 0.04 : size * 0.02)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(mood == .correct ? 1.1 : 1)
            }
            .frame(width: size, height: size)
            .overlay(alignment: .topTrailing) {
                if mood == .correct {
                    Text("✨")
                        .font(.system(size: size * 0.25))
                        .offset(x: size * 0.05, y: -size * 0.05)
                        .transition(.scale.combined(with: .opacity))
                } else if mood == .tryAgain {
                    Text("👍")
                        .font(.system(size: size * 0.22))
                        .offset(x: size * 0.05)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(TVTheme.Motion.pop, value: mood)
        .animation(TVTheme.Motion.gentle, value: spokenText)
        .onAppear {
            guard ambientMotionEnabled, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isBobbing = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Buddy says: \(spokenText)")
        .accessibilityIdentifier("buddy")
    }

    /// Same tilt language as Part A: a wave for happy, a wiggle for celebrating.
    private var rotation: Double {
        switch mood {
        case .idle: return 0
        case .happy: return 6
        case .correct: return 8
        case .tryAgain: return -6
        }
    }

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Buddy")
                .font(.system(size: max(22, size * 0.09), weight: .semibold, design: .rounded))
                .foregroundStyle(TVTheme.Palette.animalsGreen)
            Text(spokenText)
                .font(.system(size: max(26, size * 0.12), weight: .medium, design: .rounded))
                .foregroundStyle(TVTheme.Palette.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .frame(maxWidth: max(size * 1.6, 320), alignment: .leading)
        .background(TVTheme.Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner * 0.8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner * 0.8, style: .continuous)
                .stroke(TVTheme.Palette.cardStroke, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
}
