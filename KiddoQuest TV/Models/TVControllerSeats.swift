import Foundation

/// Which game controller belongs to which Family Challenge player.
/// Controllers are handed out in turn order: controller 1 → first player, and so on.
/// The shared Siri Remote is never seated, so it can always answer for whoever's turn it is.
nonisolated struct TVControllerSeats: Equatable {
    /// Controller id → player id.
    private(set) var owners: [String: UUID] = [:]

    init(controllerIDs: [String] = [], participants: [UUID] = []) {
        for (controller, player) in zip(controllerIDs, participants) {
            owners[controller] = player
        }
    }

    var isEmpty: Bool { owners.isEmpty }

    func player(for controllerID: String) -> UUID? {
        owners[controllerID]
    }

    /// 0-based seat (controller light number - 1) for a player, if they have a controller.
    func seat(for player: UUID, controllerIDs: [String]) -> Int? {
        controllerIDs.firstIndex { owners[$0] == player }
    }

    /// A press is allowed from the Siri Remote / unknown input, or from the current player's own controller.
    func allows(pressFrom controllerID: String?, currentPlayer: UUID?) -> Bool {
        guard let controllerID, let owner = owners[controllerID] else { return true }
        return owner == currentPlayer
    }
}
