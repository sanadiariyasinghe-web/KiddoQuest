import Foundation
import AudioToolbox
import UIKit

// MARK: - Sound Service
// Generates gentle system audio and haptics for rewards, button clicks, and feedback.
// Respects parent settings (soundEnabled).

final class SoundService {
    static let shared = SoundService()
    
    private init() {}
    
    private var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "sound_effects_enabled") as? Bool ?? true
    }
    
    // MARK: - Sound Effects
    func playCorrectSound() {
        guard isSoundEnabled else { return }
        // Cheerful native chime
        AudioServicesPlaySystemSound(1025)
        // Gentle success haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playTryAgainSound() {
        guard isSoundEnabled else { return }
        // Soft click / gentle reminder (never harsh buzzers)
        AudioServicesPlaySystemSound(1052)
        // Light haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func playButtonClick() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playRewardCelebration() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1026) // Fanfare / victory sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
