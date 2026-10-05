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
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
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
        let melody: [Note] = [
            Note(523.25, 0.4), Note(587.33, 0.4), Note(659.25, 0.4), Note(783.99, 0.4),
            Note(659.25, 0.4), Note(587.33, 0.4), Note(523.25, 0.4), Note(0, 0.4),
            Note(392.00, 0.4), Note(440.00, 0.4), Note(523.25, 0.4), Note(587.33, 0.4),
            Note(523.25, 0.8), Note(0, 0.4)
        ]
        guard let buffer = Self.makeBuffer(notes: melody, amplitude: 0.05, format: format) else { return }
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        // A failure here just means the music is skipped.
        try? musicPlayer.playAudio()
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
        try engine.connectNode(musicPlayer, to: engine.mainMixerNode, format: format)
        return engine
    }
    
    // MARK: - Synthesis
    private struct Note {
        let frequency: Double
        let duration: Double
        init(_ frequency: Double, _ duration: Double) {
            self.frequency = frequency
            self.duration = duration
        }
    }
    
    /// Renders notes into a mono PCM buffer with a soft bell-like envelope.
    /// A frequency of 0 renders silence (a rest).
    private static func makeBuffer(notes: [Note], amplitude: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCounts = notes.map { Int($0.duration * sampleRate) }
        let totalFrames = frameCounts.reduce(0, +)
        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }
        
        var frame = 0
        for (note, count) in zip(notes, frameCounts) {
            let attackFrames = max(1.0, 0.01 * sampleRate)
            for i in 0..<count {
                let time = Double(i) / sampleRate
                guard note.frequency > 0 else {
                    channel[frame] = 0
                    frame += 1
                    continue
                }
                let attack = min(1.0, Double(i) / attackFrames)
                let decay = exp(-3.0 * time / note.duration)
                let tone = 0.8 * sin(2 * .pi * note.frequency * time)
                    + 0.2 * sin(4 * .pi * note.frequency * time)
                channel[frame] = Float(tone * attack * decay) * amplitude
                frame += 1
            }
        }
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        return buffer
    }
}
