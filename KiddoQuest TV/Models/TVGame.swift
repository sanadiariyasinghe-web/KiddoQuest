import Foundation

/// The six KiddoQuest game concepts carried over from Part A.
nonisolated enum TVGameKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case countingPop
    case dragToMatch
    case tapToReveal
    case shapeHunt
    case animalMatch
    case shapeSort

    var id: String { rawValue }
}

/// How complete a game is in this tvOS prototype. Shown on every game card
/// so the prototype never over-claims what is implemented.
nonisolated enum TVGameAvailability: String, Codable, Hashable {
    /// Fully polished, multi-round TV game.
    case playable
    /// Simplified focus-based prototype of the Part A game.
    case prototype

    var label: String {
        switch self {
        case .playable: return "FULL GAME"
        case .prototype: return "PROTOTYPE"
        }
    }

    var symbolName: String {
        switch self {
        case .playable: return "checkmark.seal.fill"
        case .prototype: return "hammer.fill"
        }
    }
}

/// Catalogue entry describing a game in the TV library.
nonisolated struct TVGame: Identifiable, Hashable {
    let kind: TVGameKind
    let title: String
    let summary: String
    /// Learning worlds the game can be launched from. The first is the primary one.
    let categories: [TVCategory]
    let availability: TVGameAvailability
    let emoji: String

    var id: TVGameKind { kind }

    var primaryCategory: TVCategory { categories.first ?? .numbers }

    func supports(_ category: TVCategory) -> Bool {
        categories.contains(category)
    }

    /// Picks the category to launch with, falling back to the primary one
    /// if the requested category is not supported by this game.
    func launchCategory(preferred: TVCategory?) -> TVCategory {
        guard let preferred, supports(preferred) else { return primaryCategory }
        return preferred
    }
}
