#if DEBUG
import SwiftUI

// MARK: - Responsive Layout Previews (debug only)
// Renders key screens at the sizes KiddoQuest must support, so clipping or
// overlapping can be spotted without booting several simulators.

/// A device size (in points) plus the size classes that device reports.
struct PreviewDevice {
    let name: String
    let size: CGSize
    let horizontal: UserInterfaceSizeClass
    let vertical: UserInterfaceSizeClass

    static let smallPhone = PreviewDevice(name: "iPhone SE", size: CGSize(width: 375, height: 667), horizontal: .compact, vertical: .regular)
    static let phoneLandscape = PreviewDevice(name: "iPhone landscape", size: CGSize(width: 844, height: 390), horizontal: .regular, vertical: .compact)
    static let largePhone = PreviewDevice(name: "iPhone Pro Max", size: CGSize(width: 440, height: 956), horizontal: .compact, vertical: .regular)
    static let iPadPortrait = PreviewDevice(name: "iPad portrait", size: CGSize(width: 820, height: 1180), horizontal: .regular, vertical: .regular)
    static let iPadLandscape = PreviewDevice(name: "iPad landscape", size: CGSize(width: 1180, height: 820), horizontal: .regular, vertical: .regular)
}

/// Lays a screen out exactly as it would be on `device`, inside a navigation stack.
struct DevicePreview<Content: View>: View {
    let device: PreviewDevice
    /// Games open in the play phase; set false to see the instructions card.
    var startsPlaying = true
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            content
        }
        .environment(\.horizontalSizeClass, device.horizontal)
        .environment(\.verticalSizeClass, device.vertical)
        .environment(\.gameFlowPreviewStartsPlaying, startsPlaying)
        .frame(width: device.size.width, height: device.size.height)
    }
}

private let previewPath = Binding.constant(NavigationPath())

/// Every iOS game, in the order they appear on the islands.
@ViewBuilder
private func game(_ index: Int) -> some View {
    switch index {
    case 0: CountingPopGameView(navigationPath: previewPath)
    case 1: DragMatchGameView(category: .numbers, navigationPath: previewPath)
    case 2: DragMatchGameView(category: .letters, navigationPath: previewPath)
    case 3: LetterShapeHuntGameView(isShapeMode: false, navigationPath: previewPath)
    case 4: ColoringGameView(navigationPath: previewPath)
    case 5: ShapeSortGameView(navigationPath: previewPath)
    case 6: FindItGameView(navigationPath: previewPath)
    case 7: AnimalPictureGameView(game: .feedAnimals, navigationPath: previewPath)
    default: AnimalPictureGameView(game: .animalShadows, navigationPath: previewPath)
    }
}

private func gameRow(_ indices: [Int], on device: PreviewDevice) -> some View {
    HStack(alignment: .top, spacing: 8) {
        ForEach(indices, id: \.self) { index in
            DevicePreview(device: device) { game(index) }
                .border(.gray)
        }
    }
}

#Preview("Games 1 – iPhone SE", traits: .sizeThatFitsLayout) { gameRow([0, 1, 2, 3, 4], on: .smallPhone) }
#Preview("Games 2 – iPhone SE", traits: .sizeThatFitsLayout) { gameRow([5, 6, 7, 8], on: .smallPhone) }
#Preview("Games 1 – iPhone landscape", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) { gameRow([0, 1], on: .phoneLandscape); gameRow([2, 3], on: .phoneLandscape); gameRow([4], on: .phoneLandscape) }
}
#Preview("Games 2 – iPhone landscape", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) { gameRow([5, 6], on: .phoneLandscape); gameRow([7, 8], on: .phoneLandscape) }
}
#Preview("Games – iPad portrait", traits: .sizeThatFitsLayout) { gameRow([0, 2, 4, 7], on: .iPadPortrait) }
// Large text: render this one with the canvas "Dynamic Type" variant set to an accessibility size
// (KiddoQuest fonts scale through UIFontMetrics, up to 1.5×).
#Preview("Games – iPhone SE, large text", traits: .sizeThatFitsLayout) { gameRow([0, 3, 5, 7], on: .smallPhone) }
/// Non-game screens: Home, island, game list, AR, welcome, break, rewards, settings, instructions.
@ViewBuilder
private func screen(_ index: Int) -> some View {
    switch index {
    case 0: HomeView(navigationPath: previewPath)
    case 1: CategoryView(category: .shapes, navigationPath: previewPath)
    case 2: GameListView(category: .animals, navigationPath: previewPath)
    case 3: ARLearningView(navigationPath: previewPath)
    case 4: WelcomeView { }
    case 5: BreakTimeView { }
    case 6: RewardView(navigationPath: previewPath)
    case 7: ParentSettingsView(navigationPath: previewPath)
    default: FindItGameView(navigationPath: previewPath)
    }
}

private func screenRow(_ indices: [Int], on device: PreviewDevice) -> some View {
    HStack(alignment: .top, spacing: 8) {
        ForEach(indices, id: \.self) { index in
            // The last one shows a game's instructions card
            DevicePreview(device: device, startsPlaying: index != 8) { screen(index) }
                .border(.gray)
        }
    }
}

#Preview("Screens 1 – iPhone SE", traits: .sizeThatFitsLayout) { screenRow([0, 1, 2, 3, 4], on: .smallPhone) }
#Preview("Screens 2 – iPhone SE", traits: .sizeThatFitsLayout) { screenRow([5, 6, 7, 8], on: .smallPhone) }
#Preview("Screens 1 – iPhone landscape", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) { screenRow([0, 1], on: .phoneLandscape); screenRow([2, 3], on: .phoneLandscape); screenRow([4], on: .phoneLandscape) }
}
#Preview("Screens 2 – iPhone landscape", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) { screenRow([5, 6], on: .phoneLandscape); screenRow([7, 8], on: .phoneLandscape) }
}
#Preview("Screens – iPad landscape", traits: .sizeThatFitsLayout) { screenRow([0, 3, 8], on: .iPadLandscape) }
#endif


