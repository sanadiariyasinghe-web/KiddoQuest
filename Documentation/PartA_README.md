# KiddoQuest — Part A (Advanced iOS App)

**SE4041 – Mobile Application Design and Development · Assignment 02 · Part A**

## 1. Purpose

Most learning apps for young children rely on reading, long instructions or fast voices,
and many reward children with points that mean little to them. KiddoQuest is designed for
**kindergarten children who can't read yet**:

- every game is explained with **pictures** (e.g. 🐰 → 👆 → 🥕) and a pointing-hand hint,
- every game follows the same simple journey: **Learn → Play → Stars**,
- feedback is always gentle: no penalties, wrong answers fade and the child tries again,
- rewards are concrete: **stars, stickers and a dancing owl**.

Parents get a grown-ups area (protected by a maths question) with a daily time limit, Calm Mode,
audio settings and a weekly "What my child learned" summary.

## 2. Target audience

| Who | Needs | How KiddoQuest meets them |
| --- | --- | --- |
| Children aged 3–7 | Can't read yet, short attention, large finger targets | Picture instructions, 👆 hints, big buttons (≥ 64 pt), short 3–6 question rounds |
| Sensitive children | Too much motion or noise is upsetting | Calm Mode, soft synthesised chimes, respects Reduce Motion |
| Parents | Safe screen time and visible learning | Parent gate, daily time limit with a calm break screen, weekly learning summary |

## 3. Features

### Learning islands and games (9 games)

| Island | Game | What the child does |
| --- | --- | --- |
| Numbers | Counting Pop | Count the treats, tap the right number |
| Numbers | Tap-to-Match | Tap the fruits, then tap their number |
| Letters | Letter Tap-Match | Tap a big letter, then its small letter |
| Letters | Letter Hunt | Find every bubble with today's letter (random each game) |
| Shapes | Tap-to-Reveal Colouring | Paint each shape the right colour |
| Shapes | Shape Sort | Tap the box that matches each shape (random order) |
| Shapes | **Find It! 📷** | Find a real object (ball, cup, book…) or a colour at home and take a photo; on-device **Vision** checks it |
| Animals | Feed the Animals | Give each hungry animal the food it loves |
| Animals | Animal Shadows | Match a shadow to the right animal |

Every game uses the shared **game flow**:

1. **Instructions:** a picture sentence, short text for grown-ups, and a big **Let's Play!** button.
2. **Play:** an animated 👆 shows what to tap at the start and again after 8 seconds without a tap.
3. **Results:** "Great Job! 🎉", stars revealed one by one, correct answers, a new sticker, the owl dance,
   and big **🏠 Home** / **🎮 More Games** buttons (plus Play Again).

Choice-based games have **gentle levels** (2 → 3 → 4 choices). A child moves up after a 3-star round.

### AR Learning Mode (ARKit + RealityKit)

- ARKit world tracking with horizontal plane detection and Apple's coaching overlay.
- When a surface is found, the child **taps the real table or floor** to place five **3D learning objects** there
  (ARKit raycast). A **Move** button lets them place the objects somewhere else.
- Real 3D content made in code: **extruded 3D letters**, **thick 3D shapes** (triangle, circle, square, star, heart)
  and **animal picture cubes**, each on a small stand. They pop in one by one and turn gently (not in Calm Mode).
- **Explore:** tapping any object makes it hop while Buddy shares a fact ("A triangle has 3 sides, like a slice of pizza!").
- **Challenges:** three random "Find the Triangle!" / "Find the letter B!" / "Find the Lion!" rounds. A find makes the object
  lift and its stand turn green. At the end there are stars (first-try finds), a **sticker**, saved progress and the AR Explorer badge.
- Devices without AR (including the simulator) get the 2D "simulated room" fallback with the same challenges.

### Find It! (Vision, on-device machine learning)

- Each round has 5 hunts: 3 everyday objects and 2 colours, chosen at random.
- Objects are checked with Vision's built-in image classifier (`ClassifyImageRequest`). Colours are checked
  from the average hue of the centre of the photo.
- Wrong guesses are gentle: Buddy says what he saw ("I see a dog! Try again 🌟"). **Skip** means a child is never stuck.
- Photos never leave the device and are not saved. The simulator (no camera) uses the photo picker.

### Siri and Shortcuts (App Intents)

- "Open Numbers Island in KiddoQuest", "Play Find It in KiddoQuest", "How many stars do I have in KiddoQuest?"
- They appear automatically in the Shortcuts app and Spotlight, with no setup needed.

### Languages

- English, plus **Sinhala (සිංහල)** and **Tamil (தமிழ்)** for the main child screens (Home, islands, game buttons,
  results, sticker book, break screen, Find It!) in a String Catalog. The translations are marked *needs review*
  and should be checked by a native speaker.

### Rewards

- Stars per game (saved in Core Data) shown on Home and the game lists.
- A sticker for every finished round, collected in **My Sticker Book**.
- Badges (First Game, Number Explorer, Letter Explorer, Shape Master, Animal Friend, AR Explorer).

### Parent area (grown-ups only)

- Parent gate (random addition question).
- Sound effects and background music toggles.
- **Calm Mode** (no confetti or floating animations).
- **Daily time limit** (15 / 20 / 30 minutes or no limit) with a "Time for a break! 🌙" screen.
- **What my child learned this week**, plus recent sessions.
- Reset all progress.

## 4. Requirements

| Item | Version |
| --- | --- |
| Xcode | 27 or later |
| iOS / iPadOS deployment target | 27.0 |
| Device for AR | Any iPhone or iPad that supports ARKit world tracking and runs iOS 27 |
| Third-party libraries | None |

## 5. Build and run

1. Open `KiddoQuest.xcodeproj`.
2. Select the **KiddoQuest** scheme.
3. Choose a run destination:
   - **iPhone/iPad simulator:** all games work; AR shows the simulated room.
   - **Real iPhone/iPad:** needed to try real AR. Set your Development Team under
     *Signing & Capabilities* first. The app asks for camera access when AR Learning Mode opens.
4. Press **Run** (⌘R).

### Running the tests

- **All tests:** Product → Test (⌘U).
- **Unit tests only:** run the `KiddoQuestTests` target (Swift Testing).
- **UI tests only:** run the `KiddoQuestUITests` target (XCUIAutomation). UI tests launch the app with
  `-uiTesting`, so it starts fresh with an in-memory store and never changes real progress.

Tip: on Macs with 8 GB of memory, run only one simulator at a time.

## 6. Project structure

```
KiddoQuest/
├── KiddoQuest.swift          App entry, scene phase (music + play-time clock)
├── ContentView.swift         Welcome screen, NavigationStack, break-time overlay
├── Components/               Reusable SwiftUI components and modifiers
├── Models/                   Value types, game catalogue, game flow, progress summaries
├── Persistence/              Core Data stack (programmatic model) and CoreDataManager
├── Services/                 AR scene, audio, play-time tracker, stickers, levels, test environment
├── Theme/                    Design system (colours, typography, layout) and Calm Mode
├── ViewModels/               @Observable view models, one per game
└── Views/                    Screens and the eight games
KiddoQuestTests/              Unit tests (Swift Testing)
KiddoQuestUITests/            UI tests (XCUIAutomation)
```

See [PartA_TechnicalDesign.md](PartA_TechnicalDesign.md) for details.
