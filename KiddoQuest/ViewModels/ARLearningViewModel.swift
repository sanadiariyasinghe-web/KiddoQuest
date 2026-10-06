import SwiftUI
import ARKit

struct ARObjectItem: Identifiable, Hashable {
    let id = UUID()
    let display: String
    let name: String
    let isTarget: Bool
    var isDiscovered: Bool = false
    var xPosition: CGFloat
    var yPosition: CGFloat
}

@Observable
final class ARLearningViewModel {
    var selectedMode: ARMode = .letterHunt
    var isARSupported: Bool = ARService.shared.isARSupported
    
    var instructionText: String = "Find the letter A!"
    var targetObjects: [ARObjectItem] = []
    /// Changes whenever a new set of objects is created, so the AR scene re-places its 3D cards.
    var layoutID = UUID()
    /// True once ARKit has found a real table or floor to place objects on.
    var isSurfaceFound: Bool = false

    var foundCount: Int = 0
    var totalRequired: Int = 2
    var score: Int = 0
    var starsEarned: Int = 0
    
    var isCompleted: Bool = false
    var showConfetti: Bool = false
    var isGentleRetry: Bool = false
    var mascotMood: MascotMood = .idle
    var mascotMessage: String = "Look around through the camera and find the target!"
    
    init() {
        setupMode(.letterHunt)
    }
    
    func switchMode(to mode: ARMode) {
        self.selectedMode = mode
        setupMode(mode)
    }
    
    func setupMode(_ mode: ARMode) {
        foundCount = 0
        score = 0
        starsEarned = 0
        isCompleted = false
        showConfetti = false
        isGentleRetry = false
        mascotMood = .idle
        layoutID = UUID()

        switch mode {
        case .letterHunt:
            instructionText = "Find the letter A!"
            totalRequired = 2
            targetObjects = [
                ARObjectItem(display: "A", name: "Letter A", isTarget: true, xPosition: -80, yPosition: -60),
                ARObjectItem(display: "B", name: "Letter B", isTarget: false, xPosition: 70, yPosition: -80),
                ARObjectItem(display: "C", name: "Letter C", isTarget: false, xPosition: -60, yPosition: 50),
                ARObjectItem(display: "A", name: "Letter A", isTarget: true, xPosition: 80, yPosition: 60),
                ARObjectItem(display: "D", name: "Letter D", isTarget: false, xPosition: 0, yPosition: -10)
            ]
            mascotMessage = "Spot the virtual 3D letters placed in your room!"
            
        case .shapeHunt:
            instructionText = "Find all the triangles!"
            totalRequired = 2
            targetObjects = [
                ARObjectItem(display: "△", name: "Triangle", isTarget: true, xPosition: -80, yPosition: -50),
                ARObjectItem(display: "○", name: "Circle", isTarget: false, xPosition: 60, yPosition: -70),
                ARObjectItem(display: "□", name: "Square", isTarget: false, xPosition: -50, yPosition: 60),
                ARObjectItem(display: "△", name: "Triangle", isTarget: true, xPosition: 75, yPosition: 45)
            ]
            mascotMessage = "Scan a flat table or floor to spot the triangles!"
            
        case .animalDiscovery:
            instructionText = "Find the Lion!"
            totalRequired = 1
            targetObjects = [
                ARObjectItem(display: "🦁", name: "Lion", isTarget: true, xPosition: -60, yPosition: -20),
                ARObjectItem(display: "🐶", name: "Dog", isTarget: false, xPosition: 70, yPosition: -60),
                ARObjectItem(display: "🐱", name: "Cat", isTarget: false, xPosition: -70, yPosition: 70),
                ARObjectItem(display: "🐘", name: "Elephant", isTarget: false, xPosition: 60, yPosition: 60)
            ]
            mascotMessage = "Look around your space for the friendly Lion!"
        }
        
    }
    
    func tapObject(_ item: ARObjectItem) {
        guard let index = targetObjects.firstIndex(where: { $0.id == item.id }), !targetObjects[index].isDiscovered else { return }
        
        if targetObjects[index].isTarget {
            targetObjects[index].isDiscovered = true
            foundCount += 1
            score += 25
            starsEarned = min(3, max(1, foundCount))
            showConfetti = true
            mascotMood = .celebrating
            mascotMessage = "Great job! You discovered the \(item.name) in AR! ⭐"
            
            SoundService.shared.playCorrectSound()
            
            if foundCount >= totalRequired {
                isCompleted = true
                mascotMessage = "Awesome Explorer! You found all targets in AR!"
                SoundService.shared.playRewardCelebration()
                
                // Save to Core Data & unlock AR Explorer badge
                CoreDataManager.shared.saveGameProgress(
                    gameID: "ar_\(selectedMode.rawValue)",
                    category: "AR",
                    stars: 3,
                    score: score
                )
                CoreDataManager.shared.unlockBadge(named: "AR Explorer")
                CoreDataManager.shared.recordSession(
                    duration: 100,
                    gamesPlayed: 1,
                    starsEarned: 3
                )
            }
        } else {
            // Gentle retry: no penalty
            isGentleRetry = true
            mascotMood = .encouraging
            mascotMessage = "Almost! That is the \(item.name). Look for the target! 🌟"
            SoundService.shared.playTryAgainSound()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.isGentleRetry = false
            }
        }
    }
}
