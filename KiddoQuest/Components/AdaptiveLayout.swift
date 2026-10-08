import SwiftUI

// MARK: - Adaptive Layout Helpers
// Keep every screen usable on small iPhones, in landscape and with large Dynamic Type,
// without changing how it looks when there is enough room.

extension EnvironmentValues {
    /// True when a screen is being laid out in its space-saving form
    /// (big pictures and gaps are scaled down a little so everything fits).
    @Entry var isCompactLayout = false
}

/// Shows `content` in three steps, using the first one that fits the available height:
/// 1. exactly as designed,
/// 2. compact (views that read `isCompactLayout` shrink their big pictures and gaps),
/// 3. compact and vertically scrollable, so nothing is ever clipped.
struct FitsOrScrolls<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            content
                .environment(\.isCompactLayout, true)
            ScrollView(.vertical) {
                content
                    .environment(\.isCompactLayout, true)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

extension View {
    /// Wraps the view in `FitsOrScrolls`.
    func scrollsWhenNeeded() -> some View {
        FitsOrScrolls { self }
    }
}

enum AdaptiveMetric {
    /// Scale for big pictures, canvases and cards in the compact layout.
    static let compactScale: CGFloat = 0.72

    /// `value` as designed, or scaled down in the compact layout.
    static func size(_ value: CGFloat, compact isCompact: Bool) -> CGFloat {
        isCompact ? (value * compactScale).rounded() : value
    }
}

/// Reads `isCompactLayout` *inside* a `FitsOrScrolls` branch and hands it to `content`.
/// (A game builds its board in its own computed properties, which would otherwise read
/// the environment from outside the branch.)
struct CompactLayoutReader<Content: View>: View {
    @Environment(\.isCompactLayout) private var isCompact
    @ViewBuilder var content: (Bool) -> Content

    var body: some View {
        content(isCompact)
    }
}

/// A game screen whose board can be laid out compactly.
protocol CompactAdaptable {
    var isCompact: Bool { get set }
}

extension CompactAdaptable {
    /// A copy of this screen laid out compactly or not (state is shared with the original).
    func compact(_ isCompact: Bool) -> Self {
        var copy = self
        copy.isCompact = isCompact
        return copy
    }
}

/// The standard game screen: the stage (question + play area) above the controls
/// (Buddy + answer buttons). On short, wide screens (iPhone landscape) the two sit
/// side by side so the answers stay on screen. Portrait keeps the exact designed order
/// and spacing, because both groups are flattened into one stack.
struct GameScreenLayout<Stage: View, Controls: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let spacing: CGFloat
    @ViewBuilder var stage: Stage
    @ViewBuilder var controls: Controls

    var body: some View {
        if verticalSizeClass == .compact {
            HStack(alignment: .center, spacing: Theme.Spacing.large) {
                VStack(spacing: spacing) { stage }
                    .frame(maxWidth: .infinity)
                VStack(spacing: spacing) { controls }
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, Theme.Spacing.small)
        } else {
            VStack(spacing: spacing) {
                stage
                controls
            }
        }
    }
}
