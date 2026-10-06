import Foundation
import Observation

/// Pure rules for the daily time limit (unit-testable).
nonisolated enum TVPlayTimeRules {
    /// A limit of 0 minutes means "No limit".
    static func isLimitReached(secondsPlayed: TimeInterval, limitMinutes: Int, isUnlockedByParent: Bool) -> Bool {
        guard limitMinutes > 0, !isUnlockedByParent else { return false }
        return secondsPlayed >= TimeInterval(limitMinutes * 60)
    }

    /// Stable "yyyy-MM-dd" key for the day containing `date`.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// Counts how long KiddoQuest TV is on screen each day and says when the
/// parent's daily limit (Settings → Daily Time Limit) has been reached.
/// Totals are kept in UserDefaults and reset automatically each new day.
@Observable
final class TVPlayTimeTracker {
    private static let dayKey = "tv_play_time_day"
    private static let secondsKey = "tv_play_time_seconds"
    private static let unlockedDayKey = "tv_play_time_unlocked_day"

    private(set) var secondsPlayedToday: TimeInterval = 0
    private(set) var isLimitReached = false
    private(set) var limitMinutes: Int

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var activeSince: Date?

    var minutesPlayedToday: Int { Int(secondsPlayedToday / 60) }

    private var todayKey: String { TVPlayTimeRules.dayKey(for: now()) }

    init(limitMinutes: Int = 0, defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.limitMinutes = limitMinutes
        self.defaults = defaults
        self.now = now
        rollOverIfNewDay()
        secondsPlayedToday = defaults.double(forKey: Self.secondsKey)
        evaluate()
    }

    // MARK: - App lifecycle

    func appBecameActive() {
        rollOverIfNewDay()
        activeSince = now()
        evaluate()
    }

    func appBecameInactive() {
        accumulate()
        activeSince = nil
        evaluate()
    }

    /// Called regularly while the app is open to add the time played so far.
    func tick() {
        guard activeSince != nil else { return }
        accumulate()
        activeSince = now()
        evaluate()
    }

    /// Applies a new limit from Settings.
    func setLimit(minutes: Int) {
        limitMinutes = max(0, minutes)
        tick()
        evaluate()
    }

    /// A grown-up passed the parent gate: allow play for the rest of today.
    func unlockForToday() {
        defaults.set(todayKey, forKey: Self.unlockedDayKey)
        evaluate()
    }

    // MARK: - Private

    private func accumulate() {
        guard let start = activeSince else { return }
        rollOverIfNewDay()
        secondsPlayedToday += max(0, now().timeIntervalSince(start))
        defaults.set(secondsPlayedToday, forKey: Self.secondsKey)
    }

    private func rollOverIfNewDay() {
        let today = todayKey
        guard defaults.string(forKey: Self.dayKey) != today else { return }
        defaults.set(today, forKey: Self.dayKey)
        defaults.set(0.0, forKey: Self.secondsKey)
        secondsPlayedToday = 0
        if activeSince != nil {
            activeSince = now()
        }
    }

    private func evaluate() {
        isLimitReached = TVPlayTimeRules.isLimitReached(
            secondsPlayed: secondsPlayedToday,
            limitMinutes: limitMinutes,
            isUnlockedByParent: defaults.string(forKey: Self.unlockedDayKey) == todayKey
        )
    }
}
