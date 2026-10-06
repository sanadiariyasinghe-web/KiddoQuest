import SwiftUI

// MARK: - Break Time View
// Shown over the whole app when today's play time limit is reached.
// Calm and friendly for the child; a grown-up can unlock with the parent gate.

struct BreakTimeView: View {
    let onParentUnlock: () -> Void
    
    @State private var isShowingParentGate = false
    @State private var isOwlResting = false
    @CalmModeEnabled private var isCalm
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.20, blue: 0.42), Color(red: 0.08, green: 0.10, blue: 0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isShowingParentGate {
                VStack(spacing: Theme.Spacing.medium) {
                    ParentGateView(title: "Grown-Ups Only", buttonTitle: "Unlock Play") {
                        onParentUnlock()
                    }
                    Button("Back") {
                        withAnimation(.spring()) { isShowingParentGate = false }
                    }
                    .font(Theme.Typography.headline(size: 18))
                    .foregroundStyle(.white)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                restingContent
                    .transition(.opacity)
            }
        }
        .accessibilityIdentifier("breakTime.screen")
    }
    
    private var restingContent: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer()
            
            Text("🌙")
                .font(.system(size: 64))
                .accessibilityHidden(true)
            
            ZStack {
                Circle()
                    .fill(Theme.ColorPalette.numbersYellow.opacity(0.25))
                    .frame(width: 150, height: 150)
                Text("🦉")
                    .font(.system(size: 90))
                    .rotationEffect(.degrees(isOwlResting ? -6 : 6))
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isOwlResting)
                Text("💤")
                    .font(.system(size: 32))
                    .offset(x: 62, y: -58)
                    .opacity(isOwlResting ? 1 : 0.3)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isOwlResting)
            }
            .accessibilityHidden(true)
            
            VStack(spacing: 10) {
                Text("Time for a break! 🌙")
                    .font(Theme.Typography.title(size: 32))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Buddy is resting. Let's play again later!")
                    .font(Theme.Typography.headline(size: 20))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.large)
            
            Spacer()
            
            Button {
                withAnimation(.spring()) { isShowingParentGate = true }
            } label: {
                Label("Grown-ups", systemImage: "lock.fill")
                    .font(Theme.Typography.headline(size: 16))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier("breakTime.grownUps")
            .padding(.bottom, Theme.Spacing.xlarge)
        }
        .onAppear { isOwlResting = !isCalm }
    }
}

#Preview {
    BreakTimeView { }
}
