import AVFoundation
import UIKit

// MARK: - Sound Service
// Soft, friendly sound effects (synthesised chimes, like the tvOS app) plus gentle haptics
// for correct answers, gentle retries, button taps and rewards.
// Respects the parent "Sound Effects" setting. If audio can't start, it falls back to haptics only.

final class SoundService {
    static let shared = SoundService()

    enum Effect: CaseIterable {
        case correct, tryAgain, click, reward

        var notes: [ToneSynthesizer.Note] {
            switch self {
            case .correct:
                return [.init(523.25, 0.1), .init(659.25, 0.1), .init(783.99, 0.1), .init(1046.5, 0.22)]
            case .tryAgain:
                // Soft and low rather than a harsh buzzer
                return [.init(392.0, 0.14), .init(349.23, 0.22)]
            case .click:
                return [.init(880, 0.07)]
            case .reward:
                return [.init(783.99, 0.1), .init(1046.5, 0.1), .init(1318.5, 0.1), .init(1567.98, 0.3)]
            }
        }

        var amplitude: Float {
            switch self {
            case .correct: return 0.2
            case .tryAgain: return 0.12
            case .click: return 0.1
            case .reward: return 0.18
            }
        }
    }

    private var engine: AVAudioEngine?
    private let player = AVAudioPlayerNode()
    private var bufferCache: [Effect: AVAudioPCMBuffer] = [:]
    private var isAudioAvailable = true

    private init() {}

    private var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "sound_effects_enabled") as? Bool ?? true
    }

    // MARK: - Sound Effects
    func playCorrectSound() {
        play(.correct)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func playTryAgainSound() {
        play(.tryAgain)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func playButtonClick() {
        play(.click)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func playRewardCelebration() {
        play(.reward)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Playback
    private func play(_ effect: Effect) {
        guard isSoundEnabled, let buffer = buffer(for: effect), startEngineIfNeeded() else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            // A failure here just means this chime is skipped
            try? player.playAudio()
        }
    }

    private func buffer(for effect: Effect) -> AVAudioPCMBuffer? {
        if let cached = bufferCache[effect] { return cached }
        guard let format = ToneSynthesizer.format else { return nil }
        let buffer = ToneSynthesizer.makeBuffer(notes: effect.notes, amplitude: effect.amplitude, format: format)
        bufferCache[effect] = buffer
        return buffer
    }

    private func startEngineIfNeeded() -> Bool {
        guard isAudioAvailable, let format = ToneSynthesizer.format else { return false }
        if let engine, engine.isRunning { return true }

        do {
            let engine = try self.engine ?? makeEngine(format: format)
            self.engine = engine
            engine.prepare()
            try engine.start()
            return true
        } catch {
            // Fallback: haptics only
            isAudioAvailable = false
            return false
        }
    }

    private func makeEngine(format: AVAudioFormat) throws -> AVAudioEngine {
        // Ambient: mixes with the background music and respects the silent switch
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        let engine = AVAudioEngine()
        engine.attach(player)
        try engine.connectNode(player, to: engine.mainMixerNode, format: format)
        return engine
    }
}
