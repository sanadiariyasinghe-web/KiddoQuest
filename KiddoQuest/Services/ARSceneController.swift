import ARKit
import RealityKit
import SwiftUI
import UIKit

// MARK: - AR Scene Controller
// Owns the RealityKit scene for AR Learning Mode:
// • runs ARKit world tracking with horizontal plane detection,
// • shows Apple's coaching overlay until a table or floor is found,
// • places 3D picture cards (letters, shapes or animals) on that real surface,
// • hit-tests the child's taps against the 3D cards and animates the result.

final class ARSceneController: NSObject, ARSessionDelegate {
    var viewModel: ARLearningViewModel

    private weak var arView: ARView?
    private var contentAnchor: AnchorEntity?
    private var placedLayoutID: UUID?
    private var cardsByItemID: [UUID: Entity] = [:]
    private var celebratedItemIDs: Set<UUID> = []

    // Card size and layout on the real surface (metres)
    private let cardSize: Float = 0.1
    private let cardSpacing: Float = 0.13
    private let cardHeightAboveSurface: Float = 0.07

    init(viewModel: ARLearningViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Setup
    func attach(to arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
        arView.session.run(ARService.shared.createConfiguration())

        // Apple's coaching overlay: "Move iPhone to find a surface"
        let coaching = ARCoachingOverlayView(frame: arView.bounds)
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        arView.addSubview(coaching)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
    }

    func pause() {
        arView?.session.pause()
    }

    // MARK: - Layout
    /// Rebuilds the 3D cards when the mode changes, and celebrates newly found items.
    func update() {
        guard let arView else { return }

        if placedLayoutID != viewModel.layoutID {
            placedLayoutID = viewModel.layoutID
            placeCards(in: arView)
        }

        for item in viewModel.targetObjects where item.isDiscovered && !celebratedItemIDs.contains(item.id) {
            celebratedItemIDs.insert(item.id)
            if let card = cardsByItemID[item.id] {
                celebrate(card)
            }
        }
    }

    private func placeCards(in arView: ARView) {
        contentAnchor?.removeFromParent()
        cardsByItemID = [:]
        celebratedItemIDs = []

        // Anchors to the first real horizontal surface at least 20 cm × 20 cm
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.2, 0.2]))
        let items = viewModel.targetObjects

        for (index, item) in items.enumerated() {
            let card = makeCard(for: item)
            // A gentle arc in front of the child
            let offset = Float(index) - Float(items.count - 1) / 2
            card.position = [offset * cardSpacing, cardHeightAboveSurface, -abs(offset) * 0.04]
            anchor.addChild(card)
            cardsByItemID[item.id] = card
        }

        arView.scene.addAnchor(anchor)
        contentAnchor = anchor
    }

    /// A standing picture card with a small coloured base, always turned towards the camera.
    private func makeCard(for item: ARObjectItem) -> Entity {
        let container = Entity()
        container.name = item.id.uuidString

        let card = ModelEntity(
            mesh: .generatePlane(width: cardSize, height: cardSize, cornerRadius: 0.015),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        card.name = item.id.uuidString
        card.generateCollisionShapes(recursive: false)
        card.components.set(BillboardComponent())
        container.addChild(card)

        let base = ModelEntity(
            mesh: .generateCylinder(height: 0.006, radius: 0.035),
            materials: [SimpleMaterial(color: UIColor(Theme.ColorPalette.arOrange), isMetallic: false)]
        )
        base.position = [0, -cardHeightAboveSurface + 0.003, 0]
        container.addChild(base)

        // Draw the letter, shape or animal onto the card
        Task {
            guard let image = Self.cardImage(for: item.display),
                  let texture = try? await TextureResource(image: image, options: .init(semantic: .color)) else { return }
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            card.model?.materials = [material]
        }

        return container
    }

    /// Renders a symbol (letter, shape or emoji) on a friendly rounded card.
    static func cardImage(for symbol: String) -> CGImage? {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 40)
            UIColor.white.setFill()
            path.fill()
            UIColor(Theme.ColorPalette.arOrange).setStroke()
            path.lineWidth = 12
            path.stroke()

            let font = UIFont.systemFont(ofSize: 150, weight: .heavy)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)
            ]
            let text = NSAttributedString(string: symbol, attributes: attributes)
            let textSize = text.size()
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2))
        }
        return image.cgImage
    }

    // MARK: - Tapping 3D Objects
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView else { return }
        let point = gesture.location(in: arView)
        guard let hit = arView.entity(at: point),
              let item = item(for: hit),
              !item.isDiscovered else { return }

        let wasTarget = item.isTarget
        viewModel.tapObject(item)

        if !wasTarget, let card = cardsByItemID[item.id] {
            wobble(card)
        }
        update()
    }

    /// Walks up from the tapped entity to the card it belongs to.
    private func item(for entity: Entity) -> ARObjectItem? {
        var current: Entity? = entity
        while let candidate = current {
            if let item = viewModel.targetObjects.first(where: { $0.id.uuidString == candidate.name }) {
                return item
            }
            current = candidate.parent
        }
        return nil
    }

    // MARK: - Feedback Animations
    private func celebrate(_ card: Entity) {
        var lifted = card.transform
        lifted.scale = [1.35, 1.35, 1.35]
        lifted.translation.y += 0.04
        card.move(to: lifted, relativeTo: card.parent, duration: 0.45, timingFunction: .easeOut)
    }

    /// A gentle side-to-side wobble for a wrong pick (never harsh).
    private func wobble(_ card: Entity) {
        let start = card.transform
        var left = start
        left.translation.x -= 0.015
        var right = start
        right.translation.x += 0.015

        Task {
            card.move(to: left, relativeTo: card.parent, duration: 0.08)
            try? await Task.sleep(for: .seconds(0.08))
            card.move(to: right, relativeTo: card.parent, duration: 0.12)
            try? await Task.sleep(for: .seconds(0.12))
            card.move(to: start, relativeTo: card.parent, duration: 0.08)
        }
    }

    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if !viewModel.isSurfaceFound, anchors.contains(where: { $0 is ARPlaneAnchor }) {
            viewModel.isSurfaceFound = true
        }
    }
}
