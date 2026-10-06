import SwiftUI

/// Simple parent settings. No accounts, no network.
struct TVSettingsView: View {
    @Environment(TVAppStore.self) private var store
    @Environment(TVRouter.self) private var router
    @Environment(TVSoundService.self) private var sound
    @Environment(TVPlayTimeTracker.self) private var playTime

    @State private var isConfirmingReset = false
    @State private var statusMessage: String?

    var body: some View {
        @Bindable var store = store
        HStack(alignment: .top, spacing: 70) {
            // Scrolls so every setting stays reachable; focus moves scroll it automatically.
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 30) {
                    TVScreenHeader(title: "Settings", subtitle: "For grown-ups", icon: "⚙️")

                    VStack(spacing: 24) {
                        toggleRow(
                            title: "Sound",
                            detail: "Taps, cheers and focus clicks",
                            symbolOn: "speaker.wave.3.fill",
                            symbolOff: "speaker.slash.fill",
                            isOn: store.settings.soundEnabled,
                            identifier: "settings.sound"
                        ) {
                            store.settings.soundEnabled.toggle()
                        }

                        toggleRow(
                            title: "Music",
                            detail: "Gentle background melody",
                            symbolOn: "music.note",
                            symbolOff: "music.note.slash",
                            isOn: store.settings.musicEnabled,
                            identifier: "settings.music"
                        ) {
                            store.settings.musicEnabled.toggle()
                        }

                        toggleRow(
                            title: "Calm Mode",
                            detail: "No confetti or moving decorations",
                            symbolOn: "leaf.fill",
                            symbolOff: "leaf",
                            isOn: store.settings.calmMode,
                            identifier: "settings.calmMode"
                        ) {
                            store.settings.calmMode.toggle()
                        }

                        valueRow(
                            title: "Daily Time Limit",
                            detail: "Played today: \(playTime.minutesPlayedToday) min. Press to change.",
                            symbol: "moon.stars.fill",
                            value: store.settings.dailyLimitLabel,
                            identifier: "settings.dailyLimit"
                        ) {
                            store.settings.dailyLimitMinutes = store.settings.nextDailyLimit
                        }

                        actionRow(
                            title: "Player Profiles",
                            detail: "Now playing: \(store.activePlayer?.name ?? "nobody")",
                            symbol: "person.2.fill",
                            tint: TVTheme.Palette.lettersBlue,
                            identifier: "settings.players"
                        ) {
                            router.push(.playerSelection(.switchPlayer))
                        }

                        actionRow(
                            title: "Load Demo Family",
                            detail: "Restore Ava, Liam and Parent with sample progress",
                            symbol: "sparkles",
                            tint: TVTheme.Palette.animalsGreen,
                            identifier: "settings.demo"
                        ) {
                            store.loadDemoFamily()
                            statusMessage = "Demo family loaded."
                        }

                        actionRow(
                            title: "Reset Progress",
                            detail: "Clears stars, scores, badges and stickers for everyone",
                            symbol: "arrow.counterclockwise",
                            tint: TVTheme.Palette.familyCoral,
                            identifier: "settings.reset"
                        ) {
                            isConfirmingReset = true
                        }
                    }
                    .focusSection()

                    if let statusMessage {
                        Label(statusMessage, systemImage: "checkmark.circle.fill")
                            .font(TVTheme.Typography.body)
                            .foregroundStyle(TVTheme.Palette.success)
                            .accessibilityIdentifier("settings.status")
                    }
                }
                .frame(width: 1000)
                .padding(.vertical, 20)
            }
            .scrollClipDisabled()
            .frame(width: 1040)

            aboutPanel
        }
        .padding(TVTheme.Metrics.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tvScreenBackground()
        .alert("Reset all progress?", isPresented: $isConfirmingReset) {
            Button("Reset", role: .destructive) {
                store.resetProgress()
                statusMessage = "Progress was reset."
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stars, scores, badges and stickers for every player will be cleared. Profiles stay.")
        }
    }

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            TVMascotView(mood: .happy, message: "Thanks for learning with me!", size: 200)
            Text("KiddoQuest TV")
                .font(TVTheme.Typography.title)
            Text("Learn Together. Play Together.")
                .font(TVTheme.Typography.body)
                .foregroundStyle(TVTheme.Palette.textSecondary)
            VStack(alignment: .leading, spacing: 12) {
                Label("No accounts or sign-in", systemImage: "person.crop.circle.badge.checkmark")
                Label("No ads, no tracking", systemImage: "hand.raised.fill")
                Label("Progress stays on this Apple TV", systemImage: "appletv.fill")
            }
            .font(TVTheme.Typography.caption)
            if !sound.isAudioAvailable {
                Label("Audio unavailable — playing silently", systemImage: "speaker.slash.fill")
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.gentle)
            }
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: TVTheme.Metrics.cardCorner, style: .continuous).fill(TVTheme.Palette.card))
        .accessibilityElement(children: .combine)
    }

    private func toggleRow(
        title: String,
        detail: String,
        symbolOn: String,
        symbolOff: String,
        isOn: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            sound.play(.select)
            action()
        } label: {
            settingsRowLabel(title: title, detail: detail, symbol: isOn ? symbolOn : symbolOff, tint: TVTheme.Palette.numbersYellow) {
                Text(isOn ? "ON" : "OFF")
                    .font(TVTheme.Typography.headline)
                    .foregroundStyle(isOn ? TVTheme.Palette.ink : TVTheme.Palette.textPrimary)
                    .frame(width: 140)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(isOn ? TVTheme.Palette.success : TVTheme.Palette.subtle))
            }
        }
        .tvCardButtonStyle(tint: TVTheme.Palette.numbersYellow, cornerRadius: 34, focusScale: 1.04)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(detail)
        .accessibilityIdentifier(identifier)
    }

    private func valueRow(
        title: String,
        detail: String,
        symbol: String,
        value: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            sound.play(.select)
            action()
        } label: {
            settingsRowLabel(title: title, detail: detail, symbol: symbol, tint: TVTheme.Palette.lettersBlue) {
                Text(value)
                    .font(TVTheme.Typography.headline)
                    .foregroundStyle(TVTheme.Palette.ink)
                    .frame(width: 200)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(TVTheme.Palette.numbersYellow))
            }
        }
        .tvCardButtonStyle(tint: TVTheme.Palette.lettersBlue, cornerRadius: 34, focusScale: 1.04)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint(detail)
        .accessibilityIdentifier(identifier)
    }

    private func actionRow(
        title: String,
        detail: String,
        symbol: String,
        tint: Color,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            sound.play(.select)
            action()
        } label: {
            settingsRowLabel(title: title, detail: detail, symbol: symbol, tint: tint) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 34, weight: .bold))
            }
        }
        .tvCardButtonStyle(tint: tint, cornerRadius: 34, focusScale: 1.04)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
        .accessibilityIdentifier(identifier)
    }

    private func settingsRowLabel<Trailing: View>(
        title: String,
        detail: String,
        symbol: String,
        tint: Color,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 28) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(TVTheme.Typography.headline)
                Text(detail)
                    .font(TVTheme.Typography.caption)
                    .foregroundStyle(TVTheme.Palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 20)
        .frame(width: 1000)
    }
}
