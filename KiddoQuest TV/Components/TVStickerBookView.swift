import SwiftUI

/// One page of the player's sticker book: collected stickers, and "?" for ones still to find.
struct TVStickerBookView: View {
    let collected: [String]

    private var collectedSet: Set<String> { Set(collected) }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MY STICKER BOOK · \(collectedSet.count) of \(TVStickerRules.allStickers.count)")
                .font(TVTheme.Typography.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(150), spacing: 24), count: 8), spacing: 24) {
                ForEach(TVStickerRules.allStickers, id: \.self) { sticker in
                    let isCollected = collectedSet.contains(sticker)
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(isCollected ? TVTheme.Palette.numbersYellow.opacity(0.25) : TVTheme.Palette.subtle)
                        if isCollected {
                            Text(sticker).font(.system(size: 80))
                        } else {
                            Text("?")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundStyle(TVTheme.Palette.muted)
                        }
                    }
                    .frame(width: 150, height: 150)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sticker book: \(collectedSet.count) of \(TVStickerRules.allStickers.count) stickers collected")
        .accessibilityIdentifier("rewards.stickerBook")
    }
}

/// A happy dance for Buddy on the Results screen. More stars, bigger dance.
/// Stays still when ambient motion is off (Calm Mode, Reduce Motion or UI tests).
struct TVDanceModifier: ViewModifier {
    let stars: Int

    @Environment(\.tvAmbientMotionEnabled) private var isMotionEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDancing = false

    private var isBigDance: Bool { stars >= TVScoring.maxSessionStars }

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isDancing ? (isBigDance ? 10 : 5) : (isBigDance ? -10 : -5)))
            .offset(y: isDancing ? (isBigDance ? -30 : -12) : 0)
            .animation(
                isDancing ? .easeInOut(duration: isBigDance ? 0.35 : 0.5).repeatForever(autoreverses: true) : nil,
                value: isDancing
            )
            .onAppear {
                isDancing = isMotionEnabled && !reduceMotion
            }
    }
}

extension View {
    func tvDance(stars: Int) -> some View {
        modifier(TVDanceModifier(stars: stars))
    }
}
