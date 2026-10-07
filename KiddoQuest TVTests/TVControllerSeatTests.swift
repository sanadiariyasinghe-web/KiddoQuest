import Foundation
import Testing
@testable import KiddoQuest_TV

/// Game controllers in Family Challenge: seats follow turn order and turns are enforced kindly.
@MainActor
struct TVControllerSeatTests {
    private let ava = UUID()
    private let liam = UUID()

    @Test func controllersAreHandedOutInTurnOrder() {
        let seats = TVControllerSeats(controllerIDs: ["pad1", "pad2"], participants: [ava, liam])
        #expect(seats.player(for: "pad1") == ava)
        #expect(seats.player(for: "pad2") == liam)
        #expect(seats.seat(for: liam, controllerIDs: ["pad1", "pad2"]) == 1)
    }

    @Test func extraPlayersShareTheSiriRemote() {
        let seats = TVControllerSeats(controllerIDs: ["pad1"], participants: [ava, liam])
        #expect(seats.seat(for: liam, controllerIDs: ["pad1"]) == nil)
        #expect(seats.allows(pressFrom: nil, currentPlayer: liam))
    }

    @Test func onlyTheCurrentPlayersControllerCanAnswer() {
        let seats = TVControllerSeats(controllerIDs: ["pad1", "pad2"], participants: [ava, liam])
        #expect(seats.allows(pressFrom: "pad1", currentPlayer: ava))
        #expect(!seats.allows(pressFrom: "pad2", currentPlayer: ava))
        #expect(seats.allows(pressFrom: "unknown", currentPlayer: ava))
    }

    @Test func pressingOutOfTurnGivesAKindReminderWithoutScoring() throws {
        let players = TVGameDataService.demoPlayers().filter { !$0.isParent }
        let model = TVFamilyChallengeViewModel(players: players)
        let challenge = try #require(model.challenges.first)
        #expect(model.start(challenge))
        let current = try #require(model.currentPlayer)
        let other = try #require(model.participants.first { $0.id != current.id })

        model.remindToWait(other)
        #expect(model.feedbackMessage?.contains("Wait for your turn, \(other.name)") == true)
        #expect(model.score(for: other) == 0)
        #expect(model.currentPlayer?.id == current.id)
    }
}
