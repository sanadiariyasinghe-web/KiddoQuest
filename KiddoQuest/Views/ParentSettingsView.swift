import SwiftUI

struct ParentSettingsView: View {
    @Binding var navigationPath: NavigationPath
    
    // Parent Gate State
    @State private var isGateUnlocked: Bool = false
    
    // Settings toggles
    @AppStorage("sound_effects_enabled") private var soundEnabled: Bool = true
    @AppStorage(MusicService.settingsKey) private var musicEnabled: Bool = true
    @AppStorage(PlayTimeTracker.limitKey) private var sessionLimitMinutes: Int = PlayTimeTracker.defaultLimitMinutes
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
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will reset all earned stars and island completions.")
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
}
