import SwiftUI

// MARK: - Theme Design System for KiddoQuest
// High-contrast, child-friendly, rounded design system supporting both Light & Dark modes.

enum Theme {
    // MARK: - Colors
    enum ColorPalette {
        // Vibrant, friendly colors for learning islands
        static let numbersYellow = Color(red: 1.0, green: 0.78, blue: 0.20)
        static let lettersBlue = Color(red: 0.28, green: 0.65, blue: 0.95)
        static let shapesPurple = Color(red: 0.68, green: 0.42, blue: 0.92)
        static let animalsGreen = Color(red: 0.35, green: 0.78, blue: 0.45)
        static let arOrange = Color(red: 1.0, green: 0.55, blue: 0.25)
        
        // Semantic colors
        static let successGreen = Color(red: 0.20, green: 0.80, blue: 0.45)
        static let softRedWarning = Color(red: 0.95, green: 0.40, blue: 0.40)
        static let starGold = Color(red: 1.0, green: 0.84, blue: 0.0)
        
        // Adaptive Backgrounds
        static var mainBackground: LinearGradient {
            LinearGradient(
                colors: [
                    Color(uiColor: UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.10, green: 0.12, blue: 0.22, alpha: 1.0)
                        : UIColor(red: 0.88, green: 0.95, blue: 1.0, alpha: 1.0)
                    }),
                    Color(uiColor: UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.05, green: 0.06, blue: 0.14, alpha: 1.0)
                        : UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0)
                    })
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        static var cardBackground: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.18, blue: 0.28, alpha: 0.95)
                : UIColor.white
            })
        }
        
        static var cardBorder: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.12)
                : UIColor.black.withAlphaComponent(0.06)
            })
        }
        
        static var primaryText: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0)
            })
        }
        
        static var secondaryText: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.8, alpha: 1.0)
                : UIColor(red: 0.40, green: 0.45, blue: 0.55, alpha: 1.0)
            })
        }
    }
    
    // MARK: - Radius
    enum Radius {
        static let button: CGFloat = 22
        static let card: CGFloat = 20
        static let large: CGFloat = 28
        static let minimum: CGFloat = 16
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
    
    // MARK: - Typography
    enum Typography {
        static func title(size: CGFloat = 28) -> Font {
            .system(size: size, weight: .heavy, design: .rounded)
        }
        
        static func headline(size: CGFloat = 22) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func body(size: CGFloat = 18) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        
        static func caption(size: CGFloat = 14) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
    }
}
