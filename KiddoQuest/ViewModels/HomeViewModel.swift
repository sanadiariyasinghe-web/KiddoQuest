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
    
    /// Real island progress built from the stars saved in Core Data.
    func progressFor(category: IslandCategory) -> IslandProgress {
        ProgressSummary.island(category, progress: CoreDataManager.shared.progressByGame)
    }
}
