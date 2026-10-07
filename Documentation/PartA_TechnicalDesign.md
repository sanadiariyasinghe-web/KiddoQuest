# KiddoQuest — Technical Design (Part A, iOS)

## 1. Overview

| Area | Choice |
| --- | --- |
| UI | SwiftUI (iOS 27), custom design system (`Theme`) |
| Architecture | MVVM with `@Observable` view models and small service objects |
| Navigation | `NavigationStack` with a typed `AppRoute` enum and a shared `NavigationPath` |
| Persistence | Core Data (programmatic model) + `UserDefaults` for lightweight settings |
| Emerging technology | ARKit (world tracking, plane detection, coaching) + RealityKit (3D entities, hit-testing) |
| Audio | `AVAudioEngine` with runtime-synthesised tones (no audio files) |
| Testing | Swift Testing (unit), XCUIAutomation (UI) |
| Concurrency | Swift structured concurrency (`async`/`await`, `Task`, `.task` modifiers); main-actor default isolation |

## 2. Architecture

```
Views (SwiftUI)  ──reads/binds──▶  ViewModels (@Observable)  ──calls──▶  Services / Persistence
      │                                   │                                   │
      ▼                                   ▼                                   ▼
Components (reusable UI)          Models (value types, pure rules)     Core Data, UserDefaults,
Theme (design system)                                                  ARKit/RealityKit, AVAudioEngine
```

- **Views** stay declarative. Each game view only lays out its content and passes it to `GameFlowContainer`.
- **ViewModels** hold one game's state and rules (`CountingPopViewModel`, `AnimalPictureGameViewModel`, …).
- **Models** contain pure, easily tested logic: `GameScoring`, `ProgressSummary`, `WeeklyLearningSummary`, `PlayTimeRules`, `GameLevels`.
- **Services** wrap platform APIs: `ARSceneController`, `SoundService`, `MusicService`, `PlayTimeTracker`, `StickerBook`, `GameLevelStore`.

## 3. Navigation

`ContentView` owns a single `NavigationPath`:

```
Home ─▶ Category (island) ─▶ Game list ─▶ Game (GamePlayView routes by GameType)
  ├──▶ Rewards (sticker book + badges)
  ├──▶ Profile
  ├──▶ Parent Settings (behind the parent gate)
  └──▶ AR Learning Mode
```

- **Home** on the results screen resets the path (`NavigationPath()`).
- **More Games** removes the last element (the game), returning to the island's game list.
- Inside games, the system back arrow is hidden and replaced by a large 🏠 button with a confirmation, so children can't leave by accident.

## 4. The shared game flow

`GameFlowContainer` (Components) wraps every game:

| Phase (`GamePhase`) | UI | Notes |
| --- | --- | --- |
| `.instructions` | `GameInstructionsView` | Picture sentence (`PictureStep`s), short text steps, pulsing **Let's Play!** |
| `.playing` | the game's content | Pointing-hand hints via `HintTargetKey` preference + `HintHandView` |
| `.results` | `RoundResultsView` | Stars revealed one by one, correct answers, level-up, new sticker, owl dance, Home / More Games / Play Again |

**Pointing-hand hints** use an anchor preference. A game marks the correct target with
`.hintTarget(isCorrect)`; the container reads the anchor with `overlayPreferenceValue` and draws the
animated 👆 at that spot. It first appears 0.8 s after play starts, then again after 8 s with no taps
(tracked with a `simultaneousGesture` and `ContinuousClock`).

**Scoring** (`GameScoring`) is shared by all games: 20 points for a first-try answer and 10 after a retry.
Stars come from first-try accuracy (≥ 80 % → 3, ≥ 50 % → 2, otherwise 1), and every finished round earns
at least one star.

**Gentle levels** (`GameLevels`, `GameLevelStore`): level 1–3 gives 2–4 choices. A 3-star round moves
the child up one level, saved per game in `UserDefaults`.

## 5. Data persistence

### Core Data

The model is built **in code** (`PersistenceController.createManagedObjectModel()`), with four entities:

| Entity | Key attributes | Used for |
| --- | --- | --- |
| `ChildProfileEntity` | name, avatar, age, totalStars | Profile and the Home star counter |
| `GameProgressEntity` | gameID, category, completed, stars (best), score, bestScore, lastPlayed | Home and game-list progress, weekly summary |
| `SessionHistoryEntity` | date, duration, gamesPlayed, starsEarned | Parent sessions list and weekly totals |
| `BadgeEntity` | name, category, earnedDate, isUnlocked | Badges on the Rewards screen |

`CoreDataManager` (an `@Observable` singleton) performs fetches and saves on the view context and
publishes `currentProfile`, `badges`, `recentSessions` and `progressByGame`. SwiftUI views update
automatically when these change.

Design notes:

- A **single shared `NSManagedObjectModel`** is reused for every store. Creating one per store makes Core Data unable to map `NSManagedObject` subclasses when two stores exist (for example during tests).
- Automated tests use an **in-memory store** (`AppEnvironment.usesInMemoryStore`), so tests never change a child's real data.

### UserDefaults

Small, non-relational settings: sound, music, Calm Mode, daily limit, play time per day,
per-game levels, intro seen, and the sticker book (stored as JSON-encoded `[Sticker]`).

