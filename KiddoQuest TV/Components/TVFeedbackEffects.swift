import SwiftUI

/// Horizontal "gentle shake" used for incorrect answers. Animate
/// `animatableData` by whole numbers to play one shake per increment.
nonisolated struct TVShakeEffect: GeometryEffect {
    var travel: CGFloat = 16
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * shakesPerUnit * 2)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// One-shot burst of stars and sparkles. Change `trigger` to fire it.
struct TVSparkleBurst: View {
    let trigger: Int
    var colors: [Color] = [TVTheme.Palette.star, TVTheme.Palette.success, TVTheme.Palette.familyCoral, TVTheme.Palette.lettersBlue]
    var particleCount: Int = 14
    var distance: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var isVisible = false

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = Double(index) / Double(particleCount) * 2 * .pi
                let reach = distance * (index.isMultiple(of: 2) ? 1 : 0.7)
                Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "star.fill")
                    .font(.system(size: index.isMultiple(of: 2) ? 44 : 30, weight: .bold))
                    .foregroundStyle(colors[index % colors.count])
                    .offset(
                        x: isExpanded ? cos(angle) * reach : 0,
                        y: isExpanded ? sin(angle) * reach : 0
                    )
                    .scaleEffect(isExpanded ? 0.6 : 1.2)
                    .opacity(isVisible ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: trigger) {
            // Trigger 0 is the initial state; only fire on later changes.
            guard trigger > 0 else { return }
            await fire()
        }
    }

    private func fire() async {
        guard !reduceMotion else { return }
        // Reset without animation, then expand on the next frame so the
        // burst replays every time rather than coalescing into one update.
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            isExpanded = false
            isVisible = true
        }
        try? await Task.sleep(for: .milliseconds(20))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.8)) {
            isExpanded = true
        }
        withAnimation(.easeIn(duration: 0.35).delay(0.55)) {
            isVisible = false
        }
    }
}

/// Large rounded banner for "Great job!" / "Almost! Try again!".
/// Uses an icon as well as colour so the meaning never relies on colour alone.
struct TVFeedbackBanner: View {
    enum Style {
        case success, gentle

        var color: Color {
            switch self {
            case .success: return TVTheme.Palette.success
            case .gentle: return TVTheme.Palette.gentle
            }
        }

        var symbol: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .gentle: return "arrow.counterclockwise.circle.fill"
            }
        }
    }

    let message: String
    let style: Style

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: style.symbol)
                .font(.system(size: 52, weight: .bold))
            Text(message)
                .font(TVTheme.Typography.title)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(TVTheme.Palette.ink)
        .padding(.horizontal, 48)
        .padding(.vertical, 22)
        .background(Capsule().fill(style.color))
        .shadow(color: style.color.opacity(0.6), radius: 24)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityIdentifier("feedback.banner")
    }
}
