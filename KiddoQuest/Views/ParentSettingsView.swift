import SwiftUI

struct ParentSettingsView: View {
    @Binding var navigationPath: NavigationPath
    
    // Parent Gate State
    @State private var isGateUnlocked: Bool = false
    
    // Settings toggles
    @AppStorage("sound_effects_enabled") private var soundEnabled: Bool = true
    @AppStorage(MusicService.settingsKey) private var musicEnabled: Bool = true
    @AppStorage(PlayTimeTracker.limitKey) private var sessionLimitMinutes: Int = PlayTimeTracker.defaultLimitMinutes
    @AppStorage(CalmMode.settingsKey) private var calmModeEnabled: Bool = false
    @State private var showResetConfirmation: Bool = false

    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            if !isGateUnlocked {
                ParentGateView {
                    withAnimation(.spring()) {
                        isGateUnlocked = true
                    }
                }
            } else {
                settingsContentView
            }
        }
        .navigationTitle("Parent Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Settings Content
    private var settingsContentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                weeklySummarySection

                // Audio Preferences
                VStack(alignment: .leading, spacing: 16) {
                    Text("Audio Controls")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    
                    Toggle(isOn: $soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                            .font(Theme.Typography.body(size: 16))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                    }
                    .tint(Theme.ColorPalette.successGreen)
                    
                    Divider()
                    
                    Toggle(isOn: $musicEnabled) {
                        Label("Background Music", systemImage: "music.note")
                            .font(Theme.Typography.body(size: 16))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                    }
                    .tint(Theme.ColorPalette.successGreen)
                    .onChange(of: musicEnabled) { _, _ in
                        MusicService.shared.refresh()
                    }
                }
                .padding(20)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                // Comfort
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comfort")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)

                    Toggle(isOn: $calmModeEnabled) {
                        Label("Calm Mode", systemImage: "leaf.fill")
                            .font(Theme.Typography.body(size: 16))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                    }
                    .tint(Theme.ColorPalette.successGreen)

                    Text("Turns off confetti and floating animations. Also on when the device's Reduce Motion setting is on.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                }
                .padding(20)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                // Session Limits
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Session Preference")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    
                    Picker("Session Limit", selection: $sessionLimitMinutes) {
                        Text("15 Minutes").tag(15)
                        Text("20 Minutes").tag(20)
                        Text("30 Minutes").tag(30)
                        Text("No Limit").tag(0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: sessionLimitMinutes) { _, _ in
                        PlayTimeTracker.shared.refresh()
                    }
                    
                    Text("Played today: \(PlayTimeTracker.shared.minutesPlayedToday) min. When the limit is reached, KiddoQuest shows a calm break screen.")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                }
                .padding(20)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                
                // Reset Progress Action
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data Management")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    // Progress Reset
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                            Text("Reset All Learning Progress")
                        }
                        .font(Theme.Typography.body(size: 16))
                    }
                    .confirmationDialog("Reset Progress?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                        Button("Reset All Progress", role: .destructive) {
                            CoreDataManager.shared.resetAllData()
                            StickerBook.shared.reset()
                            GameLevelStore.shared.reset(gameIDs: GameInfo.sampleGames.map(\.id))
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will reset all earned stars, stickers and island completions.")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                
                // Session History Stats for Parents (Section 28)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Recent Learning Sessions")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    
                    if CoreDataManager.shared.recentSessions.isEmpty {
                        Text("No sessions recorded yet. Play a game to start tracking!")
                            .font(Theme.Typography.body(size: 14))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                    } else {
                        ForEach(CoreDataManager.shared.recentSessions) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(Theme.Typography.body(size: 15))
                                        .foregroundStyle(Theme.ColorPalette.primaryText)
                                    Text("\(session.gamesPlayed) games played • \(Int(session.duration))s active")
                                        .font(Theme.Typography.caption())
                                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Theme.ColorPalette.starGold)
                                    Text("+\(session.starsEarned)")
                                        .font(Theme.Typography.headline(size: 15))
                                        .foregroundStyle(Theme.ColorPalette.primaryText)
                                }
                            }
                            Divider()
                        }
                    }
                }
                .padding(20)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .padding(Theme.Spacing.medium)
        }
    }

    // MARK: - This Week's Learning
    /// "What my child learned this week", built from saved game progress and sessions.
    private var weeklySummarySection: some View {
        let coreData = CoreDataManager.shared
        let skills = WeeklyLearningSummary.skillsLearned(progress: coreData.progressByGame)
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let totals = coreData.sessionTotals(since: weekStart)

        return VStack(alignment: .leading, spacing: 14) {
            Text("What \(coreData.currentProfile.name) learned this week")
                .font(Theme.Typography.headline(size: 18))
                .foregroundStyle(Theme.ColorPalette.primaryText)

            HStack(spacing: Theme.Spacing.medium) {
                Label("\(totals.gamesPlayed) games", systemImage: "gamecontroller.fill")
                Label("\(totals.starsEarned) stars", systemImage: "star.fill")
                Label("\(StickerBook.shared.stickers.count) stickers", systemImage: "seal.fill")
            }
            .font(Theme.Typography.caption())
            .foregroundStyle(Theme.ColorPalette.secondaryText)

            if skills.isEmpty {
                Text("No games finished this week yet. Skills appear here after each finished game.")
                    .font(Theme.Typography.body(size: 14))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            } else {
                ForEach(skills) { skill in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.ColorPalette.successGreen)
                        Text(skill.skill)
                            .font(Theme.Typography.body(size: 15))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                        Spacer()
                        ProgressStarBar(stars: skill.stars, maxStars: 3, starSize: 12, showBackground: false)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
