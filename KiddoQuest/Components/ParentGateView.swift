import SwiftUI

// MARK: - Parent Gate
// A simple grown-ups-only check (a small sum) used before Parent Settings
// and to unlock the app after the daily break screen.

struct ParentGateView: View {
    var title: String = "Grown-Ups Only"
    var buttonTitle: String = "Unlock Settings"
    let onUnlock: () -> Void
    
    @State private var answer: String = ""
    @State private var showError: Bool = false
    // A fresh sum each time keeps children from memorising the answer
    @State private var firstNumber = Int.random(in: 3...9)
    @State private var secondNumber = Int.random(in: 2...9)
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.ColorPalette.shapesPurple.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.ColorPalette.shapesPurple)
            }
            
            VStack(spacing: 8) {
                Text(LocalizedStringKey(title))
                    .font(Theme.Typography.title(size: 24))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                
                Text("Please solve this math question to continue:")
                    .font(Theme.Typography.body(size: 16))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(firstNumber) + \(secondNumber) = ?")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ColorPalette.shapesPurple)
                .padding(.vertical, 8)
            
            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(width: 140, height: 50)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showError ? Theme.ColorPalette.softRedWarning : Theme.ColorPalette.cardBorder, lineWidth: 2)
                )
                .accessibilityIdentifier("parentGate.answer")
            
            if showError {
                Text("Please try again.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.ColorPalette.softRedWarning)
            }
            
            Button {
                checkAnswer()
            } label: {
                Text(buttonTitle)
                    .font(Theme.Typography.headline(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Theme.ColorPalette.shapesPurple)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityIdentifier("parentGate.unlock")
        }
        .padding(24)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        .padding(.horizontal, Theme.Spacing.large)
    }
    
    private func checkAnswer() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == firstNumber + secondNumber {
            showError = false
            onUnlock()
        } else {
            withAnimation(.default) {
                showError = true
            }
            answer = ""
            firstNumber = Int.random(in: 3...9)
            secondNumber = Int.random(in: 2...9)
        }
    }
}

#Preview {
    ZStack {
        Theme.ColorPalette.mainBackground.ignoresSafeArea()
        ParentGateView { }
    }
}
