import SwiftUI

extension EnvironmentValues {
    /// Controls looping "ambient" motion such as Buddy's idle bob, his
    /// celebration dance and the drifting background shapes. Turned off for
    /// UI tests (so XCTest can detect when the app is idle) and in Calm Mode.
    @Entry var tvAmbientMotionEnabled: Bool = true

    /// Calm Mode (a parent setting): no confetti bursts and no ambient motion.
    @Entry var tvCalmMode: Bool = false

    /// Pointing-hand hints. Kept on in Calm Mode (they guide, not decorate);
    /// turned off only for UI tests.
    @Entry var tvHintsEnabled: Bool = true
}
