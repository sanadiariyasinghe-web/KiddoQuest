import SwiftUI

// MARK: - Primary Child Button
// Designed specifically for children aged 3–7 with large touch target (>60pt),
// bold rounded typography, playful colors, and bouncy spring press feedback.

struct PrimaryChildButton: View {
    var title: String
    var iconName: String? = nil
    var backgroundColor: Color = Theme.ColorPalette.animalsGreen
    var foregroundColor: Color = .white
    var minHeight: CGFloat = 64
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                }
                
                Text(LocalizedStringKey(title))
                    .font(Theme.Typography.headline(size: 20))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .shadow(color: backgroundColor.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryChildButton(title: "Play Now!", iconName: "play.circle.fill") { }
        PrimaryChildButton(title: "Try Again", iconName: "arrow.counterclockwise", backgroundColor: Theme.ColorPalette.numbersYellow) { }
    }
    .padding()
}
