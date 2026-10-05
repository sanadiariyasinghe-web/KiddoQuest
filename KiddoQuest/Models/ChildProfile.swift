import Foundation

struct ChildProfile: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var avatar: String
    var age: Int
    var createdDate: Date = Date()
    var totalStars: Int = 0
    
    static let preview = ChildProfile(
        name: "Leo",
        avatar: "🦁",
        age: 5,
        totalStars: 18
    )
}
