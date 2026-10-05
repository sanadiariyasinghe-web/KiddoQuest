import AVFoundation
import Observation

/// Plays short, friendly feedback tones and an optional background melody.
///
/// All audio is synthesised at runtime from simple sine-wave notes, so the
/// app ships no audio files and there are no copyright concerns. If the
/// audio engine cannot start (for example, no output device), every call
/// becomes a silent no-op and the game keeps working with visual feedback.
@Observable
final class TVSoundService {
    enum Effect: CaseIterable {
        case focus, select, correct, incorrect, reward, turnChange
    }

    private(set) var isSoundEnabled = true
    private(set) var isMusicEnabled = false
    /// False when the engine could not start; the app then runs silently.
    private(set) var isAudioAvailable = true

    @ObservationIgnored private let isSuppressed: Bool
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private let effectsPlayer = AVAudioPlayerNode()
    @ObservationIgnored private let musicPlayer = AVAudioPlayerNode()
    @ObservationIgnored private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    @ObservationIgnored private var bufferCache: [Effect: AVAudioPCMBuffer] = [:]
    @ObservationIgnored private var lastFocusSound = Date.distantPast

    /// - Parameter isSuppressed: When true (UI tests) no audio is ever produced.
    init(isSuppressed: Bool = false) {
        self.isSuppressed = isSuppressed
    }

    func apply(_ settings: TVSettings) {
        isSoundEnabled = settings.soundEnabled
        let wantsMusic = settings.musicEnabled
        guard wantsMusic != isMusicEnabled else { return }
        isMusicEnabled = wantsMusic
        wantsMusic ? startMusic() : stopMusic()
    }

    func play(_ effect: Effect) {
        guard isSoundEnabled, !isSuppressed else { return }
        if effect == .focus {
            // Focus can change rapidly while swiping; throttle the tick.
            let now = Date()
            guard now.timeIntervalSince(lastFocusSound) > 0.08 else { return }
            lastFocusSound = now
        }
        guard let buffer = buffer(for: effect), startEngineIfNeeded() else { return }
        effectsPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !effectsPlayer.isPlaying {
            // A failure here just means this tone is skipped.
            try? effectsPlayer.playAudio()
        }
    }

    // MARK: - Music

    private func startMusic() {
        guard !isSuppressed, let format, startEngineIfNeeded() else { return }
        // A calm pentatonic loop at very low volume.
        let melody: [Note] = [
            Note(523.25, 0.4), Note(587.33, 0.4), Note(659.25, 0.4), Note(783.99, 0.4),
            Note(659.25, 0.4), Note(587.33, 0.4), Note(523.25, 0.4), Note(0, 0.4),
            Note(392.00, 0.4), Note(440.00, 0.4), Note(523.25, 0.4), Note(587.33, 0.4),
            Note(523.25, 0.8), Note(0, 0.4)
        ]
        guard let buffer = Self.makeBuffer(notes: melody, amplitude: 0.05, format: format) else { return }
        musicPlayer.stop()
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
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
            // Fallback: no audio, visual feedback only.
            isAudioAvailable = false
            return false
        }
    }

    private func makeEngine(format: AVAudioFormat) throws -> AVAudioEngine {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        let engine = AVAudioEngine()
        engine.attach(effectsPlayer)
        engine.attach(musicPlayer)
        try engine.connectNode(effectsPlayer, to: engine.mainMixerNode, format: format)
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

    private func buffer(for effect: Effect) -> AVAudioPCMBuffer? {
        if let cached = bufferCache[effect] { return cached }
        guard let format else { return nil }
        let notes: [Note]
        let amplitude: Float
        switch effect {
        case .focus:
            notes = [Note(1318.5, 0.05)]
            amplitude = 0.06
        case .select:
            notes = [Note(880, 0.09)]
            amplitude = 0.18
        case .correct:
            notes = [Note(523.25, 0.1), Note(659.25, 0.1), Note(783.99, 0.1), Note(1046.5, 0.22)]
            amplitude = 0.22
        case .incorrect:
            // Soft and low rather than a harsh buzzer.
            notes = [Note(392.0, 0.14), Note(349.23, 0.22)]
            amplitude = 0.14
        case .reward:
            notes = [Note(783.99, 0.1), Note(1046.5, 0.1), Note(1318.5, 0.1), Note(1567.98, 0.3)]
            amplitude = 0.2
        case .turnChange:
            notes = [Note(659.25, 0.09), Note(880, 0.14)]
            amplitude = 0.16
        }
        let buffer = Self.makeBuffer(notes: notes, amplitude: amplitude, format: format)
        bufferCache[effect] = buffer
        return buffer
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
