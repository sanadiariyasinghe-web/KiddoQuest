import Foundation
import Observation

/// Owns the NavigationStack path. The Siri Remote's Back (Menu) button pops
/// the stack automatically; these helpers cover programmatic navigation.
@Observable
final class TVRouter {
    var path: [TVRoute] = []

    func push(_ route: TVRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Swaps the current screen, e.g. a finished game for its results.
    func replaceTop(with route: TVRoute) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    /// CONTINUE on Home: jump back to where the player was, or start fresh.
    func continueJourney(hasPlayer: Bool, lastCategory: TVCategory?) {
        guard hasPlayer else {
            path = [.playerSelection(.startPlaying)]
            return
        }
        if let lastCategory {
            path = [.world, .category(lastCategory)]
        } else {
            path = [.world]
        }
    }
}
