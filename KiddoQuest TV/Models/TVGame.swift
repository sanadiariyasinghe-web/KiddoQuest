import Foundation

/// The seven KiddoQuest games, matching the Part A iOS app.
nonisolated enum TVGameKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case countingPop
    case dragToMatch
    case tapToReveal
    case shapeHunt
    case feedAnimals
    case animalShadows
    case shapeSort

    var id: String { rawValue }

    /// Raw value of the retired "Animal Match" game, which older saved progress may contain.
    static let legacyAnimalMatchRawValue = "animalMatch"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let kind = TVGameKind(rawValue: rawValue) {
            self = kind
        } else if rawValue == Self.legacyAnimalMatchRawValue {
            // Animal Match was replaced by Feed the Animals; keep the child's progress.
            self = .feedAnimals
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown game kind \(rawValue)")
        }
    }
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
