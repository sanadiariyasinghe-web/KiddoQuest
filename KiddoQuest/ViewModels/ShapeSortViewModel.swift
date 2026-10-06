import SwiftUI

struct SortBin: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
}

struct FallingShape: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let symbol: String
    let targetBinId: String
    let color: Color
}

@Observable
final class ShapeSortViewModel {
    let bins: [SortBin] = [
        SortBin(id: "triangle", name: "TRIANGLE", symbol: "△", color: Theme.ColorPalette.shapesPurple),
        SortBin(id: "circle", name: "CIRCLE", symbol: "○", color: Theme.ColorPalette.lettersBlue),
        SortBin(id: "square", name: "SQUARE", symbol: "□", color: Theme.ColorPalette.animalsGreen)
    ]
    
    /// One of each shape to sort.
    private static let shapeKinds: [FallingShape] = [
        FallingShape(name: "Triangle", symbol: "△", targetBinId: "triangle", color: Theme.ColorPalette.shapesPurple),
        FallingShape(name: "Circle", symbol: "○", targetBinId: "circle", color: Theme.ColorPalette.lettersBlue),
        FallingShape(name: "Square", symbol: "□", targetBinId: "square", color: Theme.ColorPalette.animalsGreen)
    ]

    /// 6 shapes in a fresh random order each game: every kind appears at least once.
    static func makeQueue(count: Int = 6) -> [FallingShape] {
        let extras = (0..<max(0, count - shapeKinds.count)).compactMap { _ in shapeKinds.randomElement() }
        return (shapeKinds + extras)
            .map { FallingShape(name: $0.name, symbol: $0.symbol, targetBinId: $0.targetBinId, color: $0.color) }
            .shuffled()
    }

    var queue: [FallingShape] = ShapeSortViewModel.makeQueue()
    
    var currentShapeIndex: Int = 0
    var bouncingBinId: String? = nil
    var score: Int = 0
    var starsEarned: Int = 0
    var correctAnswers: Int = 0
    private var hasMissedCurrentShape = false
    var isGameCompleted: Bool = false
    var showConfetti: Bool = false
    
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Tap the box that matches the shape!"
    
    var currentShape: FallingShape? {
        if currentShapeIndex < queue.count {
            return queue[currentShapeIndex]
        }
        return nil
    }
    
    var result: RoundResult {
        RoundResult(
            score: score,
            stars: GameScoring.finalStars(correct: correctAnswers, total: queue.count),
            correctAnswers: correctAnswers,
            totalQuestions: queue.count
        )
    }
    
    init() {
        startSorting()
    }
    
    func startSorting() {
        currentShapeIndex = 0
        score = 0
        starsEarned = 0
        correctAnswers = 0
        hasMissedCurrentShape = false
        isGameCompleted = false
        showConfetti = false
        mascotMood = .idle
        mascotMessage = "Tap the box that matches the shape!"
    }
    
    func dropShape(into bin: SortBin) {
        guard let shape = currentShape, !isGameCompleted else { return }
        
        if shape.targetBinId == bin.id {
            // Correct bin!
            bouncingBinId = bin.id
            if hasMissedCurrentShape {
                score += GameScoring.retryPoints
            } else {
                score += GameScoring.firstTryPoints
                correctAnswers += 1
            }
            hasMissedCurrentShape = false
            starsEarned = GameScoring.stars(correct: correctAnswers, total: queue.count)
            showConfetti = true
            mascotMood = .celebrating
            mascotMessage = "Yes! That is a \(shape.name)! ⭐"
            
            SoundService.shared.playCorrectSound()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                currentShapeIndex += 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.bouncingBinId = nil
            }
            
            if currentShape == nil {
                isGameCompleted = true
                starsEarned = result.stars
                mascotMessage = "You sorted every shape! 🎉"
                SoundService.shared.playRewardCelebration()
                
                // Save to Core Data
                CoreDataManager.shared.saveGameProgress(
                    gameID: "shp_2",
                    category: IslandCategory.shapes.rawValue,
                    stars: starsEarned,
                    score: score
                )
                CoreDataManager.shared.recordSession(
                    duration: 90,
                    gamesPlayed: 1,
                    starsEarned: starsEarned
                )
            }
        } else {
            // Gentle retry: shape bounces back, no penalty
            hasMissedCurrentShape = true
            mascotMood = .encouraging
            mascotMessage = "Almost! Look at the edges of the shape! 🌟"
            SoundService.shared.playTryAgainSound()
        }
    }
}
