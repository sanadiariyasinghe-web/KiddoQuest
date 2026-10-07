import Foundation

/// `kiddoquesttv://` links used by the Top Shelf, e.g.
/// `kiddoquesttv://game/feedAnimals/animals`, `kiddoquesttv://category/numbers`, `kiddoquesttv://family`.
nonisolated enum TVDeepLink {
    static let scheme = "kiddoquesttv"

    /// The navigation path a link opens, or nil if the link is not understood.
    /// Without a chosen player, games go through player selection first.
    static func path(for url: URL, hasPlayer: Bool) -> [TVRoute]? {
        guard url.scheme == scheme, let host = url.host() else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }

        let destination: [TVRoute]
        switch host {
        case "game":
            guard parts.count == 2,
                  let kind = TVGameKind(rawValue: parts[0]),
                  let category = TVCategory(rawValue: parts[1]) else { return nil }
            destination = [.world, .category(category), .game(kind, category)]
        case "category":
            guard let first = parts.first, let category = TVCategory(rawValue: first) else { return nil }
            destination = [.world, .category(category)]
        case "family":
            destination = [.familyChallenge]
        default:
            return nil
        }
        return hasPlayer ? destination : [.playerSelection(.startPlaying)]
    }

    static func url(game kind: TVGameKind, category: TVCategory) -> URL? {
        URL(string: "\(scheme)://game/\(kind.rawValue)/\(category.rawValue)")
    }
}
