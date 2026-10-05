import Foundation
import Observation

/// Turn-based, same-room multiplayer logic for Family Challenge mode.
///
/// Players share one Siri Remote and take turns. Every correct answer adds
/// a point for that player and a star to the shared family goal. Wrong
/// answers simply let the same player try again.
@Observable
final class TVFamilyChallengeViewModel {
    enum Phase: Equatable {
        case setup
        case playing
        case celebrating
    }

    enum Feedback: Equatable {
        case none
        case correct(playerName: String)
        case tryAgain(optionID: String)
    }

    static let minimumPlayers = 2

    let challenges: [TVFamilyChallenge]
    private(set) var availablePlayers: [TVPlayer]
    private(set) var participantIDs: [UUID]
    private(set) var phase: Phase = .setup
    private(set) var challenge: TVFamilyChallenge?
    private(set) var turnIndex = 0
    private(set) var questionIndex = 0
    private(set) var scores: [UUID: Int] = [:]
    private(set) var familyStars = 0
    private(set) var feedback: Feedback = .none
    /// Set once the outcome has been saved so it is never recorded twice.
    private(set) var hasRecordedOutcome = false

    init(players: [TVPlayer], challenges: [TVFamilyChallenge] = TVGameDataService.familyChallenges) {
        self.availablePlayers = players
        self.challenges = challenges.filter { !$0.questions.isEmpty && $0.goal > 0 }
        // Everybody in the household joins by default.
        self.participantIDs = players.map(\.id)
    }

    // MARK: - Setup

    var participants: [TVPlayer] {
        participantIDs.compactMap { id in availablePlayers.first { $0.id == id } }
    }

    var canStart: Bool { participants.count >= Self.minimumPlayers }

    func isParticipating(_ player: TVPlayer) -> Bool {
        participantIDs.contains(player.id)
    }

    func toggleParticipant(_ player: TVPlayer) {
        guard phase == .setup else { return }
        if let index = participantIDs.firstIndex(of: player.id) {
            participantIDs.remove(at: index)
        } else if availablePlayers.contains(where: { $0.id == player.id }) {
            // Keep the original household order so turns are predictable.
            participantIDs.append(player.id)
            participantIDs.sort { lhs, rhs in
                (availablePlayers.firstIndex { $0.id == lhs } ?? 0) < (availablePlayers.firstIndex { $0.id == rhs } ?? 0)
            }
        }
    }

    @discardableResult
    func start(_ challenge: TVFamilyChallenge) -> Bool {
        guard canStart, challenges.contains(challenge) else { return false }
        self.challenge = challenge
        scores = Dictionary(uniqueKeysWithValues: participantIDs.map { ($0, 0) })
        familyStars = 0
        turnIndex = 0
        questionIndex = 0
        feedback = .none
        hasRecordedOutcome = false
        phase = .playing
        return true
    }

    // MARK: - Playing

    var currentPlayer: TVPlayer? {
        let players = participants
        guard !players.isEmpty else { return nil }
        return players[turnIndex % players.count]
    }

    var currentQuestion: TVChoiceRound? {
        guard let questions = challenge?.questions, !questions.isEmpty else { return nil }
        return questions[questionIndex % questions.count]
    }

    var goal: Int { challenge?.goal ?? 0 }

    var isShowingSuccess: Bool {
        if case .correct = feedback { return true }
        return false
    }

    var turnTitle: String {
        guard let name = currentPlayer?.name else { return "" }
        return "\(name.uppercased())'S TURN"
    }

    func score(for player: TVPlayer) -> Int {
        scores[player.id] ?? 0
    }

    var mascotMood: TVMascotMood {
        switch (phase, feedback) {
        case (.celebrating, _): return .correct
        case (_, .correct): return .correct
        case (_, .tryAgain): return .tryAgain
        default: return .happy
        }
    }

    var feedbackMessage: String? {
        switch feedback {
        case .none: return nil
        case .correct(let name): return "Great job, \(name)! +1 for the family"
        case .tryAgain: return "Almost! Try again!"
        }
    }

    @discardableResult
    func answer(optionID: String) -> TVAnswerOutcome {
        guard phase == .playing, !isShowingSuccess,
              let question = currentQuestion,
              let player = currentPlayer else {
            return .ignored
        }
        guard question.isCorrect(optionID) else {
            feedback = .tryAgain(optionID: optionID)
            return .incorrect
        }
        scores[player.id, default: 0] += 1
        familyStars += 1
        feedback = .correct(playerName: player.name)
        return .correct(points: 1)
    }

    /// Passes the remote to the next player, or celebrates when the goal is met.
    func advanceTurn() {
        guard phase == .playing, isShowingSuccess else { return }
        if familyStars >= goal {
            phase = .celebrating
            feedback = .none
            return
        }
        turnIndex = (turnIndex + 1) % max(1, participants.count)
        questionIndex += 1
        feedback = .none
    }

    // MARK: - Finish

    func makeOutcome() -> TVFamilyChallengeOutcome? {
        guard let challenge, phase == .celebrating else { return nil }
        return TVFamilyChallengeOutcome(
            challengeID: challenge.id,
            category: challenge.category,
            scores: scores,
            familyStars: familyStars
        )
    }

    func markOutcomeRecorded() {
        hasRecordedOutcome = true
    }

    /// Top scorer(s) for the celebration screen. Everyone is a winner, but
    /// kids like to see who found the most.
    var topScorers: [TVPlayer] {
        let best = scores.values.max() ?? 0
        guard best > 0 else { return [] }
        return participants.filter { score(for: $0) == best }
    }

    func playAgain() {
        guard let challenge else { return }
        start(challenge)
    }

    func backToSetup(refreshing players: [TVPlayer]) {
        availablePlayers = players
        participantIDs = participantIDs.filter { id in players.contains { $0.id == id } }
        if participantIDs.isEmpty {
            participantIDs = players.map(\.id)
        }
        challenge = nil
        phase = .setup
        feedback = .none
    }
}
