import SwiftUI

// MARK: - Floating Animation Modifier
// Provides gentle, playful bobbing and floating effect for cards, mascots, and icons.
// Stays still when Calm Mode (or system Reduce Motion) is on.

struct FloatingAnimationModifier: ViewModifier {
    var yOffset: CGFloat = 8
    var duration: Double = 2.2
    var delay: Double = 0

    @State private var isFloating = false
    @CalmModeEnabled private var isCalm

    func body(content: Content) -> some View {
        content
            .offset(y: isCalm ? 0 : (isFloating ? -yOffset : yOffset))
            .animation(
                isCalm ? nil : Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

extension View {
    func floating(yOffset: CGFloat = 8, duration: Double = 2.2, delay: Double = 0) -> some View {
        modifier(FloatingAnimationModifier(yOffset: yOffset, duration: duration, delay: delay))
    }
}
