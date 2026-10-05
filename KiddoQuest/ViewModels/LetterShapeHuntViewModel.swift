import SwiftUI

struct HuntItem: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let isTarget: Bool
    var isPopped: Bool = false
    var xOffset: CGFloat
    var yOffset: CGFloat
}

@Observable
final class LetterShapeHuntViewModel {
    var isShapeMode: Bool = false
    var targetSymbol: String = "A"
    var targetPrompt: String = "Find all the A letters!"
    var items: [HuntItem] = []
    
    var foundCount: Int = 0
    var totalRequired: Int = 3
    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    /// True if the child tapped a wrong bubble since their last correct find.
    private var hasMissedSinceLastFind = false
    
    var isCompleted: Bool = false
    var showConfetti: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Tap every matching bubble!"
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: totalRequired),
            correctAnswers: correctAnswers,
            totalQuestions: totalRequired
        )
    }
    
    init(isShapeMode: Bool = false) {
        self.isShapeMode = isShapeMode
        setupHunt()
    }
    
    func setupHunt() {
        foundCount = 0
        totalRequired = 3
        score = 0
        starsEarned = 0
        correctAnswers = 0
        hasMissedSinceLastFind = false
        isCompleted = false
        showConfetti = false
        mascotMood = .idle
        
        if isShapeMode {
            targetSymbol = "△"
            targetPrompt = "Find all the triangles!"
            // 3 triangles + distractors (circles, squares, stars)
            let rawList: [(String, Bool)] = [
                ("△", true), ("○", false), ("□", false),
                ("△", true), ("⭐", false), ("△", true),
                ("○", false), ("□", false)
            ]
            items = rawList.enumerated().map { index, entry in
                HuntItem(
                    symbol: entry.0,
                    isTarget: entry.1,
                    xOffset: CGFloat((index % 3) * 100 - 100),
                    yOffset: CGFloat((index / 3) * 90 - 90)
                )
            }
        } else {
            targetSymbol = "A"
            targetPrompt = "Find all the A letters!"
            let rawList: [(String, Bool)] = [
                ("A", true), ("B", false), ("A", true),
                ("C", false), ("A", true), ("D", false),
                ("E", false), ("B", false)
            ]
            items = rawList.enumerated().map { index, entry in
                HuntItem(
                    symbol: entry.0,
                    isTarget: entry.1,
                    xOffset: CGFloat((index % 3) * 100 - 100),
                    yOffset: CGFloat((index / 3) * 90 - 90)
                )
            }
        }
        
        mascotMessage = isShapeMode ? "Tap each triangle!" : "Tap each A!"
    }
    
    func tapItem(_ item: HuntItem) {
        guard !isCompleted,
              let index = items.firstIndex(where: { $0.id == item.id }),
              !items[index].isPopped else { return }
        
        if items[index].isTarget {
            // Correct pop!
            items[index].isPopped = true
            foundCount += 1
            if hasMissedSinceLastFind {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            hasMissedSinceLastFind = false
            starsEarned = GameScoring.stars(correct: correctAnswers, total: totalRequired)
            mascotMood = .celebrating
            
            SoundService.shared.playCorrectSound()
            
            if foundCount >= totalRequired {
                isCompleted = true
                showConfetti = true
                starsEarned = result.stars
                mascotMessage = "You found them all! 🎉"
                SoundService.shared.playRewardCelebration()
                
                // Save to Core Data
                CoreDataManager.shared.saveGameProgress(
                    gameID: isShapeMode ? "shp_hunt" : "let_2",
                    category: isShapeMode ? IslandCategory.shapes.rawValue : IslandCategory.letters.rawValue,
                    stars: starsEarned,
                    score: score
                )
                CoreDataManager.shared.recordSession(
                    duration: 65,
                    gamesPlayed: 1,
                    starsEarned: starsEarned
                )
            } else {
                let remaining = totalRequired - foundCount
                mascotMessage = "Pop! ⭐ \(remaining) more to find!"
            }
        } else {
            // Distractor tapped: gentle feedback
            hasMissedSinceLastFind = true
            mascotMood = .encouraging
            mascotMessage = "Almost! That is \(item.symbol). Look for \(targetSymbol)! 🌟"
            SoundService.shared.playTryAgainSound()
        }
    }
}
