import Foundation

// MARK: - Play Time Rules
// Pure rules for the parent's daily time limit (easy to unit test).
enum PlayTimeRules {
    /// A limit of 0 minutes means "No Limit".
    static func isLimitReached(secondsPlayed: TimeInterval, limitMinutes: Int, isUnlockedByParent: Bool) -> Bool {
        guard limitMinutes > 0, !isUnlockedByParent else { return false }
        return secondsPlayed >= TimeInterval(limitMinutes * 60)
    }
    
    /// Stable "yyyy-MM-dd" key for the calendar day containing `date`.
    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

// MARK: - Play Time Tracker
// Counts how long the app is open and active each day, and tells the app when the
// parent's daily limit (Parent Settings → Daily Session Preference) has been reached.
// Totals are kept in UserDefaults and reset automatically each new day.

@Observable
final class PlayTimeTracker {
    static let shared = PlayTimeTracker()
    
    static let limitKey = "session_limit_minutes"
    static let defaultLimitMinutes = 20
    private static let dayKey = "play_time_day"
    private static let secondsKey = "play_time_seconds"
    private static let unlockedDayKey = "play_time_unlocked_day"
    
    private(set) var secondsPlayedToday: TimeInterval = 0
    private(set) var isLimitReached = false
    
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var activeSince: Date?
    
    var minutesPlayedToday: Int { Int(secondsPlayedToday / 60) }
    
    private var limitMinutes: Int {
        defaults.object(forKey: Self.limitKey) as? Int ?? Self.defaultLimitMinutes
    }
    
    private var todayKey: String { PlayTimeRules.dayKey(for: now()) }
    
    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        rollOverIfNewDay()
        secondsPlayedToday = defaults.double(forKey: Self.secondsKey)
        evaluate()
    }
    
    // MARK: - App Lifecycle
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
    
    /// Re-checks the limit (e.g. after a parent changes it).
    func refresh() {
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
        let isUnlocked = defaults.string(forKey: Self.unlockedDayKey) == todayKey
        isLimitReached = PlayTimeRules.isLimitReached(
            secondsPlayed: secondsPlayedToday,
            limitMinutes: limitMinutes,
            isUnlockedByParent: isUnlocked
        )
    }
}
