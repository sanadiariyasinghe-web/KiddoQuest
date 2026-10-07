import SwiftUI

// MARK: - Game Flow Phase
// Every game follows the same journey: Instructions → Play → Round Results.
enum GamePhase: Int, CaseIterable, Comparable {
    case instructions
    case playing
    case results
    
    static func < (lhs: GamePhase, rhs: GamePhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Game Instructions
struct InstructionStep: Identifiable, Hashable {
    let id = UUID()
    let icon: String // SF Symbol
    let text: String
}

/// One picture in the "picture sentence" shown to children who can't read yet,
/// e.g. 🐰 → 👆 → 🥕. Shadow pictures are drawn as a dark silhouette.
struct PictureStep: Hashable {
    let symbol: String
    var isShadow: Bool = false
    
    static let tap = PictureStep(symbol: "👆")
}

struct GameInstructions {
    let title: String
    let emoji: String
    let themeColor: Color
    /// Picture-only version of the instructions (read left to right).
    let pictureStory: [PictureStep]
    let steps: [InstructionStep]
}

extension GameInstructions {
    static let countingPop = GameInstructions(
        title: "Counting Pop",
        emoji: "🍎",
        themeColor: Theme.ColorPalette.numbersYellow,
        pictureStory: [PictureStep(symbol: "🍎🍎🍎"), .tap, PictureStep(symbol: "3")],
        steps: [
            InstructionStep(icon: "eye.fill", text: "Count the treats."),
            InstructionStep(icon: "hand.tap.fill", text: "Then tap the right number.")
        ]
    )
    
    static func dragMatch(for category: IslandCategory) -> GameInstructions {
        if category == .numbers {
            return GameInstructions(
                title: "Number Match",
                emoji: "🔢",
                themeColor: category.themeColor,
                pictureStory: [PictureStep(symbol: "🍌🍌"), .tap, PictureStep(symbol: "2")],
                steps: [
                    InstructionStep(icon: "hand.tap.fill", text: "Tap the fruits."),
                    InstructionStep(icon: "number.circle.fill", text: "Then tap their number.")
                ]
            )
        }
        return GameInstructions(
            title: "Letter Match",
            emoji: "🔤",
            themeColor: category.themeColor,
            pictureStory: [PictureStep(symbol: "A"), .tap, PictureStep(symbol: "a")],
            steps: [
                InstructionStep(icon: "hand.tap.fill", text: "Tap a big letter."),
                InstructionStep(icon: "textformat.size.smaller", text: "Then tap its small letter.")
            ]
        )
    }
    
    static let coloring = GameInstructions(
        title: "Colour the Shapes",
        emoji: "🎨",
        themeColor: Theme.ColorPalette.shapesPurple,
        pictureStory: [PictureStep(symbol: "⭐"), .tap, PictureStep(symbol: "🟡")],
        steps: [
            InstructionStep(icon: "eye.fill", text: "Look at the shape."),
            InstructionStep(icon: "paintbrush.fill", text: "Tap the right colour.")
        ]
    )
    
    static func hunt(isShapeMode: Bool, targetSymbol: String = "A") -> GameInstructions {
        if isShapeMode {
            return GameInstructions(
                title: "Shape Hunt",
                emoji: "🔍",
                themeColor: Theme.ColorPalette.shapesPurple,
                pictureStory: [PictureStep(symbol: "🔺"), .tap, PictureStep(symbol: "✅")],
                steps: [
                    InstructionStep(icon: "magnifyingglass", text: "Find all the triangles."),
                    InstructionStep(icon: "hand.tap.fill", text: "Tap each triangle.")
                ]
            )
        }
        return GameInstructions(
            title: "Letter Hunt",
            emoji: "🔍",
            themeColor: Theme.ColorPalette.lettersBlue,
            pictureStory: [PictureStep(symbol: targetSymbol), .tap, PictureStep(symbol: "✅")],
            steps: [
                InstructionStep(icon: "magnifyingglass", text: "Find all the \(targetSymbol) letters."),
                InstructionStep(icon: "hand.tap.fill", text: "Tap each \(targetSymbol).")
            ]
        )
    }
    
    static let shapeSort = GameInstructions(
        title: "Shape Sort",
        emoji: "🧺",
        themeColor: Theme.ColorPalette.shapesPurple,
        pictureStory: [PictureStep(symbol: "🔺"), .tap, PictureStep(symbol: "🧺")],
        steps: [
            InstructionStep(icon: "eye.fill", text: "Look at the shape."),
            InstructionStep(icon: "tray.fill", text: "Tap the box that matches.")
        ]
    )
    
    static let findIt = GameInstructions(
        title: "Find It!",
        emoji: "📷",
        themeColor: Theme.ColorPalette.shapesPurple,
        pictureStory: [PictureStep(symbol: "⚽"), PictureStep(symbol: "📷"), PictureStep(symbol: "✅")],
        steps: [
            InstructionStep(icon: "magnifyingglass", text: "Find the thing in your house."),
            InstructionStep(icon: "camera.fill", text: "Take a photo of it.")
        ]
    )

    static let feedAnimals = GameInstructions(
        title: "Feed the Animals",
        emoji: "🥕",
        themeColor: Theme.ColorPalette.animalsGreen,
        pictureStory: [PictureStep(symbol: "🐰"), .tap, PictureStep(symbol: "🥕")],
        steps: [
            InstructionStep(icon: "eye.fill", text: "Look at the hungry animal."),
            InstructionStep(icon: "hand.tap.fill", text: "Tap the food it likes.")
        ]
    )
    
    static let animalShadows = GameInstructions(
        title: "Animal Shadows",
        emoji: "🦒",
        themeColor: Theme.ColorPalette.animalsGreen,
        pictureStory: [PictureStep(symbol: "🦒", isShadow: true), .tap, PictureStep(symbol: "🦒")],
        steps: [
            InstructionStep(icon: "eye.fill", text: "Look at the shadow."),
            InstructionStep(icon: "hand.tap.fill", text: "Tap the animal that matches.")
        ]
    )
}

// MARK: - Round Result
struct RoundResult: Equatable {
    var score: Int
    var stars: Int
    var correctAnswers: Int
    var totalQuestions: Int
    var correctLabel: String = "Correct Answers"
    /// Set when this round moved the child up to a new level.
    var newLevel: Int? = nil
}

// MARK: - Shared Scoring Rules
// Consistent, encouraging scoring for every game.
enum GameScoring {
    /// Points for answering correctly on the first try.
    static let firstTryPoints = 20
    /// Points for answering correctly after a gentle retry (never zero, never a penalty).
    static let retryPoints = 10
    
    /// Stars earned so far, based on first-try correct answers out of the round total.
    static func stars(correct: Int, total: Int) -> Int {
        guard total > 0, correct > 0 else { return 0 }
        let ratio = Double(correct) / Double(total)
        if ratio >= 0.8 { return 3 }
        if ratio >= 0.5 { return 2 }
        return 1
    }
    
    /// Final stars for a finished round: every child who finishes earns at least one star.
    static func finalStars(correct: Int, total: Int) -> Int {
        max(1, stars(correct: correct, total: total))
    }
}
