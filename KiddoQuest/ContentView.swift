import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @AppStorage("has_seen_intro") private var hasSeenIntro: Bool = false
    @State private var showWelcomeScreen: Bool = true
    
    var body: some View {
        Group {
            if showWelcomeScreen && !hasSeenIntro {
                welcomeStartupView
            } else {
                mainNavigationView
            }
        }
    }
    
    // MARK: - App Startup Screen (Section 33)
    private var welcomeStartupView: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated App Logo / Mascot
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.ColorPalette.numbersYellow.opacity(0.3))
                            .frame(width: 140, height: 140)
                        
                        Text("🦉")
                            .font(.system(size: 72))
                    }
                    
                    Text("KiddoQuest")
                        .font(Theme.Typography.title(size: 40))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    
                    Text("Play • Learn • Discover!")
                        .font(Theme.Typography.headline(size: 22))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                }
                
                Spacer()
                
                // "Let's Begin!" Primary Child Button
                PrimaryChildButton(
                    title: "Let's Begin!",
                    iconName: "sparkles",
                    backgroundColor: Theme.ColorPalette.animalsGreen
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        hasSeenIntro = true
                        showWelcomeScreen = false
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
    
    // MARK: - Main NavigationStack
    private var mainNavigationView: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .category(let category):
                        CategoryView(category: category, navigationPath: $navigationPath)
                    case .gameList(let category):
                        GameListView(category: category, navigationPath: $navigationPath)
                    case .gamePlay(let game):
                        GamePlayView(game: game, navigationPath: $navigationPath)
                    case .rewards:
                        RewardView(navigationPath: $navigationPath)
                    case .profile:
                        ProfileView(navigationPath: $navigationPath)
                    case .parentSettings:
                        ParentSettingsView(navigationPath: $navigationPath)
                    case .arLearning:
                        ARLearningView(navigationPath: $navigationPath)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
