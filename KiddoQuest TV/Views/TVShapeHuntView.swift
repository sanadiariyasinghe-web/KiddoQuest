import SwiftUI

/// Shape Hunt TV — every shape on screen is focusable. Find all the
/// targets, e.g. "Find all the TRIANGLES!". Launched from Letters it
/// becomes a letter hunt using the same engine.
struct TVShapeHuntView: View {
    let player: TVPlayer?
    let onFinish: (TVSessionResult) -> Void

    @State private var model: TVShapeHuntViewModel
    @Environment(TVSoundService.self) private var sound
    @Environment(TVRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Focus: Hashable {
        case item(Int)
        case nextChallenge
    }

    @FocusState private var focus: Focus?
    @State private var shakeCounts: [Int: Int] = [:]
    @State private var sparkleTriggers: [Int: Int] = [:]
    @State private var completeTrigger = 0

    init(category: TVCategory, player: TVPlayer?, onFinish: @escaping (TVSessionResult) -> Void) {
        self.player = player
        self.onFinish = onFinish
        _model = State(initialValue: TVShapeHuntViewModel(category: category))
    }

    private var title: String {
        model.category == .letters ? "Letter Hunt TV" : "Shape Hunt TV"
    }

    var body: some View {
        if let challenge = model.currentChallenge {
            gameBody(challenge)
        } else {
            TVEmptyStateView(title: "Nothing to find!", message: "There are no hunts available right now.") {
                router.pop()
            }
        }
    }

    private func gameBody(_ challenge: TVHuntChallenge) -> some View {
        ZStack {
            VStack(spacing: 34) {
                TVGameHeader(
                    title: title,
                    roundLabel: model.challengeLabel,
                    points: model.tracker.points,
                    starsThisGame: model.tracker.correctAnswers,
                    player: player
                )

                HStack(spacing: 40) {
                    targetBadge(challenge.target)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(challenge.prompt)
                            .font(TVTheme.Typography.screenTitle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("shapeHunt.prompt")
                        Text(model.foundLabel)
                            .font(TVTheme.Typography.title)
                            .foregroundStyle(TVTheme.Palette.star)
                            .contentTransition(.numericText(value: Double(model.foundCount)))
                            .accessibilityIdentifier("shapeHunt.foundCount")
                    }
                    Spacer()
                    TVMascotView(mood: model.mascotMood, message: model.feedbackMessage ?? "Look carefully!", size: 170)
                        .frame(width: 330)
                }

                itemsGrid(challenge)
                    .frame(maxHeight: .infinity)
                    .disabled(model.isChallengeComplete)

                feedbackArea
            }
            .padding(.horizontal, TVTheme.Metrics.screenPadding)
            .padding(.vertical, 40)

            if model.isChallengeComplete {
                challengeCompleteCard
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .tvScreenBackground()
        .animation(TVTheme.Motion.pop, value: model.isChallengeComplete)
        .defaultFocus($focus, .item(challenge.items.first?.id ?? 0))
        .tvHintActivity(model.tracker.correctAnswers + model.tracker.mistakes)
        .onChange(of: model.isChallengeComplete) { _, isComplete in
            if isComplete {
                sound.play(.reward)
                completeTrigger += 1
                focus = .nextChallenge
            }
        }
        .onChange(of: model.challengeIndex) { _, _ in
            shakeCounts = [:]
            sparkleTriggers = [:]
            focus = model.currentChallenge?.items.first.map { .item($0.id) }
        }
    }

    // MARK: - Pieces

    private func targetBadge(_ target: TVHuntItemContent) -> some View {
        itemArtwork(target, color: TVTheme.Palette.textPrimary, size: 110)
            .frame(width: 170, height: 170)
            .background(Circle().fill(TVTheme.Palette.card))
            .overlay(Circle().strokeBorder(TVTheme.Palette.shapesPurple.opacity(0.5), lineWidth: 4))
            .accessibilityElement()
            .accessibilityLabel("Looking for: \(target.spokenName)")
    }

    private func itemsGrid(_ challenge: TVHuntChallenge) -> some View {
        HStack(spacing: 30) {
            ForEach(challenge.items) { item in
                let isFound = model.isFound(item)
                Button {
                    choose(item)
                } label: {
                    ZStack {
                        itemArtwork(item.content, color: TVShapeView.huntColor(at: item.paletteIndex), size: 150)
                            .scaleEffect(isFound ? 0.85 : 1)
                        if isFound {
                            VStack {
                                Spacer()
                                Label("Found!", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundStyle(TVTheme.Palette.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(TVTheme.Palette.success))
                            }
                            .padding(.bottom, 14)
                            .transition(.scale.combined(with: .opacity))
                        }
                        TVSparkleBurst(trigger: sparkleTriggers[item.id, default: 0], distance: 170)
                    }
                    .frame(width: 220, height: 250)
                }
                .tvCardButtonStyle(
                    tint: isFound ? TVTheme.Palette.success : TVTheme.Palette.shapesPurple,
                    cornerRadius: 40,
                    focusScale: 1.12
                )
                .modifier(TVShakeEffect(animatableData: CGFloat(shakeCounts[item.id, default: 0])))
                .focused($focus, equals: .item(item.id))
                .animation(TVTheme.Motion.pop, value: isFound)
                .accessibilityLabel(isFound ? "\(item.content.spokenName), found" : item.content.spokenName)
                .accessibilityIdentifier("shapeHunt.item.\(item.id)")
                // Hint: the next target that hasn't been found yet
                .tvHintTarget(!model.isChallengeComplete && item.id == challenge.items.first { $0.isTarget && !model.isFound($0) }?.id)
            }
        }
        .focusSection()
    }

    @ViewBuilder
    private func itemArtwork(_ content: TVHuntItemContent, color: Color, size: CGFloat) -> some View {
        switch content {
        case .shape(let kind):
            TVShapeView(kind: kind, color: color)
                .frame(width: size, height: size)
        case .letter(let letter):
            Text(letter)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                .frame(width: size, height: size)
        }
    }

    private var feedbackArea: some View {
        ZStack {
            if let message = model.feedbackMessage, !model.isChallengeComplete {
                TVFeedbackBanner(message: message, style: {
                    if case .notThis = model.feedback { return .gentle }
                    return .success
                }())
                .id(message + "\(model.foundCount)-\(model.tracker.mistakes)")
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Text("Swipe to move between shapes, press to choose")
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }
        }
        .frame(height: 100)
        .animation(TVTheme.Motion.pop, value: model.feedbackMessage)
    }

    private var challengeCompleteCard: some View {
        VStack(spacing: 30) {
            Text("Great job!")
                .font(TVTheme.Typography.hero)
                .accessibilityIdentifier("shapeHunt.greatJob")
            ZStack {
                TVStarRowView(count: model.challengeStars, slots: TVScoring.maxSessionStars, size: 90, animationTrigger: completeTrigger)
                TVSparkleBurst(trigger: completeTrigger, distance: 360)
            }
            TVPrimaryButton(
                title: model.isLastChallenge ? "See My Stars" : "Next Challenge",
                systemImage: model.isLastChallenge ? "star.fill" : "arrow.right.circle.fill",
                tint: TVTheme.Palette.numbersYellow,
                minWidth: 520
            ) {
                nextChallenge()
            }
            .focused($focus, equals: .nextChallenge)
            .accessibilityIdentifier("shapeHunt.next")
        }
        .padding(70)
        .background(
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(TVTheme.Palette.backgroundTop.opacity(0.96))
                .shadow(color: .black.opacity(0.5), radius: 40)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .strokeBorder(TVTheme.Palette.star, lineWidth: 6)
        )
        .focusSection()
    }

    // MARK: - Actions

    private func choose(_ item: TVHuntItem) {
        switch model.select(item) {
        case .found:
            sound.play(.correct)
            sparkleTriggers[item.id, default: 0] += 1
        case .notTarget:
            sound.play(.incorrect)
            withAnimation(.easeInOut(duration: 0.45)) {
                shakeCounts[item.id, default: 0] += 1
            }
        case .alreadyFound:
            sound.play(.select)
        case .ignored:
            break
        }
    }

    private func nextChallenge() {
        model.nextChallenge()
        if model.isFinished {
            onFinish(model.makeResult())
        }
    }
}
