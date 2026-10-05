import SwiftUI

@main
struct KiddoQuestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // Start (or resume) the background music whenever the app becomes active
            if phase == .active {
                MusicService.shared.refresh()
            }
        }
    }
}
