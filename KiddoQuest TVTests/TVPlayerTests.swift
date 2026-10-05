import Foundation
import Testing
@testable import KiddoQuest_TV

/// Player switching, persistence and the app store's safe defaults.
@MainActor
struct TVPlayerTests {

    private func makeStore(snapshot: TVAppSnapshot? = nil) -> (TVAppStore, TVInMemoryPersistence) {
        let persistence = TVInMemoryPersistence(snapshot: snapshot)
        return (TVAppStore(persistence: persistence), persistence)
    }

    @Test func firstLaunchLoadsDemoFamilyWithNoSelection() {
        let (store, _) = makeStore()
        #expect(store.players.map(\.name) == ["Ava", "Liam", "Parent"])
        #expect(store.selectedPlayer == nil)
        // A safe fallback player still exists for games.
        #expect(store.activePlayer?.name == "Ava")
    }

    @Test func selectingAPlayerSwitchesAndPersists() throws {
        let (store, persistence) = makeStore()
        let liam = try #require(store.players.first { $0.name == "Liam" })
        store.selectPlayer(liam.id)
        #expect(store.selectedPlayer?.id == liam.id)
        #expect(store.activePlayer?.name == "Liam")
        #expect(persistence.snapshot?.selectedPlayerID == liam.id)

        // Switch again.
        let ava = try #require(store.players.first { $0.name == "Ava" })
        store.selectPlayer(ava.id)
        #expect(store.activePlayer?.name == "Ava")
    }

    @Test func selectingAnUnknownPlayerIsIgnored() {
        let (store, persistence) = makeStore()
        store.selectPlayer(UUID())
        #expect(store.selectedPlayer == nil)
        #expect(persistence.saveCount == 0)
    }

    @Test func selectionSurvivesRelaunch() throws {
        let (store, persistence) = makeStore()
        let liam = try #require(store.players.first { $0.name == "Liam" })
        store.selectPlayer(liam.id)

        let relaunched = TVAppStore(persistence: persistence)
        #expect(relaunched.selectedPlayer?.name == "Liam")
    }

    @Test func staleSelectedIDFallsBackSafely() {
        let players = TVGameDataService.demoPlayers()
        let snapshot = TVAppSnapshot(
            players: players, selectedPlayerID: UUID(),
            family: TVFamilyScore(), settings: TVSettings(), lastPlayedCategory: nil
        )
        let (store, _) = makeStore(snapshot: snapshot)
        #expect(store.selectedPlayer == nil)
        #expect(store.activePlayer != nil)
    }

    @Test func recordingASessionUpdatesTheActivePlayer() throws {
        let (store, _) = makeStore()
        let liam = try #require(store.players.first { $0.name == "Liam" })
        store.selectPlayer(liam.id)

        var tracker = TVRoundTracker()
        for _ in 0..<5 { tracker.registerCorrect(); tracker.startNextRound() }
        let recorded = store.recordSession(TVSessionResult(gameKind: .countingPop, category: .numbers, tracker: tracker))

        let updated = try #require(store.player(withID: liam.id))
        #expect(recorded.playerID == liam.id)
        #expect(updated.progress.progress(for: .numbers).stars == liam.progress.progress(for: .numbers).stars + 3)
        #expect(updated.points == liam.points + 50)
        #expect(store.lastPlayedCategory == .numbers)
        // Liam had 9 number stars; 3 more unlocks Number Explorer.
        #expect(recorded.newRewards == [.numberExplorer])
        #expect(updated.earnedRewards.contains(.numberExplorer))
    }

    @Test func recordingWithoutASelectedPlayerUsesTheFallback() {
        let (store, _) = makeStore()
        var tracker = TVRoundTracker()
        tracker.registerCorrect()
        let recorded = store.recordSession(TVSessionResult(gameKind: .shapeSort, category: .shapes, tracker: tracker))
        #expect(recorded.playerID == store.players.first?.id)
        #expect(store.selectedPlayer?.name == "Ava")
    }

    @Test func resetProgressKeepsProfilesButClearsProgress() {
        let (store, persistence) = makeStore()
        store.resetProgress()
        #expect(store.players.count == 3)
        #expect(store.players.allSatisfy { $0.totalStars == 0 && $0.earnedRewards.isEmpty && $0.points == 0 })
        #expect(store.family == TVFamilyScore())
        #expect(persistence.snapshot?.family == TVFamilyScore())
    }

    @Test func settingsChangesArePersisted() {
        let (store, persistence) = makeStore()
        store.settings.musicEnabled = true
        #expect(persistence.snapshot?.settings.musicEnabled == true)
    }

    @Test func userDefaultsPersistenceRoundTripsAndToleratesCorruptData() throws {
        let suite = "kiddoquest.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let persistence = TVUserDefaultsPersistence(defaults: defaults, key: "snapshot")
        #expect(persistence.load() == nil)

        let snapshot = TVAppSnapshot(
            players: TVGameDataService.demoPlayers(), selectedPlayerID: nil,
            family: TVGameDataService.demoFamilyScore, settings: TVSettings(), lastPlayedCategory: .shapes
        )
        persistence.save(snapshot)
        #expect(persistence.load() == snapshot)

        defaults.set(Data("not json".utf8), forKey: "snapshot")
        #expect(persistence.load() == nil)

        persistence.clear()
        #expect(persistence.load() == nil)
    }

    @Test func playerSelectionPutsChildrenFirstAndFocusesActivePlayer() throws {
        let players = TVGameDataService.demoPlayers().reversed().map { $0 }
        let liam = try #require(players.first { $0.name == "Liam" })
        let model = TVPlayerSelectionViewModel(players: players, selectedPlayerID: liam.id, mode: .startPlaying)
        #expect(model.cards.last?.player.isParent == true)
        #expect(model.initialFocusID == liam.id)
        #expect(model.cards.first { $0.id == liam.id }?.isActive == true)
    }

    @Test func playerCardHighlightShowsStrongestCategory() throws {
        let ava = try #require(TVGameDataService.demoPlayers().first)
        let card = TVPlayerSelectionViewModel.Card(player: ava, isActive: false)
        #expect(card.highlight == "Animals 90%")
        let parent = TVPlayer(name: "Parent", avatar: "🧑", color: .mint, role: .parent)
        #expect(TVPlayerSelectionViewModel.Card(player: parent, isActive: false).highlight == "Family helper")
    }

    @Test func homeContinueNeedsASelectedPlayer() throws {
        let ava = try #require(TVGameDataService.demoPlayers().first)
        let noSelection = TVHomeViewModel(activePlayer: ava, hasSelectedPlayer: false, lastPlayedCategory: nil)
        #expect(noSelection.continueSubtitle == "Pick a player first")
        let selected = TVHomeViewModel(activePlayer: ava, hasSelectedPlayer: true, lastPlayedCategory: .shapes)
        #expect(selected.continueSubtitle == "Ava · Shapes")
    }

    @Test func routerContinueJourneyRoutesSafely() {
        let router = TVRouter()
        router.continueJourney(hasPlayer: false, lastCategory: .letters)
        #expect(router.path == [.playerSelection(.startPlaying)])
        router.continueJourney(hasPlayer: true, lastCategory: .letters)
        #expect(router.path == [.world, .category(.letters)])
        router.pop()
        router.pop()
        router.pop() // Popping an empty stack is a no-op.
        #expect(router.path.isEmpty)
    }
}
