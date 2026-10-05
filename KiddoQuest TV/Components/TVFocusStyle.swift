import SwiftUI

/// The single focus treatment used by every interactive element, so focus
/// always looks the same and is always obvious from across the room.
/// At rest a card looks like a Part A (iOS) card: a soft tinted border and
/// shadow. When focused it scales up and gains a thick tint border and glow.
/// The border width change means focus never relies on colour alone.
struct TVFocusEffect: ViewModifier {
    let isFocused: Bool
    var isPressed: Bool = false
    var tint: Color = TVTheme.Palette.lettersBlue
    var cornerRadius: CGFloat = TVTheme.Metrics.cardCorner
    var focusScale: CGFloat = TVTheme.Metrics.focusScale

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .overlay {
                shape.strokeBorder(
                    isFocused ? tint : tint.opacity(0.4),
                    lineWidth: isFocused ? TVTheme.Metrics.focusBorderWidth : TVTheme.Metrics.restingBorderWidth
                )
            }
            .shadow(color: isFocused ? tint.opacity(0.6) : tint.opacity(0.2), radius: isFocused ? 34 : 14, y: isFocused ? 16 : 7)
            .scaleEffect(isPressed ? focusScale * 0.96 : (isFocused ? focusScale : 1))
            .zIndex(isFocused ? 1 : 0)
            .animation(reduceMotion ? .easeInOut(duration: 0.12) : TVTheme.Motion.focus, value: isFocused)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

/// Visual weight of a focusable control.
enum TVButtonProminence {
    /// Solid tint fill with dark text (for bright tints such as yellow).
    case filled
    /// Translucent card that tints up when focused.
    case card
}

/// Button style that applies `TVFocusEffect` and a subtle focus sound.
struct TVCardButtonStyle: ButtonStyle {
    var tint: Color = TVTheme.Palette.lettersBlue
    var prominence: TVButtonProminence = .card
    var cornerRadius: CGFloat = TVTheme.Metrics.cardCorner
    var focusScale: CGFloat = TVTheme.Metrics.focusScale

    func makeBody(configuration: Configuration) -> some View {
        TVCardButtonBody(
            configuration: configuration,
            tint: tint,
            prominence: prominence,
            cornerRadius: cornerRadius,
            focusScale: focusScale
        )
    }
}

private struct TVCardButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let tint: Color
    let prominence: TVButtonProminence
    let cornerRadius: CGFloat
    let focusScale: CGFloat

    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled
    @Environment(TVSoundService.self) private var sound: TVSoundService?

    var body: some View {
        configuration.label
            .foregroundStyle(prominence == .filled ? TVTheme.Palette.ink : TVTheme.Palette.textPrimary)
            .background {
                ZStack {
                    // Opaque card base so tinted focus washes stay readable.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(TVTheme.Palette.card)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fill)
                }
            }
            .modifier(
                TVFocusEffect(
                    isFocused: isFocused,
                    isPressed: configuration.isPressed,
                    tint: tint,
                    cornerRadius: cornerRadius,
                    focusScale: focusScale
                )
            )
            .opacity(isEnabled ? 1 : 0.45)
            .onChange(of: isFocused) { _, focused in
                if focused { sound?.play(.focus) }
            }
    }

    private var fill: AnyShapeStyle {
        switch prominence {
        case .filled:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [tint.mix(with: .white, by: isFocused ? 0.25 : 0.05), tint],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .card:
            // Part A card surface, washed with the tint when focused.
            return AnyShapeStyle(isFocused ? tint.opacity(0.22) : Color.clear)
        }
    }
}

extension View {
    /// Applies the shared KiddoQuest TV focus look to a button.
    func tvCardButtonStyle(
        tint: Color = TVTheme.Palette.lettersBlue,
        prominence: TVButtonProminence = .card,
        cornerRadius: CGFloat = TVTheme.Metrics.cardCorner,
        focusScale: CGFloat = TVTheme.Metrics.focusScale
    ) -> some View {
        buttonStyle(TVCardButtonStyle(tint: tint, prominence: prominence, cornerRadius: cornerRadius, focusScale: focusScale))
    }
}
