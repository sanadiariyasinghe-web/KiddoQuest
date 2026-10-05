import SwiftUI

/// Thick, high-contrast progress bar readable from across the room.
struct TVProgressBar: View {
    /// Progress between 0 and 1. Out-of-range values are clamped.
    let value: Double
    var tint: Color = TVTheme.Palette.success
    var height: CGFloat = 22

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(1, max(0, value.isFinite ? value : 0)) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(TVTheme.Palette.subtle)
                Capsule()
                    .fill(LinearGradient(colors: [tint.mix(with: .white, by: 0.3), tint], startPoint: .top, endPoint: .bottom))
                    .frame(width: max(height, proxy.size.width * clamped))
                    .opacity(clamped > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: clamped)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}
