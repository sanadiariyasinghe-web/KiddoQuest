import SwiftUI

// MARK: - Find It! View Model
// Five hunts per round. The child photographs something; Vision checks it.
// Wrong guesses are gentle: Buddy says what he saw and the child tries again (or skips).

@Observable
final class FindItViewModel {
    enum Feedback: Equatable {
        case none
        case checking
        case found
        case tryAgain(saw: String?)
        case skipped
    }

    static let gameID = "shp_3"

    let targets: [FindItTarget]
    var currentIndex: Int = 0
    var photo: UIImage?
    var feedback: Feedback = .none

    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    private var hasMissedThisRound = false

    var isGameCompleted: Bool = false
    var showConfetti: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Take a photo of it!"

    var currentTarget: FindItTarget { targets[currentIndex] }
    var isChecking: Bool { feedback == .checking }
    var isShowingSuccess: Bool { feedback == .found }

    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: targets.count),
            correctAnswers: correctAnswers,
            totalQuestions: targets.count,
            correctLabel: "Things Found"
        )
    }

    init(targets: [FindItTarget] = FindItRules.makeRound()) {
        self.targets = targets.isEmpty ? FindItRules.makeRound() : targets
    }

    // MARK: - Checking a photo

    /// Checks a photo with Vision (objects) or the centre colour (colours).
    func check(_ image: UIImage) async {
        guard !isChecking, !isShowingSuccess, !isGameCompleted else { return }
        photo = image
        feedback = .checking
        mascotMood = .idle
        mascotMessage = "Let me look… 🔍"

        switch currentTarget {
        case .object(_, _, let labels):
            let observations = await ImageClassifier.classify(image)
            evaluate(
                matched: FindItRules.matches(labels: labels, observations: observations),
                saw: FindItRules.bestGuess(from: observations)
            )
        case .color(let wanted):
            let seen = ImageClassifier.centreColor(of: image).flatMap {
                FindItRules.dominantColor(red: $0.red, green: $0.green, blue: $0.blue)
            }
            evaluate(matched: seen == wanted, saw: seen.map { "something \($0.name.lowercased())" })
        }
    }

    /// Applies a check result (separate from Vision so it can be unit-tested).
    func evaluate(matched: Bool, saw: String?) {
        if matched {
            if hasMissedThisRound {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            starsEarned = GameScoring.stars(correct: correctAnswers, total: targets.count)
            feedback = .found
            showConfetti = true
            mascotMood = .celebrating
            mascotMessage = "Yes! \(currentTarget.successMessage) ⭐"
            SoundService.shared.playCorrectSound()
            advance(after: 2.2)
        } else {
            hasMissedThisRound = true
            feedback = .tryAgain(saw: saw)
            mascotMood = .encouraging
            if let saw {
                mascotMessage = "I see \(saw)! Try again 🌟"
            } else {
                mascotMessage = "Hmm, I'm not sure. Try again 🌟"
            }
            SoundService.shared.playTryAgainSound()
        }
    }

    /// Moves on without a point, so a child is never stuck.
    func skip() {
        guard !isChecking, !isShowingSuccess, !isGameCompleted else { return }
        feedback = .skipped
        mascotMood = .idle
        mascotMessage = "That's OK! Let's find the next one."
        advance(after: 0.8)
    }

    // MARK: - Private

    private func advance(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.currentIndex < self.targets.count - 1 {
                self.currentIndex += 1
                self.photo = nil
                self.feedback = .none
                self.hasMissedThisRound = false
                self.mascotMood = .idle
                self.mascotMessage = "Take a photo of it!"
            } else {
                self.finish()
            }
        }
    }

    private func finish() {
        isGameCompleted = true
        starsEarned = result.stars
        mascotMood = .celebrating
        mascotMessage = "You are a super finder! 🎉"
        SoundService.shared.playRewardCelebration()

        CoreDataManager.shared.saveGameProgress(
            gameID: Self.gameID,
            category: IslandCategory.shapes.rawValue,
            stars: starsEarned,
            score: score
        )
        CoreDataManager.shared.recordSession(duration: 120, gamesPlayed: 1, starsEarned: starsEarned)
    }
}
