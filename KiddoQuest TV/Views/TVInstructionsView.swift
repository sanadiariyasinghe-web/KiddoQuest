import SwiftUI

/// Shown before every TV game: a picture sentence (e.g. 🐰 → 👆 → 🥕) that
/// children who can't read yet can follow, short steps for grown-ups, and a
/// big Let's Play! button that already has focus.
struct TVInstructionsView: View {
    let instructions: TVGameInstructions
    let tint: Color
    let onStart: () -> Void

    @FocusState private var isPlayFocused: Bool
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 50) {
            TVJourneyTrail(current: .learn, tint: tint)

            Text(instructions.title)
                .font(TVTheme.Typography.hero)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("instructions.title")

            HStack(spacing: 60) {
                pictureStory
                TVMascotView(mood: .happy, message: "Watch, then play!", size: 200)
                    .frame(width: 360)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(instructions.steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 20) {
                        Text("\(index + 1)")
                            .font(TVTheme.Typography.headline)
                            .foregroundStyle(TVTheme.Palette.ink)
                            .frame(width: 64, height: 64)
                            .background(Circle().fill(tint))
                        Text(step)
                            .font(TVTheme.Typography.body)
                            .foregroundStyle(TVTheme.Palette.textSecondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            TVPrimaryButton(title: "Let's Play!", systemImage: "play.fill", tint: TVTheme.Palette.success, minWidth: 520) {
                onStart()
            }
            .focused($isPlayFocused)
            .accessibilityIdentifier("instructions.play")
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tvScreenBackground()
        .defaultFocus($isPlayFocused, true)
        .onAppear { hasAppeared = true }
    }

    /// Big pictures joined by arrows, appearing one after another.
    private var pictureStory: some View {
        HStack(spacing: 30) {
            ForEach(Array(instructions.pictureStory.enumerated()), id: \.offset) { index, picture in
                if index > 0 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(tint)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(Double(index) * 0.45), value: hasAppeared)
                }
                Text(picture.symbol)
                    .font(.system(size: 110, weight: .heavy, design: .rounded))
                    .foregroundStyle(TVTheme.Palette.textPrimary)
                    .colorMultiply(picture.isShadow ? .black : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(minWidth: 200, minHeight: 200)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner, style: .continuous).fill(TVTheme.Palette.card))
                    .scaleEffect(hasAppeared ? 1 : 0.4)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(TVTheme.Motion.pop.delay(0.15 + Double(index) * 0.45), value: hasAppeared)
            }
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner, style: .continuous).fill(tint.opacity(0.18)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(instructions.steps.joined(separator: " "))
        .accessibilityIdentifier("instructions.pictures")
    }
}
