import SwiftUI

@main
struct KiddoQuestApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppEnvironment.prepareForUITestingIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                // Start (or resume) the background music and the daily play-time clock
                MusicService.shared.refresh()
                PlayTimeTracker.shared.appBecameActive()
            case .inactive, .background:
                PlayTimeTracker.shared.appBecameInactive()
            @unknown default:
                break
            }
        }
    }
}
