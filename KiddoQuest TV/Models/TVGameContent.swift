import SwiftUI

// MARK: - Shared vocabulary

/// Shapes drawn natively with SwiftUI paths (no image assets).
nonisolated enum TVShapeKind: String, CaseIterable, Codable, Hashable {
    case triangle, circle, square, star, diamond

    var name: String { rawValue.capitalized }

    var pluralName: String { name.uppercased() + "S" }
}

/// Colours used by Tap-to-Reveal. Always shown with a text label too.
nonisolated enum TVColorChoice: String, CaseIterable, Codable, Hashable {
    case red, blue, yellow, green

    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .red: return Color(red: 0.95, green: 0.27, blue: 0.30)
        case .blue: return Color(red: 0.24, green: 0.52, blue: 0.98)
        case .yellow: return Color(red: 1.00, green: 0.84, blue: 0.16)
        case .green: return Color(red: 0.24, green: 0.78, blue: 0.40)
        }
    }
}

// MARK: - Counting Pop

nonisolated struct TVCountingRound: Identifiable, Hashable {
    let id: Int
    let emoji: String
    let objectName: String
    let count: Int
    let options: [Int]

    var question: String { "How many \(objectName)?" }

    func isCorrect(_ answer: Int) -> Bool { answer == count }
}

// MARK: - Shape / Letter Hunt

nonisolated enum TVHuntItemContent: Hashable {
    case shape(TVShapeKind)
    case letter(String)

    var spokenName: String {
        switch self {
        case .shape(let kind): return kind.name
        case .letter(let letter): return "Letter \(letter)"
        }
    }
}

nonisolated struct TVHuntItem: Identifiable, Hashable {
    let id: Int
    let content: TVHuntItemContent
    let isTarget: Bool
    /// Index into a decorative palette so targets are not all the same colour.
    let paletteIndex: Int
}

nonisolated struct TVHuntChallenge: Identifiable, Hashable {
    let id: Int
    let prompt: String
    let target: TVHuntItemContent
    let items: [TVHuntItem]

    var targetCount: Int { items.filter(\.isTarget).count }
}

// MARK: - Choice rounds (choice games and Family Challenge)

/// What the player is looking at while choosing an answer.
nonisolated enum TVRoundSubject: Hashable {
    /// A group of identical objects to count, e.g. three apples.
    case group(emoji: String, count: Int)
    /// A capital letter to match with its lowercase partner.
    case letter(String)
    /// An outlined picture that should be coloured in.
    case colorReveal(symbol: String, name: String, answer: TVColorChoice)
    /// A hungry animal waiting for the food it loves (Feed the Animals).
    case hungryAnimal(emoji: String, name: String, food: String)
    /// The dark shadow of an animal to identify (Animal Shadows).
    case animalShadow(emoji: String, name: String)
    /// A shape that should be dropped into the matching bin.
    case shape(TVShapeKind)
    /// No picture: the prompt alone carries the question.
    case none
}

/// How an answer option is drawn.
nonisolated enum TVOptionVisual: Hashable {
    case number(Int)
    case letter(String)
    case color(TVColorChoice)
    /// A large picture (an animal or a food).
    case animal(emoji: String)
    case shapeBin(TVShapeKind)
    case shape(TVShapeKind)
}

nonisolated struct TVChoiceOption: Identifiable, Hashable {
    let id: String
    /// Plain-language label used on screen and by VoiceOver.
    let label: String
    let visual: TVOptionVisual
}

nonisolated struct TVChoiceRound: Identifiable, Hashable {
    let id: Int
    let prompt: String
    let subject: TVRoundSubject
    let options: [TVChoiceOption]
    let correctOptionID: String
    /// Short celebration line, e.g. "Lion is complete!".
    let successMessage: String

    func isCorrect(_ optionID: String) -> Bool { optionID == correctOptionID }

    var correctOption: TVChoiceOption? {
        options.first { $0.id == correctOptionID }
    }
}

// MARK: - Family Challenge

nonisolated struct TVFamilyChallenge: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    /// The shared goal, e.g. "Can the family find 5 shapes together?".
    let goalPrompt: String
    let category: TVCategory
    /// Correct answers the family needs together to win.
    let goal: Int
    let questions: [TVChoiceRound]
}
