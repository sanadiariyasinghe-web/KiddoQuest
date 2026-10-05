import Foundation

struct GameProgress: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var gameID: String
    var category: String
    var completed: Bool = false
    var stars: Int = 0
    var score: Int = 0
    var bestScore: Int = 0
    var lastPlayed: Date = Date()
    
    static let preview = GameProgress(
        gameID: "counting_pop",
        category: "Numbers",
        completed: true,
        stars: 3,
        score: 100,
        bestScore: 100
    )
}
