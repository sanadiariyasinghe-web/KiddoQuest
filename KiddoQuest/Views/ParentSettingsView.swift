import SwiftUI

struct ParentSettingsView: View {
    @Binding var navigationPath: NavigationPath
    
    // Parent Gate State
    @State private var isGateUnlocked: Bool = false
    @State private var gateAnswer: String = ""
    @State private var gateError: Bool = false
    private let num1 = 5
    private let num2 = 3
    
    // Settings toggles
    @AppStorage("sound_effects_enabled") private var soundEnabled: Bool = true
    @AppStorage(MusicService.settingsKey) private var musicEnabled: Bool = true
    @AppStorage("session_limit_minutes") private var sessionLimitMinutes: Int = 20
    @State private var showResetConfirmation: Bool = false
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            if !isGateUnlocked {
                parentGateView
            } else {
                settingsContentView
            }
        }
        .navigationTitle("Parent Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Parent Gate Security Screen
    private var parentGateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.ColorPalette.shapesPurple.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.ColorPalette.shapesPurple)
            }
            
            VStack(spacing: 8) {
                Text("Grown-Ups Only")
                    .font(Theme.Typography.title(size: 24))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                
                Text("Please solve this math question to continue:")
                    .font(Theme.Typography.body(size: 16))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(num1) + \(num2) = ?")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ColorPalette.shapesPurple)
                .padding(.vertical, 8)
            
            TextField("Answer", text: $gateAnswer)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(width: 140, height: 50)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gateError ? Theme.ColorPalette.softRedWarning : Theme.ColorPalette.cardBorder, lineWidth: 2)
                )
            
            if gateError {
                Text("Please try again.")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.ColorPalette.softRedWarning)
            }
            
            Button {
                checkGate()
            } label: {
                Text("Unlock Settings")
                    .font(Theme.Typography.headline(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Theme.ColorPalette.shapesPurple)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(24)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        .padding(.horizontal, Theme.Spacing.large)
    }
    
    private func checkGate() {
        if Int(gateAnswer.trimmingCharacters(in: .whitespaces)) == (num1 + num2) {
            withAnimation(.spring()) {
                isGateUnlocked = true
                gateError = false
            }
        } else {
            withAnimation(.default) {
                gateError = true
            }
        }
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
