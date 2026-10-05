import SwiftUI

struct ColorOption: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let emoji: String
}

struct ColoringTask: Identifiable, Hashable {
    let id = UUID()
    let shapeName: String
    let shapeSymbol: String // e.g. "circle.fill", "triangle.fill", "star.fill", "square.fill"
    let targetColorName: String
    let targetColor: Color
}

@Observable
final class ColoringViewModel {
    var currentTaskIndex: Int = 0
    var tasks: [ColoringTask] = [
        ColoringTask(shapeName: "Circle", shapeSymbol: "circle.fill", targetColorName: "Red", targetColor: Color.red),
        ColoringTask(shapeName: "Star", shapeSymbol: "star.fill", targetColorName: "Yellow", targetColor: Theme.ColorPalette.starGold),
        ColoringTask(shapeName: "Square", shapeSymbol: "square.fill", targetColorName: "Blue", targetColor: Theme.ColorPalette.lettersBlue),
        ColoringTask(shapeName: "Triangle", shapeSymbol: "triangle.fill", targetColorName: "Green", targetColor: Theme.ColorPalette.animalsGreen)
    ]
    
    let colorOptions: [ColorOption] = [
        ColorOption(id: "red", name: "Red", color: Color.red, emoji: "🔴"),
        ColorOption(id: "blue", name: "Blue", color: Theme.ColorPalette.lettersBlue, emoji: "🔵"),
        ColorOption(id: "yellow", name: "Yellow", color: Theme.ColorPalette.numbersYellow, emoji: "🟡"),
        ColorOption(id: "green", name: "Green", color: Theme.ColorPalette.animalsGreen, emoji: "🟢")
    ]
    
    var currentTask: ColoringTask {
        tasks[currentTaskIndex]
    }
    
    var filledColor: Color? = nil
    var isFilled: Bool = false
    var isCorrect: Bool = false
    var isGentleRetry: Bool = false
    var showConfetti: Bool = false
    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    private var hasMissedThisRound = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = ""
    var isGameCompleted: Bool = false
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: tasks.count),
            correctAnswers: correctAnswers,
            totalQuestions: tasks.count
        )
    }
    
    init() {
        startRound()
    }
    
    func startRound() {
        filledColor = nil
        isFilled = false
        isCorrect = false
        isGentleRetry = false
        showConfetti = false
        hasMissedThisRound = false
        mascotMood = .idle
        mascotMessage = "Paint the \(currentTask.shapeName) \(currentTask.targetColorName)!"
    }
    
    func selectColor(_ option: ColorOption) {
        guard !isFilled, !isGameCompleted else { return }
        if option.name == currentTask.targetColorName {
            // Correct color!
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                filledColor = option.color
                isFilled = true
                isCorrect = true
                showConfetti = true
            }
            if hasMissedThisRound {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            starsEarned = GameScoring.stars(correct: correctAnswers, total: tasks.count)
            mascotMood = .celebrating
            mascotMessage = "Great job! The \(currentTask.shapeName) is \(option.name)!"
            
            SoundService.shared.playCorrectSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                if self.currentTaskIndex < self.tasks.count - 1 {
                    self.currentTaskIndex += 1
                    self.startRound()
                } else {
                    self.isGameCompleted = true
                    self.starsEarned = self.result.stars
                    self.mascotMessage = "You painted every shape! 🎉"
                    SoundService.shared.playRewardCelebration()
                    
                    // Save to Core Data
                    CoreDataManager.shared.saveGameProgress(
                        gameID: "shp_1",
                        category: IslandCategory.shapes.rawValue,
                        stars: self.starsEarned,
                        score: self.score
                    )
                    CoreDataManager.shared.recordSession(
                        duration: 80,
                        gamesPlayed: 1,
                        starsEarned: self.starsEarned
                    )
                }
            }
        } else {
            // Gentle retry
            isGentleRetry = true
            hasMissedThisRound = true
            mascotMood = .encouraging
            mascotMessage = "Almost! Find the \(currentTask.targetColorName) paint. 🎨"
            SoundService.shared.playTryAgainSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.isGentleRetry = false
            }
        }
    }
}
