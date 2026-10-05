import SwiftUI

struct MatchPair: Identifiable, Hashable {
    let id: String
    let sourceDisplay: String // e.g. "🍎🍎🍎" or "A"
    let targetDisplay: String // e.g. "3" or "a"
    var isMatched: Bool = false
}

@Observable
final class DragMatchViewModel {
    var category: IslandCategory = .numbers
    var pairs: [MatchPair] = []
    var targetOrder: [MatchPair] = []
    var matchedPairIds: Set<String> = []
    /// Pairs the child tried to match incorrectly at least once.
    private var retriedPairIds: Set<String> = []
    
    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    var isCompleted: Bool = false
    var showConfetti: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = ""
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: pairs.count),
            correctAnswers: correctAnswers,
            totalQuestions: pairs.count
        )
    }
    
    /// What the child should tap first.
    private var firstStepPrompt: String {
        category == .numbers ? "Tap the fruits." : "Tap a big letter."
    }
    
    /// What the child should tap after choosing an item.
    private var secondStepPrompt: String {
        category == .numbers ? "Now tap their number." : "Now tap its small letter."
    }
    
    init(category: IslandCategory = .numbers) {
        self.category = category
        setupGame()
    }
    
    func setupGame() {
        matchedPairIds.removeAll()
        retriedPairIds.removeAll()
        score = 0
        starsEarned = 0
        correctAnswers = 0
        isCompleted = false
        showConfetti = false
        mascotMood = .idle
        
        if category == .numbers {
            pairs = [
                MatchPair(id: "p1", sourceDisplay: "🍎", targetDisplay: "1"),
                MatchPair(id: "p2", sourceDisplay: "🍌🍌", targetDisplay: "2"),
                MatchPair(id: "p3", sourceDisplay: "🍓🍓🍓", targetDisplay: "3")
            ]
        } else {
            pairs = [
                MatchPair(id: "la", sourceDisplay: "A", targetDisplay: "a"),
                MatchPair(id: "lb", sourceDisplay: "B", targetDisplay: "b"),
                MatchPair(id: "lc", sourceDisplay: "C", targetDisplay: "c")
            ]
        }
        mascotMessage = firstStepPrompt
        
        // Shuffle targets on the right side so they aren't directly aligned
        targetOrder = pairs.shuffled()
    }
    
    /// Guides the child to the next step after they pick an item on the left.
    func didSelectSource() {
        mascotMood = .idle
        mascotMessage = secondStepPrompt
    }
    
    /// Reminds the child to pick an item on the left first.
    func remindFirstStep() {
        mascotMood = .encouraging
        mascotMessage = "First, \(firstStepPrompt.lowercased())"
    }
    
    func registerMatch(pairId: String) {
        guard !matchedPairIds.contains(pairId) else { return }
        matchedPairIds.insert(pairId)
        if retriedPairIds.contains(pairId) {
            score += GameScoring.retryPoints
        } else {
            score += GameScoring.firstTryPoints
            correctAnswers += 1
        }
        starsEarned = GameScoring.stars(correct: correctAnswers, total: pairs.count)
        mascotMood = .celebrating
        
        SoundService.shared.playCorrectSound()
        
        if matchedPairIds.count >= pairs.count {
            isCompleted = true
            showConfetti = true
            starsEarned = result.stars
            mascotMessage = "You matched them all! 🎉"
            SoundService.shared.playRewardCelebration()
            
            // Save to Core Data
            let gameID = category == .numbers ? "num_2" : "let_1"
            CoreDataManager.shared.saveGameProgress(
                gameID: gameID,
                category: category.rawValue,
                stars: starsEarned,
                score: score
            )
            CoreDataManager.shared.recordSession(
                duration: 75,
                gamesPlayed: 1,
                starsEarned: starsEarned
            )
        } else {
            mascotMessage = "Great match! ⭐ \(firstStepPrompt)"
        }
    }
    
    func registerFail(sourceId: String) {
        retriedPairIds.insert(sourceId)
        mascotMood = .encouraging
        mascotMessage = "Almost! Try again! 🌟"
        SoundService.shared.playTryAgainSound()
    }
}
