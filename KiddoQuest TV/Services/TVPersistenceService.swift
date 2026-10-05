import Foundation

/// Everything KiddoQuest TV saves between launches.
nonisolated struct TVAppSnapshot: Codable, Hashable {
    static let currentVersion = 1

    var version = TVAppSnapshot.currentVersion
    var players: [TVPlayer]
    var selectedPlayerID: UUID?
    var family: TVFamilyScore
    var settings: TVSettings
    var lastPlayedCategory: TVCategory?
}

/// Abstraction over local storage so tests and UI tests can use memory only.
protocol TVPersistenceStoring: AnyObject {
    func load() -> TVAppSnapshot?
    func save(_ snapshot: TVAppSnapshot)
    func clear()
}

/// Stores the snapshot as JSON in `UserDefaults`.
///
/// tvOS does not guarantee persistent local file storage (caches can be
/// purged), but small amounts of `UserDefaults` data are kept. The whole
/// snapshot is only a few kilobytes, well within that allowance.
final class TVUserDefaultsPersistence: TVPersistenceStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "kiddoquest.tv.snapshot") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> TVAppSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        // Corrupt or incompatible data is ignored rather than crashing;
        // the store then falls back to safe defaults.
        guard let snapshot = try? JSONDecoder().decode(TVAppSnapshot.self, from: data),
              snapshot.version == TVAppSnapshot.currentVersion else {
            return nil
        }
        return snapshot
    }

    func save(_ snapshot: TVAppSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// Keeps the snapshot in memory only. Used by unit and UI tests.
final class TVInMemoryPersistence: TVPersistenceStoring {
    private(set) var snapshot: TVAppSnapshot?
    private(set) var saveCount = 0

    init(snapshot: TVAppSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load() -> TVAppSnapshot? { snapshot }

    func save(_ snapshot: TVAppSnapshot) {
        self.snapshot = snapshot
        saveCount += 1
    }

    func clear() {
        snapshot = nil
    }
}
