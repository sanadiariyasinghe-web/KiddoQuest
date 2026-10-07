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
        case .numbers: return String(localized: "Numbers Island")
        case .letters: return String(localized: "Letters Island")
        case .shapes: return String(localized: "Shapes Island")
        case .animals: return String(localized: "Animals Island")
        }
    }
    
    var shortTitle: String {
        switch self {
        case .numbers: return String(localized: "Numbers").uppercased()
        case .letters: return String(localized: "Letters").uppercased()
        case .shapes: return String(localized: "Shapes").uppercased()
        case .animals: return String(localized: "Animals").uppercased()
        }
    }
    
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
    case findIt = "find_it"
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
            isUnlocked: true
        ),
        GameInfo(
            id: "num_2",
            title: "Tap-to-Match",
            category: .numbers,
            description: "Tap the fruits, then tap their number.",
            iconName: "hand.tap.fill",
            gameType: .dragMatch,
            isUnlocked: true
        ),
        
        // Letters Island
        GameInfo(
            id: "let_1",
            title: "Letter Tap-Match",
            category: .letters,
            description: "Tap a big letter, then its small letter.",
            iconName: "textformat.abc",
            gameType: .dragMatch,
            isUnlocked: true
        ),
        GameInfo(
            id: "let_2",
            title: "Letter Hunt",
            category: .letters,
            description: "Find and bubble-pop all the target letters!",
            iconName: "magnifyingglass.circle.fill",
            gameType: .letterHunt,
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
            isUnlocked: true
        ),
        GameInfo(
            id: "shp_2",
            title: "Shape Sort",
            category: .shapes,
            description: "Tap the box that matches each shape.",
            iconName: "tray.2.fill",
            gameType: .shapeSort,
            isUnlocked: true
        ),
        GameInfo(
            id: "shp_3",
            title: "Find It!",
            category: .shapes,
            description: "Find colours and things in your house with the camera!",
            iconName: "camera.viewfinder",
            gameType: .findIt,
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
