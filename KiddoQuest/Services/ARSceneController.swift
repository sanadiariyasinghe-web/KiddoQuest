import ARKit
import RealityKit
import SwiftUI
import UIKit

// MARK: - AR Scene Controller
// Owns the RealityKit scene for AR Learning Mode:
// • runs ARKit world tracking with horizontal plane detection,
// • shows Apple's coaching overlay until a table or floor is found,
// • lets the child tap the real surface to place five 3D learning objects there
//   (extruded 3D letters, thick 3D shapes or animal picture cubes on little stands),
// • hit-tests taps on the 3D objects: exploring makes an object hop, finding it lifts it up.

final class ARSceneController: NSObject, ARSessionDelegate {
    var viewModel: ARLearningViewModel

    private weak var arView: ARView?
    private var placementAnchor: AnchorEntity?
    private var objectsRoot: Entity?
    private var builtLayoutID: UUID?
    private var objectsByItemID: [UUID: Entity] = [:]
    private var pedestalsByItemID: [UUID: ModelEntity] = [:]
    private var celebratedItemIDs: Set<UUID> = []

    // Sizes on the real surface (metres)
    private let objectSpacing: Float = 0.13
    private let objectSize: Float = 0.08
    private let pedestalHeight: Float = 0.01
    private let pedestalRadius: Float = 0.05

    private static let letterColors: [UIColor] = [
        UIColor(Theme.ColorPalette.arOrange), UIColor(Theme.ColorPalette.lettersBlue),
        UIColor(Theme.ColorPalette.animalsGreen), UIColor(Theme.ColorPalette.shapesPurple),
        UIColor(Theme.ColorPalette.numbersYellow)
    ]

    /// Calm Mode (parent setting) or system Reduce Motion: no idle swaying.
    private var isCalm: Bool {
        UserDefaults.standard.bool(forKey: CalmMode.settingsKey) || UIAccessibility.isReduceMotionEnabled
    }

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

    // MARK: - Updates from SwiftUI
    /// Rebuilds the objects for a new challenge set, removes them when the child wants to
    /// move them, and celebrates newly found objects.
    func update() {
        // "Move" pressed: take the objects away until the child taps a new spot
        if !viewModel.isPlaced, placementAnchor != nil {
            removePlacement()
            return
        }

        if viewModel.isPlaced, builtLayoutID != viewModel.layoutID {
            buildObjects()
        }

        for item in viewModel.targetObjects where item.isDiscovered && !celebratedItemIDs.contains(item.id) {
            celebratedItemIDs.insert(item.id)
            if let object = objectsByItemID[item.id] {
                celebrate(object, pedestal: pedestalsByItemID[item.id])
            }
        }
    }

    // MARK: - Placing on the real surface
    /// Places the objects where the child tapped on the detected table or floor.
    private func place(at worldTransform: simd_float4x4) {
        guard let arView else { return }
        removePlacement()

        let position = SIMD3<Float>(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
        let anchor = AnchorEntity(world: position)
        let root = Entity()
        anchor.addChild(root)

        // Turn the row of objects to face the child
        let camera = arView.cameraTransform.translation
        let yaw = atan2(camera.x - position.x, camera.z - position.z)
        root.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])

