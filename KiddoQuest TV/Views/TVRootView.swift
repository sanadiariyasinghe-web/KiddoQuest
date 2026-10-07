import SwiftUI

/// Hosts the NavigationStack and maps every route to its screen.
/// The Siri Remote Back (Menu) button pops one level at a time.
/// Also applies Calm Mode and shows the daily break screen.
struct TVRootView: View {
    @Environment(TVRouter.self) private var router
    @Environment(TVAppStore.self) private var store
    @Environment(TVSoundService.self) private var sound
    @Environment(TVPlayTimeTracker.self) private var playTime
    @Environment(\.tvAmbientMotionEnabled) private var baseAmbientMotion
    @Environment(\.scenePhase) private var scenePhase

    /// How often today's play time is updated while the app is open.
    private let playTimeCheckInterval: Duration = .seconds(20)

    var body: some View {
        @Bindable var router = router
        ZStack {
            NavigationStack(path: $router.path) {
                TVHomeView()
                    .navigationDestination(for: TVRoute.self) { route in
                        destination(for: route)
                    }
            }
            // Top Shelf shortcuts open straight into a game or island
            .onOpenURL { url in
                if let path = TVDeepLink.path(for: url, hasPlayer: store.selectedPlayer != nil) {
                    router.path = path
                }
            }
            .environment(\.tvAmbientMotionEnabled, baseAmbientMotion && !store.settings.calmMode)
            .environment(\.tvCalmMode, store.settings.calmMode)
            .disabled(playTime.isLimitReached)
            .accessibilityHidden(playTime.isLimitReached)

            // Daily limit reached: a calm break screen covers everything
            if playTime.isLimitReached {
                TVBreakTimeView {
                    playTime.unlockForToday()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(TVTheme.Motion.gentle, value: playTime.isLimitReached)
        .onChange(of: store.settings, initial: true) { _, settings in
            sound.apply(settings)
            playTime.setLimit(minutes: settings.dailyLimitMinutes)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                playTime.appBecameActive()
            } else {
                playTime.appBecameInactive()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: playTimeCheckInterval)
                playTime.tick()
            }
        }
    }

    @ViewBuilder
    private func destination(for route: TVRoute) -> some View {
        switch route {
        case .playerSelection(let mode):
            TVPlayerSelectionView(mode: mode)
        case .world:
            TVWorldView()
        case .category(let category):
            TVCategoryView(category: category)
        case .gameLibrary(let category):
            TVGameSelectionView(initialFilter: category)
        case .game(let kind, let category):
            TVGamePlayView(kind: kind, category: category)
        case .familyChallenge:
            TVFamilyChallengeView()
        case .results(let result):
            TVRewardView(result: result)
        case .rewards:
            TVRewardView(result: nil)
        case .familyProgress:
            TVFamilyProgressView()
        case .settings:
            TVSettingsView()
        }
    }
}
