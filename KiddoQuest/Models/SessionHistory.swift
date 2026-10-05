import Foundation

struct SessionHistory: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var duration: TimeInterval
    var gamesPlayed: Int
    var starsEarned: Int
    
    static let preview = SessionHistory(
        duration: 420,
        gamesPlayed: 3,
        starsEarned: 8
    )
}
