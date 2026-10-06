import SwiftUI

/// Family Challenge — the shared living-room mode. Players pass the Siri
/// Remote and take turns; every correct answer adds to one family goal.
struct TVFamilyChallengeView: View {
    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound

    @State private var model: TVFamilyChallengeViewModel?
    @State private var unlockedRewards: [UUID: [TVRewardKind]] = [:]

    var body: some View {
        Group {
            if let model {
                switch model.phase {
                case .setup:
                    TVFamilyChallengeSetupView(model: model)
                case .playing:
                    TVFamilyChallengePlayView(model: model, challengesCompleted: store.family.challengesCompleted)
                case .celebrating:
                    TVFamilyChallengeCelebrationView(model: model, unlockedRewards: unlockedRewards) {
                        unlockedRewards = [:]
                        model.backToSetup(refreshing: store.players)
                    }
                }
            } else {
                Color.clear
            }
        }
        .tvScreenBackground()
        .onAppear {
            if model == nil {
                model = TVFamilyChallengeViewModel(players: store.players)
            }
        }
        .onChange(of: model?.phase) { _, phase in
            guard phase == .celebrating, let model, !model.hasRecordedOutcome,
                  let outcome = model.makeOutcome() else { return }
            unlockedRewards = store.recordFamilyChallenge(outcome)
            model.markOutcomeRecorded()
            sound.play(.reward)
        }
    }
}

// MARK: - Setup

private struct TVFamilyChallengeSetupView: View {
    let model: TVFamilyChallengeViewModel

    @Environment(TVSoundService.self) private var sound

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            TVScreenHeader(
                title: "FAMILY CHALLENGE",
                subtitle: "Learn together. Play together. Pass the remote and take turns!",
                icon: "👨‍👩‍👧‍👦"
            ) {
                TVMascotView(mood: .happy, message: "Who's joining in?", size: 140)
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("1. Who's playing?")
                    .font(TVTheme.Typography.headline)
                HStack(spacing: 34) {
                    ForEach(model.availablePlayers) { player in
                        participantToggle(player)
                    }
                    Spacer(minLength: 0)
                    if !model.canStart {
                        Label("Pick at least \(TVFamilyChallengeViewModel.minimumPlayers) players", systemImage: "person.2.fill")
                            .font(TVTheme.Typography.body)
                            .foregroundStyle(TVTheme.Palette.gentle)
                            .accessibilityIdentifier("familyChallenge.needPlayers")
                    }
                }
                .focusSection()
            }

            VStack(alignment: .leading, spacing: 20) {
                Text("2. Pick a challenge")
                    .font(TVTheme.Typography.headline)
                HStack(spacing: 40) {
                    ForEach(model.challenges) { challenge in
                        TVFocusCard(tint: TVTheme.Palette.familyCoral, action: {
                            sound.play(.select)
                            model.start(challenge)
                        }) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(challenge.emoji).font(.system(size: 70))
                                Text(challenge.title).font(TVTheme.Typography.headline)
                                Text(challenge.goalPrompt)
                                    .font(TVTheme.Typography.caption)
                                    .foregroundStyle(TVTheme.Palette.textSecondary)
                                    .lineLimit(2, reservesSpace: true)
                            }
                            .padding(30)
                            .frame(width: 500, height: 290, alignment: .topLeading)
                        }
                        .disabled(!model.canStart)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(challenge.title). \(challenge.goalPrompt)")
                        .accessibilityIdentifier("familyChallenge.challenge.\(challenge.id)")
                    }
                }
                .focusSection()
            }
            Spacer(minLength: 0)
        }
        .padding(TVTheme.Metrics.screenPadding)
    }

    private func participantToggle(_ player: TVPlayer) -> some View {
        let isOn = model.isParticipating(player)
        return TVFocusCard(tint: player.color.color, cornerRadius: 36, action: {
            sound.play(.select)
            model.toggleParticipant(player)
        }) {
            HStack(spacing: 18) {
                TVAvatarView(player: player, size: 90)
                Text(player.name)
                    .font(TVTheme.Typography.headline)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(isOn ? TVTheme.Palette.success : TVTheme.Palette.muted)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 26)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name), \(isOn ? "joining" : "not joining")")
        .accessibilityHint("Toggles whether \(player.name) plays")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("familyChallenge.participant.\(player.name)")
    }
}

