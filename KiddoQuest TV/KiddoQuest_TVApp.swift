//
//  KiddoQuest_TVApp.swift
//  KiddoQuest TV
//
//  Part B of SE4041 MADD Assignment 02 — the tvOS companion to the
//  KiddoQuest iOS app (Part A). "Learn Together. Play Together."
//

import SwiftUI

@main
struct KiddoQuestTVApp: App {
    @State private var store: TVAppStore
    @State private var router = TVRouter()
    @State private var sound: TVSoundService
    private let configuration = TVLaunchConfiguration()

    init() {
        _store = State(initialValue: TVAppStore(persistence: configuration.makePersistence()))
        _sound = State(initialValue: TVSoundService(isSuppressed: configuration.isUITesting))
    }

    var body: some Scene {
        WindowGroup {
            TVRootView()
                .environment(store)
                .environment(router)
                .environment(sound)
                .environment(\.tvAmbientMotionEnabled, !configuration.isUITesting)
                .preferredColorScheme(configuration.forcedColorScheme)
        }
    }
}
