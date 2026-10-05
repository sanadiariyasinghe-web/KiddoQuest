import Foundation

// MARK: - Sticker
struct Sticker: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let emoji: String
    let gameTitle: String
    let earnedDate: Date
}

// MARK: - Sticker Book
// Every finished game gives the child a sticker for their sticker book (shown on the Rewards screen).
// New stickers are chosen from ones the child doesn't have yet, so the book keeps filling up.
// The collection is saved in UserDefaults as JSON.

@Observable
final class StickerBook {
    static let shared = StickerBook()
    
    /// All stickers that can be collected (one page of the book).
    static let allStickers = [
        "🦁", "🐼", "🦄", "🌈", "⭐", "🐬", "🦋", "🍓",
        "🚀", "🌻", "🐢", "🎈", "🐙", "🍦", "🦖", "🐝"
    ]
    
    private static let storageKey = "sticker_book"
    
    private(set) var stickers: [Sticker] = []
    
    @ObservationIgnored private let defaults: UserDefaults
    
    var collectedEmojis: Set<String> { Set(stickers.map(\.emoji)) }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([Sticker].self, from: data) {
            stickers = saved
        }
    }
    
    /// Picks a sticker the child doesn't have yet (or any sticker once the book is full).
    static func nextStickerEmoji(collected: Set<String>, pool: [String] = allStickers) -> String {
        let missing = pool.filter { !collected.contains($0) }
        return (missing.isEmpty ? pool : missing).randomElement() ?? "⭐"
    }
    
    /// Adds a new sticker for a finished game and returns it.
    @discardableResult
    func awardSticker(for gameTitle: String, on date: Date = Date()) -> Sticker {
        let sticker = Sticker(
            emoji: Self.nextStickerEmoji(collected: collectedEmojis),
            gameTitle: gameTitle,
            earnedDate: date
        )
        stickers.append(sticker)
        save()
        return sticker
    }
    
    func reset() {
        stickers = []
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(stickers) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
