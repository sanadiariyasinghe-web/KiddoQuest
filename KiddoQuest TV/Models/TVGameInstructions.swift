import Foundation

/// One picture in the "picture sentence" for children who can't read yet,
/// e.g. 🐰 → 👆 → 🥕. Shadow pictures are drawn as a dark silhouette.
nonisolated struct TVPictureStep: Hashable {
    let symbol: String
    var isShadow = false

    /// The remote's touch surface: "press to choose".
    static let press = TVPictureStep(symbol: "👆")
}

/// What a child sees before a game starts: the same picture-first
/// instructions as the KiddoQuest iOS app, sized for the TV.
nonisolated struct TVGameInstructions: Hashable {
    let title: String
    let pictureStory: [TVPictureStep]
    /// Short steps for grown-ups reading along.
    let steps: [String]

    static func instructions(for kind: TVGameKind, category: TVCategory) -> TVGameInstructions {
        switch kind {
        case .countingPop:
            let group = category == .animals ? "🦆🦆🦆" : "🍎🍎🍎"
            return TVGameInstructions(
                title: "Counting Pop TV",
                pictureStory: [TVPictureStep(symbol: group), .press, TVPictureStep(symbol: "3")],
                steps: ["Count the treats.", "Then choose the right number."]
            )
        case .dragToMatch where category == .letters:
            return TVGameInstructions(
                title: "Letter Match",
                pictureStory: [TVPictureStep(symbol: "A"), .press, TVPictureStep(symbol: "a")],
                steps: ["Look at the big letter.", "Choose its little letter."]
            )
        case .dragToMatch:
            return TVGameInstructions(
                title: "Tap-to-Match",
                pictureStory: [TVPictureStep(symbol: "🍌🍌"), .press, TVPictureStep(symbol: "2")],
                steps: ["Count the fruits.", "Choose their number."]
            )
        case .tapToReveal:
            return TVGameInstructions(
                title: "Tap-to-Reveal",
                pictureStory: [TVPictureStep(symbol: "☀️", isShadow: true), .press, TVPictureStep(symbol: "🟡")],
                steps: ["Look at the picture.", "Choose the right colour."]
            )
        case .shapeHunt where category == .letters:
            return TVGameInstructions(
                title: "Letter Hunt TV",
                pictureStory: [TVPictureStep(symbol: "A"), .press, TVPictureStep(symbol: "✅")],
                steps: ["Find every matching letter.", "Choose each one."]
            )
        case .shapeHunt:
            return TVGameInstructions(
                title: "Shape Hunt TV",
                pictureStory: [TVPictureStep(symbol: "🔺"), .press, TVPictureStep(symbol: "✅")],
                steps: ["Find every matching shape.", "Choose each one."]
            )
        case .feedAnimals:
            return TVGameInstructions(
                title: "Feed the Animals",
                pictureStory: [TVPictureStep(symbol: "🐰"), .press, TVPictureStep(symbol: "🥕")],
                steps: ["Look at the hungry animal.", "Choose the food it likes."]
            )
        case .animalShadows:
            return TVGameInstructions(
                title: "Animal Shadows",
                pictureStory: [TVPictureStep(symbol: "🦒", isShadow: true), .press, TVPictureStep(symbol: "🦒")],
                steps: ["Look at the shadow.", "Choose the animal that matches."]
            )
        case .shapeSort:
            return TVGameInstructions(
                title: "Shape Sort",
                pictureStory: [TVPictureStep(symbol: "🔺"), .press, TVPictureStep(symbol: "🧺")],
                steps: ["Look at the shape.", "Choose the bin that matches."]
            )
        }
    }
}
