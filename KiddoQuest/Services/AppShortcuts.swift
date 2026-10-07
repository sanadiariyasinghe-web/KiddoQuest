import AppIntents
import SwiftUI

// MARK: - Siri & Shortcuts (App Intents)
// "Hey Siri, open Numbers Island in KiddoQuest" / "How many stars do I have in KiddoQuest?"
// Phrases appear automatically in Shortcuts and Spotlight — no setup needed by parents.

/// Hands a route from an intent to the app's navigation (ContentView listens for it).
@Observable
final class ShortcutRouter {
    static let shared = ShortcutRouter()
    var pendingRoute: AppRoute?
}

/// Islands as Siri understands them (kept separate because the app's types are main-actor isolated).
nonisolated enum ShortcutIsland: String, AppEnum {
    case numbers, letters, shapes, animals

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Island"
    static let caseDisplayRepresentations: [ShortcutIsland: DisplayRepresentation] = [
        .numbers: "Numbers Island",
        .letters: "Letters Island",
        .shapes: "Shapes Island",
        .animals: "Animals Island"
    ]

    var category: IslandCategory {
        switch self {
        case .numbers: return .numbers
        case .letters: return .letters
        case .shapes: return .shapes
        case .animals: return .animals
        }
    }
}

struct OpenIslandIntent: AppIntent {
    static let title: LocalizedStringResource = "Open an Island"
    static let description = IntentDescription("Opens a KiddoQuest learning island.")
    static let openAppWhenRun = true

    @Parameter(title: "Island")
    var island: ShortcutIsland

    func perform() async throws -> some IntentResult {
        ShortcutRouter.shared.pendingRoute = .category(island.category)
        return .result()
    }
}

struct PlayFindItIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Find It!"
    static let description = IntentDescription("Starts the Find It! camera game.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        if let game = GameInfo.sampleGames.first(where: { $0.gameType == .findIt }) {
            ShortcutRouter.shared.pendingRoute = .gamePlay(game)
        }
        return .result()
    }
}

struct StarCountIntent: AppIntent {
    static let title: LocalizedStringResource = "How Many Stars?"
    static let description = IntentDescription("Says how many stars and stickers have been collected.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let stars = CoreDataManager.shared.currentProfile.totalStars
        let stickers = StickerBook.shared.stickers.count
        return .result(dialog: "You have \(stars) stars and \(stickers) stickers. Great job! 🌟")
    }
}

struct KiddoQuestShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenIslandIntent(),
            phrases: ["Open \(\.$island) in \(.applicationName)", "Play \(\.$island) in \(.applicationName)"],
            shortTitle: "Open Island",
            systemImageName: "map.fill"
        )
        AppShortcut(
            intent: PlayFindItIntent(),
            phrases: ["Play Find It in \(.applicationName)"],
            shortTitle: "Find It!",
            systemImageName: "camera.viewfinder"
        )
        AppShortcut(
            intent: StarCountIntent(),
            phrases: ["How many stars do I have in \(.applicationName)", "My \(.applicationName) stars"],
            shortTitle: "My Stars",
            systemImageName: "star.fill"
        )
    }
}
