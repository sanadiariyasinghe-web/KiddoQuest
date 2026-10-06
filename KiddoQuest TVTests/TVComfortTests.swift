import Foundation
import Testing
@testable import KiddoQuest_TV

/// Calm Mode, the daily time limit and the break screen's parent question.
@MainActor
struct TVComfortTests {

    private func freshDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "TVComfortTests.\(UUID().uuidString)"))
    }

    @Test func limitRules() {
        #expect(TVPlayTimeRules.isLimitReached(secondsPlayed: 15 * 60, limitMinutes: 15, isUnlockedByParent: false))
        #expect(!TVPlayTimeRules.isLimitReached(secondsPlayed: 14 * 60, limitMinutes: 15, isUnlockedByParent: false))
        #expect(!TVPlayTimeRules.isLimitReached(secondsPlayed: 99 * 60, limitMinutes: 0, isUnlockedByParent: false))
        #expect(!TVPlayTimeRules.isLimitReached(secondsPlayed: 99 * 60, limitMinutes: 15, isUnlockedByParent: true))
    }

    @Test func breakAppearsAfterTheLimitAndAGrownUpCanUnlock() throws {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let tracker = TVPlayTimeTracker(limitMinutes: 20, defaults: try freshDefaults(), now: { now })

        tracker.appBecameActive()
        now.addTimeInterval(19 * 60)
        tracker.tick()
        #expect(!tracker.isLimitReached)
        #expect(tracker.minutesPlayedToday == 19)

        now.addTimeInterval(60)
        tracker.tick()
        #expect(tracker.isLimitReached)

        tracker.unlockForToday()
        #expect(!tracker.isLimitReached)
    }

    @Test func playTimeResetsOnANewDayAndNoLimitNeverBreaks() throws {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let tracker = TVPlayTimeTracker(limitMinutes: 15, defaults: try freshDefaults(), now: { now })
        tracker.appBecameActive()
        now.addTimeInterval(16 * 60)
        tracker.appBecameInactive()
        #expect(tracker.isLimitReached)

        tracker.setLimit(minutes: 0)
        #expect(!tracker.isLimitReached)

        tracker.setLimit(minutes: 15)
        now.addTimeInterval(24 * 60 * 60)
        tracker.appBecameActive()
        #expect(!tracker.isLimitReached)
        #expect(tracker.minutesPlayedToday == 0)
    }

    @Test func dailyLimitCyclesThroughChoices() {
        var settings = TVSettings()
        #expect(settings.dailyLimitLabel == "No limit")
        var seen: [Int] = []
        for _ in 0..<TVSettings.dailyLimitChoices.count {
            settings.dailyLimitMinutes = settings.nextDailyLimit
            seen.append(settings.dailyLimitMinutes)
        }
        #expect(seen == [15, 20, 30, 0])
    }

    @Test func settingsSavedBeforeCalmModeStillLoad() throws {
        let json = #"{"soundEnabled":false,"musicEnabled":true}"#
        let settings = try JSONDecoder().decode(TVSettings.self, from: Data(json.utf8))
        #expect(settings.soundEnabled == false)
        #expect(settings.musicEnabled == true)
        #expect(settings.calmMode == false)
        #expect(settings.dailyLimitMinutes == 0)
    }

    @Test func calmModeAndLimitArePersisted() {
        let persistence = TVInMemoryPersistence(snapshot: nil)
        let store = TVAppStore(persistence: persistence)
        store.settings.calmMode = true
        store.settings.dailyLimitMinutes = 20
        #expect(persistence.snapshot?.settings.calmMode == true)
        #expect(persistence.snapshot?.settings.dailyLimitMinutes == 20)
    }

    @Test func parentQuestionAlwaysOffersTheAnswer() {
        for _ in 0..<50 {
            let question = TVParentQuestion.random()
            #expect(question.choices.contains(question.answer))
            #expect(Set(question.choices).count == 3)
        }
    }
}
