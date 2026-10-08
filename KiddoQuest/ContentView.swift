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
        WelcomeView {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                hasSeenIntro = true
                showWelcomeScreen = false
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

// MARK: - Welcome Screen
/// The first-launch screen. Fits as designed, or a little smaller / scrollable on short screens.
struct WelcomeView: View, CompactAdaptable {
    let onBegin: () -> Void
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false

    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()

            FitsOrScrolls {
                CompactLayoutReader { compact($0).content }
            }
        }
    }

    private var content: some View {
        VStack(spacing: isCompact ? 16 : 32) {
            Spacer(minLength: 0)

            // Animated App Logo / Mascot
            VStack(spacing: isCompact ? 8 : 16) {
                ZStack {
                    Circle()
                        .fill(Theme.ColorPalette.numbersYellow.opacity(0.3))
                        .frame(width: AdaptiveMetric.size(140, compact: isCompact), height: AdaptiveMetric.size(140, compact: isCompact))

                    Text("🦉")
                        .font(.system(size: AdaptiveMetric.size(72, compact: isCompact)))
                }

                Text("KiddoQuest")
                    .font(Theme.Typography.title(size: 40))
                    .foregroundStyle(Theme.ColorPalette.primaryText)

                Text("Play • Learn • Discover!")
                    .font(Theme.Typography.headline(size: 22))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            }

            Spacer(minLength: 0)

            // "Let's Begin!" Primary Child Button
            PrimaryChildButton(
                title: "Let's Begin!",
                iconName: "sparkles",
                backgroundColor: Theme.ColorPalette.animalsGreen,
                action: onBegin
            )
            .frame(maxWidth: Theme.Layout.maxCardWidth)
            .padding(.horizontal, 32)
            .padding(.bottom, isCompact ? 16 : 48)
        }
        .padding(.top, isCompact ? 16 : 0)
    }
}
