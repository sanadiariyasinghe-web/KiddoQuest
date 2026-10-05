import SwiftUI

// MARK: - Island Categories
enum IslandCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case numbers = "Numbers"
    case letters = "Letters"
    case shapes = "Shapes"
    case animals = "Animals"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .numbers: return "Numbers Island"
        case .letters: return "Letters Island"
        case .shapes: return "Shapes Island"
        case .animals: return "Animals Island"
        }
    }
    
    var shortTitle: String { rawValue.uppercased() }
    
    var icon: String {
        switch self {
        case .numbers: return "🔢"
        case .letters: return "🔤"
        case .shapes: return "🔷"
        case .animals: return "🦁"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .numbers: return "number.circle.fill"
        case .letters: return "character.book.closed.fill"
        case .shapes: return "square.on.circle.fill"
        case .animals: return "pawprint.fill"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .numbers: return Theme.ColorPalette.numbersYellow
        case .letters: return Theme.ColorPalette.lettersBlue
        case .shapes: return Theme.ColorPalette.shapesPurple
        case .animals: return Theme.ColorPalette.animalsGreen
        }
    }
}

// MARK: - Game Type
enum GameType: String, CaseIterable, Identifiable, Hashable, Codable {
    case countingPop = "counting_pop"
    case dragMatch = "drag_match"
    case coloring = "coloring"
    case letterHunt = "letter_hunt"
    case feedAnimals = "feed_animals"
    case animalShadows = "animal_shadows"
    case shapeSort = "shape_sort"
    case arLearning = "ar_learning"
    
    var id: String { rawValue }
}

// MARK: - Game Info
struct GameInfo: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var category: IslandCategory
    var description: String
    var iconName: String
    var gameType: GameType
    var difficulty: Int = 1
    var starsEarned: Int = 0
    var completionPercentage: Int = 0
    var isUnlocked: Bool = true
    
    static let sampleGames: [GameInfo] = [
        // Numbers Island
        GameInfo(
            id: "num_1",
            title: "Counting Pop",
            category: .numbers,
            description: "Count floating yummy treats and pop the right number!",
            iconName: "1.circle.fill",
            gameType: .countingPop,
            starsEarned: 3,
            completionPercentage: 100,
            isUnlocked: true
        ),
        GameInfo(
            id: "num_2",
            title: "Drag-to-Match",
            category: .numbers,
            description: "Match number cards to the groups of cute objects.",
            iconName: "hand.draw.fill",
            gameType: .dragMatch,
            starsEarned: 2,
            completionPercentage: 60,
            isUnlocked: true
        ),
        
        // Letters Island
        GameInfo(
            id: "let_1",
            title: "Letter Drag-Match",
            category: .letters,
            description: "Match uppercase and lowercase letters together.",
            iconName: "textformat.abc",
            gameType: .dragMatch,
            starsEarned: 2,
            completionPercentage: 50,
            isUnlocked: true
        ),
        GameInfo(
            id: "let_2",
            title: "Letter Hunt",
            category: .letters,
            description: "Find and bubble-pop all the target letters!",
            iconName: "magnifyingglass.circle.fill",
            gameType: .letterHunt,
            starsEarned: 1,
            completionPercentage: 30,
            isUnlocked: true
        ),
        
        // Shapes Island
        GameInfo(
            id: "shp_1",
            title: "Tap-to-Reveal Coloring",
            category: .shapes,
            description: "Pick bright colors and fill in beautiful shapes!",
            iconName: "paintpalette.fill",
            gameType: .coloring,
            starsEarned: 3,
            completionPercentage: 100,
            isUnlocked: true
        ),
        GameInfo(
            id: "shp_2",
            title: "Shape Sort",
            category: .shapes,
            description: "Drag dropping shapes into their matching bins.",
            iconName: "tray.2.fill",
            gameType: .shapeSort,
            starsEarned: 2,
            completionPercentage: 70,
            isUnlocked: true
        ),
        
        // Animals Island
        GameInfo(
            id: "ani_1",
            title: "Feed the Animals",
            category: .animals,
            description: "Give each hungry animal the food it loves!",
            iconName: "carrot.fill",
            gameType: .feedAnimals,
            starsEarned: 1,
            completionPercentage: 25,
            isUnlocked: true
        ),
        GameInfo(
            id: "ani_2",
            title: "Animal Shadows",
            category: .animals,
            description: "Look at the shadow and find the animal!",
            iconName: "pawprint.fill",
            gameType: .animalShadows,
            isUnlocked: true
        )
    ]
}

// MARK: - Game Question / Data Model
struct GameQuestion: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var category: IslandCategory
    var question: String
    var correctAnswer: String
    var options: [String]
    var imageName: String
    var difficulty: Int
}
