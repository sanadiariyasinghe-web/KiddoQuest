import SwiftUI

/// Simplified, focus-based TV prototypes of the remaining Part A games:
/// Drag-to-Match, Tap-to-Reveal, Animal Match and Shape Sort.
///
/// Mobile drag gestures don't suit a Siri Remote, so each prototype turns
/// the interaction into "move focus to the target, then press select".
struct TVOtherGamePrototypeView: View {
    let game: TVGame
    let player: TVPlayer?
    let onFinish: (TVSessionResult) -> Void

    @State private var model: TVPrototypeGameViewModel
    @Environment(TVSoundService.self) private var sound
    @Environment(TVRouter.self) private var router

    /// Round-qualified focus so repeated options (e.g. the same four colours)
    /// still receive focus when a new round starts.
    private struct OptionFocus: Hashable {
        let round: Int
        let optionID: String
    }

    @FocusState private var focusedOption: OptionFocus?
    @State private var shakeCounts: [String: Int] = [:]
    @State private var celebrationTrigger = 0

    init(game: TVGame, category: TVCategory, player: TVPlayer?, onFinish: @escaping (TVSessionResult) -> Void) {
        self.game = game
        self.player = player
        self.onFinish = onFinish
        _model = State(initialValue: TVPrototypeGameViewModel(kind: game.kind, category: category))
    }

    var body: some View {
        if let round = model.currentRound {
            gameBody(round)
        } else {
            TVEmptyStateView(title: "Coming soon!", message: "This prototype has no rounds for this world yet.") {
                router.pop()
            }
        }
    }

    private func gameBody(_ round: TVChoiceRound) -> some View {
        VStack(spacing: 30) {
            TVGameHeader(
                title: game.title,
                roundLabel: model.roundLabel,
                points: model.tracker.points,
                starsThisGame: model.tracker.correctAnswers,
                player: player,
                isPrototype: true
            )

            Text(round.prompt)
                .font(TVTheme.Typography.screenTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("prototype.prompt")

            HStack(spacing: 60) {
                ZStack {
                    TVPrototypeSubjectView(subject: round.subject, isSolved: model.isShowingSuccess)
                    TVSparkleBurst(trigger: celebrationTrigger, distance: 300)
                }
                .frame(maxWidth: .infinity)

                TVMascotView(mood: model.mascotMood, message: model.feedbackMessage ?? "You can do it!", size: 190)
                    .frame(width: 360)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 44) {
                ForEach(round.options, id: \.id) { option in
                    let isWinner = model.isShowingSuccess && round.isCorrect(option.id)
                    let focusValue = OptionFocus(round: model.roundIndex, optionID: option.id)
                    Button {
                        choose(option)
                    } label: {
                        TVPrototypeOptionView(option: option, isWinner: isWinner)
                            .frame(width: optionSize.width, height: optionSize.height)
                    }
                    .tvCardButtonStyle(
                        tint: isWinner ? TVTheme.Palette.success : game.primaryCategory.color,
                        cornerRadius: 36,
                        focusScale: 1.1
                    )
                    .modifier(TVShakeEffect(animatableData: CGFloat(shakeCounts[option.id, default: 0])))
                    .focused($focusedOption, equals: focusValue)
                    .accessibilityLabel(option.label)
                    .accessibilityIdentifier("prototype.option.\(option.id)")
                }
            }
            .focusSection()

            footer
        }
        .padding(.horizontal, TVTheme.Metrics.screenPadding)
        .padding(.vertical, 36)
        .tvScreenBackground()
        .defaultFocus($focusedOption, round.options.first.map { OptionFocus(round: model.roundIndex, optionID: $0.id) })
        .onChange(of: model.roundIndex) { _, _ in
            shakeCounts = [:]
            focusedOption = model.currentRound?.options.first.map { OptionFocus(round: model.roundIndex, optionID: $0.id) }
        }
        .task(id: celebrationTrigger) {
            guard celebrationTrigger > 0 else { return }
            try? await Task.sleep(for: .seconds(1.7))
            guard !Task.isCancelled else { return }
            model.advance()
            if model.isFinished {
                onFinish(model.makeResult())
            }
        }
    }

    private var optionSize: CGSize {
        game.kind == .tapToReveal ? CGSize(width: 280, height: 190) : CGSize(width: 300, height: 220)
    }

    private var footer: some View {
        ZStack {
            if let message = model.feedbackMessage {
                TVFeedbackBanner(message: message, style: model.isShowingSuccess ? .success : .gentle)
                    .id(message + "\(model.tracker.mistakes)")
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Label(
                    "Prototype: a focus-based TV version of \(game.title) from KiddoQuest iOS",
                    systemImage: "info.circle"
                )
                .font(TVTheme.Typography.caption)
                .foregroundStyle(TVTheme.Palette.textSecondary)
            }
        }
        .frame(height: 100)
        .animation(TVTheme.Motion.pop, value: model.feedbackMessage)
    }

    private func choose(_ option: TVChoiceOption) {
        switch model.select(optionID: option.id) {
        case .correct:
            sound.play(.correct)
            celebrationTrigger += 1
        case .incorrect:
            sound.play(.incorrect)
            withAnimation(.easeInOut(duration: 0.45)) {
                shakeCounts[option.id, default: 0] += 1
            }
        case .ignored:
            break
        }
    }
}

// MARK: - Subject artwork

/// The picture the player is answering about, with a "solved" animation
/// specific to each prototype (snap, colour reveal, join, or drop-in).
struct TVPrototypeSubjectView: View {
    let subject: TVRoundSubject
    let isSolved: Bool

