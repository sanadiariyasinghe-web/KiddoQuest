import SwiftUI

/// Large focusable learning-world card: icon, name, progress and stars.
struct TVCategoryCard: View {
    let category: TVCategory
    let percent: Int
    let rating: Int
    let action: () -> Void

    var body: some View {
        TVFocusCard(tint: category.color, action: action) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.25))
                        .frame(width: 150, height: 150)
                    Text(category.emoji)
                        .font(.system(size: 84))
                }
                .accessibilityHidden(true)

                Text(category.title.uppercased())
                    .font(TVTheme.Typography.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(spacing: 10) {
                    TVProgressBar(value: Double(percent) / 100, tint: category.color, height: 18)
                    Text("\(percent)% COMPLETE")
                        .font(TVTheme.Typography.caption)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                }

                TVStarRatingView(rating: rating, size: 30)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 36)
            .frame(width: 370, height: 440)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.title). \(percent) percent complete. \(rating) of 5 stars.")
        .accessibilityHint("Opens the \(category.title) world")
        .accessibilityIdentifier("category.\(category.rawValue)")
    }
}
