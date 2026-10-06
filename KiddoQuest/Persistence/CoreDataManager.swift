import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Manager
// Handles all CRUD operations, profile management, progress saving, badges,
// and session history tracking across app launches.

@Observable
final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let context: NSManagedObjectContext
    
    var currentProfile: ChildProfile = ChildProfile.preview
    var badges: [Badge] = Badge.initialBadges
    var recentSessions: [SessionHistory] = []
    /// Saved progress for every finished game, keyed by game ID.
    var progressByGame: [String: GameProgress] = [:]
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        bootstrapInitialData()
    }
    
    // MARK: - Bootstrap Data
    func bootstrapInitialData() {
        _ = fetchOrCreateProfile()
        fetchBadges()
        fetchSessions()
        fetchAllProgress()
    }
    
    // MARK: - Child Profile Operations
    @discardableResult
    func fetchOrCreateProfile() -> ChildProfile {
        let request: NSFetchRequest<ChildProfileEntity> = NSFetchRequest(entityName: "ChildProfileEntity")
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                let profile = ChildProfile(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "Explorer",
                    avatar: entity.avatar ?? "🦁",
                    age: Int(entity.age),
                    createdDate: entity.createdDate ?? Date(),
                    totalStars: Int(entity.totalStars)
                )
                self.currentProfile = profile
                return profile
            } else {
                // Create initial profile
                let newEntity = ChildProfileEntity(context: context)
                let newId = UUID()
                newEntity.id = newId
                newEntity.name = "Leo"
                newEntity.avatar = "🦁"
                newEntity.age = 5
                newEntity.createdDate = Date()
                newEntity.totalStars = 0
                
                try context.save()
                
                let profile = ChildProfile(id: newId, name: "Leo", avatar: "🦁", age: 5, createdDate: Date(), totalStars: 0)
                self.currentProfile = profile
                return profile
            }
        } catch {
            print("Failed to fetch profile: \(error)")
            return ChildProfile.preview
        }
    }
    
    func updateProfile(name: String, avatar: String, age: Int) {
        let request: NSFetchRequest<ChildProfileEntity> = NSFetchRequest(entityName: "ChildProfileEntity")
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.name = name
                entity.avatar = avatar
                entity.age = Int16(age)
                try context.save()
                
                currentProfile.name = name
                currentProfile.avatar = avatar
                currentProfile.age = age
            }
        } catch {
            print("Failed to update profile: \(error)")
        }
    }
    
    func addStars(_ count: Int) {
        let request: NSFetchRequest<ChildProfileEntity> = NSFetchRequest(entityName: "ChildProfileEntity")
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                entity.totalStars += Int32(count)
                try context.save()
                currentProfile.totalStars = Int(entity.totalStars)
            }
        } catch {
            print("Failed to add stars: \(error)")
        }
    }
    
    // MARK: - Game Progress Operations
    func saveGameProgress(gameID: String, category: String, stars: Int, score: Int) {
        let request: NSFetchRequest<GameProgressEntity> = NSFetchRequest(entityName: "GameProgressEntity")
        request.predicate = NSPredicate(format: "gameID == %@", gameID)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            let entity: GameProgressEntity
            if let existing = results.first {
                entity = existing
            } else {
                entity = GameProgressEntity(context: context)
                entity.id = UUID()
                entity.gameID = gameID
                entity.category = category
            }
            
            entity.completed = true
            entity.stars = max(entity.stars, Int16(stars))
            entity.score = Int32(score)
            entity.bestScore = max(entity.bestScore, Int32(score))
            entity.lastPlayed = Date()
            
            try context.save()
            fetchAllProgress()
            
            // Add stars to overall profile
            addStars(stars)
            
            // Check for badge unlocks
            checkBadgeUnlocks(for: category)
        } catch {
            print("Failed to save game progress: \(error)")
        }
    }
    
    /// Loads saved progress for all games so Home and the game lists show real stars.
    func fetchAllProgress() {
        let request: NSFetchRequest<GameProgressEntity> = NSFetchRequest(entityName: "GameProgressEntity")
        
        do {
            let results = try context.fetch(request)
            var progress: [String: GameProgress] = [:]
            for entity in results {
                guard let gameID = entity.gameID else { continue }
                progress[gameID] = GameProgress(
                    id: entity.id ?? UUID(),
                    gameID: gameID,
                    category: entity.category ?? "",
                    completed: entity.completed,
                    stars: Int(entity.stars),
                    score: Int(entity.score),
                    bestScore: Int(entity.bestScore),
                    lastPlayed: entity.lastPlayed ?? Date()
                )
            }
            progressByGame = progress
        } catch {
            print("Failed to fetch all game progress: \(error)")
        }
    }
    
    func fetchProgress(for gameID: String) -> GameProgress? {
        let request: NSFetchRequest<GameProgressEntity> = NSFetchRequest(entityName: "GameProgressEntity")
        request.predicate = NSPredicate(format: "gameID == %@", gameID)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first {
                return GameProgress(
                    id: entity.id ?? UUID(),
                    gameID: entity.gameID ?? gameID,
                    category: entity.category ?? "",
                    completed: entity.completed,
                    stars: Int(entity.stars),
                    score: Int(entity.score),
                    bestScore: Int(entity.bestScore),
                    lastPlayed: entity.lastPlayed ?? Date()
                )
            }
        } catch {
            print("Failed to fetch game progress: \(error)")
        }
        return nil
    }
    
    // MARK: - Badge Management
    func fetchBadges() {
        let request: NSFetchRequest<BadgeEntity> = NSFetchRequest(entityName: "BadgeEntity")
        
        do {
            let results = try context.fetch(request)
            if results.isEmpty {
                // Initialize default badges
                for initial in Badge.initialBadges {
                    let entity = BadgeEntity(context: context)
                    entity.id = initial.id
                    entity.name = initial.name
                    entity.category = initial.category
                    entity.earnedDate = initial.earnedDate
                    entity.isUnlocked = initial.isUnlocked
                }
                try context.save()
                self.badges = Badge.initialBadges
            } else {
                self.badges = results.map { entity in
                    Badge(
                        id: entity.id ?? UUID(),
                        name: entity.name ?? "",
                        description: "",
                        icon: iconForBadge(named: entity.name ?? ""),
                        category: entity.category ?? "",
                        earnedDate: entity.earnedDate,
                        isUnlocked: entity.isUnlocked
                    )
                }
            }
        } catch {
            print("Failed to fetch badges: \(error)")
            self.badges = Badge.initialBadges
        }
    }
    
    func unlockBadge(named name: String) {
        let request: NSFetchRequest<BadgeEntity> = NSFetchRequest(entityName: "BadgeEntity")
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entity = results.first, !entity.isUnlocked {
                entity.isUnlocked = true
                entity.earnedDate = Date()
                try context.save()
                fetchBadges()
            }
        } catch {
            print("Failed to unlock badge \(name): \(error)")
        }
    }
    
    private func checkBadgeUnlocks(for category: String) {
        unlockBadge(named: "First Game")
        switch category {
        case "Numbers":
            unlockBadge(named: "Number Explorer")
        case "Letters":
            unlockBadge(named: "Letter Explorer")
        case "Shapes":
            unlockBadge(named: "Shape Master")
        case "Animals":
            unlockBadge(named: "Animal Friend")
        case "AR":
            unlockBadge(named: "AR Explorer")
        default:
            break
        }
    }
    
    private func iconForBadge(named name: String) -> String {
        switch name {
        case "First Game": return "star.circle.fill"
        case "Number Explorer": return "number.circle.fill"
        case "Letter Explorer": return "character.book.closed.fill"
        case "Shape Master": return "square.on.circle.fill"
        case "Animal Friend": return "pawprint.fill"
        case "AR Explorer": return "arkit"
        default: return "trophy.fill"
        }
    }
    
    // MARK: - Session History Tracking
    func recordSession(duration: TimeInterval, gamesPlayed: Int, starsEarned: Int) {
        let entity = SessionHistoryEntity(context: context)
        entity.id = UUID()
        entity.date = Date()
        entity.duration = duration
        entity.gamesPlayed = Int16(gamesPlayed)
        entity.starsEarned = Int16(starsEarned)
        
        do {
            try context.save()
            fetchSessions()
        } catch {
            print("Failed to record session: \(error)")
        }
    }
    
    func fetchSessions() {
        let request: NSFetchRequest<SessionHistoryEntity> = NSFetchRequest(entityName: "SessionHistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = 10
        
        do {
            let results = try context.fetch(request)
            self.recentSessions = results.map { entity in
                SessionHistory(
                    id: entity.id ?? UUID(),
                    date: entity.date ?? Date(),
                    duration: entity.duration,
                    gamesPlayed: Int(entity.gamesPlayed),
                    starsEarned: Int(entity.starsEarned)
                )
            }
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    /// Games finished and stars earned since `date` (used for the parent's weekly summary).
    func sessionTotals(since date: Date) -> (gamesPlayed: Int, starsEarned: Int) {
        let request: NSFetchRequest<SessionHistoryEntity> = NSFetchRequest(entityName: "SessionHistoryEntity")
        request.predicate = NSPredicate(format: "date >= %@", date as NSDate)

        do {
            let results = try context.fetch(request)
            let games = results.reduce(0) { $0 + Int($1.gamesPlayed) }
            let stars = results.reduce(0) { $0 + Int($1.starsEarned) }
            return (games, stars)
        } catch {
            print("Failed to fetch session totals: \(error)")
            return (0, 0)
        }
    }

    // MARK: - Reset All Data
    func resetAllData() {
        let entities = ["ChildProfileEntity", "GameProgressEntity", "SessionHistoryEntity", "BadgeEntity"]
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }
        do {
            try context.save()
        } catch {
            print("Failed to save reset context: \(error)")
        }
        bootstrapInitialData()
    }
}
