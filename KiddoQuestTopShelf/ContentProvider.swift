//
//  ContentProvider.swift
//  KiddoQuestTopShelf
//
//  The Apple TV Top Shelf for KiddoQuest: big picture shortcuts that open a
//  game straight away (via kiddoquesttv:// links handled by the app).
//

import TVServices
import UIKit

class ContentProvider: TVTopShelfContentProvider {

    /// One Top Shelf shortcut. Kept in sync with `TVGameKind` / `TVCategory` raw values in the app.
    private struct Shortcut {
        let title: String
        let emoji: String
        let kind: String
        let category: String
        let color: UIColor
    }

    private let sections: [(title: String, shortcuts: [Shortcut])] = [
        ("Play & Learn", [
            Shortcut(title: "Counting Pop", emoji: "🎈", kind: "countingPop", category: "numbers", color: .systemYellow),
            Shortcut(title: "Letter Match", emoji: "🔤", kind: "dragToMatch", category: "letters", color: .systemBlue),
            Shortcut(title: "Shape Sort", emoji: "🔷", kind: "shapeSort", category: "shapes", color: .systemPurple),
            Shortcut(title: "Feed the Animals", emoji: "🥕", kind: "feedAnimals", category: "animals", color: .systemGreen),
            Shortcut(title: "Animal Shadows", emoji: "🦒", kind: "animalShadows", category: "animals", color: .systemTeal),
            Shortcut(title: "Colour It In", emoji: "🎨", kind: "tapToReveal", category: "shapes", color: .systemPink)
        ])
    ]

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        let collections = sections.map { section in
            let items = section.shortcuts.compactMap(makeItem)
            let collection = TVTopShelfItemCollection(items: items)
            collection.title = section.title
            return collection
        }
        return TVTopShelfSectionedContent(sections: collections)
    }

    private func makeItem(_ shortcut: Shortcut) -> TVTopShelfSectionedItem? {
        guard let url = URL(string: "kiddoquesttv://game/\(shortcut.kind)/\(shortcut.category)") else { return nil }
        let item = TVTopShelfSectionedItem(identifier: shortcut.kind + "." + shortcut.category)
        item.title = shortcut.title
        item.imageShape = .square
        item.displayAction = TVTopShelfAction(url: url)
        item.playAction = TVTopShelfAction(url: url)
        if let imageURL = artwork(for: shortcut) {
            item.setImageURL(imageURL, for: [.screenScale1x, .screenScale2x])
        }
        return item
    }

    /// Draws a bright tile with the game's emoji and caches it as a PNG file.
    private func artwork(for shortcut: Shortcut) -> URL? {
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = folder.appendingPathComponent("topshelf-\(shortcut.kind)-\(shortcut.category).png")
        if FileManager.default.fileExists(atPath: fileURL.path) { return fileURL }

        let size = CGSize(width: 400, height: 400)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            shortcut.color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 60).fill()
            let text = shortcut.emoji as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 220)]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2),
                withAttributes: attributes
            )
        }
        guard let data = image.pngData(), (try? data.write(to: fileURL)) != nil else { return nil }
        return fileURL
    }
}
