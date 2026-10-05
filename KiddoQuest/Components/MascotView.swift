import SwiftUI

// MARK: - Reusable Animated Mascot: "Buddy"
// Friendly owl buddy that encourages children, waves, celebrates, and guides them.

enum MascotMood {
    case idle
    case waving
    case celebrating
    case encouraging
    
    var speechBubbleText: String {
        switch self {
        case .idle:
            return "Hi there, Explorer! Let's play!"
        case .waving:
            return "Welcome back! Ready for fun?"
        case .celebrating:
            return "Awesome! You did it! ⭐"
        case .encouraging:
            return "Almost! Let's try one more time! 🌟"
        }
    }
    
    var emoji: String {
        switch self {
        case .idle: return "🦉"
        case .waving: return "🦉"
        case .celebrating: return "🥳"
        case .encouraging: return "✨🦉"
        }
    }
}

struct MascotView: View {
    var mood: MascotMood = .idle
    var customMessage: String? = nil
    var showSpeechBubble: Bool = true
    var size: CGFloat = 80
    
    @State private var bounceOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Mascot Character Avatar
            ZStack {
                Circle()
                    .fill(Theme.ColorPalette.numbersYellow.opacity(0.25))
                    .frame(width: size, height: size)
                
                Text("🦉")
                    .font(.system(size: size * 0.65))
                    .offset(y: bounceOffset)
                    .rotationEffect(.degrees(rotationAngle))
            }
            .accessibilityHidden(true)
            
            // Speech Bubble
            if showSpeechBubble {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buddy")
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.ColorPalette.animalsGreen)
                    
                    Text(customMessage ?? mood.speechBubbleText)
                        .font(Theme.Typography.body(size: 15))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Theme.ColorPalette.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            }
        }
        .onAppear {
            applyMoodAnimation()
        }
        .onChange(of: mood) { _, _ in
            applyMoodAnimation()
        }
    }
    
    private func applyMoodAnimation() {
        switch mood {
        case .idle:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bounceOffset = -6
                rotationAngle = 0
            }
        case .waving:
            withAnimation(.easeInOut(duration: 0.5).repeatCount(4, autoreverses: true)) {
                rotationAngle = 10
            }
        case .celebrating:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).repeatCount(3, autoreverses: true)) {
                bounceOffset = -14
                rotationAngle = 8
            }
        case .encouraging:
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bounceOffset = -4
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MascotView(mood: .idle)
        MascotView(mood: .celebrating)
        MascotView(mood: .encouraging)
    }
    .padding()
}