// MARK: - Playing

private struct TVFamilyChallengePlayView: View {
    let model: TVFamilyChallengeViewModel
    let challengesCompleted: Int

    @Environment(TVSoundService.self) private var sound
    /// Question-qualified focus so a repeated shape still gets focus on the next turn.
    private struct OptionFocus: Hashable {
        let question: Int
        let optionID: String
    }

    @FocusState private var focusedOption: OptionFocus?
    @State private var shakeCounts: [String: Int] = [:]
    @State private var celebrationTrigger = 0

    var body: some View {
        HStack(alignment: .top, spacing: 60) {
            TVScoreBoard(
                entries: model.participants.map {
                    TVScoreBoard.Entry(player: $0, score: model.score(for: $0), isCurrentTurn: $0.id == model.currentPlayer?.id)
                },
                familyStars: model.familyStars,
                goal: model.goal,
                challengesCompleted: challengesCompleted
            )

            VStack(spacing: 34) {
                if let challenge = model.challenge {
                    Text(challenge.goalPrompt)
                        .font(TVTheme.Typography.headline)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                        .accessibilityIdentifier("familyChallenge.goal")
                }

                turnBanner

                if let question = model.currentQuestion {
                    questionArea(question)
                }

                feedback
            }
            .frame(maxWidth: .infinity)
        }
        .padding(TVTheme.Metrics.screenPadding)
        .defaultFocus($focusedOption, model.currentQuestion?.options.first.map { OptionFocus(question: model.questionIndex, optionID: $0.id) })
        .onChange(of: model.questionIndex) { _, _ in
            shakeCounts = [:]
            sound.play(.turnChange)
            focusedOption = model.currentQuestion?.options.first.map { OptionFocus(question: model.questionIndex, optionID: $0.id) }
        }
        .task(id: celebrationTrigger) {
            guard celebrationTrigger > 0 else { return }
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(TVTheme.Motion.entrance) {
                model.advanceTurn()
            }
        }
    }

