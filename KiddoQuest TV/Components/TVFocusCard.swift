import SwiftUI

/// A large rounded card that can receive Siri Remote focus.
///
/// With an `action` it behaves as a button. Without one it is still
/// focusable, so information panels (such as dashboard cards) can be
/// browsed and scrolled with the remote.
struct TVFocusCard<Content: View>: View {
    var tint: Color = TVTheme.Palette.lettersBlue
    var cornerRadius: CGFloat = TVTheme.Metrics.cardCorner
    var focusScale: CGFloat = TVTheme.Metrics.focusScale
    var action: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        if let action {
            Button(action: action) {
                content()
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .tvCardButtonStyle(tint: tint, cornerRadius: cornerRadius, focusScale: focusScale)
        } else {
            TVFocusablePanel(tint: tint, cornerRadius: cornerRadius, focusScale: focusScale, content: content)
        }
    }
}

/// Focusable, non-actionable variant of `TVFocusCard`.
private struct TVFocusablePanel<Content: View>: View {
    let tint: Color
    let cornerRadius: CGFloat
    let focusScale: CGFloat
    @ViewBuilder var content: () -> Content

    @FocusState private var isFocused: Bool

    var body: some View {
        content()
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(TVTheme.Palette.card)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isFocused ? tint.opacity(0.2) : .clear)
                }
            }
            .focusable()
            .focused($isFocused)
            .modifier(TVFocusEffect(isFocused: isFocused, tint: tint, cornerRadius: cornerRadius, focusScale: focusScale))
            .accessibilityElement(children: .combine)
    }
}
