# AI Assistance — Part B (KiddoQuest TV)

The brief asks students to document AI-assisted development. This file covers the tvOS app
(Part B). The iOS app (Part A) is covered in [AI_Usage_Log.md](AI_Usage_Log.md).

| Item | Detail |
| --- | --- |
| Tool | Claude (Anthropic) coding assistant inside Xcode 27 |
| Model | Claude Opus 5.5 |
| Access | Read and edit project files, build, run tests on the Apple TV simulator, run Git commands |
| Commits | AI-authored commits end with `Co-Authored-By: Claude Opus 5.5` |

> **Recommendation:** export the full conversation transcript from Xcode and attach it to your submission.

## Session of 7 October 2026: bringing the tvOS app in line with the iOS app

| # | My prompt (summary) | What the AI did | How it was verified |
| --- | --- | --- | --- |
| 1 | "What can we improve in tvOS, or is it already good?" | Reviewed the code and README against the Part B rubric. Found 4 of 6 games were prototypes, Animal Match still present (removed on iOS), single-remote multiplayer, and a missing `AI_ASSISTANCE.md` | Read the findings against the code |
| 2 | "Develop tvOS the same as the mobile one" | Four feature branches, each built, tested and merged (below) | Unit and UI tests on the Apple TV 4K (3rd generation) simulator, tvOS 27 |

Feature branches:

1. `feature/tv-full-games`: Feed the Animals and Animal Shadows replace Animal Match; Tap-to-Match, Tap-to-Reveal and Shape Sort become full 5-round shuffled games; saved `animalMatch` progress decodes as Feed the Animals.
2. `feature/tv-instructions-hints`: picture instructions before every game, the Learn → Play → Stars trail, and pointing-hand hints.
3. `feature/tv-stickers`: per-player sticker book and Buddy's dance on Results.
4. `feature/tv-calm-time-limit`: Calm Mode and a daily time limit with a break screen and a remote-friendly parent question.

## Testing performed

**Run on 7 October 2026, Apple TV 4K (3rd generation) simulator, tvOS 27:**

| Suite | Result |
| --- | --- |
| Unit tests (`KiddoQuest TVTests`, Swift Testing) | **85 / 85 passed** (TVScoreTests, TVGameLogicTests, TVPlayerTests, TVFamilyChallengeTests, TVComfortTests) |
| UI tests (`KiddoQuest TVUITests`, XCUIRemote) | **20 / 20 passed** |

Notes:

- UI tests were run in small batches. Large batches sometimes produced an incomplete result bundle because the 8 GB Mac was low on memory; re-running the same tests in smaller groups passed.
- Pointing-hand hints and ambient motion are switched off under `-uiTesting`, so XCTest can detect when the app is idle. They were reviewed manually.

## What I checked or changed myself

*(Complete honestly before you submit.)*

- I played every TV game with the Simulator remote: *(notes)*
- I tried Calm Mode and the daily limit: *(notes)*
- I can explain `TVGamePlayView`, `TVHintOverlay`, `TVChoiceGameViewModel`, `TVPlayTimeTracker` and the backward-compatible decoding during the viva.