    @ViewBuilder
    private var turnBanner: some View {
        if let player = model.currentPlayer {
            HStack(spacing: 24) {
                TVAvatarView(player: player, size: 110)
                Text(model.turnTitle)
                    .font(TVTheme.Typography.screenTitle)
                    .foregroundStyle(TVTheme.Palette.ink)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 40)
            .background(Capsule().fill(player.color.color))
            .id(player.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(player.name)'s turn")
            .accessibilityIdentifier("familyChallenge.turn")
        }
    }

    private func questionArea(_ question: TVChoiceRound) -> some View {
        VStack(spacing: 30) {
            Text(question.prompt)
                .font(TVTheme.Typography.title)
                .accessibilityIdentifier("familyChallenge.question")

            if question.subject != .none {
                TVRoundSubjectView(subject: question.subject, isSolved: model.isShowingSuccess)
                    .scaleEffect(0.7)
                    .frame(height: 200)
            }

            ZStack {
                HStack(spacing: 40) {
                    ForEach(question.options) { option in
                        let isWinner = model.isShowingSuccess && question.isCorrect(option.id)
                        Button {
                            choose(option)
                        } label: {
                            TVChoiceOptionView(option: option, isWinner: isWinner)
                                .frame(width: 260, height: 220)
                        }
                        .tvCardButtonStyle(
                            tint: isWinner ? TVTheme.Palette.success : (model.currentPlayer?.color.color ?? TVTheme.Palette.lettersBlue),
                            cornerRadius: 36,
                            focusScale: 1.1
                        )
                        .modifier(TVShakeEffect(animatableData: CGFloat(shakeCounts[option.id, default: 0])))
                        .focused($focusedOption, equals: OptionFocus(question: model.questionIndex, optionID: option.id))
                        .accessibilityLabel(option.label)
                        .accessibilityIdentifier("familyChallenge.option.\(option.id)")
                    }
                }
                .focusSection()
                TVSparkleBurst(trigger: celebrationTrigger, distance: 320)
            }
        }
    }

    private var feedback: some View {
        ZStack {
            if let message = model.feedbackMessage {
                TVFeedbackBanner(message: message, style: model.isShowingSuccess ? .success : .gentle)
                    .id(message + "\(model.familyStars)")
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                Text("Every right answer adds a star to the family score!")
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
            }
        }
        .frame(height: 100)
        .animation(TVTheme.Motion.pop, value: model.feedbackMessage)
    }

    private func choose(_ option: TVChoiceOption) {
        switch model.answer(optionID: option.id) {
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

// MARK: - Celebration

private struct TVFamilyChallengeCelebrationView: View {
    let model: TVFamilyChallengeViewModel
    let unlockedRewards: [UUID: [TVRewardKind]]
    let onNewChallenge: () -> Void

    @Environment(TVRouter.self) private var router
    @FocusState private var isPlayAgainFocused: Bool
    @State private var burst = 0

    var body: some View {
        VStack(spacing: 40) {
            HStack(spacing: 50) {
                TVMascotView(mood: .correct, message: "Awesome teamwork!", size: 220)
                VStack(alignment: .leading, spacing: 16) {
                    Text("The family did it! 🎉")
                        .font(TVTheme.Typography.hero)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .accessibilityIdentifier("familyChallenge.complete")
                    Text(model.challenge?.goalPrompt.replacingOccurrences(of: "Can the family ", with: "You ").replacingOccurrences(of: "?", with: "!") ?? "")
                        .font(TVTheme.Typography.title)
                        .foregroundStyle(TVTheme.Palette.textSecondary)
                }
            }

            ZStack {
                VStack(spacing: 10) {
                    Text("FAMILY SCORE").font(TVTheme.Typography.caption)
                    TVStarRowView(count: model.familyStars, size: 70, animationTrigger: burst)
                }
                TVSparkleBurst(trigger: burst, distance: 420)
            }

            HStack(spacing: 40) {
                ForEach(model.participants) { player in
                    VStack(spacing: 12) {
                        TVAvatarView(player: player, size: 120)
                        Text(player.name.uppercased()).font(TVTheme.Typography.headline)
                        Text("\(model.score(for: player)) points").font(TVTheme.Typography.body)
                        if let rewards = unlockedRewards[player.id] {
                            ForEach(rewards) { reward in
                                Text("\(reward.emoji) \(reward.title)!")
                                    .font(TVTheme.Typography.caption)
                                    .foregroundStyle(TVTheme.Palette.ink)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(TVTheme.Palette.star))
                            }
                        }
                    }
                    .padding(26)
                    .background(RoundedRectangle(cornerRadius: 34, style: .continuous).fill(TVTheme.Palette.card))
                    .accessibilityElement(children: .combine)
                }
            }

            HStack(spacing: 40) {
                TVPrimaryButton(title: "Play Again", systemImage: "arrow.clockwise", tint: TVTheme.Palette.numbersYellow, minWidth: 380) {
                    model.playAgain()
                }
                .focused($isPlayAgainFocused)
                .accessibilityIdentifier("familyChallenge.playAgain")

                TVPrimaryButton(title: "New Challenge", systemImage: "square.grid.2x2.fill", tint: TVTheme.Palette.familyCoral, minWidth: 420, action: onNewChallenge)
                    .accessibilityIdentifier("familyChallenge.newChallenge")

                TVPrimaryButton(title: "Family Progress", systemImage: "chart.bar.fill", tint: TVTheme.Palette.animalsGreen, minWidth: 440) {
                    router.replaceTop(with: .familyProgress)
                }
                .accessibilityIdentifier("familyChallenge.progress")
            }
            .focusSection()
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultFocus($isPlayAgainFocused, true)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            burst += 1
        }
    }
}
