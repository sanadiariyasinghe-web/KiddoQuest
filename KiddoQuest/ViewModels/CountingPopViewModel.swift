import SwiftUI

// MARK: - Counting Pop Game Item
struct CountingItem: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    var isPopped: Bool = false
    var scale: CGFloat = 0.1
    var opacity: Double = 0.0
}

@Observable
final class CountingPopViewModel {
    // Gameplay state
    var questionText: String = "How many yummy apples?"
    var currentEmoji: String = "🍎"
    var currentItemName: String = "apples"
    var targetCount: Int = 4
    var items: [CountingItem] = []
    var options: [Int] = [3, 4, 5, 6]
    var selectedAnswer: Int? = nil
    
    // Scoring & stars
    var score: Int = 0
    var starsEarned: Int = 0
    var correctInRound: Int = 0
    var correctAnswers: Int = 0
    var totalRounds: Int = 5
    var currentRound: Int = 1
    var difficultyLevel: Int = 1
    /// Gentle level: decides how many number cards to choose from.
    let level: Int = GameLevelStore.shared.level(for: "num_1")
    private(set) var newLevel: Int? = nil
    private var hasMissedThisRound = false
    
    // Feedback
    var isCorrect: Bool = false
    var isGentleRetry: Bool = false
    var showConfetti: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Count the treats. Then tap the number!"
    var isGameCompleted: Bool = false
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: totalRounds),
            correctAnswers: correctAnswers,
            totalQuestions: totalRounds,
            newLevel: newLevel
        )
    }
    
    // Questions pool
    private let itemTypes: [(emoji: String, name: String)] = [
        ("🍎", "apples"),
        ("🍌", "bananas"),
        ("🍓", "strawberries"),
        ("⭐", "stars"),
        ("🎈", "balloons"),
        ("🍪", "cookies"),
        ("🥕", "carrots")
    ]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        currentRound = 1
        score = 0
        starsEarned = 0
        correctInRound = 0
        correctAnswers = 0
        isGameCompleted = false
        setupRound()
    }
    
    func setupRound() {
        isCorrect = false
        isGentleRetry = false
        showConfetti = false
        selectedAnswer = nil
        hasMissedThisRound = false
        mascotMood = .idle
        
        let selectedItem = itemTypes.randomElement() ?? ("🍎", "apples")
        currentEmoji = selectedItem.emoji
        currentItemName = selectedItem.name
        
        // Adaptive difficulty: Level 1 (2–5), Level 2 (4–8), Level 3 (6–10)
        let countRange: ClosedRange<Int>
        switch difficultyLevel {
        case 1: countRange = 2...5
        case 2: countRange = 4...8
        default: countRange = 6...10
        }
        
        targetCount = Int.random(in: countRange)
        questionText = "How many \(selectedItem.name)?"
        mascotMessage = "Count the \(selectedItem.name). Then tap the number!"
        
        // Generate unique number cards (2, 3 or 4 depending on the child's level)
        let choiceCount = GameLevels.choiceCount(forLevel: level)
        var choices = Set<Int>()
        choices.insert(targetCount)
        while choices.count < choiceCount {
            let offset = Int.random(in: -3...3)
            let candidate = targetCount + offset
            if candidate > 0 && candidate <= 12 {
                choices.insert(candidate)
            }
        }
        options = Array(choices).shuffled()
        
        // Spawn items
        items = (0..<targetCount).map { _ in
            CountingItem(emoji: currentEmoji)
        }
    }
    
    func checkAnswer(_ answer: Int) {
        guard !isCorrect, !isGameCompleted else { return }
        selectedAnswer = answer
        
        if answer == targetCount {
            // Correct answer
            isCorrect = true
            isGentleRetry = false
            showConfetti = true
            mascotMood = .celebrating
            if hasMissedThisRound {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            correctInRound += 1
            
            // Adaptive difficulty progression
            if correctInRound >= 2 && difficultyLevel < 3 {
                difficultyLevel += 1
            }
            
            starsEarned = GameScoring.stars(correct: correctAnswers, total: totalRounds)
            mascotMessage = "Yes! There are \(targetCount) \(currentEmoji)!"
            
            SoundService.shared.playCorrectSound()
            
            // Advance to next round or finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
                guard let self = self else { return }
                if self.currentRound < self.totalRounds {
                    self.currentRound += 1
                    self.setupRound()
                } else {
                    self.finishGame()
                }
            }
        } else {
            // Gentle retry: NEVER shame or penalize
            isCorrect = false
            isGentleRetry = true
            hasMissedThisRound = true
            mascotMood = .encouraging
            mascotMessage = "Almost! Count again slowly. 🌟"
            
            // If struggling, lower difficulty
            if difficultyLevel > 1 {
                difficultyLevel -= 1
            }
            
            SoundService.shared.playTryAgainSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.isGentleRetry = false
            }
        }
    }
    
    private func finishGame() {
        isGameCompleted = true
        starsEarned = result.stars
        newLevel = GameLevelStore.shared.recordRound(gameID: "num_1", stars: starsEarned)
        mascotMood = .celebrating
        mascotMessage = "You finished all the counting! 🎉"
        SoundService.shared.playRewardCelebration()
        
        // Save to Core Data
        CoreDataManager.shared.saveGameProgress(
            gameID: "num_1",
            category: IslandCategory.numbers.rawValue,
            stars: starsEarned,
            score: score
        )
        CoreDataManager.shared.recordSession(
            duration: 90,
            gamesPlayed: 1,
            starsEarned: starsEarned
        )
    }
}
