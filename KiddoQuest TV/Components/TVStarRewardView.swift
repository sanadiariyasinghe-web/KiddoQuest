import SwiftUI

/// Filled / outlined stars out of a maximum, e.g. ★★★★☆ for 4 of 5.
/// Filled and empty stars differ in shape as well as colour.
struct TVStarRatingView: View {
    let rating: Int
    var maximum: Int = TVScoring.maxRating
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<max(0, maximum), id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < rating ? TVTheme.Palette.star : TVTheme.Palette.muted)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(min(rating, maximum)) of \(maximum) stars")
    }
}

/// A row of earned stars that pop in one by one, e.g. the session result.
/// Shows at most `maxVisible` icons, then a "×N" count for large totals.
struct TVStarRowView: View {
    let count: Int
    var slots: Int? = nil
    var maxVisible: Int = 10
    var size: CGFloat = 60
    /// Change to replay the pop-in animation.
    var animationTrigger: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = 0

    private var visibleCount: Int { min(count, maxVisible) }
    private var slotCount: Int { max(visibleCount, min(slots ?? visibleCount, maxVisible)) }

    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<slotCount, id: \.self) { index in
                let isOn = index < visibleCount && index < revealed
                Image(systemName: isOn ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(isOn ? TVTheme.Palette.star : TVTheme.Palette.muted)
                    .shadow(color: isOn ? TVTheme.Palette.star.opacity(0.7) : .clear, radius: 14)
                    .scaleEffect(isOn ? 1 : 0.8)
            }
            if count > maxVisible {
                Text("×\(count)")
                    .font(.system(size: size * 0.8, weight: .heavy, design: .rounded))
                    .foregroundStyle(TVTheme.Palette.star)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(count) \(count == 1 ? "star" : "stars")")
        .task(id: animationTrigger) {
            // Full replay on first appearance or when the trigger changes.
            await reveal(from: 0)
        }
        .onChange(of: count) { oldValue, newValue in
            // Only pop in the newly added stars.
            Task { await reveal(from: newValue > oldValue ? min(oldValue, maxVisible) : 0) }
        }
    }

    private func reveal(from start: Int) async {
        guard !reduceMotion else {
            revealed = visibleCount
            return
        }
        revealed = min(start, visibleCount)
        for index in revealed..<visibleCount {
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
            withAnimation(TVTheme.Motion.pop) { revealed = index + 1 }
        }
    }
}

/// Compact "⭐ 72" counter that bumps when the value changes.
struct TVStarCounterView: View {
    let count: Int
    var label: String? = nil
    var size: CGFloat = 40

    @State private var bump = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(TVTheme.Palette.star)
                .scaleEffect(bump ? 1.35 : 1)
            Text("\(count)")
                .contentTransition(.numericText(value: Double(count)))
            if let label {
                Text(label).opacity(0.8)
            }
        }
        .font(.system(size: size, weight: .heavy, design: .rounded))
        .foregroundStyle(TVTheme.Palette.textPrimary)
        .animation(TVTheme.Motion.pop, value: count)
        .onChange(of: count) { _, _ in
            withAnimation(TVTheme.Motion.pop) { bump = true }
            withAnimation(TVTheme.Motion.pop.delay(0.25)) { bump = false }
        }
        .accessibilityElement()
        .accessibilityLabel("\(count) \(label ?? "stars")")
    }
}
