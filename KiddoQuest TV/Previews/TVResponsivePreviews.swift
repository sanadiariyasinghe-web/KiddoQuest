#if DEBUG
import SwiftUI

// MARK: - TV Layout Previews (debug only)
// Every Apple TV (HD or 4K) lays apps out in the same 1920 × 1080-point space, so each
// screen is rendered full size on the TV canvas with the demo family loaded.

/// Hosts a TV screen with the same environment the app provides.
struct TVPreviewScreen<Content: View>: View {
    var startsPlaying = true
    @ViewBuilder var content: Content

    @State private var store = TVAppStore(persistence: TVInMemoryPersistence(snapshot: nil))
    @State private var router = TVRouter()
    @State private var sound = TVSoundService(isSuppressed: true)
    @State private var playTime = TVPlayTimeTracker(defaults: UserDefaults(suiteName: "tv.preview") ?? .standard)
    @State private var controllers = TVGameControllerService()

    var body: some View {
        NavigationStack { content }
            .environment(store)
            .environment(router)
            .environment(sound)
            .environment(playTime)
            .environment(controllers)
            .environment(\.tvAmbientMotionEnabled, false)
            .environment(\.tvHintsEnabled, false)
            .environment(\.tvPreviewStartsPlaying, startsPlaying)
    }
}

#Preview("TV Home") { TVPreviewScreen { TVHomeView() } }
#Preview("TV World") { TVPreviewScreen { TVWorldView() } }
#Preview("TV Who's Playing") { TVPreviewScreen { TVPlayerSelectionView(mode: .startPlaying) } }
#Preview("TV Instructions") { TVPreviewScreen(startsPlaying: false) { TVGamePlayView(kind: .feedAnimals, category: .animals) } }
#Preview("TV Counting Pop") { TVPreviewScreen { TVGamePlayView(kind: .countingPop, category: .numbers) } }
#Preview("TV Shape Hunt") { TVPreviewScreen { TVGamePlayView(kind: .shapeHunt, category: .shapes) } }
#Preview("TV Feed the Animals") { TVPreviewScreen { TVGamePlayView(kind: .feedAnimals, category: .animals) } }
#Preview("TV Colour It In") { TVPreviewScreen { TVGamePlayView(kind: .tapToReveal, category: .shapes) } }
#Preview("TV Tap-to-Match") { TVPreviewScreen { TVGamePlayView(kind: .dragToMatch, category: .letters) } }
#Preview("TV Family Challenge") { TVPreviewScreen { TVFamilyChallengeView() } }
#Preview("TV Break") { TVPreviewScreen { TVBreakTimeView { } } }
#Preview("TV Rewards") { TVPreviewScreen { TVRewardView(result: nil) } }
#Preview("TV Family Progress") { TVPreviewScreen { TVFamilyProgressView() } }
#endif
