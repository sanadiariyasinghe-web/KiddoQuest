import CoreData

// MARK: - Persistence Controller
// Programmatically defines and manages the Core Data stack for KiddoQuest,
// supporting SQLite persistent storage and in-memory storage for previews/unit tests.

struct PersistenceController {
    /// The app's store. Automated tests get an in-memory store so real progress is never touched.
    static let shared = PersistenceController(inMemory: AppEnvironment.usesInMemoryStore)

    /// One shared model for every store. Creating a new model per store makes Core Data
    /// unable to tell which entity description a managed object class belongs to.
    private static let managedObjectModel = createManagedObjectModel()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Seed preview profile
        let profile = ChildProfileEntity(context: viewContext)
        profile.id = UUID()
        profile.name = "Leo"
        profile.avatar = "🦁"
        profile.age = 5
        profile.createdDate = Date()
        profile.totalStars = 24
        
        // Seed sample badges
        for badge in Badge.initialBadges {
            let entity = BadgeEntity(context: viewContext)
            entity.id = badge.id
            entity.name = badge.name
            entity.category = badge.category
            entity.earnedDate = badge.earnedDate
            entity.isUnlocked = badge.isUnlocked
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Preview save error: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "KiddoQuestModel", managedObjectModel: Self.managedObjectModel)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data load error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Programmatic Core Data Model
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // 1. ChildProfileEntity
        let profileEntity = NSEntityDescription()
        profileEntity.name = "ChildProfileEntity"
        profileEntity.managedObjectClassName = NSStringFromClass(ChildProfileEntity.self)
        
        let profileId = NSAttributeDescription()
        profileId.name = "id"
        profileId.attributeType = .UUIDAttributeType
        profileId.isOptional = false
        
        let profileName = NSAttributeDescription()
        profileName.name = "name"
        profileName.attributeType = .stringAttributeType
        profileName.isOptional = false
        
        let profileAvatar = NSAttributeDescription()
        profileAvatar.name = "avatar"
        profileAvatar.attributeType = .stringAttributeType
        profileAvatar.isOptional = false
        
        let profileAge = NSAttributeDescription()
        profileAge.name = "age"
        profileAge.attributeType = .integer16AttributeType
        profileAge.defaultValue = 5
        
        let profileCreatedDate = NSAttributeDescription()
        profileCreatedDate.name = "createdDate"
        profileCreatedDate.attributeType = .dateAttributeType
        profileCreatedDate.isOptional = false
        
        let profileTotalStars = NSAttributeDescription()
        profileTotalStars.name = "totalStars"
        profileTotalStars.attributeType = .integer32AttributeType
        profileTotalStars.defaultValue = 0
        
        profileEntity.properties = [profileId, profileName, profileAvatar, profileAge, profileCreatedDate, profileTotalStars]
        
        // 2. GameProgressEntity
        let progressEntity = NSEntityDescription()
        progressEntity.name = "GameProgressEntity"
        progressEntity.managedObjectClassName = NSStringFromClass(GameProgressEntity.self)
        
        let progressId = NSAttributeDescription()
        progressId.name = "id"
        progressId.attributeType = .UUIDAttributeType
        progressId.isOptional = false
        
        let progressGameId = NSAttributeDescription()
        progressGameId.name = "gameID"
        progressGameId.attributeType = .stringAttributeType
        progressGameId.isOptional = false
        
        let progressCategory = NSAttributeDescription()
        progressCategory.name = "category"
        progressCategory.attributeType = .stringAttributeType
        progressCategory.isOptional = false
        
        let progressCompleted = NSAttributeDescription()
        progressCompleted.name = "completed"
        progressCompleted.attributeType = .booleanAttributeType
        progressCompleted.defaultValue = false
        
        let progressStars = NSAttributeDescription()
        progressStars.name = "stars"
        progressStars.attributeType = .integer16AttributeType
        progressStars.defaultValue = 0
        
        let progressScore = NSAttributeDescription()
        progressScore.name = "score"
        progressScore.attributeType = .integer32AttributeType
        progressScore.defaultValue = 0
        
        let progressBestScore = NSAttributeDescription()
        progressBestScore.name = "bestScore"
        progressBestScore.attributeType = .integer32AttributeType
        progressBestScore.defaultValue = 0
        
