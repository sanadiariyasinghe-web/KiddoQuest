import SwiftUI

// MARK: - ProgressStarBar Component
// Displays child-friendly stars (⭐) and completion progress.

struct ProgressStarBar: View {
    var stars: Int
    var maxStars: Int = 3
    var progressPercentage: Int? = nil
    var starSize: CGFloat = 20
    var showBackground: Bool = true
    
    var body: some View {
        HStack(spacing: 8) {
            // Star icons
            HStack(spacing: 4) {
                ForEach(0..<maxStars, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.system(size: starSize))
                        .foregroundStyle(index < stars ? Theme.ColorPalette.starGold : Theme.ColorPalette.secondaryText.opacity(0.35))
                        .scaleEffect(index < stars ? 1.05 : 0.95)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: stars)
                }
            }
            
            // Optional progress bar and text
            if let percentage = progressPercentage {
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.ColorPalette.cardBorder)
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.ColorPalette.numbersYellow, Theme.ColorPalette.successGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(percentage) / 100)), height: 10)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: percentage)
                        }
                    }
                    .frame(height: 10)
                    
                    Text("\(percentage)%")
                        .font(Theme.Typography.caption(size: 13))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                        .frame(minWidth: 36, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, showBackground ? 12 : 0)
        .padding(.vertical, showBackground ? 8 : 0)
        .background(showBackground ? Theme.ColorPalette.cardBackground : Color.clear)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stars) of \(maxStars) stars earned\(progressPercentage.map { ", \($0) percent complete" } ?? "")")
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressStarBar(stars: 2, maxStars: 3, progressPercentage: 66)
        ProgressStarBar(stars: 3, maxStars: 3, progressPercentage: 100)
    }
    .padding()
}
