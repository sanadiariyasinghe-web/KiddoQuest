import Foundation
import ARKit
import RealityKit

// MARK: - AR Service
// Manages ARKit plane detection, world tracking session availability,
// and RealityKit entity generation for the 3 learning activities.

final class ARService {
    static let shared = ARService()
    
    private init() {}
    
    var isARSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }
    
    func createConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        return configuration
    }
}
