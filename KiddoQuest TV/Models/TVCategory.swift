import SwiftUI

/// The four KiddoQuest learning worlds, shared conceptually with Part A.
nonisolated enum TVCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case numbers
    case letters
    case shapes
    case animals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: return "Numbers"
        case .letters: return "Letters"
        case .shapes: return "Shapes"
        case .animals: return "Animals"
        }
    }

    /// Part A name for the world, e.g. "Numbers Island".
    var islandTitle: String { "\(title) Island" }

    var emoji: String {
        switch self {
        case .numbers: return "🔢"
        case .letters: return "🔤"
        case .shapes: return "🔷"
        case .animals: return "🦁"
        }
    }

    var symbolName: String {
        switch self {
        case .numbers: return "number"
        case .letters: return "textformat.abc"
        case .shapes: return "square.on.circle"
        case .animals: return "pawprint.fill"
        }
    }

    var color: Color {
        switch self {
        case .numbers: return TVTheme.Palette.numbersYellow
        case .letters: return TVTheme.Palette.lettersBlue
        case .shapes: return TVTheme.Palette.shapesPurple
        case .animals: return TVTheme.Palette.animalsGreen
        }
    }

    var tagline: String {
        switch self {
        case .numbers: return "Count, compare and pop!"
        case .letters: return "Spot letters big and small."
        case .shapes: return "Find, sort and colour shapes."
        case .animals: return "Meet and match animal friends."
        }
    }
}
