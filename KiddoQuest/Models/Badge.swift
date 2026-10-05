import Foundation

struct Badge: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var icon: String
    var category: String
    var earnedDate: Date?
    var isUnlocked: Bool = false
    
    static let initialBadges: [Badge] = [
        Badge(name: "First Game", description: "Completed your first learning activity!", icon: "star.circle.fill", category: "General", earnedDate: Date(), isUnlocked: true),
        Badge(name: "Number Explorer", description: "Counted objects and matched numbers!", icon: "number.circle.fill", category: "Numbers", earnedDate: Date(), isUnlocked: true),
        Badge(name: "Letter Explorer", description: "Discovered letters and hunted sounds!", icon: "character.book.closed.fill", category: "Letters", earnedDate: nil, isUnlocked: false),
        Badge(name: "Shape Master", description: "Colored and sorted geometric shapes!", icon: "square.on.circle.fill", category: "Shapes", earnedDate: nil, isUnlocked: false),
        Badge(name: "Animal Friend", description: "Matched animal friends together!", icon: "pawprint.fill", category: "Animals", earnedDate: nil, isUnlocked: false),
        Badge(name: "AR Explorer", description: "Explored virtual learning objects in AR!", icon: "arkit", category: "AR", earnedDate: nil, isUnlocked: false)
    ]
}
