# KiddoQuest — Testing Report (Part A, iOS)

## 1. Strategy

| Level | Tool | Focus |
| --- | --- | --- |
| Unit tests | Swift Testing (`KiddoQuestTests`) | Pure rules, data generation, persistence |
| UI tests | XCUIAutomation (`KiddoQuestUITests`) | The child's journey through real screens |
| Manual / acceptance | Simulator and device | Look and feel, AR on a real device, accessibility settings |

Test isolation:

- Unit tests create their own `UserDefaults(suiteName:)` and an **in-memory** Core Data store.
- UI tests launch the app with `-uiTesting`. `AppEnvironment` then uses an in-memory store and resets settings: intro skipped, no time limit, Calm Mode on (no moving targets), sound and music off.
- The time-limit tracker receives an injected clock (`now:`), so day changes and limits are tested without waiting.

## 2. Unit tests — `KiddoQuestTests` (27 tests, 37 cases)

| Suite | What is checked |
| --- | --- |
| `GameScoringTests` | Star thresholds from first-try accuracy; at least 1 star for finishing; no questions → 0 stars |
| `GameLevelsTests` | 2/3/4 choices per level; only 3-star rounds level up; max level; per-game storage and reset |
| `ProgressSummaryTests` | Island stars and percentage; unplayed islands show 0; game cards decorated from saved stars; no made-up progress in the catalogue |
| `PlayTimeTests` | Limit rules (incl. "No Limit" and parent unlock); break shown after the limit; reset on a new day |
| `StickerBookTests` | New stickers prefer missing ones; a full book still gives stickers; saving and reset |
| `WeeklyLearningSummaryTests` | Only finished games from the last 7 days are listed; every catalogue game has a skill |
| `GameContentTests` | Animal rounds contain the answer with unique choices (2–4); Shape Sort includes every shape; Letter Hunt has 3 targets; only first-try finds count; Counting Pop options include the answer |
| `CoreDataManagerTests` | New profile has 0 stars; best stars kept and added to the profile; badges unlock; session totals |

**Result (6 October 2026, iPhone simulator, iOS 27):** all 37 cases passed.

## 3. UI tests — `KiddoQuestUITests` (5 tests)

| Test | Journey |
| --- | --- |
| `testHomeShowsAllIslandsWithFreshProgress` | Home shows all four islands with 0 % progress |
| `testFinishingLetterHuntShowsResultsAndHomeReturnsHome` | Letters → Play Island Games → Letter Hunt → Let's Play! → reads the target letter → pops all 3 → **Great Job! 🎉**, This Round, New sticker! → **Home** → Letters Island progress is no longer 0 % |
| `testMoreGamesReturnsToTheIslandGameList` | Finish Letter Hunt → **More Games** → Letters game list |
| `testBigHomeButtonAsksBeforeLeavingAGame` | 🏠 → "Go home?" → Keep playing (stays) → 🏠 → Home (leaves) |
| `testRewardsShowTheStickerBook` | Star counter → Rewards → My Sticker Book |

**Result (6 October 2026, iPhone simulator, iOS 27):** all 5 passed.
The first attempt failed before any test ran: the test runner stalled while loading accessibility,
because the 8 GB Mac was overloaded. Re-running with fewer simulators open passed.

## 4. Manual and user acceptance testing

Fill in this checklist during your own testing sessions (with a child where possible, supervised by a parent).

| # | Scenario | Expected | Result |
| --- | --- | --- | --- |
| 1 | First launch | Welcome screen → Let's Begin! → Home | |
| 2 | Each of the 8 games | Instructions → Play → Results → Home / More Games | |
| 3 | Wrong answer | Gentle fade or shake, no penalty, can try again | |
| 4 | Idle for 8 s during play | 👆 hint appears on the right answer | |
| 5 | 3-star round | Big owl dance; "Level up!" next to the stars | |
| 6 | Sticker book | New sticker after each game; count increases | |
| 7 | Parent gate | Wrong answer → new question; right answer → settings | |
| 8 | Daily limit 15 min | Break screen after 15 min; grown-up unlock works | |
| 9 | Calm Mode / Reduce Motion | No confetti or floating | |
| 10 | Dark Mode | All screens readable | |
| 11 | Largest Text Size | Text larger, layouts still usable | |
| 12 | iPad portrait and landscape | Content centred, nothing stretched | |
| 13 | AR on a real device | Coaching → cards on the table → tapping works | |
| 14 | Camera permission denied | App does not crash; AR view stays empty | |

## 5. Performance notes

- Build and run were verified on an 8 GB MacBook Air with one simulator running.
- No bundled audio or image assets: tones and AR textures are generated at runtime.
- Calm Mode is recommended for older devices.

## 6. Known limitations

- Real AR placement can only be verified on a physical device (the simulator uses the 2D fallback).
- The UI tests cover one complete game journey (Letter Hunt). The other games share the same `GameFlowContainer` and are covered by unit tests of their rules.
