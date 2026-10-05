import Foundation

/// Presentation logic for "Who's Playing?".
struct TVPlayerSelectionViewModel {
    struct Card: Identifiable, Hashable {
        let player: TVPlayer
        let isActive: Bool

        var id: UUID { player.id }

        /// e.g. "Numbers 85%" or "Family helper" for a parent with no progress.
        var highlight: String {
            if let category = player.progress.strongestCategory {
                return "\(category.title) \(player.progress.percent(for: category))%"
            }
            return player.isParent ? "Family helper" : "Ready to start!"
        }

        var accessibilityLabel: String {
            var parts = [player.name, "\(player.rating) of 5 stars", highlight]
            if isActive { parts.append("currently playing") }
            return parts.joined(separator: ", ")
        }
    }

    let players: [TVPlayer]
    let selectedPlayerID: UUID?
    let mode: TVPlayerSelectionMode

    /// Children first, then grown-ups.
    var cards: [Card] {
        let ordered = players.filter { !$0.isParent } + players.filter(\.isParent)
        return ordered.map { Card(player: $0, isActive: $0.id == selectedPlayerID) }
    }

    /// The card that should receive focus when the screen appears.
    var initialFocusID: UUID? {
        selectedPlayerID.flatMap { id in cards.first { $0.id == id }?.id } ?? cards.first?.id
    }

    var subtitle: String {
        switch mode {
        case .startPlaying: return "Pick your player with the remote, then press select."
        case .switchPlayer: return "Pass the remote! Who's playing next?"
        }
    }
}
