import SwiftUI

/// Covers the app when today's play-time limit is reached: calm and friendly
/// for the child, with a remote-friendly maths question for grown-ups.
struct TVBreakTimeView: View {
    let onParentUnlock: () -> Void

    private enum Focus: Hashable {
        case grownUps
        case answer(Int)
    }

    @FocusState private var focus: Focus?
    @State private var isShowingGate = false
    @State private var question = TVParentQuestion.random()
    @State private var showTryAgain = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.20, blue: 0.42), Color(red: 0.08, green: 0.10, blue: 0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isShowingGate {
                parentGate
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                restingContent
                    .transition(.opacity)
            }
        }
        .animation(TVTheme.Motion.gentle, value: isShowingGate)
        .defaultFocus($focus, .grownUps)
        .onExitCommand {
            // Back closes the grown-ups question but never leaves the break screen.
            if isShowingGate {
                isShowingGate = false
                focus = .grownUps
            }
        }
        .accessibilityIdentifier("breakTime.screen")
    }

    private var restingContent: some View {
        VStack(spacing: 40) {
            Text("🌙")
                .font(.system(size: 120))
                .accessibilityHidden(true)
            TVMascotView(mood: .happy, message: "Buddy is resting. Let's play again later!", size: 240)
            Text("Time for a break! 🌙")
                .font(TVTheme.Typography.hero)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Button {
                question = .random()
                showTryAgain = false
                isShowingGate = true
                focus = .answer(question.choices.first ?? 0)
            } label: {
                Label("Grown-ups", systemImage: "lock.fill")
                    .font(TVTheme.Typography.body)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
            }
            .tvCardButtonStyle(tint: TVTheme.Palette.lettersBlue, cornerRadius: 40, focusScale: 1.06)
            .focused($focus, equals: .grownUps)
            .accessibilityIdentifier("breakTime.grownUps")
        }
    }

    private var parentGate: some View {
        VStack(spacing: 40) {
            Text("Grown-Ups Only")
                .font(TVTheme.Typography.title)
                .foregroundStyle(.white)
            Text("What is \(question.left) + \(question.right)?")
                .font(TVTheme.Typography.screenTitle)
                .foregroundStyle(.white)
                .accessibilityIdentifier("breakTime.question")
            HStack(spacing: 40) {
                ForEach(question.choices, id: \.self) { choice in
                    Button {
                        answer(choice)
                    } label: {
                        Text("\(choice)")
                            .font(TVTheme.Typography.answer)
                            .frame(width: 220, height: 160)
                    }
                    .tvCardButtonStyle(tint: TVTheme.Palette.shapesPurple, cornerRadius: 36, focusScale: 1.1)
                    .focused($focus, equals: .answer(choice))
                    .accessibilityIdentifier("breakTime.answer.\(choice)")
                }
            }
            .focusSection()
            if showTryAgain {
                Text("Please try again.")
                    .font(TVTheme.Typography.body)
                    .foregroundStyle(TVTheme.Palette.gentle)
            }
        }
    }

    private func answer(_ choice: Int) {
        if choice == question.answer {
            onParentUnlock()
        } else {
            // A new sum each time so children can't guess their way in.
            question = .random()
            showTryAgain = true
            focus = .answer(question.choices.first ?? 0)
        }
    }
}

/// A small addition question with three answers, easy for a grown-up with a remote.
nonisolated struct TVParentQuestion: Hashable {
    let left: Int
    let right: Int
    let choices: [Int]

    var answer: Int { left + right }

    static func random() -> TVParentQuestion {
        let left = Int.random(in: 4...9)
        let right = Int.random(in: 3...9)
        let answer = left + right
        let wrong = [answer - 2, answer + 1, answer + 3, answer - 1].shuffled().prefix(2)
        return TVParentQuestion(left: left, right: right, choices: ([answer] + wrong).shuffled())
    }
}
