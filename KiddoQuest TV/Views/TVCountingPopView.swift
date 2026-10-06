import SwiftUI

/// Counting Pop TV — count the big objects, then move focus to the right
/// number with the Siri Remote and press select.
struct TVCountingPopView: View {
    let player: TVPlayer?
    let onFinish: (TVSessionResult) -> Void

    @State private var model: TVCountingPopViewModel
    @Environment(TVSoundService.self) private var sound
    @Environment(TVRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Focus value includes the round so a new round is always a real focus
    /// change, even when the same number appears again (e.g. "4" twice in a row).
    private struct AnswerFocus: Hashable {
        let round: Int
        let value: Int
    }

    @FocusState private var focusedAnswer: AnswerFocus?
    @State private var shakeCounts: [Int: Int] = [:]
    @State private var celebrationTrigger = 0
    @State private var objectsVisible = false

    init(category: TVCategory, player: TVPlayer?, onFinish: @escaping (TVSessionResult) -> Void) {
        self.player = player
        self.onFinish = onFinish
        _model = State(initialValue: TVCountingPopViewModel(category: category))
    }

    var body: some View {
        if let round = model.currentRound {
            gameBody(round)
        } else {
            TVEmptyStateView(title: "No apples today!", message: "There are no counting rounds right now.") {
                router.pop()
            }
        }
    }

    private func gameBody(_ round: TVCountingRound) -> some View {
        VStack(spacing: 36) {
            TVGameHeader(
                title: "Counting Pop TV",
                roundLabel: model.roundLabel,
                points: model.tracker.points,
                starsThisGame: model.tracker.correctAnswers,
                player: player
            )
            TVProgressBar(value: model.progress, tint: TVTheme.Palette.numbersYellow, height: 16)

            HStack(alignment: .center, spacing: 60) {
                VStack(spacing: 30) {
                    Text(round.question)
                        .font(TVTheme.Typography.screenTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("countingPop.question")
                    objectGrid(round)
                }
                .frame(maxWidth: .infinity)

                TVMascotView(mood: model.mascotMood, message: model.feedbackMessage ?? "Count with me!", size: 230)
                    .frame(width: 380)
            }
            .frame(maxHeight: .infinity)

            ZStack {
                answerRow(round)
                TVSparkleBurst(trigger: celebrationTrigger, distance: 320)
            }

            feedbackArea
        }
        .padding(.horizontal, TVTheme.Metrics.screenPadding)
        .padding(.vertical, 40)
        .tvScreenBackground()
        .defaultFocus($focusedAnswer, round.options.first.map { AnswerFocus(round: model.roundIndex, value: $0) })
        .tvHintActivity(model.tracker.correctAnswers + model.tracker.mistakes)
        .onAppear(perform: revealObjects)
        .onChange(of: model.roundIndex) { _, _ in
            shakeCounts = [:]
            revealObjects()
            focusedAnswer = model.currentRound?.options.first.map { AnswerFocus(round: model.roundIndex, value: $0) }
        }
        .task(id: celebrationTrigger) {
            // Let the celebration play, then move on. Tied to the view's
            // lifetime, so leaving with the Back button cancels it safely.
            guard celebrationTrigger > 0 else { return }
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            advance()
        }
    }

    // MARK: - Pieces

    private func objectGrid(_ round: TVCountingRound) -> some View {
        let columns = Array(repeating: GridItem(.fixed(150), spacing: 24), count: min(5, max(1, round.count)))
        return LazyVGrid(columns: columns, spacing: 24) {
            ForEach(0..<round.count, id: \.self) { index in
                Text(round.emoji)
                    .font(TVTheme.Typography.gameObject)
                    .scaleEffect(objectsVisible ? (model.isShowingSuccess ? 1.15 : 1) : 0.2)
                    .opacity(objectsVisible ? 1 : 0)
                    .rotationEffect(.degrees(model.isShowingSuccess ? (index.isMultiple(of: 2) ? -8 : 8) : 0))
                    .animation(
                        reduceMotion ? nil : TVTheme.Motion.pop.delay(Double(index) * 0.06),
                        value: objectsVisible
                    )
                    .animation(reduceMotion ? nil : TVTheme.Motion.pop.delay(Double(index) * 0.04), value: model.isShowingSuccess)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(round.count) \(round.objectName)")
        .accessibilityIdentifier("countingPop.objects")
    }

    private func answerRow(_ round: TVCountingRound) -> some View {
        HStack(spacing: 50) {
            ForEach(round.options.map { AnswerFocus(round: model.roundIndex, value: $0) }, id: \.self) { answer in
                let option = answer.value
                Button {
                    choose(option)
                } label: {
                    Text("\(option)")
                        .font(TVTheme.Typography.answer)
                        .frame(width: 230, height: 170)
                        .overlay(alignment: .topTrailing) {
                            if model.isShowingSuccess && round.isCorrect(option) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(TVTheme.Palette.success)
                                    .padding(12)
                                    .transition(.scale)
                            }
                        }
                }
                .tvCardButtonStyle(
                    tint: model.isShowingSuccess && round.isCorrect(option) ? TVTheme.Palette.success : TVTheme.Palette.numbersYellow,
                    cornerRadius: 36,
                    focusScale: 1.12
                )
                .opacity(model.triedOptions.contains(option) ? 0.6 : 1)
                .modifier(TVShakeEffect(animatableData: CGFloat(shakeCounts[option, default: 0])))
                .focused($focusedAnswer, equals: answer)
                .accessibilityLabel("\(option)")
                .accessibilityHint("Answer \(option) \(round.objectName)")
                .accessibilityIdentifier("countingPop.option.\(option)")
                .tvHintTarget(!model.isShowingSuccess && round.isCorrect(option))
            }
        }
        .focusSection()
    }

    private var feedbackArea: some View {
        ZStack {
            if let message = model.feedbackMessage {
                TVFeedbackBanner(message: message, style: model.isShowingSuccess ? .success : .gentle)
                    .id(message + "\(model.tracker.mistakes)")
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Text("Swipe to pick a number, then press to answer")
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }
        }
        .frame(height: 100)
        .animation(TVTheme.Motion.pop, value: model.feedbackMessage)
    }

    // MARK: - Actions

    private func revealObjects() {
        objectsVisible = false
        Task {
            try? await Task.sleep(for: .milliseconds(60))
            objectsVisible = true
        }
    }

    private func choose(_ option: Int) {
        switch model.select(option) {
        case .correct:
            sound.play(.correct)
            // Fires the sparkle burst and the delayed advance task below.
            celebrationTrigger += 1
        case .incorrect:
            sound.play(.incorrect)
            withAnimation(.easeInOut(duration: 0.45)) {
                shakeCounts[option, default: 0] += 1
            }
        case .ignored:
            break
        }
    }

    private func advance() {
        model.advance()
        if model.isFinished {
            onFinish(model.makeResult())
        }
    }
}
