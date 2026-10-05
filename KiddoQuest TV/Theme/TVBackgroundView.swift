import SwiftUI

/// Child-friendly sky backdrop shared by every screen — the same gradient
/// and drifting clouds as the iOS app's Home screen (Part A).
///
/// When `isAnimated` is true a handful of soft shapes drift slowly. The
/// count is deliberately small and each shape only animates a transform,
/// which keeps GPU cost low on Apple TV. Motion is disabled entirely when
/// the viewer has Reduce Motion turned on.
struct TVBackgroundView: View {
    var isAnimated: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tvAmbientMotionEnabled) private var ambientMotionEnabled
    @State private var isDrifting = false

    private struct Decoration: Identifiable {
        let id: Int
        let symbol: String
        let color: Color
        let size: CGFloat
        let position: UnitPoint
        let drift: CGSize
        let duration: Double
    }

    private let decorations: [Decoration] = [
        // Part A-style clouds.
        Decoration(id: 0, symbol: "cloud.fill", color: .white, size: 150, position: UnitPoint(x: 0.08, y: 0.07), drift: CGSize(width: 40, height: 0), duration: 6),
        Decoration(id: 1, symbol: "cloud.fill", color: .white, size: 110, position: UnitPoint(x: 0.9, y: 0.06), drift: CGSize(width: -40, height: 0), duration: 7),
        Decoration(id: 2, symbol: "cloud.fill", color: .white, size: 90, position: UnitPoint(x: 0.55, y: 0.97), drift: CGSize(width: 30, height: 0), duration: 8),
        // Soft category shapes in the corners.
        Decoration(id: 3, symbol: "star.fill", color: TVTheme.Palette.star, size: 60, position: UnitPoint(x: 0.03, y: 0.94), drift: CGSize(width: 14, height: -12), duration: 6),
        Decoration(id: 4, symbol: "triangle.fill", color: TVTheme.Palette.shapesPurple, size: 80, position: UnitPoint(x: 0.97, y: 0.93), drift: CGSize(width: -14, height: -14), duration: 7)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [TVTheme.Palette.backgroundTop, TVTheme.Palette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ForEach(decorations) { item in
                    Image(systemName: item.symbol)
                        .font(.system(size: item.size))
                        .foregroundStyle(item.color.opacity(item.symbol == "cloud.fill" ? 0.45 : 0.18))
                        .position(
                            x: proxy.size.width * item.position.x,
                            y: proxy.size.height * item.position.y
                        )
                        .offset(isDrifting ? item.drift : .zero)
                        .animation(
                            isDrifting
                                ? .easeInOut(duration: item.duration).repeatForever(autoreverses: true)
                                : .default,
                            value: isDrifting
                        )
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            isDrifting = isAnimated && ambientMotionEnabled && !reduceMotion
        }
        .onDisappear {
            // Stop the repeating animation when the screen is off-stage.
            isDrifting = false
        }
    }
}

extension View {
    /// Places the shared KiddoQuest TV backdrop behind a full screen.
    func tvScreenBackground(animated: Bool = false) -> some View {
        background { TVBackgroundView(isAnimated: animated) }
    }
}
