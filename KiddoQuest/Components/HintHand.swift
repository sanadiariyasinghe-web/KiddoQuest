import SwiftUI

// MARK: - Pointing-Hand Hints
// Games mark the element a child should tap with `.hintTarget(true)`.
// GameFlowContainer then shows a friendly 👆 tapping that spot when play starts
// and again whenever the child hasn't tapped anything for a while.

/// Carries the bounds of the current hint target up to the game container.
struct HintTargetKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        // Keep the first active target in the view tree
        value = value ?? nextValue()
    }
}

extension View {
    /// Marks this view as the place the pointing-hand hint should tap.
    func hintTarget(_ isActive: Bool) -> some View {
        anchorPreference(key: HintTargetKey.self, value: .bounds) { isActive ? $0 : nil }
    }
}

/// The animated hand: moves in, taps twice with a ripple, then fades.
struct HintHandView: View {
    var color: Color = Theme.ColorPalette.numbersYellow
    
    @State private var isPressing = false
    @State private var rippleScale: CGFloat = 0.4
    @State private var rippleOpacity: Double = 0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(width: 56, height: 56)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
            
            Text("👆")
                .font(.system(size: 52))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .offset(x: 10, y: isPressing ? 14 : 30)
                .scaleEffect(isPressing ? 0.9 : 1.0)
        }
        .frame(width: 56, height: 56)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            for _ in 0..<2 {
                withAnimation(.easeInOut(duration: 0.35)) { isPressing = true }
                rippleScale = 0.4
                rippleOpacity = 0.9
                withAnimation(.easeOut(duration: 0.6)) {
                    rippleScale = 1.4
                    rippleOpacity = 0
                }
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.easeInOut(duration: 0.35)) { isPressing = false }
                try? await Task.sleep(for: .seconds(0.55))
            }
        }
    }
}

#Preview {
    HintHandView()
        .padding(60)
}
