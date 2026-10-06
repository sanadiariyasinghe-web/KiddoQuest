import Foundation

/// Local, bundled content for every game. The app needs no backend,
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
            title: "Tap-to-Match",
            summary: "Pick the number or little letter that matches.",
            categories: [.numbers, .letters],
            availability: .playable,
            emoji: "🧲"
        ),
        TVGame(
            kind: .tapToReveal,
            title: "Tap-to-Reveal",
            summary: "Choose the right colour to reveal the picture.",
            categories: [.shapes],
            availability: .playable,
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
            kind: .feedAnimals,
            title: "Feed the Animals",
            summary: "Give each hungry animal the food it loves.",
            categories: [.animals],
            availability: .playable,
            emoji: "🥕"
        ),
        TVGame(
            kind: .animalShadows,
            title: "Animal Shadows",
            summary: "Look at the shadow and find the animal.",
            categories: [.animals],
            availability: .playable,
            emoji: "🦒"
        ),
        TVGame(
            kind: .shapeSort,
            title: "Shape Sort",
            summary: "Send each shape to its matching bin.",
            categories: [.shapes],
            availability: .playable,
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

    // MARK: - Choice games

    /// Rounds in every choice game (Tap-to-Match, Tap-to-Reveal, Feed the Animals,
    /// Animal Shadows and Shape Sort), matching the length of the iOS games.
    static let choiceRoundCount = 5

    /// Builds a fresh, shuffled set of rounds so replays feel new.
    static func choiceRounds(for kind: TVGameKind, category: TVCategory) -> [TVChoiceRound] {
        let rounds: [TVChoiceRound]
        switch kind {
        case .dragToMatch:
            rounds = category == .letters ? letterMatchRounds() : numberMatchRounds()
        case .tapToReveal:
            rounds = colorRevealRounds()
        case .feedAnimals:
            rounds = feedAnimalsRounds()
        case .animalShadows:
            rounds = animalShadowRounds()
        case .shapeSort:
            rounds = shapeSortRounds()
        case .countingPop, .shapeHunt:
            // These have dedicated game engines.
            rounds = []
        }
        // Give rounds stable, sequential ids after shuffling.
        return rounds.enumerated().map { index, round in
            TVChoiceRound(
                id: index, prompt: round.prompt, subject: round.subject,
                options: round.options, correctOptionID: round.correctOptionID,
                successMessage: round.successMessage
            )
        }
    }

    /// The correct option plus `distractors`, in a random order.
    private static func shuffledOptions(correct: TVChoiceOption, distractors: [TVChoiceOption]) -> [TVChoiceOption] {
        ([correct] + distractors).shuffled()
    }

    private static func numberOption(_ value: Int) -> TVChoiceOption {
        TVChoiceOption(id: "\(value)", label: "\(value)", visual: .number(value))
    }

    private static func numberMatchRounds() -> [TVChoiceRound] {
        let groups: [(emoji: String, name: String)] = [
            ("🍎", "apples"), ("⭐", "stars"), ("🎈", "balloons"), ("🍓", "strawberries"),
            ("🐟", "fish"), ("🌸", "flowers"), ("🚗", "cars")
        ]
        return groups.shuffled().prefix(choiceRoundCount).map { group in
            let count = Int.random(in: 1...5)
            let others = (1...6).filter { $0 != count }.shuffled().prefix(2).map(numberOption)
            return TVChoiceRound(
                id: 0, prompt: "Match the \(group.name) to their number!",
                subject: .group(emoji: group.emoji, count: count),
                options: shuffledOptions(correct: numberOption(count), distractors: Array(others)),
                correctOptionID: "\(count)", successMessage: "Snap! \(count) \(group.name)!"
            )
        }
    }

    private static func letterOption(_ letter: String) -> TVChoiceOption {
        TVChoiceOption(id: letter, label: "Letter \(letter)", visual: .letter(letter))
    }

    private static func letterMatchRounds() -> [TVChoiceRound] {
        let letters = ["A", "B", "C", "D", "E", "M", "S", "T"]
        return letters.shuffled().prefix(choiceRoundCount).map { letter in
            let small = letter.lowercased()
            let others = letters.map { $0.lowercased() }.filter { $0 != small }.shuffled().prefix(2).map(letterOption)
            return TVChoiceRound(
                id: 0, prompt: "Find the little letter that matches \(letter)!",
                subject: .letter(letter),
                options: shuffledOptions(correct: letterOption(small), distractors: Array(others)),
                correctOptionID: small, successMessage: "Snap! \(letter) and \(small)!"
            )
        }
    }

    private static func colorRevealRounds() -> [TVChoiceRound] {
        let pictures: [(symbol: String, name: String, color: TVColorChoice, message: String)] = [
            ("sun.max", "sun", .yellow, "A bright yellow sun!"),
            ("leaf", "leaf", .green, "A lovely green leaf!"),
            ("heart", "heart", .red, "A big red heart!"),
            ("drop", "raindrop", .blue, "A shiny blue raindrop!"),
            ("star", "star", .yellow, "A twinkly yellow star!"),
            ("tree", "tree", .green, "A tall green tree!")
        ]
        return pictures.shuffled().prefix(choiceRoundCount).map { picture in
            let options = TVColorChoice.allCases.shuffled().map {
                TVChoiceOption(id: $0.rawValue, label: $0.name, visual: .color($0))
            }
            return TVChoiceRound(
                id: 0, prompt: "What colour should this \(picture.name) be?",
                subject: .colorReveal(symbol: picture.symbol, name: picture.name.capitalized, answer: picture.color),
                options: options, correctOptionID: picture.color.rawValue,
                successMessage: picture.message
            )
        }
    }

    private static func pictureOption(_ emoji: String, _ name: String) -> TVChoiceOption {
        TVChoiceOption(id: name, label: name.capitalized, visual: .animal(emoji: emoji))
    }

    /// Animals and the food each one loves (same pairs as the iOS game).
    static let animalFoods: [(animal: String, name: String, food: String, foodName: String)] = [
        ("🐰", "bunny", "🥕", "carrots"),
        ("🐶", "dog", "🦴", "bones"),
        ("🐵", "monkey", "🍌", "bananas"),
        ("🐱", "cat", "🐟", "fish"),
        ("🐭", "mouse", "🧀", "cheese"),
        ("🐼", "panda", "🎋", "bamboo"),
        ("🐝", "bee", "🌻", "flowers"),
        ("🐔", "hen", "🌽", "corn")
    ]

    private static func feedAnimalsRounds() -> [TVChoiceRound] {
        animalFoods.shuffled().prefix(choiceRoundCount).map { pair in
            let others = animalFoods.filter { $0.foodName != pair.foodName }
                .shuffled().prefix(2)
                .map { pictureOption($0.food, $0.foodName) }
            return TVChoiceRound(
                id: 0, prompt: "What does the \(pair.name) eat?",
                subject: .hungryAnimal(emoji: pair.animal, name: pair.name, food: pair.food),
                options: shuffledOptions(correct: pictureOption(pair.food, pair.foodName), distractors: Array(others)),
                correctOptionID: pair.foodName,
                successMessage: "Yum! The \(pair.name) loves \(pair.foodName)!"
            )
        }
    }

    /// Animals with clear, recognisable outlines for the shadow game.
    static let shadowAnimals: [(emoji: String, name: String)] = [
        ("🐘", "elephant"), ("🦒", "giraffe"), ("🐢", "turtle"), ("🐧", "penguin"), ("🦁", "lion"),
        ("🐰", "bunny"), ("🐌", "snail"), ("🦋", "butterfly"), ("🐙", "octopus"), ("🦀", "crab")
    ]

    private static func animalShadowRounds() -> [TVChoiceRound] {
        shadowAnimals.shuffled().prefix(choiceRoundCount).map { animal in
            let others = shadowAnimals.filter { $0.name != animal.name }
                .shuffled().prefix(2)
                .map { pictureOption($0.emoji, $0.name) }
            return TVChoiceRound(
                id: 0, prompt: "Whose shadow is this?",
                subject: .animalShadow(emoji: animal.emoji, name: animal.name),
                options: shuffledOptions(correct: pictureOption(animal.emoji, animal.name), distractors: Array(others)),
                correctOptionID: animal.name,
                successMessage: "Yes! It is the \(animal.name)!"
            )
        }
    }

    private static func bin(_ kind: TVShapeKind) -> TVChoiceOption {
        TVChoiceOption(id: kind.rawValue, label: "\(kind.name) bin", visual: .shapeBin(kind))
    }

    private static func shapeSortRounds() -> [TVChoiceRound] {
        let kinds: [TVShapeKind] = [.triangle, .circle, .square]
        // Every shape appears at least once, in a random order.
        let queue = (kinds + (0..<(choiceRoundCount - kinds.count)).compactMap { _ in kinds.randomElement() }).shuffled()
        return queue.map { kind in
            TVChoiceRound(
                id: 0, prompt: "Which bin does the \(kind.name.lowercased()) go in?",
                subject: .shape(kind),
                options: kinds.shuffled().map(bin),
                correctOptionID: kind.rawValue, successMessage: "Sorted! \(kind.name) bin!"
            )
        }
    }

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

    /// The sample family shown on first launch so the app is demo-ready.
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
                    completedGames: [.countingPop, .dragToMatch, .feedAnimals, .tapToReveal]
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
                    completedGames: [.countingPop, .shapeHunt, .feedAnimals]
                ),
                earnedRewards: [.letterExplorer, .animalFriend]
            ),
            TVPlayer(name: "Parent", avatar: "🧑", color: .mint, role: .parent)
        ]
    }

    static let demoFamilyScore = TVFamilyScore(familyStars: 118, challengesCompleted: 1, gamesCompleted: 41)
}
