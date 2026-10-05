import SwiftUI

// MARK: - Celebrating Owl
// Buddy the owl dances on the results screen. More stars = a bigger dance.

struct CelebratingOwlView: View {
    let stars: Int
    
    @State private var isDancing = false
    
    private var isBigCelebration: Bool { stars >= 3 }
    private var jumpHeight: CGFloat { isBigCelebration ? -22 : -10 }
    private var swayAngle: Double { isBigCelebration ? 14 : 7 }
    private var beat: Double { isBigCelebration ? 0.35 : 0.5 }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.ColorPalette.numbersYellow.opacity(0.25))
                .frame(width: 110, height: 110)
                .scaleEffect(isBigCelebration && isDancing ? 1.08 : 1.0)
            
            Text("🦉")
                .font(.system(size: 66))
                .rotationEffect(.degrees(isDancing ? swayAngle : -swayAngle))
                .offset(y: isDancing ? jumpHeight : 0)
            
            if isBigCelebration {
                // Extra sparkles for a 3-star round
                Text("✨")
                    .font(.system(size: 28))
                    .offset(x: -54, y: isDancing ? -44 : -30)
                Text("🎉")
                    .font(.system(size: 28))
                    .offset(x: 54, y: isDancing ? -40 : -28)
            }
        }
        .frame(height: 130)
        .animation(.easeInOut(duration: beat).repeatForever(autoreverses: true), value: isDancing)
        .onAppear { isDancing = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isBigCelebration ? "Buddy the owl is doing a big happy dance" : "Buddy the owl is dancing")
    }
}

#Preview {
    HStack(spacing: 40) {
        CelebratingOwlView(stars: 2)
        CelebratingOwlView(stars: 3)
    }
}
