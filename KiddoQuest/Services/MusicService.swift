import AVFoundation

// MARK: - Music Service
// Plays the same calm background melody as the KiddoQuest tvOS app.
// The music is synthesised at runtime from simple sine-wave notes, so the app ships
// no audio files. Respects the parent "Background Music" setting (music_enabled).
// If the audio engine cannot start, music is silently skipped and the app keeps working.

final class MusicService {
    static let shared = MusicService()
    
    static let settingsKey = "music_enabled"
    
    private var engine: AVAudioEngine?
    private let musicPlayer = AVAudioPlayerNode()
    private let format = ToneSynthesizer.format
    private var isAudioAvailable = true
    
    private init() {}
    
    private var isMusicEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.settingsKey) as? Bool ?? true
    }
    
    /// Starts or stops the music to match the parent setting.
    /// Safe to call repeatedly (e.g. on launch, when returning to the app, or when the toggle changes).
    func refresh() {
        if isMusicEnabled {
            startMusic()
        } else {
            stopMusic()
        }
    }
    
    // MARK: - Music
    private func startMusic() {
        // If the engine was stopped (e.g. while the app was in the background), the loop must be rescheduled.
        let wasRunning = engine?.isRunning ?? false
        guard let format, startEngineIfNeeded() else { return }
        if wasRunning && musicPlayer.isPlaying { return }
        // A calm pentatonic loop at very low volume (same melody as the tvOS app).
        let melody: [ToneSynthesizer.Note] = [
            .init(523.25, 0.4), .init(587.33, 0.4), .init(659.25, 0.4), .init(783.99, 0.4),
            .init(659.25, 0.4), .init(587.33, 0.4), .init(523.25, 0.4), .init(0, 0.4),
            .init(392.00, 0.4), .init(440.00, 0.4), .init(523.25, 0.4), .init(587.33, 0.4),
            .init(523.25, 0.8), .init(0, 0.4)
        ]
        guard let buffer = ToneSynthesizer.makeBuffer(notes: melody, amplitude: 0.05, format: format) else { return }
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        // A failure here just means the music is skipped.
        if #available(iOS 27.0, *) {
            try? musicPlayer.playAudio()
        } else {
            musicPlayer.play()
        }
    }
    
    private func stopMusic() {
        musicPlayer.stop()
    }
    
    // MARK: - Engine
    private func startEngineIfNeeded() -> Bool {
        guard isAudioAvailable, let format else { return false }
        if let engine, engine.isRunning { return true }
        
        do {
            let engine = try self.engine ?? makeEngine(format: format)
            self.engine = engine
            engine.prepare()
            try engine.start()
            return true
        } catch {
            // Fallback: no music, the app keeps working silently.
            isAudioAvailable = false
            return false
        }
    }
    
    private func makeEngine(format: AVAudioFormat) throws -> AVAudioEngine {
        // Ambient: mixes with other audio and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        let engine = AVAudioEngine()
        engine.attach(musicPlayer)
        // The deployment target is iOS 26.6, so use the older API there
        if #available(iOS 27.0, *) {
            try engine.connectNode(musicPlayer, to: engine.mainMixerNode, format: format)
        } else {
            engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        }
        return engine
    }

}
