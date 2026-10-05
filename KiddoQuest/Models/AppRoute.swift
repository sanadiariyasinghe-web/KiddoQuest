import Foundation

enum ARMode: String, CaseIterable, Identifiable, Hashable, Codable {
    case letterHunt = "AR Letter Hunt"
    case shapeHunt = "AR Shape Hunt"
    case animalDiscovery = "AR Animal Discovery"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .letterHunt: return "textformat.abc"
        case .shapeHunt: return "triangle.fill"
        case .animalDiscovery: return "pawprint.fill"
        }
    }
    
    var description: String {
        switch self {
        case .letterHunt: return "Spot virtual 3D letters floating in your room!"
        case .shapeHunt: return "Find geometric shapes placed on flat surfaces!"
        case .animalDiscovery: return "Discover animated safari animal friends!"
        }
    }
}

enum AppRoute: Hashable {
    case category(IslandCategory)
    case gameList(IslandCategory)
    case gamePlay(GameInfo)
    case rewards
    case profile
    case parentSettings
    case arLearning(ARMode? = nil)
}
