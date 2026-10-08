import SwiftUI

// MARK: - Break Time View
// Shown over the whole app when today's play time limit is reached.
// Calm and friendly for the child; a grown-up can unlock with the parent gate.

struct BreakTimeView: View, CompactAdaptable {
    let onParentUnlock: () -> Void
    
    @State private var isShowingParentGate = false
    @State private var isOwlResting = false
    @CalmModeEnabled private var isCalm
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false
    
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
                .padding(.vertical, Theme.Spacing.medium)
                .scrollsWhenNeeded()
                .transition(.scale.combined(with: .opacity))
            } else {
                // Fits as designed, or smaller / scrollable on short screens (iPhone landscape)
                FitsOrScrolls {
                    CompactLayoutReader { compact($0).restingContent }
                }
                .transition(.opacity)
            }
        }
        .accessibilityIdentifier("breakTime.screen")
    }
    
    private var restingContent: some View {
        VStack(spacing: isCompact ? Theme.Spacing.medium : Theme.Spacing.large) {
            Spacer(minLength: 0)
            
            Text("🌙")
                .font(.system(size: AdaptiveMetric.size(64, compact: isCompact)))
                .accessibilityHidden(true)
            
            ZStack {
                Circle()
                    .fill(Theme.ColorPalette.numbersYellow.opacity(0.25))
                    .frame(width: AdaptiveMetric.size(150, compact: isCompact), height: AdaptiveMetric.size(150, compact: isCompact))
                Text("🦉")
                    .font(.system(size: AdaptiveMetric.size(90, compact: isCompact)))
                    .rotationEffect(.degrees(isOwlResting ? -6 : 6))
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isOwlResting)
                Text("💤")
                    .font(.system(size: 32))
                    .offset(x: AdaptiveMetric.size(62, compact: isCompact), y: AdaptiveMetric.size(-58, compact: isCompact))
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
            
            Spacer(minLength: 0)
            
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
            .padding(.bottom, isCompact ? Theme.Spacing.medium : Theme.Spacing.xlarge)
        }
        .padding(.top, isCompact ? Theme.Spacing.medium : 0)
        .onAppear { isOwlResting = !isCalm }
    }
}

#Preview {
    BreakTimeView { }
}
