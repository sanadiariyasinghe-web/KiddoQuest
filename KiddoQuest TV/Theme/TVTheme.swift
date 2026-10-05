import SwiftUI

/// Design tokens for KiddoQuest TV.
///
/// Every size here is tuned for "10-foot" viewing on a 1920 × 1080 point
/// television canvas, so values are intentionally much larger than the
/// iOS Part A theme rather than being a scaled copy of it.
nonisolated enum TVTheme {

    // MARK: - Colour

    /// Same palette values as the iOS app's `Theme.ColorPalette` (Part A),
    /// including its light / dark adaptive surfaces, so both apps look like
    /// one product. Only sizes differ for the 10-foot TV experience.
    enum Palette {
        // Category colours — identical to Part A.
        static let numbersYellow = Color(red: 1.00, green: 0.78, blue: 0.20)
        static let lettersBlue = Color(red: 0.28, green: 0.65, blue: 0.95)
        static let shapesPurple = Color(red: 0.68, green: 0.42, blue: 0.92)
        static let animalsGreen = Color(red: 0.35, green: 0.78, blue: 0.45)

        // Semantic colours — identical to Part A.
        static let success = Color(red: 0.20, green: 0.80, blue: 0.45)
        static let star = Color(red: 1.00, green: 0.84, blue: 0.00)
        static let softRed = Color(red: 0.95, green: 0.40, blue: 0.40)
        /// Part A's AR orange, used for gentle "try again" feedback.
        static let gentle = Color(red: 1.00, green: 0.55, blue: 0.25)

        // TV-only feature colours, chosen to sit inside the Part A palette.
        static let familyCoral = Color(red: 0.95, green: 0.45, blue: 0.45)
        static let buddyOrange = Color(red: 1.00, green: 0.55, blue: 0.25)

        // Adaptive surfaces — identical to Part A's light / dark values.
        static let backgroundTop = adaptive(light: (0.88, 0.95, 1.00, 1), dark: (0.10, 0.12, 0.22, 1))
        static let backgroundBottom = adaptive(light: (0.96, 0.98, 1.00, 1), dark: (0.05, 0.06, 0.14, 1))
        static let card = adaptive(light: (1, 1, 1, 1), dark: (0.16, 0.18, 0.28, 0.95))
        static let cardStroke = adaptive(light: (0, 0, 0, 0.06), dark: (1, 1, 1, 0.12))
        static let textPrimary = adaptive(light: (0.15, 0.18, 0.25, 1), dark: (1, 1, 1, 1))
        static let textSecondary = adaptive(light: (0.40, 0.45, 0.55, 1), dark: (0.8, 0.8, 0.8, 1))

        /// Neutral fill for chips, progress tracks and empty states.
        static let subtle = adaptive(light: (0, 0, 0, 0.06), dark: (1, 1, 1, 0.12))
        /// Low-emphasis strokes, dashed outlines and empty stars.
        static let muted = adaptive(light: (0.40, 0.45, 0.55, 0.45), dark: (1, 1, 1, 0.4))
        /// Dark text used on top of bright filled colours.
        static let ink = Color(red: 0.12, green: 0.14, blue: 0.22)

        private static func adaptive(
            light: (CGFloat, CGFloat, CGFloat, CGFloat),
            dark: (CGFloat, CGFloat, CGFloat, CGFloat)
        ) -> Color {
            Color(uiColor: UIColor { traits in
                let c = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(red: c.0, green: c.1, blue: c.2, alpha: c.3)
            })
        }
    }

    // MARK: - Layout

    enum Metrics {
        static let screenPadding: CGFloat = 80
        static let sectionSpacing: CGFloat = 48
        static let itemSpacing: CGFloat = 40
        // Part A radii (card 20, button 22, large 28) scaled ~1.6× for TV.
        static let cardCorner: CGFloat = 36
        static let buttonCorner: CGFloat = 36
        static let focusScale: CGFloat = 1.08
        static let focusBorderWidth: CGFloat = 8
        static let restingBorderWidth: CGFloat = 3
    }

    // MARK: - Typography

    enum Typography {
        static let hero = Font.system(size: 120, weight: .heavy, design: .rounded)
        static let screenTitle = Font.system(size: 76, weight: .heavy, design: .rounded)
        static let title = Font.system(size: 56, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 42, weight: .bold, design: .rounded)
        static let body = Font.system(size: 34, weight: .semibold, design: .rounded)
        static let caption = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let answer = Font.system(size: 96, weight: .heavy, design: .rounded)
        static let gameObject = Font.system(size: 120)
    }

    // MARK: - Motion

    enum Motion {
        static let focus = Animation.spring(response: 0.30, dampingFraction: 0.72)
        static let pop = Animation.spring(response: 0.45, dampingFraction: 0.55)
        static let gentle = Animation.easeInOut(duration: 0.35)
        static let entrance = Animation.spring(response: 0.55, dampingFraction: 0.78)
    }
}
