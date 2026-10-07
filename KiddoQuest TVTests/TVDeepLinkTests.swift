import Foundation
import Testing
@testable import KiddoQuest_TV

/// Top Shelf links (kiddoquesttv://) open the right screen.
@MainActor
struct TVDeepLinkTests {

    @Test func gameLinkOpensTheGameInsideItsIsland() throws {
        let url = try #require(TVDeepLink.url(game: .feedAnimals, category: .animals))
        #expect(TVDeepLink.path(for: url, hasPlayer: true) == [.world, .category(.animals), .game(.feedAnimals, .animals)])
    }

    @Test func categoryAndFamilyLinks() throws {
        let island = try #require(URL(string: "kiddoquesttv://category/numbers"))
        #expect(TVDeepLink.path(for: island, hasPlayer: true) == [.world, .category(.numbers)])
        let family = try #require(URL(string: "kiddoquesttv://family"))
        #expect(TVDeepLink.path(for: family, hasPlayer: true) == [.familyChallenge])
    }

    @Test func withoutAPlayerTheChildPicksWhoIsPlayingFirst() throws {
        let url = try #require(TVDeepLink.url(game: .shapeSort, category: .shapes))
        #expect(TVDeepLink.path(for: url, hasPlayer: false) == [.playerSelection(.startPlaying)])
    }

    @Test(arguments: ["kiddoquesttv://game/unknown/animals", "kiddoquesttv://game/feedAnimals", "https://example.com/game/feedAnimals/animals", "kiddoquesttv://nothing"])
    func unknownLinksAreIgnored(link: String) throws {
        let url = try #require(URL(string: link))
        #expect(TVDeepLink.path(for: url, hasPlayer: true) == nil)
    }
}
