import SwiftUI

@Observable
final class HomeViewModel {
    var categories: [IslandCategory] = IslandCategory.allCases
    
    var selectedProfile: ChildProfile {
        CoreDataManager.shared.currentProfile
    }
    
    var totalStars: Int {
        CoreDataManager.shared.currentProfile.totalStars
    }
    
    // Island completion summaries
    var categoryProgress: [IslandCategory: (stars: Int, percentage: Int, isUnlocked: Bool)] = [
        .numbers: (stars: 3, percentage: 80, isUnlocked: true),
        .letters: (stars: 2, percentage: 50, isUnlocked: true),
        .shapes: (stars: 4, percentage: 100, isUnlocked: true),
        .animals: (stars: 1, percentage: 25, isUnlocked: true)
    ]
    
    func progressFor(category: IslandCategory) -> (stars: Int, percentage: Int, isUnlocked: Bool) {
        categoryProgress[category] ?? (stars: 0, percentage: 0, isUnlocked: true)
    }
}
