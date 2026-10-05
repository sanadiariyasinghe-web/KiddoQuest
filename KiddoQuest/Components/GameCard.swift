import SwiftUI

// MARK: - Reusable GameCard Component
// Child-friendly card displaying game information, stars, and completion state.

struct GameCard: View {
    let game: GameInfo
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Game Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(game.category.themeColor.opacity(0.2))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: game.iconName)
                        .font(.system(size: 32))
                        .foregroundStyle(game.category.themeColor)
                }
                
                // Game Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.title)
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    
                    Text(game.description)
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Star rating and completion
                    HStack(spacing: 8) {
                        ProgressStarBar(
                            stars: game.starsEarned,
                            maxStars: 3,
                            progressPercentage: game.completionPercentage,
                            starSize: 13,
                            showBackground: false
                        )
                    }
                }
                
                Spacer()
                
                // Navigation indicator or lock
                Image(systemName: game.isUnlocked ? "chevron.right.circle.fill" : "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(game.isUnlocked ? game.category.themeColor : Theme.ColorPalette.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.ColorPalette.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(game.title), \(game.starsEarned) stars earned, \(game.completionPercentage) percent complete")
    }
}
