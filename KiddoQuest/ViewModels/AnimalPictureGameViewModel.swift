import SwiftUI

// MARK: - Animal Picture Games
// Two picture-based Animals Island games for kindergarten children (no reading needed):
// • Feed the Animals – tap the food the animal likes.
// • Animal Shadows – tap the animal that matches the shadow.

struct AnimalChoice: Identifiable, Hashable {
    var id: String { emoji }
    let emoji: String
    let name: String
}

struct AnimalPictureRound: Identifiable {
    let id = UUID()
    let animal: AnimalChoice
    let answer: AnimalChoice
    let choices: [AnimalChoice]
}

enum AnimalPictureGame: Hashable {
    case feedAnimals
    case animalShadows
    
    var gameID: String {
        switch self {
        case .feedAnimals: return "ani_1"
        case .animalShadows: return "ani_2"
        }
    }
    
    var title: String {
        switch self {
        case .feedAnimals: return "Feed the Animals"
        case .animalShadows: return "Animal Shadows"
        }
    }
    
    var instructions: GameInstructions {
        switch self {
        case .feedAnimals: return .feedAnimals
        case .animalShadows: return .animalShadows
        }
    }
    
    func question(for round: AnimalPictureRound) -> String {
        switch self {
        case .feedAnimals: return "What does the \(round.animal.name) eat?"
        case .animalShadows: return "Whose shadow is this?"
        }
    }
    
    func successMessage(for round: AnimalPictureRound) -> String {
        switch self {
        case .feedAnimals: return "Yum! The \(round.animal.name) loves \(round.answer.name)!"
        case .animalShadows: return "Yes! It is the \(round.animal.name)!"
        }
    }
    
    // MARK: Content Pools
    private static let animalFoods: [(animal: AnimalChoice, food: AnimalChoice)] = [
        (AnimalChoice(emoji: "🐰", name: "bunny"), AnimalChoice(emoji: "🥕", name: "carrots")),
        (AnimalChoice(emoji: "🐶", name: "dog"), AnimalChoice(emoji: "🦴", name: "bones")),
        (AnimalChoice(emoji: "🐵", name: "monkey"), AnimalChoice(emoji: "🍌", name: "bananas")),
        (AnimalChoice(emoji: "🐱", name: "cat"), AnimalChoice(emoji: "🐟", name: "fish")),
        (AnimalChoice(emoji: "🐭", name: "mouse"), AnimalChoice(emoji: "🧀", name: "cheese")),
        (AnimalChoice(emoji: "🐼", name: "panda"), AnimalChoice(emoji: "🎋", name: "bamboo")),
        (AnimalChoice(emoji: "🐝", name: "bee"), AnimalChoice(emoji: "🌻", name: "flowers")),
        (AnimalChoice(emoji: "🐔", name: "hen"), AnimalChoice(emoji: "🌽", name: "corn"))
    ]
    
    private static let shadowAnimals: [AnimalChoice] = [
        AnimalChoice(emoji: "🐘", name: "elephant"),
        AnimalChoice(emoji: "🦒", name: "giraffe"),
        AnimalChoice(emoji: "🐢", name: "turtle"),
        AnimalChoice(emoji: "🐧", name: "penguin"),
        AnimalChoice(emoji: "🦁", name: "lion"),
        AnimalChoice(emoji: "🐰", name: "bunny"),
        AnimalChoice(emoji: "🐌", name: "snail"),
        AnimalChoice(emoji: "🦋", name: "butterfly"),
        AnimalChoice(emoji: "🐙", name: "octopus"),
        AnimalChoice(emoji: "🦀", name: "crab")
    ]
    
    /// Builds random rounds, each with the right answer and two different distractors.
    func makeRounds(count: Int) -> [AnimalPictureRound] {
        switch self {
        case .feedAnimals:
            return Self.animalFoods.shuffled().prefix(count).map { pair in
                let distractors = Self.animalFoods
                    .map(\.food)
                    .filter { $0 != pair.food }
                    .shuffled()
                    .prefix(2)
                return AnimalPictureRound(
                    animal: pair.animal,
                    answer: pair.food,
                    choices: ([pair.food] + distractors).shuffled()
                )
            }
        case .animalShadows:
            return Self.shadowAnimals.shuffled().prefix(count).map { animal in
                let distractors = Self.shadowAnimals
                    .filter { $0 != animal }
                    .shuffled()
                    .prefix(2)
                return AnimalPictureRound(
                    animal: animal,
                    answer: animal,
                    choices: ([animal] + distractors).shuffled()
                )
            }
        }
    }
}

// MARK: - View Model
@Observable
final class AnimalPictureGameViewModel {
    let game: AnimalPictureGame
    let totalRounds = 5
    
    var rounds: [AnimalPictureRound] = []
    var currentRoundIndex: Int = 0
    /// Wrong choices fade out so the child can easily try again.
    var wrongChoiceIDs: Set<String> = []
    
    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    private var hasMissedThisRound = false
    
    var isCorrect: Bool = false
    var isGentleRetry: Bool = false
    var showConfetti: Bool = false
    var isGameCompleted: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = ""
    
    var currentRound: AnimalPictureRound {
        rounds[currentRoundIndex]
    }
    
    var questionText: String {
        game.question(for: currentRound)
    }
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: totalRounds),
            correctAnswers: correctAnswers,
            totalQuestions: totalRounds
        )
    }
    
    init(game: AnimalPictureGame) {
        self.game = game
        rounds = game.makeRounds(count: totalRounds)
        setupRound()
    }
    
    func setupRound() {
        isCorrect = false
        isGentleRetry = false
        showConfetti = false
        hasMissedThisRound = false
        wrongChoiceIDs.removeAll()
        mascotMood = .idle
        mascotMessage = game == .feedAnimals ? "I'm hungry! 😋" : "Who can it be? 🤔"
    }
    
    func choose(_ choice: AnimalChoice) {
        guard !isCorrect, !isGameCompleted, !wrongChoiceIDs.contains(choice.id) else { return }
        
        if choice == currentRound.answer {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                isCorrect = true
                showConfetti = true
            }
            if hasMissedThisRound {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            starsEarned = GameScoring.stars(correct: correctAnswers, total: totalRounds)
            mascotMood = .celebrating
            mascotMessage = game.successMessage(for: currentRound) + " ⭐"
            SoundService.shared.playCorrectSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self else { return }
                if self.currentRoundIndex < self.rounds.count - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.currentRoundIndex += 1
                        self.setupRound()
                    }
                } else {
                    self.finishGame()
                }
            }
        } else {
            // Gentle retry: the wrong picture fades, never a penalty
            hasMissedThisRound = true
            withAnimation(.easeInOut(duration: 0.3)) {
                _ = wrongChoiceIDs.insert(choice.id)
            }
            isGentleRetry = true
            mascotMood = .encouraging
            mascotMessage = "Almost! Try again! 🌟"
            SoundService.shared.playTryAgainSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.isGentleRetry = false
            }
        }
    }
    
    private func finishGame() {
        isGameCompleted = true
        starsEarned = result.stars
        mascotMood = .celebrating
        mascotMessage = "You did it! 🎉"
        SoundService.shared.playRewardCelebration()
        
        // Save to Core Data
        CoreDataManager.shared.saveGameProgress(
            gameID: game.gameID,
            category: IslandCategory.animals.rawValue,
            stars: starsEarned,
            score: score
        )
        CoreDataManager.shared.recordSession(
            duration: 70,
            gamesPlayed: 1,
            starsEarned: starsEarned
        )
    }
}
