# AI Usage Log

The brief asks students to document AI-assisted development: the prompts, the responses, and how
they helped. This log covers the Xcode coding-assistant session of **6 October 2026**.

| Item | Detail |
| --- | --- |
| Tool | Claude (Anthropic) coding assistant inside Xcode 27 |
| Model | Claude Opus 5.5 |
| Access | Read and edit project files, build, run tests, drive the simulator, run Git commands |
| Commits | AI-authored commits end with `Co-Authored-By: Claude Opus 5.5` |

> **Recommendation:** also export the full conversation transcript from Xcode and attach it to your
> submission. This log is a summary of it.

## Session summary

| # | My prompt (summary) | What the AI did | How I verified it |
| --- | --- | --- | --- |
| 1 | "The simulator takes a long time to start, gets stuck and closes." | Read console logs, crash reports, memory and swap. Found that the 8 GB Mac was running the iOS and tvOS simulators together (7.7 GB swap; system apps killed by watchdogs). Advised running one simulator at a time. | Checked the swap figures and booted simulators myself |
| 2 | Improve the iOS app: replace Animal Match with Memory Match; slower, friendlier voice; clear instructions; a results screen with Home / More Games for every game | Added the shared `GameFlowContainer` (instructions → play → results), `RoundResultsView`, `GameJourneyIndicator`, Memory Match and a tuned speech service; converted all games | Build passed; partial simulator run (Memory Match and Counting Pop results seen) |
| 3 | Kindergarten focus: remove the AI voice; replace the Animal game with two simple games; add background music; don't change tvOS | Removed `SpeechService`; added **Feed the Animals** and **Animal Shadows**; ported the tvOS melody to a new iOS `MusicService`. Pointed out that the iOS app had no music, while tvOS did | Build passed; confirmed no tvOS files changed |
| 4 | "Give your ideas to improve KiddoQuest" | Suggested real progress, a time limit, pointing-hand hints, picture instructions, a sticker book, levels, Calm Mode, a parent summary | — (ideas only) |
| 5 | Compare the app with my assignment brief | Mapped each requirement and rubric item to the code. Found the missing camera permission, shallow AR, no iOS tests and no Part A documentation | Read the brief and checked each finding in the project |
| 6 | "Do all" (the ideas from #4 and the fixes from #5) | Feature branches, each built and merged: camera permission; real Core Data progress; daily time limit + break screen; picture instructions + hints + no score; sticker book + owl dance; random targets + gentle levels + Tap-to-Match rename; big Home button + Calm Mode + soft chimes; weekly parent summary; RealityKit AR; Dynamic Type + adaptive layouts; unit + UI tests; this documentation | Build after each feature; 37 unit test cases and 5 UI tests passing; reviewed each diff and commit |

## How AI assistance was used

- **Diagnosis:** reading logs and crash reports to explain the simulator problems.
- **Implementation:** writing new SwiftUI views, view models, services and tests to my requirements.
- **Platform APIs:** looking up current RealityKit, ARKit and AVFoundation APIs in Apple's documentation (e.g. `TextureResource(image:options:)`, `ARView.entity(at:)`).
- **Review:** comparing the project with the assignment rubric.
- **Documentation:** first drafts of these documents.

## What I checked or changed myself

*(Complete this section honestly before you submit. For example:)*

- I tested every game on the simulator and noted any problems.
- I tested AR on my own device: *(describe the result)*.
- I rewrote the reflections in `PartA_Report.md` in my own words.
- I understand and can explain the code during the viva, especially `GameFlowContainer`, `ARSceneController`, `CoreDataManager` and the tests.

## Limitations noticed in AI output

- Edits applied in parallel sometimes overwrote each other; this was found by checking files on disk and fixed.
- AR placement could not be verified in the simulator. It needs testing on a real device.
- Simulator UI testing was unreliable on the overloaded 8 GB Mac and needed retries.
