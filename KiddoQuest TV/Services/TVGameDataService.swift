import Foundation

/// Local, bundled content for every game. The prototype needs no backend,
/// so all rounds are defined here as plain data.
nonisolated enum TVGameDataService {

    // MARK: - Game library

    static let games: [TVGame] = [
        TVGame(
            kind: .countingPop,
            title: "Counting Pop TV",
            summary: "Count the big bouncing objects and pick the right number.",
            categories: [.numbers, .animals],
            availability: .playable,
            emoji: "🎈"
        ),
        TVGame(
            kind: .dragToMatch,
            title: "Drag-to-Match",
            summary: "Move focus to the matching number or letter and snap it in place.",
            categories: [.numbers, .letters],
            availability: .prototype,
            emoji: "🧲"
        ),
        TVGame(
            kind: .tapToReveal,
            title: "Tap-to-Reveal",
            summary: "Choose the right colour to reveal the picture.",
            categories: [.shapes],
            availability: .prototype,
            emoji: "🎨"
        ),
        TVGame(
            kind: .shapeHunt,
            title: "Shape Hunt TV",
            summary: "Letter / Shape Hunt: find every matching shape or letter on the big screen.",
            categories: [.shapes, .letters],
            availability: .playable,
            emoji: "🔍"
        ),
        TVGame(
            kind: .animalMatch,
            title: "Animal Match",
            summary: "Join the front and back halves of animal friends.",
            categories: [.animals],
            availability: .prototype,
            emoji: "🧩"
        ),
        TVGame(
            kind: .shapeSort,
            title: "Shape Sort",
            summary: "Send each shape to its matching bin.",
            categories: [.shapes],
            availability: .prototype,
            emoji: "🗂️"
        )
    ]

    static func game(for kind: TVGameKind) -> TVGame? {
        games.first { $0.kind == kind }
    }

    /// Games for a world, full games first so the polished experiences lead.
    static func games(in category: TVCategory?) -> [TVGame] {
        guard let category else { return games }
        let matching = games.filter { $0.supports(category) }
        return matching.filter { $0.availability == .playable } + matching.filter { $0.availability == .prototype }
    }

    // MARK: - Counting Pop

    static func countingRounds(for category: TVCategory) -> [TVCountingRound] {
        switch category {
        case .animals:
            return [
                TVCountingRound(id: 0, emoji: "🦆", objectName: "ducks", count: 4, options: [3, 4, 5, 6]),
                TVCountingRound(id: 1, emoji: "🐰", objectName: "bunnies", count: 3, options: [2, 3, 5, 7]),
                TVCountingRound(id: 2, emoji: "🐟", objectName: "fish", count: 6, options: [4, 6, 8, 9]),
                TVCountingRound(id: 3, emoji: "🐶", objectName: "puppies", count: 2, options: [1, 2, 3, 4]),
                TVCountingRound(id: 4, emoji: "🦋", objectName: "butterflies", count: 8, options: [6, 7, 8, 9])
            ]
        default:
            return [
                TVCountingRound(id: 0, emoji: "🍎", objectName: "apples", count: 5, options: [3, 5, 7, 9]),
                TVCountingRound(id: 1, emoji: "🍌", objectName: "bananas", count: 3, options: [2, 3, 4, 6]),
                TVCountingRound(id: 2, emoji: "🍓", objectName: "strawberries", count: 7, options: [5, 6, 7, 8]),
                TVCountingRound(id: 3, emoji: "🍊", objectName: "oranges", count: 4, options: [2, 4, 6, 8]),
                TVCountingRound(id: 4, emoji: "🍇", objectName: "grapes", count: 6, options: [4, 5, 6, 9])
            ]
        }
    }

    // MARK: - Shape / Letter Hunt

    static func huntChallenges(for category: TVCategory) -> [TVHuntChallenge] {
        switch category {
        case .letters:
            return [
                letterHunt(id: 0, target: "A", items: ["A", "B", "A", "C", "E"]),
                letterHunt(id: 1, target: "M", items: ["M", "N", "M", "W", "O", "M"]),
                letterHunt(id: 2, target: "S", items: ["C", "S", "O", "S", "G", "Z"])
            ]
        default:
            return [
                shapeHunt(id: 0, target: .triangle, items: [.triangle, .circle, .square, .triangle, .circle]),
                shapeHunt(id: 1, target: .circle, items: [.circle, .star, .circle, .square, .triangle, .circle]),
                shapeHunt(id: 2, target: .square, items: [.diamond, .square, .triangle, .square, .star, .circle])
            ]
        }
    }

    private static func shapeHunt(id: Int, target: TVShapeKind, items: [TVShapeKind]) -> TVHuntChallenge {
        TVHuntChallenge(
            id: id,
            prompt: "Find all the \(target.pluralName)!",
            target: .shape(target),
            items: items.enumerated().map { index, kind in
                TVHuntItem(id: index, content: .shape(kind), isTarget: kind == target, paletteIndex: index)
            }
        )
    }

    private static func letterHunt(id: Int, target: String, items: [String]) -> TVHuntChallenge {
        TVHuntChallenge(
            id: id,
            prompt: "Find all the letter \(target)s!",
            target: .letter(target),
            items: items.enumerated().map { index, letter in
                TVHuntItem(id: index, content: .letter(letter), isTarget: letter == target, paletteIndex: index)
            }
        )
    }

    // MARK: - Prototype games

    static func prototypeRounds(for kind: TVGameKind, category: TVCategory) -> [TVChoiceRound] {
        switch kind {
        case .dragToMatch:
            return category == .letters ? letterMatchRounds : numberMatchRounds
        case .tapToReveal:
            return colorRevealRounds
        case .animalMatch:
            return animalMatchRounds
        case .shapeSort:
            return shapeSortRounds
        case .countingPop, .shapeHunt:
            // These have dedicated full game engines.
            return []
        }
    }

    private static func numberOption(_ value: Int) -> TVChoiceOption {
        TVChoiceOption(id: "\(value)", label: "\(value)", visual: .number(value))
    }

    private static let numberMatchRounds: [TVChoiceRound] = [
        TVChoiceRound(
            id: 0, prompt: "Match the apples to their number!",
            subject: .group(emoji: "🍎", count: 3),
            options: [numberOption(2), numberOption(3), numberOption(5)],
            correctOptionID: "3", successMessage: "Snap! 3 apples!"
        ),
        TVChoiceRound(
            id: 1, prompt: "Match the stars to their number!",
            subject: .group(emoji: "⭐", count: 5),
            options: [numberOption(4), numberOption(6), numberOption(5)],
            correctOptionID: "5", successMessage: "Snap! 5 stars!"
        ),
        TVChoiceRound(
            id: 2, prompt: "Match the balloons to their number!",
            subject: .group(emoji: "🎈", count: 2),
            options: [numberOption(2), numberOption(1), numberOption(3)],
            correctOptionID: "2", successMessage: "Snap! 2 balloons!"
        )
    ]

    private static func letterOption(_ letter: String) -> TVChoiceOption {
        TVChoiceOption(id: letter, label: "Letter \(letter)", visual: .letter(letter))
    }

    private static let letterMatchRounds: [TVChoiceRound] = [
        TVChoiceRound(
            id: 0, prompt: "Find the little letter that matches A!",
            subject: .letter("A"),
            options: [letterOption("e"), letterOption("a"), letterOption("o")],
            correctOptionID: "a", successMessage: "Snap! A and a!"
        ),
        TVChoiceRound(
            id: 1, prompt: "Find the little letter that matches B!",
            subject: .letter("B"),
            options: [letterOption("b"), letterOption("d"), letterOption("p")],
            correctOptionID: "b", successMessage: "Snap! B and b!"
        ),
        TVChoiceRound(
            id: 2, prompt: "Find the little letter that matches T!",
            subject: .letter("T"),
            options: [letterOption("f"), letterOption("l"), letterOption("t")],
            correctOptionID: "t", successMessage: "Snap! T and t!"
        )
    ]

    private static var colorOptions: [TVChoiceOption] {
        TVColorChoice.allCases.map { TVChoiceOption(id: $0.rawValue, label: $0.name, visual: .color($0)) }
    }

    private static var colorRevealRounds: [TVChoiceRound] {
        [
            TVChoiceRound(
                id: 0, prompt: "What colour should this sun be?",
                subject: .colorReveal(symbol: "sun.max", name: "Sun", answer: .yellow),
                options: colorOptions, correctOptionID: TVColorChoice.yellow.rawValue,
                successMessage: "A bright yellow sun!"
            ),
            TVChoiceRound(
                id: 1, prompt: "What colour should this leaf be?",
                subject: .colorReveal(symbol: "leaf", name: "Leaf", answer: .green),
                options: colorOptions, correctOptionID: TVColorChoice.green.rawValue,
                successMessage: "A lovely green leaf!"
            ),
            TVChoiceRound(
                id: 2, prompt: "What colour should this heart be?",
                subject: .colorReveal(symbol: "heart", name: "Heart", answer: .red),
                options: colorOptions, correctOptionID: TVColorChoice.red.rawValue,
                successMessage: "A big red heart!"
            ),
            TVChoiceRound(
                id: 3, prompt: "What colour should this raindrop be?",
                subject: .colorReveal(symbol: "drop", name: "Raindrop", answer: .blue),
                options: colorOptions, correctOptionID: TVColorChoice.blue.rawValue,
                successMessage: "A shiny blue raindrop!"
            )
        ]
    }

    private static func backHalf(_ emoji: String, _ name: String) -> TVChoiceOption {
        TVChoiceOption(id: name, label: "\(name) back half", visual: .animalBackHalf(emoji: emoji))
    }

    private static let animalMatchRounds: [TVChoiceRound] = [
        TVChoiceRound(
            id: 0, prompt: "Who does this half belong to?",
            subject: .animalHalf(emoji: "🦁", name: "Lion"),
            options: [backHalf("🐶", "Dog"), backHalf("🦁", "Lion"), backHalf("🐘", "Elephant")],
            correctOptionID: "Lion", successMessage: "Roar! The lion is complete!"
        ),
        TVChoiceRound(
            id: 1, prompt: "Who does this half belong to?",
            subject: .animalHalf(emoji: "🐵", name: "Monkey"),
            options: [backHalf("🐵", "Monkey"), backHalf("🐱", "Cat"), backHalf("🐶", "Dog")],
            correctOptionID: "Monkey", successMessage: "Ooh ooh! The monkey is complete!"
        ),
        TVChoiceRound(
            id: 2, prompt: "Who does this half belong to?",
            subject: .animalHalf(emoji: "🐘", name: "Elephant"),
            options: [backHalf("🐱", "Cat"), backHalf("🦁", "Lion"), backHalf("🐘", "Elephant")],
            correctOptionID: "Elephant", successMessage: "Toot! The elephant is complete!"
        ),
        TVChoiceRound(
            id: 3, prompt: "Who does this half belong to?",
            subject: .animalHalf(emoji: "🐱", name: "Cat"),
            options: [backHalf("🐱", "Cat"), backHalf("🐵", "Monkey"), backHalf("🐶", "Dog")],
            correctOptionID: "Cat", successMessage: "Meow! The cat is complete!"
        )
    ]

    private static func bin(_ kind: TVShapeKind) -> TVChoiceOption {
        TVChoiceOption(id: kind.rawValue, label: "\(kind.name) bin", visual: .shapeBin(kind))
    }

    private static let shapeSortRounds: [TVChoiceRound] = [
        TVChoiceRound(
            id: 0, prompt: "Which bin does the triangle go in?",
            subject: .shape(.triangle),
            options: [bin(.circle), bin(.triangle), bin(.square)],
            correctOptionID: TVShapeKind.triangle.rawValue, successMessage: "Sorted! Triangle bin!"
        ),
        TVChoiceRound(
            id: 1, prompt: "Which bin does the circle go in?",
            subject: .shape(.circle),
            options: [bin(.square), bin(.triangle), bin(.circle)],
            correctOptionID: TVShapeKind.circle.rawValue, successMessage: "Sorted! Circle bin!"
        ),
        TVChoiceRound(
            id: 2, prompt: "Which bin does the square go in?",
            subject: .shape(.square),
            options: [bin(.square), bin(.circle), bin(.triangle)],
            correctOptionID: TVShapeKind.square.rawValue, successMessage: "Sorted! Square bin!"
        )
    ]

    // MARK: - Family Challenge

    static let familyChallenges: [TVFamilyChallenge] = [
        TVFamilyChallenge(
            id: "shape-squad",
            title: "Shape Squad",
            emoji: "🔷",
            goalPrompt: "Can the family find 5 shapes together?",
            category: .shapes,
            goal: 5,
            questions: [
                findShape(id: 0, target: .circle, others: [.square, .triangle]),
                findShape(id: 1, target: .triangle, others: [.circle, .star]),
                findShape(id: 2, target: .square, others: [.diamond, .circle]),
                findShape(id: 3, target: .star, others: [.triangle, .square]),
                findShape(id: 4, target: .diamond, others: [.star, .circle]),
                findShape(id: 5, target: .circle, others: [.triangle, .diamond])
            ]
        ),
        TVFamilyChallenge(
            id: "counting-crew",
            title: "Counting Crew",
            emoji: "🔢",
            goalPrompt: "Can the family count 6 groups together?",
            category: .numbers,
            goal: 6,
            questions: [
                countGroup(id: 0, emoji: "🍎", count: 3, options: [2, 3, 4]),
                countGroup(id: 1, emoji: "🐞", count: 5, options: [5, 6, 3]),
                countGroup(id: 2, emoji: "🌸", count: 2, options: [1, 4, 2]),
                countGroup(id: 3, emoji: "🚗", count: 4, options: [4, 3, 6]),
                countGroup(id: 4, emoji: "🍪", count: 6, options: [5, 7, 6]),
                countGroup(id: 5, emoji: "⚽", count: 1, options: [1, 2, 3]),
                countGroup(id: 6, emoji: "🧁", count: 7, options: [8, 7, 6])
            ]
        ),
        TVFamilyChallenge(
            id: "animal-parade",
            title: "Animal Parade",
            emoji: "🐘",
            goalPrompt: "Can the family find 4 animals together?",
            category: .animals,
            goal: 4,
            questions: [
                findAnimal(id: 0, prompt: "Who says MOO?", answer: ("🐮", "Cow"), others: [("🐷", "Pig"), ("🐔", "Chicken")]),
                findAnimal(id: 1, prompt: "Who has a long trunk?", answer: ("🐘", "Elephant"), others: [("🦁", "Lion"), ("🐵", "Monkey")]),
                findAnimal(id: 2, prompt: "Who says WOOF?", answer: ("🐶", "Dog"), others: [("🐱", "Cat"), ("🐮", "Cow")]),
                findAnimal(id: 3, prompt: "Who loves bananas?", answer: ("🐵", "Monkey"), others: [("🐘", "Elephant"), ("🐟", "Fish")]),
                findAnimal(id: 4, prompt: "Who can swim?", answer: ("🐟", "Fish"), others: [("🐶", "Dog"), ("🦁", "Lion")])
            ]
        )
    ]

    private static func findShape(id: Int, target: TVShapeKind, others: [TVShapeKind]) -> TVChoiceRound {
        var options = others.map { TVChoiceOption(id: $0.rawValue, label: $0.name, visual: .shape($0)) }
        // Vary the position of the correct answer between questions.
        options.insert(TVChoiceOption(id: target.rawValue, label: target.name, visual: .shape(target)), at: id % 3)
        return TVChoiceRound(
            id: id, prompt: "Find the \(target.name.uppercased())!",
            subject: .none, options: options, correctOptionID: target.rawValue,
            successMessage: "You found the \(target.name.lowercased())!"
        )
    }

    private static func countGroup(id: Int, emoji: String, count: Int, options: [Int]) -> TVChoiceRound {
        TVChoiceRound(
            id: id, prompt: "How many can you count?",
            subject: .group(emoji: emoji, count: count),
            options: options.map(numberOption), correctOptionID: "\(count)",
            successMessage: "Yes, \(count)!"
        )
    }

    private static func findAnimal(
        id: Int,
        prompt: String,
        answer: (emoji: String, name: String),
        others: [(emoji: String, name: String)]
    ) -> TVChoiceRound {
        var options = others.map { TVChoiceOption(id: $0.name, label: $0.name, visual: .animal(emoji: $0.emoji)) }
        options.insert(TVChoiceOption(id: answer.name, label: answer.name, visual: .animal(emoji: answer.emoji)), at: (id + 1) % 3)
        return TVChoiceRound(
            id: id, prompt: prompt, subject: .none, options: options,
            correctOptionID: answer.name, successMessage: "It's the \(answer.name.lowercased())!"
        )
    }

    // MARK: - Players

    /// The sample family shown on first launch so the prototype is demo-ready.
    static func demoPlayers() -> [TVPlayer] {
        [
            TVPlayer(
                name: "Ava", avatar: "👧", color: .coral, points: 640, familyChallengesPlayed: 1,
                progress: TVGameProgress(
                    categories: [
                        .numbers: TVCategoryProgress(stars: 24, correctAnswers: 17, gamesPlayed: 7),
                        .letters: TVCategoryProgress(stars: 18, correctAnswers: 14, gamesPlayed: 6),
                        // Two stars short of Shape Master so a demo game can unlock it live.
                        .shapes: TVCategoryProgress(stars: 8, correctAnswers: 12, gamesPlayed: 4),
                        .animals: TVCategoryProgress(stars: 22, correctAnswers: 18, gamesPlayed: 7)
                    ],
                    completedGames: [.countingPop, .dragToMatch, .animalMatch, .tapToReveal]
                ),
                earnedRewards: [.numberExplorer, .letterExplorer, .animalFriend, .familyLearner]
            ),
            TVPlayer(
                name: "Liam", avatar: "👦", color: .sky, points: 410,
                progress: TVGameProgress(
                    categories: [
                        .numbers: TVCategoryProgress(stars: 9, correctAnswers: 9, gamesPlayed: 4),
                        .letters: TVCategoryProgress(stars: 14, correctAnswers: 13, gamesPlayed: 5),
                        .shapes: TVCategoryProgress(stars: 7, correctAnswers: 8, gamesPlayed: 3),
                        .animals: TVCategoryProgress(stars: 10, correctAnswers: 10, gamesPlayed: 4)
                    ],
                    completedGames: [.countingPop, .shapeHunt, .animalMatch]
                ),
                earnedRewards: [.letterExplorer, .animalFriend]
            ),
            TVPlayer(name: "Parent", avatar: "🧑", color: .mint, role: .parent)
        ]
    }

    static let demoFamilyScore = TVFamilyScore(familyStars: 118, challengesCompleted: 1, gamesCompleted: 41)
}
