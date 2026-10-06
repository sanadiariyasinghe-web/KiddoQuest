import SwiftUI

// MARK: - Pointing-hand hints (same idea as the iOS app)
//
// Games mark the correct answer with `.tvHintTarget(true)` and report answer
// activity with `.tvHintActivity(_:)`. `TVHintOverlay` then shows a friendly 👆
// over the right answer shortly after play starts and again after 8 seconds
// without an answer.

/// Carries the bounds of the current hint target up to the game container.
struct TVHintTargetKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// A number that changes whenever the child answers (right or wrong).
struct TVHintActivityKey: PreferenceKey {
    static let defaultValue = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = max(value, nextValue())
    }
}

extension View {
    /// Marks this view as the place the pointing hand should point to.
    func tvHintTarget(_ isActive: Bool) -> some View {
        anchorPreference(key: TVHintTargetKey.self, value: .bounds) { isActive ? $0 : nil }
    }

    /// Reports how many answers have been given, so the hint knows the child is busy.
    func tvHintActivity(_ answersGiven: Int) -> some View {
        preference(key: TVHintActivityKey.self, value: answersGiven)
    }
}

/// The animated hand: presses twice with a ripple, like pressing the remote.
struct TVHintHandView: View {
    @State private var isPressing = false
    @State private var rippleScale: CGFloat = 0.4
    @State private var rippleOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(TVTheme.Palette.star, lineWidth: 8)
                .frame(width: 120, height: 120)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)

            Text("👆")
                .font(.system(size: 110))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                .offset(x: 30, y: isPressing ? 40 : 75)
                .scaleEffect(isPressing ? 0.9 : 1)
        }
        .frame(width: 120, height: 120)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            for _ in 0..<2 {
                withAnimation(.easeInOut(duration: 0.35)) { isPressing = true }
                rippleScale = 0.4
                rippleOpacity = 0.9
                withAnimation(.easeOut(duration: 0.6)) {
                    rippleScale = 1.5
                    rippleOpacity = 0
                }
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.easeInOut(duration: 0.35)) { isPressing = false }
                try? await Task.sleep(for: .seconds(0.55))
            }
        }
    }
}

/// Shows the hint hand over the marked answer at the start and after idle periods.
struct TVHintOverlay: ViewModifier {
    @Environment(\.tvAmbientMotionEnabled) private var isMotionEnabled

    @State private var isShowingHint = false
    @State private var lastActivity = ContinuousClock.now

    private let firstHintDelay: Duration = .seconds(1.2)
    private let idleHintDelay: Duration = .seconds(8)
    private let hintDuration: Duration = .seconds(2.4)

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(TVHintTargetKey.self) { anchor in
                GeometryReader { proxy in
                    if isShowingHint, let anchor {
                        let target = proxy[anchor]
                        TVHintHandView()
                            .position(x: target.midX, y: target.midY)
                            .transition(.opacity)
                    }
                }
            }
            .backgroundPreferenceValue(TVHintActivityKey.self) { answersGiven in
                // Any answer counts as activity and hides a hint that is showing.
                Color.clear.onChange(of: answersGiven) { _, _ in
                    lastActivity = .now
                    if isShowingHint {
                        withAnimation(.easeOut(duration: 0.2)) { isShowingHint = false }
                    }
                }
            }
            .task {
                // Looping hints are skipped when ambient motion is off (UI tests).
                guard isMotionEnabled else { return }
                try? await Task.sleep(for: firstHintDelay)
                await showHint()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    if ContinuousClock.now - lastActivity >= idleHintDelay {
                        await showHint()
                    }
                }
            }
    }

    private func showHint() async {
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: 0.25)) { isShowingHint = true }
        try? await Task.sleep(for: hintDuration)
        withAnimation(.easeOut(duration: 0.25)) { isShowingHint = false }
        lastActivity = .now
    }
}

extension View {
    /// Adds pointing-hand hints to a game screen.
    func tvHintOverlay() -> some View {
        modifier(TVHintOverlay())
    }
}
