import GameController
import Observation
import SwiftUI

/// Game controllers for Family Challenge: each child can hold their own controller.
/// Controllers drive the tvOS focus engine natively; this service adds
/// player numbers, light colours that match each child's avatar,
/// and remembers which controller was used last so turns can be enforced kindly.
@Observable
final class TVGameControllerService {
    private(set) var controllerIDs: [String] = []
    /// The controller a child last moved or pressed with (nil = Siri Remote).
    private(set) var lastActiveControllerID: String?
    private var controllers: [String: GCController] = [:]

    var hasControllers: Bool { !controllerIDs.isEmpty }

    static func id(for controller: GCController) -> String {
        String(describing: ObjectIdentifier(controller))
    }

    /// Watches controllers connecting and disconnecting (call from a `.task`).
    func observe() async {
        refresh()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await _ in NotificationCenter.default.notifications(named: .GCControllerDidConnect) { self.refresh() }
            }
            group.addTask { @MainActor in
                for await _ in NotificationCenter.default.notifications(named: .GCControllerDidDisconnect) { self.refresh() }
            }
        }
    }

    /// Lights each seated controller with its player number and avatar colour.
    func light(seats: TVControllerSeats, players: [TVPlayer]) {
        for (index, id) in controllerIDs.enumerated() {
            guard let controller = controllers[id] else { continue }
            let player = seats.player(for: id).flatMap { owner in players.first { $0.id == owner } }
            controller.playerIndex = player == nil ? .indexUnset : (GCControllerPlayerIndex(rawValue: index) ?? .indexUnset)
            if let player, let light = controller.light {
                let rgb = UIColor(player.color.color).cgColor.components ?? [1, 1, 1]
                light.color = GCColor(red: Float(rgb[0]), green: Float(rgb[min(1, rgb.count - 1)]), blue: Float(rgb[min(2, rgb.count - 1)]))
            }
        }
    }

    private func refresh() {
        // Only real game controllers (the Siri Remote is a micro gamepad).
        let pads = GCController.controllers().filter { $0.extendedGamepad != nil }
        controllers = Dictionary(uniqueKeysWithValues: pads.map { (Self.id(for: $0), $0) })
        controllerIDs = pads.map(Self.id(for:))
        for pad in pads {
            let id = Self.id(for: pad)
            pad.extendedGamepad?.valueChangedHandler = { [weak self] _, _ in
                self?.lastActiveControllerID = id
            }
        }
        // Any Siri Remote input means the shared remote is in use again.
        for remote in GCController.controllers() where remote.extendedGamepad == nil {
            remote.microGamepad?.valueChangedHandler = { [weak self] _, _ in
                self?.lastActiveControllerID = nil
            }
        }
    }
}
