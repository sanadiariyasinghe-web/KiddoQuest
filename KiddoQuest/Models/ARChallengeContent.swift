import SwiftUI

// MARK: - AR Learning content and rules
// What appears on the real table or floor in AR Learning Mode, and the
// "Find the …!" challenges. Pure logic, so it is unit-tested without a camera.

/// The 3D shapes a child can find (2D shapes the app teaches, made into thick 3D tokens).
enum ARShapeKind: String, CaseIterable, Hashable {
    case triangle, circle, square, star, heart

    var name: String { rawValue.capitalized }

    /// Glyph used on the 2D fallback.
    var glyph: String {
        switch self {
        case .triangle: return "▲"
        case .circle: return "●"
        case .square: return "■"
        case .star: return "★"
        case .heart: return "♥"
        }
    }

    var color: Color {
        switch self {
        case .triangle: return Theme.ColorPalette.arOrange
        case .circle: return Theme.ColorPalette.lettersBlue
        case .square: return Theme.ColorPalette.animalsGreen
        case .star: return Theme.ColorPalette.numbersYellow
        case .heart: return Theme.ColorPalette.softRedWarning
        }
    }

    /// A short, true fact Buddy says when the child explores this shape.
    var fact: String {
        switch self {
        case .triangle: return "A triangle has 3 sides, like a slice of pizza!"
        case .circle: return "A circle is round, like a ball!"
        case .square: return "A square has 4 sides that are all the same!"
        case .star: return "A star has 5 points that twinkle!"
        case .heart: return "A heart means love! 💛"
        }
    }
}

/// What a 3D learning object is.
enum ARObjectKind: Hashable {
    case letter(String)
    case shape(ARShapeKind)
    case animal(emoji: String)
}

/// One 3D learning object placed in the room (also drawn on the 2D fallback).
struct ARObjectItem: Identifiable, Hashable {
    let id = UUID()
    let kind: ARObjectKind
    /// Letter, shape glyph or emoji (used on the 2D fallback and for accessibility).
    let display: String
    /// e.g. "Letter B", "Triangle", "Lion".
    let name: String
    /// What Buddy says when the child taps it to explore.
    let fact: String
    var isDiscovered: Bool = false
    /// Position on the 2D fallback "simulated room".
    var xPosition: CGFloat
    var yPosition: CGFloat
}

enum ARChallengeRules {
    /// Objects placed for each mode.
    static let objectCount = 5
    /// "Find the …!" rounds in one session.
    static let roundCount = 3

    /// Where the five objects sit on the 2D fallback room.
    static let fallbackSlots: [CGPoint] = [
        CGPoint(x: -85, y: -65), CGPoint(x: 75, y: -80), CGPoint(x: 0, y: -5),
        CGPoint(x: -70, y: 65), CGPoint(x: 80, y: 60)
    ]

    static let letters: [(letter: String, word: String, emoji: String)] = [
        ("A", "Apple", "🍎"), ("B", "Ball", "⚽"), ("C", "Cat", "🐱"), ("D", "Dog", "🐶"),
        ("E", "Egg", "🥚"), ("F", "Fish", "🐟"), ("M", "Moon", "🌙"), ("S", "Sun", "☀️"), ("T", "Tree", "🌳")
    ]

    static let animals: [(emoji: String, name: String, fact: String)] = [
        ("🦁", "Lion", "The lion says ROAR! It is the king of the jungle."),
        ("🐘", "Elephant", "The elephant has a long trunk to drink water!"),
        ("🐶", "Dog", "The dog says WOOF and loves to play!"),
        ("🐱", "Cat", "The cat says MEOW and loves naps!"),
        ("🐮", "Cow", "The cow says MOO and gives us milk!"),
        ("🦆", "Duck", "The duck says QUACK and loves to swim!"),
        ("🐵", "Monkey", "The monkey loves bananas and climbing trees!")
    ]

    /// Five different objects for a mode, in random order.
    static func makeObjects(for mode: ARMode) -> [ARObjectItem] {
        let slots = fallbackSlots
        switch mode {
        case .letterHunt:
            return letters.shuffled().prefix(objectCount).enumerated().map { index, entry in
                ARObjectItem(
                    kind: .letter(entry.letter), display: entry.letter, name: "Letter \(entry.letter)",
                    fact: "\(entry.letter) is for \(entry.word)! \(entry.emoji)",
                    xPosition: slots[index].x, yPosition: slots[index].y
                )
            }
        case .shapeHunt:
            return ARShapeKind.allCases.shuffled().prefix(objectCount).enumerated().map { index, shape in
                ARObjectItem(
                    kind: .shape(shape), display: shape.glyph, name: shape.name, fact: shape.fact,
                    xPosition: slots[index].x, yPosition: slots[index].y
                )
            }
        case .animalDiscovery:
            return animals.shuffled().prefix(objectCount).enumerated().map { index, animal in
                ARObjectItem(
                    kind: .animal(emoji: animal.emoji), display: animal.emoji, name: animal.name, fact: animal.fact,
                    xPosition: slots[index].x, yPosition: slots[index].y
                )
            }
        }
    }

    /// Three different objects to find, in random order.
    static func makeRounds(from objects: [ARObjectItem], count: Int = roundCount) -> [UUID] {
        Array(objects.shuffled().prefix(count).map(\.id))
    }

    /// The challenge sentence, e.g. "Find the Triangle!" or "Find the letter B!".
    static func prompt(for item: ARObjectItem) -> String {
        switch item.kind {
        case .letter(let letter): return "Find the letter \(letter)!"
        case .shape, .animal: return "Find the \(item.name)!"
        }
    }
}
