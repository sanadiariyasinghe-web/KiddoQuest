import Foundation
import Observation

/// Single source of truth for players, progress, family score and settings.
///
/// Every mutation is written straight to the injected persistence store,
/// so progress survives relaunches without any backend.
@Observable
final class TVAppStore {
    private(set) var players: [TVPlayer]
    private(set) var selectedPlayerID: UUID?
    private(set) var family: TVFamilyScore
    private(set) var lastPlayedCategory: TVCategory?
    var settings: TVSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
        }
    }

    @ObservationIgnored private let persistence: TVPersistenceStoring

    init(persistence: TVPersistenceStoring) {
        self.persistence = persistence
        if let snapshot = persistence.load(), !snapshot.players.isEmpty {
            players = snapshot.players
            family = snapshot.family
            settings = snapshot.settings
            lastPlayedCategory = snapshot.lastPlayedCategory
            // Drop a stale selection that no longer matches a profile.
            selectedPlayerID = snapshot.players.contains { $0.id == snapshot.selectedPlayerID }
                ? snapshot.selectedPlayerID
                : nil
        } else {
            // First launch (or unreadable data): start with the demo family.
            players = TVGameDataService.demoPlayers()
            family = TVGameDataService.demoFamilyScore
            settings = TVSettings()
            lastPlayedCategory = nil
            selectedPlayerID = nil
        }
    }

    // MARK: - Players

    var selectedPlayer: TVPlayer? {
        players.first { $0.id == selectedPlayerID }
    }

    /// The player who is playing right now. Falls back to the first child
    /// profile when nobody has been picked, so games never crash.
    var activePlayer: TVPlayer? {
        selectedPlayer ?? players.first { !$0.isParent } ?? players.first
    }

    var children: [TVPlayer] { players.filter { !$0.isParent } }

    func player(withID id: UUID) -> TVPlayer? {
        players.first { $0.id == id }
    }

    func selectPlayer(_ id: UUID) {
        guard players.contains(where: { $0.id == id }), selectedPlayerID != id else { return }
        selectedPlayerID = id
        save()
    }

    // MARK: - Recording play

    /// Saves a finished solo game for the active player and returns the
    /// result with any newly unlocked badges filled in.
    @discardableResult
    func recordSession(_ result: TVSessionResult) -> TVSessionResult {
        var recorded = result
        guard let index = activePlayerIndex else { return recorded }

        players[index].points += result.points
        players[index].progress.record(
            correctAnswers: result.correctAnswers,
            stars: result.stars,
            in: result.category,
            game: result.gameKind
        )
        family.addSoloGame(stars: result.stars)
        lastPlayedCategory = result.category

        recorded.playerID = players[index].id
        recorded.newRewards = unlockRewards(at: index)
        let sticker = TVStickerRules.nextSticker(collected: Set(players[index].stickers))
        players[index].stickers.append(sticker)
        recorded.newSticker = sticker
        selectedPlayerID = players[index].id
        save()
        return recorded
    }

    /// Saves a finished Family Challenge for every participant and returns
    /// newly unlocked badges keyed by player.
    @discardableResult
    func recordFamilyChallenge(_ outcome: TVFamilyChallengeOutcome) -> [UUID: [TVRewardKind]] {
        var unlocked: [UUID: [TVRewardKind]] = [:]
        for (playerID, score) in outcome.scores {
            guard let index = players.firstIndex(where: { $0.id == playerID }) else { continue }
            players[index].points += score * TVScoring.firstTryPoints
            players[index].familyChallengesPlayed += 1
            players[index].progress.record(
                correctAnswers: score,
                stars: score,
                in: outcome.category,
                game: nil
            )
            let rewards = unlockRewards(at: index)
            if !rewards.isEmpty {
                unlocked[playerID] = rewards
            }
        }
        family.addFamilyChallenge(stars: outcome.familyStars)
        lastPlayedCategory = outcome.category
        save()
        return unlocked
    }

    // MARK: - Settings actions

    /// Clears all learning progress but keeps the family's profiles.
    func resetProgress() {
        players = players.map { $0.resettingProgress() }
        family = TVFamilyScore()
        lastPlayedCategory = nil
        save()
    }

    /// Restores the sample family used for demonstrations.
    func loadDemoFamily() {
        players = TVGameDataService.demoPlayers()
        family = TVGameDataService.demoFamilyScore
        selectedPlayerID = players.first?.id
        lastPlayedCategory = nil
        save()
    }

    // MARK: - Private

    private var activePlayerIndex: Int? {
        guard let id = activePlayer?.id else { return nil }
        return players.firstIndex { $0.id == id }
    }

    private func unlockRewards(at index: Int) -> [TVRewardKind] {
        let newRewards = TVRewardRules.newRewards(for: players[index])
        players[index].earnedRewards.formUnion(newRewards)
        return newRewards
    }

    private func save() {
        persistence.save(
            TVAppSnapshot(
                players: players,
                selectedPlayerID: selectedPlayerID,
                family: family,
                settings: settings,
                lastPlayedCategory: lastPlayedCategory
            )
        )
    }
}