        arView.scene.addAnchor(anchor)
        placementAnchor = anchor
        objectsRoot = root
        viewModel.isPlaced = true
        buildObjects()
    }

    private func removePlacement() {
        placementAnchor?.removeFromParent()
        placementAnchor = nil
        objectsRoot = nil
        objectsByItemID = [:]
        pedestalsByItemID = [:]
        celebratedItemIDs = []
        builtLayoutID = nil
    }

    private func buildObjects() {
        guard let root = objectsRoot else { return }
        root.children.removeAll()
        objectsByItemID = [:]
        pedestalsByItemID = [:]
        celebratedItemIDs = []
        builtLayoutID = viewModel.layoutID

        let items = viewModel.targetObjects
        for (index, item) in items.enumerated() {
            let object = makeObject(for: item, index: index)
            // A gentle arc around the child (the camera is towards +z)
            let offset = Float(index) - Float(items.count - 1) / 2
            object.position = [offset * objectSpacing, 0, -abs(offset) * 0.05]
            root.addChild(object)
            objectsByItemID[item.id] = object

            // Pop in one after another
            object.scale = [0.01, 0.01, 0.01]
            var shown = object.transform
            shown.scale = [1, 1, 1]
            object.move(to: shown, relativeTo: root, duration: 0.35 + Double(index) * 0.08, timingFunction: .easeOut)
        }
    }

    // MARK: - 3D Learning Objects
    /// A 3D letter, shape or animal cube standing on a small round stand.
    private func makeObject(for item: ARObjectItem, index: Int) -> Entity {
        let container = Entity()
        container.name = item.id.uuidString

        let pedestal = ModelEntity(
            mesh: .generateCylinder(height: pedestalHeight, radius: pedestalRadius),
            materials: [SimpleMaterial(color: .white, roughness: 0.6, isMetallic: false)]
        )
        pedestal.position = [0, pedestalHeight / 2, 0]
        container.addChild(pedestal)
        pedestalsByItemID[item.id] = pedestal

        let model: ModelEntity
        switch item.kind {
        case .letter(let letter):
            model = makeLetter(letter, color: Self.letterColors[index % Self.letterColors.count])
        case .shape(let shape):
            model = makeShape(shape)
        case .animal(let emoji):
            model = makeAnimalCube(emoji)
        }

        // Stand the model on top of the pedestal, centred
        let bounds = model.visualBounds(relativeTo: nil)
        let holder = Entity()
        holder.position = [0, pedestalHeight + (bounds.max.y - bounds.min.y) / 2 + 0.004, 0]
        model.position = -bounds.center
        holder.addChild(model)
        container.addChild(holder)

        if !isCalm {
            sway(holder)
        }

        container.generateCollisionShapes(recursive: true)
        return container
    }

    private func makeLetter(_ letter: String, color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateText(
            letter,
            extrusionDepth: 0.025,
            font: .systemFont(ofSize: CGFloat(objectSize * 1.1), weight: .heavy),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        return ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)])
    }

    private func makeShape(_ shape: ARShapeKind) -> ModelEntity {
        var options = MeshResource.ShapeExtrusionOptions()
        options.extrusionMethod = .linear(depth: 0.025)
        let material = SimpleMaterial(color: UIColor(shape.color), roughness: 0.35, isMetallic: false)
        guard let mesh = try? MeshResource(extruding: Self.path(for: shape, size: CGFloat(objectSize)), extrusionOptions: options) else {
            // Should never happen, but a box still lets the child play
            return ModelEntity(mesh: .generateBox(size: objectSize * 0.8), materials: [material])
        }
        return ModelEntity(mesh: mesh, materials: [material])
    }

    /// Outlines for the shapes in a y-up coordinate system, centred on the origin.
    static func path(for shape: ARShapeKind, size: CGFloat) -> Path {
        let r = size / 2
        var path = Path()
        switch shape {
        case .triangle:
            path.move(to: CGPoint(x: 0, y: r))
            path.addLine(to: CGPoint(x: r, y: -r * 0.8))
            path.addLine(to: CGPoint(x: -r, y: -r * 0.8))
            path.closeSubpath()
        case .circle:
            path.addEllipse(in: CGRect(x: -r, y: -r, width: size, height: size))
        case .square:
            path.addRoundedRect(in: CGRect(x: -r * 0.85, y: -r * 0.85, width: r * 1.7, height: r * 1.7), cornerSize: CGSize(width: r * 0.12, height: r * 0.12))
        case .star:
            for point in 0..<10 {
                let radius = point.isMultiple(of: 2) ? r : r * 0.45
                let angle = Double(point) * .pi / 5 + .pi / 2
                let p = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        case .heart:
            // Two lobes on top, point at the bottom (y-up)
            path.move(to: CGPoint(x: 0, y: -r))
            path.addCurve(to: CGPoint(x: -r, y: r * 0.35), control1: CGPoint(x: -r * 0.4, y: -r * 0.55), control2: CGPoint(x: -r, y: -r * 0.1))
            path.addArc(center: CGPoint(x: -r * 0.5, y: r * 0.35), radius: r * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            path.addArc(center: CGPoint(x: r * 0.5, y: r * 0.35), radius: r * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            path.addCurve(to: CGPoint(x: 0, y: -r), control1: CGPoint(x: r, y: -r * 0.1), control2: CGPoint(x: r * 0.4, y: -r * 0.55))
            path.closeSubpath()
        }
        return path
    }

    /// A soft rounded cube with the animal picture on every side.
    private func makeAnimalCube(_ emoji: String) -> ModelEntity {
        let cube = ModelEntity(
            mesh: .generateBox(size: objectSize * 0.9, cornerRadius: 0.012),
            materials: [SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)]
        )
        Task {
            guard let image = Self.pictureImage(for: emoji),
                  let texture = try? await TextureResource(image: image, options: .init(semantic: .color)) else { return }
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            cube.model?.materials = [material]
        }
        return cube
    }

    /// Renders an emoji on a friendly rounded tile (used on the animal cubes).
    static func pictureImage(for symbol: String) -> CGImage? {
        let size = CGSize(width: 256, height: 256)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.white.setFill()
            UIRectFill(rect)
            let border = UIBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), cornerRadius: 36)
            UIColor(Theme.ColorPalette.animalsGreen).setStroke()
            border.lineWidth = 14
            border.stroke()

            let text = NSAttributedString(string: symbol, attributes: [.font: UIFont.systemFont(ofSize: 160)])
            let textSize = text.size()
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2))
        }
        return image.cgImage
    }

    // MARK: - Tapping
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView else { return }
        let point = gesture.location(in: arView)

        // 1. Tapped a 3D object: explore it or find it
        if let hit = arView.entity(at: point), let item = item(for: hit) {
            guard !item.isDiscovered else { return }
            let wasTarget = viewModel.isTarget(item)
            viewModel.tapObject(item)
            if !wasTarget, let object = objectsByItemID[item.id] {
                hop(object)
            }
            update()
            return
        }

        // 2. Not placed yet: tapping the real table or floor puts the objects there
        guard !viewModel.isPlaced,
              let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first else { return }
        place(at: result.worldTransform)
        SoundService.shared.playButtonClick()
    }

    /// Walks up from the tapped entity to the object it belongs to.
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

    // MARK: - Animations
    /// A gentle side-to-side turn so the objects look alive and show they are 3D.
    private func sway(_ entity: Entity) {
        let start = entity.transform
        var from = start
        from.rotation = simd_quatf(angle: -0.35, axis: [0, 1, 0])
        var to = start
        to.rotation = simd_quatf(angle: 0.35, axis: [0, 1, 0])
        let animation = FromToByAnimation<Transform>(
            from: from, to: to, duration: 2.4, timing: .easeInOut,
            bindTarget: .transform, repeatMode: .autoReverse
        )
        if let resource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(resource)
        }
    }

    /// Found it: the object lifts, grows and its stand turns green.
    private func celebrate(_ object: Entity, pedestal: ModelEntity?) {
        var lifted = object.transform
        lifted.scale = [1.3, 1.3, 1.3]
        lifted.translation.y += 0.03
        object.move(to: lifted, relativeTo: object.parent, duration: 0.45, timingFunction: .easeOut)
        pedestal?.model?.materials = [SimpleMaterial(color: UIColor(Theme.ColorPalette.successGreen), roughness: 0.4, isMetallic: false)]
    }

    /// Exploring: a happy little hop (never a "wrong" shake).
    private func hop(_ object: Entity) {
        let start = object.transform
        var up = start
        up.translation.y += 0.035
        Task {
            object.move(to: up, relativeTo: object.parent, duration: 0.15, timingFunction: .easeOut)
            try? await Task.sleep(for: .seconds(0.15))
            object.move(to: start, relativeTo: object.parent, duration: 0.2, timingFunction: .easeIn)
        }
    }

    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        if !viewModel.isSurfaceFound, anchors.contains(where: { $0 is ARPlaneAnchor }) {
            viewModel.isSurfaceFound = true
        }
    }
}
