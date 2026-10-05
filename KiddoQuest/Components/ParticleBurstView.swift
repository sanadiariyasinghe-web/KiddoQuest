import SwiftUI

// MARK: - Native SwiftUI Particle Burst / Confetti Effect
// Pure SwiftUI particle celebration effect without any third-party libraries.

struct ParticleBurstView: View {
    @Binding var isEmitting: Bool
    var particleCount: Int = 24
    
    @State private var particles: [ParticleItem] = []
    
    struct ParticleItem: Identifiable {
        let id = UUID()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var scale: CGFloat = 1.0
        var opacity: Double = 1.0
        var rotation: Double = 0
        var color: Color
        var shapeType: Int // 0: circle, 1: star, 2: rounded rectangle
        var targetX: CGFloat
        var targetY: CGFloat
    }
    
    private let colors: [Color] = [
        Theme.ColorPalette.starGold,
        Theme.ColorPalette.lettersBlue,
        Theme.ColorPalette.animalsGreen,
        Theme.ColorPalette.shapesPurple,
        Theme.ColorPalette.numbersYellow,
        Color.pink
    ]
    
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                particleShape(for: p)
                    .foregroundStyle(p.color)
                    .scaleEffect(p.scale)
                    .rotationEffect(.degrees(p.rotation))
                    .opacity(p.opacity)
                    .offset(x: p.x, y: p.y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isEmitting) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
    }
    
    @ViewBuilder
    private func particleShape(for item: ParticleItem) -> some View {
        switch item.shapeType {
        case 0:
            Circle()
                .frame(width: 12, height: 12)
        case 1:
            Image(systemName: "star.fill")
                .font(.system(size: 14))
        default:
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 14, height: 8)
        }
    }
    
    private func triggerBurst() {
        var newParticles: [ParticleItem] = []
        for _ in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...160)
            let targetX = cos(angle) * distance
            let targetY = sin(angle) * distance
            
            newParticles.append(
                ParticleItem(
                    color: colors.randomElement() ?? .yellow,
                    shapeType: Int.random(in: 0...2),
                    targetX: targetX,
                    targetY: targetY
                )
            )
        }
        self.particles = newParticles
        
        // Animate particles bursting outwards and fading
        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                particles[i].x = particles[i].targetX
                particles[i].y = particles[i].targetY
                particles[i].rotation = Double.random(in: 90...360)
                particles[i].scale = CGFloat.random(in: 0.6...1.3)
            }
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
            for i in particles.indices {
                particles[i].opacity = 0
            }
        }
        
        // Reset emission state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll()
            isEmitting = false
        }
    }
}
