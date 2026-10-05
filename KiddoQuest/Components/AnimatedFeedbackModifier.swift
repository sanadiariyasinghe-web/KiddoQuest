import SwiftUI

// MARK: - Animated Feedback Modifier
// Provides gentle, encouraging visual feedback for correct answers and friendly "try again" moments.
// Never uses harsh or jarring effects.

struct AnimatedFeedbackModifier: ViewModifier {
    var isSuccess: Bool
    var isGentleRetry: Bool
    
    @State private var shakeOffset: CGFloat = 0
    @State private var successScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(successScale)
            .offset(x: shakeOffset)
            .onChange(of: isSuccess) { _, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        successScale = 1.12
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.25)) {
                        successScale = 1.0
                    }
                }
            }
            .onChange(of: isGentleRetry) { _, newValue in
                if newValue {
                    // Soft, gentle shake (never jarring)
                    withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) {
                        shakeOffset = 6
                    }
                    withAnimation(.easeInOut(duration: 0.08).delay(0.25)) {
                        shakeOffset = 0
                    }
                }
            }
    }
}

extension View {
    func animatedFeedback(isSuccess: Bool, isGentleRetry: Bool) -> some View {
        modifier(AnimatedFeedbackModifier(isSuccess: isSuccess, isGentleRetry: isGentleRetry))
    }
}
