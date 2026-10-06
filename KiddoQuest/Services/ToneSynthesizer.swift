import AVFoundation

// MARK: - Tone Synthesizer
// Renders simple notes into audio buffers at runtime (sine waves with a soft, bell-like fade).
// Shared by the background music and the sound effects, so the app ships no audio files.

enum ToneSynthesizer {
    struct Note {
        let frequency: Double
        let duration: Double

        init(_ frequency: Double, _ duration: Double) {
            self.frequency = frequency
            self.duration = duration
        }
    }

    static let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

    /// Renders notes into a mono PCM buffer with a soft bell-like envelope.
    /// A frequency of 0 renders silence (a rest).
    static func makeBuffer(notes: [Note], amplitude: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
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
