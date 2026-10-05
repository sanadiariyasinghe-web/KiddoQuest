import SwiftUI

// MARK: - GamePlayView Router
// Automatically routes the child into the specific interactive mini-game view.

struct GamePlayView: View {
    let game: GameInfo
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        switch game.gameType {
        case .countingPop:
            CountingPopGameView(navigationPath: $navigationPath)
        case .dragMatch:
            DragMatchGameView(category: game.category, navigationPath: $navigationPath)
        case .coloring:
            ColoringGameView(navigationPath: $navigationPath)
        case .letterHunt:
            LetterShapeHuntGameView(isShapeMode: false, navigationPath: $navigationPath)
        case .feedAnimals:
            AnimalPictureGameView(game: .feedAnimals, navigationPath: $navigationPath)
        case .animalShadows:
            AnimalPictureGameView(game: .animalShadows, navigationPath: $navigationPath)
        case .shapeSort:
            ShapeSortGameView(navigationPath: $navigationPath)
        case .arLearning:
            ARLearningView(navigationPath: $navigationPath)
        }
    }
}
