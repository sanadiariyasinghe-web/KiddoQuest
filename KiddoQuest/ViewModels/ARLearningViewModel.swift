import SwiftUI
import ARKit

// MARK: - AR Learning View Model
// Five 3D learning objects (letters, shapes or animals) are placed on a real surface.
// The child explores them by tapping (Buddy tells a fact) and completes three
// "Find the …!" challenges, earning stars, a sticker and saved progress.

@Observable
final class ARLearningViewModel {
    var selectedMode: ARMode = .letterHunt
    var isARSupported: Bool = ARService.shared.isARSupported

    var instructionText: String = ""
    var targetObjects: [ARObjectItem] = []
    /// Changes whenever a new set of objects is created, so the AR scene rebuilds its 3D objects.
    var layoutID = UUID()
    /// True once ARKit has found a real table or floor.
    var isSurfaceFound: Bool = false
    /// True once the child has tapped the surface and the objects are standing on it.
    var isPlaced: Bool = false

    /// Ids of the objects to find, one per round.
    private(set) var rounds: [UUID] = []
    private(set) var roundIndex: Int = 0
    /// True while the "found it" celebration plays before the next round.
    private(set) var isAdvancing: Bool = false
    private var missedThisRound = false
    private(set) var firstTryFinds: Int = 0

    var foundCount: Int = 0
    var totalRequired: Int = ARChallengeRules.roundCount
    var score: Int = 0
    var starsEarned: Int = 0

    var isCompleted: Bool = false
    var showConfetti: Bool = false
    var isGentleRetry: Bool = false
    /// The sticker earned for finishing all challenges.
    private(set) var newSticker: Sticker?
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Look around through the camera and find the target!"

    init() {
        setupMode(.letterHunt)
    }

    /// The object the child is looking for right now.
    var currentTarget: ARObjectItem? {
        guard rounds.indices.contains(roundIndex) else { return nil }
        return targetObjects.first { $0.id == rounds[roundIndex] }
    }

    func isTarget(_ item: ARObjectItem) -> Bool {
        item.id == currentTarget?.id
    }

    func switchMode(to mode: ARMode) {
        selectedMode = mode
        setupMode(mode)
    }

    func playAgain() {
        setupMode(selectedMode)
    }

    func setupMode(_ mode: ARMode) {
        foundCount = 0
        score = 0
        starsEarned = 0
        firstTryFinds = 0
        missedThisRound = false
        isAdvancing = false
        isCompleted = false
        showConfetti = false
        isGentleRetry = false
        newSticker = nil
        mascotMood = .idle
        layoutID = UUID()

        targetObjects = ARChallengeRules.makeObjects(for: mode)
        rounds = ARChallengeRules.makeRounds(from: targetObjects)
        totalRequired = rounds.count
        roundIndex = 0
        instructionText = currentTarget.map { ARChallengeRules.prompt(for: $0) } ?? ""

        switch mode {
        case .letterHunt: mascotMessage = "Tap the letters to explore, then find the one I ask for!"
        case .shapeHunt: mascotMessage = "Tap the shapes to explore, then find the one I ask for!"
        case .animalDiscovery: mascotMessage = "Tap the animals to say hello, then find the one I ask for!"
        }
    }

    func tapObject(_ item: ARObjectItem) {
        guard !isCompleted, !isAdvancing,
              let index = targetObjects.firstIndex(where: { $0.id == item.id }),
              !targetObjects[index].isDiscovered else { return }

        if isTarget(item) {
            found(at: index)
        } else {
            explore(targetObjects[index])
        }
    }

    // MARK: - Private

    private func found(at index: Int) {
        let item = targetObjects[index]
        targetObjects[index].isDiscovered = true
        foundCount += 1
        if missedThisRound {
            score += GameScoring.retryPoints
        } else {
            score += GameScoring.firstTryPoints
            firstTryFinds += 1
        }
        starsEarned = GameScoring.stars(correct: firstTryFinds, total: totalRequired)
        showConfetti = true
        mascotMood = .celebrating
        mascotMessage = "Yes! You found the \(item.name)! ⭐"
        SoundService.shared.playCorrectSound()

        if foundCount >= totalRequired {
            finish()
        } else {
            isAdvancing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                self?.advanceToNextRound()
            }
        }
    }

    /// Tapping another object is exploring, not failing: Buddy shares a fact and repeats the challenge.
    private func explore(_ item: ARObjectItem) {
        missedThisRound = true
        isGentleRetry = true
        mascotMood = .encouraging
        if let target = currentTarget {
            mascotMessage = "\(item.fact) Now can you find the \(target.name)? 🌟"
        } else {
            mascotMessage = item.fact
        }
        SoundService.shared.playButtonClick()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.isGentleRetry = false
        }
    }

    /// Moves to the next "Find the …!" round (called after the celebration).
    func advanceToNextRound() {
        guard isAdvancing, !isCompleted else { return }
        isAdvancing = false
        missedThisRound = false
        roundIndex += 1
        instructionText = currentTarget.map { ARChallengeRules.prompt(for: $0) } ?? ""
        mascotMood = .idle
        mascotMessage = "Next challenge: \(instructionText)"
    }

    private func finish() {
        isCompleted = true
        starsEarned = GameScoring.finalStars(correct: firstTryFinds, total: totalRequired)
        mascotMood = .celebrating
        mascotMessage = "Awesome Explorer! You finished every AR challenge! 🎉"
        SoundService.shared.playRewardCelebration()

        newSticker = StickerBook.shared.awardSticker(for: selectedMode.rawValue)

        // Save to Core Data & unlock the AR Explorer badge
        CoreDataManager.shared.saveGameProgress(
            gameID: "ar_\(selectedMode.rawValue)",
            category: "AR",
            stars: starsEarned,
            score: score
        )
        CoreDataManager.shared.unlockBadge(named: "AR Explorer")
        CoreDataManager.shared.recordSession(duration: 120, gamesPlayed: 1, starsEarned: starsEarned)
    }
}
