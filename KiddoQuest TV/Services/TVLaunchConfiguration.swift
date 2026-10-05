import SwiftUI

/// Reads launch arguments so UI tests can start from a known, isolated state.
struct TVLaunchConfiguration {
    static let uiTestingArgument = "-uiTesting"
    static let noSelectedPlayerArgument = "-uiTestingNoSelectedPlayer"

    static let appearanceArgument = "-forceAppearance"

    let isUITesting: Bool
    let startsWithoutSelectedPlayer: Bool
    /// Optional override for demos and tests (`-forceAppearance light|dark`).
    /// By default the app follows the system, exactly like the iOS app.
    let forcedColorScheme: ColorScheme?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITesting = arguments.contains(Self.uiTestingArgument)
        startsWithoutSelectedPlayer = arguments.contains(Self.noSelectedPlayerArgument)
        if let index = arguments.firstIndex(of: Self.appearanceArgument), arguments.indices.contains(index + 1) {
            switch arguments[index + 1] {
            case "light": forcedColorScheme = .light
            case "dark": forcedColorScheme = .dark
            default: forcedColorScheme = nil
            }
        } else {
            forcedColorScheme = nil
        }
    }

    /// UI tests use memory-only storage so they never touch saved family data.
    func makePersistence() -> TVPersistenceStoring {
        guard isUITesting else { return TVUserDefaultsPersistence() }
        let players = TVGameDataService.demoPlayers()
        let snapshot = TVAppSnapshot(
            players: players,
            selectedPlayerID: startsWithoutSelectedPlayer ? nil : players.first?.id,
            family: TVGameDataService.demoFamilyScore,
            settings: TVSettings(soundEnabled: false, musicEnabled: false),
            lastPlayedCategory: nil
        )
        return TVInMemoryPersistence(snapshot: snapshot)
    }
}