## 6. Emerging technology: ARKit + RealityKit

`ARRealityViewRepresentable` (a `UIViewRepresentable`) hosts an `ARView` configured manually
(`automaticallyConfigureSession: false`). Its coordinator is `ARSceneController`:

1. **Tracking:** runs `ARWorldTrackingConfiguration` with horizontal plane detection and automatic environment texturing.
2. **Coaching:** adds `ARCoachingOverlayView` (goal `.horizontalPlane`) so children are guided to point at a surface.
3. **Placement:** once a plane is found, a tap that misses every object is ray-cast onto the real surface
   (`ARView.raycast(from:allowing: .estimatedPlane, alignment: .horizontal)`). An `AnchorEntity(world:)` is created at that point,
   and the row of objects is turned (yaw) to face the camera. **Move** removes the anchor so the child can tap a new spot.
4. **Content:** each learning object is a container entity with a cylinder stand and a 3D model:
   - letters: `MeshResource.generateText(_:extrusionDepth:font:…)` (2.5 cm deep, bold rounded colours),
   - shapes: a SwiftUI `Path` (triangle, circle, square, star, heart) extruded with `MeshResource(extruding:extrusionOptions:)`,
   - animals: a rounded `generateBox` cube whose faces show the animal, drawn with `UIGraphicsImageRenderer` and loaded with `TextureResource(image:options:)` into an `UnlitMaterial`,
   - collision shapes for hit-testing. A repeating `FromToByAnimation<Transform>` sways each model (off in Calm Mode / Reduce Motion).
5. **Interaction:** a `UITapGestureRecognizer` calls `ARView.entity(at:)`, walks up to the object's container, and passes the item to `ARLearningViewModel.tapObject`.
6. **Feedback:** exploring an object makes it hop. Finding the target lifts and scales it (`Entity.move(to:relativeTo:duration:)`) and turns its stand green.
7. **Challenges (`ARChallengeRules`, pure and unit-tested):** five random objects per mode, three different targets per session, first-try stars (`GameScoring`), a sticker (`StickerBook`), and progress plus the AR Explorer badge saved in Core Data.
8. **State:** `ARSessionDelegate.session(_:didAdd:)` sets `isSurfaceFound` when the first `ARPlaneAnchor` appears, and the SwiftUI status pill updates.

If `ARWorldTrackingConfiguration.isSupported` is false (simulator, older devices), the view falls back to
a 2D "simulated room" with the same game logic.

## 7. Audio

`ToneSynthesizer` renders notes (sine waves with a soft attack and decay) into `AVAudioPCMBuffer`s.

- `MusicService`: a calm pentatonic loop (the same melody as the tvOS app) at very low volume, which resumes when the app becomes active.
- `SoundService`: short chimes (correct, try again, click, reward) plus haptics.
- Both use the `.ambient` audio session: they mix with other audio and respect the silent switch.

## 8. Custom SwiftUI components and modifiers

| Component / modifier | Purpose |
| --- | --- |
| `GameFlowContainer` | Generic container for the Learn → Play → Results journey |
| `GameInstructionsView`, `RoundResultsView`, `GameJourneyIndicator` | Shared flow screens |
| `HintHandView` + `.hintTarget(_:)` (anchor preference) | Pointing-hand hints |
| `CelebratingOwlView`, `MascotView` | Animated mascot |
| `ParticleBurstView` | Pure SwiftUI confetti |
| `.animatedFeedback(isSuccess:isGentleRetry:)` | Success pop and gentle shake |
| `.floating(...)` | Bobbing animation (disabled in Calm Mode) |
| `@CalmModeEnabled` (custom `DynamicProperty` property wrapper) | Calm Mode or Reduce Motion |
| `BouncyButtonStyle`, `PrimaryChildButton`, `ParentGateView`, `ProgressStarBar`, `GameCard` | Child-friendly controls |

## 9. Design system, accessibility and adaptivity

- **Theme:** island colours, adaptive light/dark backgrounds and text colours, spacing, corner radius and rounded typography.
- **Dark Mode:** all theme colours are dynamic `UIColor`s.
- **Dynamic Type:** `Theme.Typography` scales sizes with `UIFontMetrics` (capped at 1.5×). The root view redraws when the text size changes, while keeping the navigation path.
- **VoiceOver:** labels on interactive elements; decorative emoji hidden; answers stay hidden (e.g. a shadow is read as "Animal shadow" until it is matched).
- **Reduce Motion:** automatically enables Calm Mode.
- **Adaptive layouts:** adaptive grids on Home and the game lists. Games and cards are limited to a comfortable width (`Theme.Layout`) on iPad and in landscape. iPhone is portrait-only (a deliberate choice for a children's game); iPad supports all orientations.

## 10. Performance and memory

- No bundled media: audio is synthesised and AR textures are generated at runtime.
- Audio buffers are cached per effect, and a single engine is reused.
- `[weak self]` in delayed callbacks prevents retain cycles in view models.
- The AR session is paused in `dismantleUIView`.
- Calm Mode removes repeating animations on low-end devices.
- Fetches are small and targeted (fetch limits, predicates).
