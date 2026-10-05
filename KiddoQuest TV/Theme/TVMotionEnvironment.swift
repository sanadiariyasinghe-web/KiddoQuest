import SwiftUI

extension EnvironmentValues {
    /// Controls looping "ambient" motion such as Buddy's idle bob and the
    /// drifting background shapes. Turned off for UI tests so XCTest can
    /// detect when the app is idle; feedback animations are unaffected.
    @Entry var tvAmbientMotionEnabled: Bool = true
}
