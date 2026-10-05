import SwiftUI

struct GameListView: View {
    let category: IslandCategory
    @Binding var navigationPath: NavigationPath
    
    // Filter sample games for this category
    var gamesForCategory: [GameInfo] {
        GameInfo.sampleGames.filter { $0.category == category }
    }
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Header Subtitle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose a Mini-Game")
                                .font(Theme.Typography.title(size: 24))
                                .foregroundStyle(Theme.ColorPalette.primaryText)
                            Text("Tap any adventure to start playing!")
                                .font(Theme.Typography.body(size: 15))
                                .foregroundStyle(Theme.ColorPalette.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    // Responsive Grid of Game Cards
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 280, maximum: 360), spacing: Theme.Spacing.medium)
                        ],
                        spacing: Theme.Spacing.medium
                    ) {
                        ForEach(gamesForCategory) { game in
                            GameCard(game: game) {
                                navigationPath.append(AppRoute.gamePlay(game))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                }
                .padding(.vertical, Theme.Spacing.medium)
            }
        }
        .navigationTitle("\(category.rawValue) Games")
        .navigationBarTitleDisplayMode(.inline)
    }
}
