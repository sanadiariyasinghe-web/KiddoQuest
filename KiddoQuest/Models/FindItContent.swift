import SwiftUI

// MARK: - Find It! content and rules
// "Find it in your house": children photograph a real object or colour,
// and on-device Vision image classification checks what they found.

/// Colours children can hunt for (always shown with a name and a swatch).
enum FindItColor: String, CaseIterable, Hashable {
    case red, blue, yellow, green

    var name: String { rawValue.capitalized }

    var swatch: Color {
        switch self {
        case .red: return .red
        case .blue: return Theme.ColorPalette.lettersBlue
        case .yellow: return Theme.ColorPalette.numbersYellow
        case .green: return Theme.ColorPalette.animalsGreen
        }
    }
}

/// One thing to find: a household object or a colour.
enum FindItTarget: Hashable {
    /// `labels` are the Vision classifier identifiers that count as this object.
    case object(name: String, emoji: String, labels: Set<String>)
    case color(FindItColor)

    var prompt: String {
        switch self {
        case .object(let name, _, _): return "Find \(article(for: name)) \(name.uppercased())!"
        case .color(let color): return "Find something \(color.name.uppercased())!"
        }
    }

    var symbol: String {
        switch self {
        case .object(_, let emoji, _): return emoji
        case .color: return "🎨"
        }
    }

    var successMessage: String {
        switch self {
        case .object(let name, _, _): return "You found \(article(for: name)) \(name)!"
        case .color(let color): return "That's \(color.name.lowercased())!"
        }
    }

    private func article(for word: String) -> String {
        guard let first = word.lowercased().first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }
}

/// Pure rules for Find It! (unit-testable without a camera).
enum FindItRules {
    /// Classifications at or above this confidence count as "seen".
    static let minimumConfidence: Float = 0.2

    /// Everyday things that Vision's built-in classifier recognises.
    static let objects: [FindItTarget] = [
        .object(name: "ball", emoji: "⚽", labels: ["ball", "baseball", "basketball", "soccer_ball", "tennis_ball", "volleyball", "football"]),
        .object(name: "cup", emoji: "☕", labels: ["cup", "mug"]),
        .object(name: "book", emoji: "📚", labels: ["book", "bookshelf"]),
        .object(name: "toy", emoji: "🧸", labels: ["toy", "vehicle_toy", "train_toy", "stuffed_animal"]),
        .object(name: "apple", emoji: "🍎", labels: ["apple"]),
        .object(name: "banana", emoji: "🍌", labels: ["banana"]),
        .object(name: "shoe", emoji: "👟", labels: ["shoes", "sneaker", "boot"]),
        .object(name: "spoon", emoji: "🥄", labels: ["spoon"]),
        .object(name: "sock", emoji: "🧦", labels: ["sock"]),
        .object(name: "hat", emoji: "👒", labels: ["hat", "sunhat", "baseball_hat", "cowboy_hat"]),
        .object(name: "flower", emoji: "🌼", labels: ["flower", "sunflower", "flower_arrangement"]),
        .object(name: "chair", emoji: "🪑", labels: ["chair", "armchair", "chair_other", "folding_chair", "high_chair"])
    ]

    /// A round of `count` hunts: mostly objects, plus colours for variety.
    static func makeRound(count: Int = 5, colorHunts: Int = 2) -> [FindItTarget] {
        let colours = FindItColor.allCases.shuffled().prefix(colorHunts).map { FindItTarget.color($0) }
        let things = objects.shuffled().prefix(max(0, count - colours.count))
        return (Array(things) + colours).shuffled()
    }

    /// Does any confident classification match the object being hunted?
    static func matches(labels: Set<String>, observations: [(identifier: String, confidence: Float)]) -> Bool {
        observations.contains { labels.contains($0.identifier) && $0.confidence >= minimumConfidence }
    }

    /// The most confident thing Vision saw, as a friendly word (e.g. "armchair" → "armchair").
    static func bestGuess(from observations: [(identifier: String, confidence: Float)]) -> String? {
        observations
            .filter { $0.confidence >= minimumConfidence }
            .max { $0.confidence < $1.confidence }
            .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
    }

    /// Names the main colour of an average RGB value (0...1), or nil if it is too grey or dark.
    static func dominantColor(red: Double, green: Double, blue: Double) -> FindItColor? {
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let saturation = maxValue == 0 ? 0 : (maxValue - minValue) / maxValue
        guard maxValue > 0.2, saturation > 0.25 else { return nil }

        // Hue in degrees
        var hue: Double
        let delta = maxValue - minValue
        if maxValue == red {
            hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxValue == green {
            hue = 60 * ((blue - red) / delta + 2)
        } else {
            hue = 60 * ((red - green) / delta + 4)
        }
        if hue < 0 { hue += 360 }

        switch hue {
        case 0..<20, 330...360: return .red
        case 40..<70: return .yellow
        case 70..<170: return .green
        case 180..<260: return .blue
        default: return nil
        }
    }
}
