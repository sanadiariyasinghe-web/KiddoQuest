# KiddoQuest — Project Report (Part A, iOS)

> **Draft:** this report was drafted with AI assistance (see [AI_Usage_Log.md](AI_Usage_Log.md)).
> Before you submit, rewrite the reflections in your own words and add your own experiences,
> screenshots and user-testing notes. The brief requires original work and documented AI use.

## 1. Introduction

KiddoQuest is an iOS learning app for kindergarten children (3–7). It turns early numeracy,
literacy, shapes and animal knowledge into short picture-based games, adds AR exploration of the
child's own room, and gives parents gentle control over screen time.

## 2. Design decisions

### 2.1 Designing for children who can't read

Early versions explained games with text, then with a synthesised voice. Testing showed two problems.
The voice was too fast and robotic for young children, and the text needed an adult to read it.
The final design removes the voice and explains every game with:

- a **picture sentence** (e.g. 🐰 → 👆 → 🥕),
- an animated **pointing hand** that taps the right kind of answer at the start and again after 10 s without a tap,
- one consistent journey for all games: **Learn → Play → Stars**.

Short text remains for grown-ups reading along.

### 2.2 One flow for every game

All games share `GameFlowContainer`: instructions, play, then results with big **Home** and **More Games**
buttons. This removed eight slightly different completion screens and guarantees that a child always
knows what to do next. It also kept each game view small: it only describes its own content.

### 2.3 Encouraging scoring

- No penalties: a wrong answer fades or wiggles and the child tries again.
- Stars come from first-try accuracy, and every finished round earns at least one star.
- Points are kept for parents, but the number is hidden from children (stars and stickers mean more at this age).
- Gentle levels add choices (2 → 3 → 4) only after a 3-star round, and never go down.

### 2.4 Replacing weak games

The original "Animal Half-Match" (matching front and back halves) was hard to understand. It was replaced
first by Memory Match and finally by two simpler picture games, **Feed the Animals** and
**Animal Shadows**, which need no reading and teach real-world knowledge.

### 2.5 Meaningful AR

The first AR version showed 2D buttons over the camera feed, which isn't real AR. The final version uses
ARKit plane detection and RealityKit to place 3D cards on a real table or floor. It guides children with
Apple's coaching overlay and hit-tests taps against the 3D entities.

### 2.6 Safety and comfort

A parent gate, a daily time limit with a calm break screen, Calm Mode (also triggered by Reduce Motion),
soft synthesised sounds, a big 🏠 button with confirmation instead of a small back arrow, and a
portrait-only layout on iPhone.

### 2.7 Persistence choices

Relational, long-lived learning data (profile, progress, sessions, badges) uses **Core Data**. Small
settings and the sticker collection use **UserDefaults**: they are simple key/value data that doesn't
need relationships or queries, and keeping them out of Core Data avoided a schema migration.

## 3. Development challenges

| Challenge | What happened | Resolution |
| --- | --- | --- |
| Simulator hangs and crashes | An 8 GB Mac running iOS and tvOS simulators together ran out of memory (heavy swap, system apps killed by watchdogs) | Run one simulator at a time; Calm Mode for heavy animations |
| Text-to-speech quality | The voice was too fast and unfriendly for children | Tuned it, then removed it in favour of picture instructions and hints |
| Lost edits | Several file edits applied in parallel overwrote each other | Edit files one at a time and check the result on disk after each change |
| Fake progress | Home showed hard-coded percentages | Computed from Core Data through the `ProgressSummary` helpers |
| Core Data in tests | Two stores built from two model instances confused entity mapping | One shared model; in-memory store under tests |
| AR without a device | The simulator has no ARKit world tracking | 2D fallback kept; AR logic isolated in `ARSceneController` |

## 4. Testing summary

- 27 unit tests (37 cases) and 5 UI tests, all passing on the iOS 27 simulator.
- See [PartA_TestingReport.md](PartA_TestingReport.md) for details and the manual acceptance checklist.

## 5. Reflections

*(Write this section in your own words. Prompts to help:)*

- What did you learn about designing for an audience that can't read?
- Which SwiftUI features (Observation, preferences, custom property wrappers) were new to you?
- What would you change if you started again?
- What did testing with a real child (or parent) teach you?
- How did using AI tools help or hinder you, and how did you check the generated code?

## 6. Future work

- Recorded human voice prompts (warmer than synthesised speech), with a parent toggle.
- More AR activities (counting objects placed around the room).
- Multiple child profiles.
- iCloud sync of progress between iPhone, iPad and the tvOS app.
- A localised Sinhala/Tamil version.
