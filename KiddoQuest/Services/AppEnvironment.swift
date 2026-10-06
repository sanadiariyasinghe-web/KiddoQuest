import Foundation

// MARK: - App Environment
// Detects automated testing so the app can start from a clean, predictable state
// without touching a child's real saved progress.

enum AppEnvironment {
    /// Launch argument used by the UI tests.
    static let uiTestingArgument = "-uiTesting"

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingArgument)
    }

    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Tests use an in-memory Core Data store so real progress is never changed.
    static var usesInMemoryStore: Bool {
        isUITesting || isRunningUnitTests
    }

    /// UI tests start fresh: intro skipped, no time limit, Calm Mode on, sound and music off.
    static func prepareForUITestingIfNeeded() {
        guard isUITesting else { return }
        let defaults = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        defaults.set(true, forKey: "has_seen_intro")
        defaults.set(0, forKey: PlayTimeTracker.limitKey)
        defaults.set(true, forKey: CalmMode.settingsKey)
        defaults.set(false, forKey: "sound_effects_enabled")
        defaults.set(false, forKey: MusicService.settingsKey)
    }
}
