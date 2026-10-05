import SwiftUI

// MARK: - Floating Animation Modifier
// Provides gentle, playful bobbing and floating effect for cards, mascots, and icons.

struct FloatingAnimationModifier: ViewModifier {
    var yOffset: CGFloat = 8
    var duration: Double = 2.2
    var delay: Double = 0
    
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -yOffset : yOffset)
            .animation(
                Animation.easeInOut(duration: duration)
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
