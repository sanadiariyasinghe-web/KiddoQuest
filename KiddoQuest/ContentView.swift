import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @AppStorage("has_seen_intro") private var hasSeenIntro: Bool = false
    @State private var showWelcomeScreen: Bool = true
    @State private var playTime = PlayTimeTracker.shared
    @State private var shortcuts = ShortcutRouter.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    /// How often the daily play-time clock is updated while the app is open.
    private let playTimeCheckInterval: Duration = .seconds(20)
    
    var body: some View {
        ZStack {
            Group {
                if showWelcomeScreen && !hasSeenIntro {
                    welcomeStartupView
                } else {
                    mainNavigationView
                }
            }
            // Theme fonts are sized from Dynamic Type, so redraw when the text size changes
            // (the navigation path lives here, so the child stays on the same screen)
            .id(dynamicTypeSize)
            .accessibilityHidden(playTime.isLimitReached)
            
            // Daily limit reached: a calm break screen covers the whole app
            if playTime.isLimitReached {
                BreakTimeView {
                    withAnimation(.easeInOut) {
                        playTime.unlockForToday()
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: playTime.isLimitReached)
        // Siri / Shortcuts: jump straight to the requested island or game
        .onChange(of: shortcuts.pendingRoute, initial: true) { _, route in
            guard let route else { return }
            showWelcomeScreen = false
            hasSeenIntro = true
            var path = NavigationPath()
            path.append(route)
            navigationPath = path
            shortcuts.pendingRoute = nil
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: playTimeCheckInterval)
                playTime.tick()
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