    var body: some View {
        content
            .animation(TVTheme.Motion.pop, value: isSolved)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityIdentifier("prototype.subject")
    }

    @ViewBuilder
    private var content: some View {
        switch subject {
        case .group(let emoji, let count):
            // Drag-to-Match numbers: the group "snaps" onto its number.
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ForEach(0..<count, id: \.self) { _ in
                        Text(emoji).font(.system(size: 110))
                    }
                }
                .padding(36)
                .background(RoundedRectangle(cornerRadius: 40, style: .continuous).fill(TVTheme.Palette.card))
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .strokeBorder(isSolved ? TVTheme.Palette.success : TVTheme.Palette.muted, style: StrokeStyle(lineWidth: 6, dash: isSolved ? [] : [18, 12]))
                )
                .overlay(alignment: .topTrailing) {
                    if isSolved {
                        snapBadge(text: "\(count)")
                    }
                }
                .scaleEffect(isSolved ? 1.05 : 1)
            }

        case .letter(let letter):
            // Drag-to-Match letters: the little letter snaps beside the big one.
            HStack(spacing: 10) {
                Text(letter)
                if isSolved {
                    Text(letter.lowercased())
                        .foregroundStyle(TVTheme.Palette.success)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .font(.system(size: 240, weight: .heavy, design: .rounded))
            .padding(.horizontal, 60)
            .background(RoundedRectangle(cornerRadius: 40, style: .continuous).fill(TVTheme.Palette.card))

        case .colorReveal(let symbol, _, let answer):
            // Tap-to-Reveal: the outline fills with colour once solved.
            Image(systemName: isSolved ? "\(symbol).fill" : symbol)
                .font(.system(size: 280, weight: .regular))
                .foregroundStyle(isSolved ? answer.color : TVTheme.Palette.textSecondary)
                .shadow(color: isSolved ? answer.color.opacity(0.7) : .clear, radius: 40)
                .scaleEffect(isSolved ? 1.12 : 1)
                .contentTransition(.symbolEffect(.replace))

        case .animalHalf(let emoji, _):
            // Animal Match: the back half slides in to complete the animal.
            HStack(spacing: isSolved ? 0 : 30) {
                TVAnimalHalfView(emoji: emoji, side: .leading, size: 300)
                if isSolved {
                    TVAnimalHalfView(emoji: emoji, side: .trailing, size: 300)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(TVTheme.Palette.muted, style: StrokeStyle(lineWidth: 6, dash: [18, 12]))
                        .frame(width: 150, height: 300)
                        .overlay(Text("?").font(.system(size: 100, weight: .heavy, design: .rounded)))
                }
            }

        case .shape(let kind):
            // Shape Sort: the shape drops down into its bin.
            TVShapeView(kind: kind, color: TVTheme.Palette.shapesPurple)
                .frame(width: 260, height: 260)
                .offset(y: isSolved ? 120 : 0)
                .scaleEffect(isSolved ? 0.5 : 1)
                .opacity(isSolved ? 0.2 : 1)

        case .none:
            EmptyView()
        }
    }

    private func snapBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 80, weight: .heavy, design: .rounded))
            .foregroundStyle(TVTheme.Palette.ink)
            .frame(width: 130, height: 130)
            .background(Circle().fill(TVTheme.Palette.success))
            .offset(x: 40, y: -40)
            .transition(.scale(scale: 2).combined(with: .opacity))
    }

    private var accessibilityText: String {
        switch subject {
        case .group(let emoji, let count): return "A group of \(count) \(emoji)"
        case .letter(let letter): return "Capital letter \(letter)"
        case .colorReveal(_, let name, let answer): return isSolved ? "\(answer.name) \(name)" : "Uncoloured \(name)"
        case .animalHalf(_, let name): return isSolved ? "Complete \(name)" : "Front half of an animal"
        case .shape(let kind): return isSolved ? "\(kind.name) sorted" : kind.name
        case .none: return ""
        }
    }
}

/// Shows the front (leading) or back (trailing) half of an emoji animal.
struct TVAnimalHalfView: View {
    enum Side { case leading, trailing }

    let emoji: String
    let side: Side
    var size: CGFloat = 160

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.9))
            .frame(width: size, height: size)
            .frame(width: size / 2, alignment: side == .leading ? .leading : .trailing)
            .clipped()
    }
}

/// Visual for one answer option.
struct TVPrototypeOptionView: View {
    let option: TVChoiceOption
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 10) {
            artwork
            Text(option.label)
                .font(TVTheme.Typography.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .overlay(alignment: .topTrailing) {
            if isWinner {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(TVTheme.Palette.success)
                    .offset(x: 30, y: -10)
                    .transition(.scale)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var artwork: some View {
        switch option.visual {
        case .number(let value):
            Text("\(value)").font(.system(size: 110, weight: .heavy, design: .rounded))
        case .letter(let letter):
            Text(letter).font(.system(size: 110, weight: .heavy, design: .rounded))
        case .color(let choice):
            Circle()
                .fill(choice.color)
                .frame(width: 100, height: 100)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
        case .animalBackHalf(let emoji):
            TVAnimalHalfView(emoji: emoji, side: .trailing, size: 150)
        case .animal(let emoji):
            Text(emoji).font(.system(size: 110))
        case .shapeBin(let kind):
            ZStack(alignment: .bottom) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(TVTheme.Palette.muted)
                TVShapeView(kind: kind, color: TVTheme.Palette.textPrimary)
                    .frame(width: 60, height: 60)
                    .padding(.bottom, 30)
            }
        case .shape(let kind):
            TVShapeView(kind: kind, color: TVTheme.Palette.shapesPurple)
                .frame(width: 110, height: 110)
        }
    }
}
