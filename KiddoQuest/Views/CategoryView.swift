import SwiftUI

struct CategoryView: View {
    let category: IslandCategory
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            ScrollView {
                // iPhone landscape: island card left, Buddy + Play button right (no scrolling needed)
                GameScreenLayout(spacing: Theme.Spacing.large) {
                    // Island Hero Card
                    VStack(spacing: Theme.Spacing.medium) {
                        ZStack {
                            Circle()
                                .fill(category.themeColor.opacity(0.3))
                                .frame(width: 120, height: 120)
                            
                            Text(category.icon)
                                .font(.system(size: 64))
                        }
                        
                        Text(category.title)
                            .font(Theme.Typography.title(size: 30))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                        
                        Text("Welcome to \(category.rawValue)! Let's play friendly games and earn shiny stars together.")
                            .font(Theme.Typography.body(size: 16))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.large)
                            .stroke(category.themeColor.opacity(0.3), lineWidth: 3)
                    )
                    .shadow(color: category.themeColor.opacity(0.15), radius: 12, y: 6)
                    
                } controls: {
                    // Mascot Encouragement Component
                    MascotView(
                        mood: .idle,
                        customMessage: "Ready to explore \(category.rawValue)? Tap below to choose your game!"
                    )
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    // Primary Action: Go to Game List
                    PrimaryChildButton(
                        title: "Play Island Games",
                        iconName: "play.circle.fill",
                        backgroundColor: category.themeColor
                    ) {
                        navigationPath.append(AppRoute.gameList(category))
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                }
                .padding(Theme.Spacing.medium)
                // Comfortable reading width on iPad and in landscape
                .frame(maxWidth: Theme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
