import SwiftUI

/// Hosts the NavigationStack and maps every route to its screen.
/// The Siri Remote Back (Menu) button pops one level at a time.
struct TVRootView: View {
    @Environment(TVRouter.self) private var router
    @Environment(TVAppStore.self) private var store
    @Environment(TVSoundService.self) private var sound

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            TVHomeView()
                .navigationDestination(for: TVRoute.self) { route in
                    destination(for: route)
                }
        }
        .onChange(of: store.settings, initial: true) { _, settings in
            sound.apply(settings)
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