        let progressLastPlayed = NSAttributeDescription()
        progressLastPlayed.name = "lastPlayed"
        progressLastPlayed.attributeType = .dateAttributeType
        progressLastPlayed.isOptional = true
        
        progressEntity.properties = [progressId, progressGameId, progressCategory, progressCompleted, progressStars, progressScore, progressBestScore, progressLastPlayed]
        
        // 3. SessionHistoryEntity
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "SessionHistoryEntity"
        sessionEntity.managedObjectClassName = NSStringFromClass(SessionHistoryEntity.self)
        
        let sessionId = NSAttributeDescription()
        sessionId.name = "id"
        sessionId.attributeType = .UUIDAttributeType
        sessionId.isOptional = false
        
        let sessionDate = NSAttributeDescription()
        sessionDate.name = "date"
        sessionDate.attributeType = .dateAttributeType
        sessionDate.isOptional = false
        
        let sessionDuration = NSAttributeDescription()
        sessionDuration.name = "duration"
        sessionDuration.attributeType = .doubleAttributeType
        sessionDuration.defaultValue = 0.0
        
        let sessionGamesPlayed = NSAttributeDescription()
        sessionGamesPlayed.name = "gamesPlayed"
        sessionGamesPlayed.attributeType = .integer16AttributeType
        sessionGamesPlayed.defaultValue = 0
        
        let sessionStarsEarned = NSAttributeDescription()
        sessionStarsEarned.name = "starsEarned"
        sessionStarsEarned.attributeType = .integer16AttributeType
        sessionStarsEarned.defaultValue = 0
        
        sessionEntity.properties = [sessionId, sessionDate, sessionDuration, sessionGamesPlayed, sessionStarsEarned]
        
        // 4. BadgeEntity
        let badgeEntity = NSEntityDescription()
        badgeEntity.name = "BadgeEntity"
        badgeEntity.managedObjectClassName = NSStringFromClass(BadgeEntity.self)
        
        let badgeId = NSAttributeDescription()
        badgeId.name = "id"
        badgeId.attributeType = .UUIDAttributeType
        badgeId.isOptional = false
        
        let badgeName = NSAttributeDescription()
        badgeName.name = "name"
        badgeName.attributeType = .stringAttributeType
        badgeName.isOptional = false
        
        let badgeCategory = NSAttributeDescription()
        badgeCategory.name = "category"
        badgeCategory.attributeType = .stringAttributeType
        badgeCategory.isOptional = false
        
        let badgeEarnedDate = NSAttributeDescription()
        badgeEarnedDate.name = "earnedDate"
        badgeEarnedDate.attributeType = .dateAttributeType
        badgeEarnedDate.isOptional = true
        
        let badgeIsUnlocked = NSAttributeDescription()
        badgeIsUnlocked.name = "isUnlocked"
        badgeIsUnlocked.attributeType = .booleanAttributeType
        badgeIsUnlocked.defaultValue = false
        
        badgeEntity.properties = [badgeId, badgeName, badgeCategory, badgeEarnedDate, badgeIsUnlocked]
        
        model.entities = [profileEntity, progressEntity, sessionEntity, badgeEntity]
        return model
    }
}

// MARK: - Core Data NSManagedObject Subclasses

@objc(ChildProfileEntity)
public class ChildProfileEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var avatar: String?
    @NSManaged public var age: Int16
    @NSManaged public var createdDate: Date?
    @NSManaged public var totalStars: Int32
}

@objc(GameProgressEntity)
public class GameProgressEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var gameID: String?
    @NSManaged public var category: String?
    @NSManaged public var completed: Bool
    @NSManaged public var stars: Int16
    @NSManaged public var score: Int32
    @NSManaged public var bestScore: Int32
    @NSManaged public var lastPlayed: Date?
}

@objc(SessionHistoryEntity)
public class SessionHistoryEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var gamesPlayed: Int16
    @NSManaged public var starsEarned: Int16
}

@objc(BadgeEntity)
public class BadgeEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var category: String?
    @NSManaged public var earnedDate: Date?
    @NSManaged public var isUnlocked: Bool
}
