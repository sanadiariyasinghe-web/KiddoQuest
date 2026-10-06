import SwiftUI

// MARK: - Calm Mode
// A parent setting that turns off confetti and repeating floating/bouncing animations.
// Helps sensitive children (and older devices). It also turns on automatically
// when the system "Reduce Motion" accessibility setting is enabled.

enum CalmMode {
    static let settingsKey = "calm_mode_enabled"
}

/// Reads whether Calm Mode is active inside any SwiftUI view or modifier:
/// `@CalmModeEnabled private var isCalm`
@propertyWrapper
struct CalmModeEnabled: DynamicProperty {
    @AppStorage(CalmMode.settingsKey) private var isTurnedOnByParent = false
    @Environment(\.accessibilityReduceMotion) private var isReduceMotionOn

    var wrappedValue: Bool {
        isTurnedOnByParent || isReduceMotionOn
    }
}
