import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Learning View (Primary Emerging Technology)
// Integrates ARKit and RealityKit meaningfully into learning games for letters, shapes, and animals.

struct ARLearningView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ARLearningViewModel()
    @State private var selectedTab: ARMode = .letterHunt
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            // Portrait: one column, as designed. iPhone landscape: the camera on the left,
            // the challenge and buttons on the right, so the AR view keeps a usable size.
            if verticalSizeClass == .compact {
                HStack(alignment: .top, spacing: 0) {
                    arArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, Theme.Spacing.small)
                    VStack(spacing: Theme.Spacing.small) {
                        topControls
                        bottomControls
                    }
                    .padding(.vertical, Theme.Spacing.small)
                    .scrollsWhenNeeded()
                    .frame(width: 360)
                }
            } else {
                VStack(spacing: Theme.Spacing.small) {
                    topControls
                    arArea
                    bottomControls
                }
            }
            
            // Confetti Burst Overlay
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
        .navigationTitle("AR Learning Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Screen Sections
    /// Safety banner, mode picker and the current challenge.
    @ViewBuilder
    private var topControls: some View {
        // Child Safety Instruction Banner (Section 32)
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.ColorPalette.numbersYellow)
            
            Text("Move your device slowly and make sure you are in a safe place.")
                .font(Theme.Typography.caption())
                .foregroundStyle(Theme.ColorPalette.primaryText)
            
            Spacer()
        }
        .padding(12)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, Theme.Spacing.medium)
        
        // AR Mode Segmented Selector (Letter Hunt, Shape Hunt, Animal Discovery)
        Picker("AR Mode", selection: $selectedTab) {
            ForEach(ARMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.medium)
        .onChange(of: selectedTab) { _, newValue in
            viewModel.switchMode(to: newValue)
        }
        
        // Instruction Card
        HStack(spacing: 12) {
            Text(viewModel.instructionText)
                .font(Theme.Typography.title(size: 22))
                .foregroundStyle(Theme.ColorPalette.primaryText)
            
            Spacer()
            
            // Found counter
            Text("Found: \(viewModel.foundCount)/\(viewModel.totalRequired)")
                .font(Theme.Typography.headline(size: 15))
                .foregroundStyle(Theme.ColorPalette.arOrange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.ColorPalette.arOrange.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .padding(.horizontal, Theme.Spacing.medium)
    }

    /// The AR camera (or 2D fallback) with the completion card on top.
    private var arArea: some View {
        // AR Camera View or Fallback Interactive Canvas
        ZStack {
            if viewModel.isARSupported {
                actualARCameraView
            } else {
                fallbackSpatialView
            }

            if viewModel.isCompleted {
                completionCard
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.isCompleted)
    }

    /// Buddy and the Exit / Play Again buttons.
    @ViewBuilder
    private var bottomControls: some View {
        // Mascot Feedback
        MascotView(
            mood: viewModel.mascotMood,
            customMessage: viewModel.mascotMessage,
            size: 54
        )
        .padding(.horizontal, Theme.Spacing.medium)
        
        // Bottom Persistent "Exit AR" & "Celebrate" Buttons
        HStack(spacing: 12) {
            if viewModel.isCompleted {
                PrimaryChildButton(
                    title: "Play Again",
                    iconName: "arrow.clockwise",
                    backgroundColor: Theme.ColorPalette.animalsGreen
                ) {
                    viewModel.playAgain()
                }
                .accessibilityIdentifier("ar.playAgain")

                PrimaryChildButton(
                    title: "View AR Rewards",
                    iconName: "trophy.fill",
                    backgroundColor: Theme.ColorPalette.arOrange
                ) {
                    navigationPath.append(AppRoute.rewards)
                }
            } else {
                Button {
                    navigationPath = NavigationPath()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Exit AR to World Map")
                            .font(Theme.Typography.headline(size: 16))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.ColorPalette.softRedWarning)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.medium)
    }

    // MARK: - Actual AR Camera View (for supported devices)
    /// Real AR: 3D picture cards are placed on a detected table or floor and tapped directly.
    private var actualARCameraView: some View {
        ZStack(alignment: .top) {
            ARRealityViewRepresentable(viewModel: viewModel)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.large)
                        .stroke(Theme.ColorPalette.arOrange, lineWidth: 3)
                )

            // Simple status so the child knows what to do next
            Label(arStatus.text, systemImage: arStatus.symbol)
                .font(Theme.Typography.headline(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.45))
                .clipShape(Capsule())
                .padding(.top, 12)
                .allowsHitTesting(false)
                .accessibilityIdentifier("ar.status")
        }
        .overlay(alignment: .bottomTrailing) {
            // Put the objects somewhere else (tap a new spot afterwards)
            if viewModel.isPlaced && !viewModel.isCompleted {
                Button {
                    viewModel.isPlaced = false
                } label: {
                    Label("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(Theme.Typography.headline(size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.ColorPalette.arOrange)
                        .clipShape(Capsule())
                }
                .buttonStyle(BouncyButtonStyle())
                .padding(12)
                .accessibilityLabel("Move the learning objects")
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
    }

    /// Step-by-step guidance: find a surface → tap it to place → tap the 3D objects.
    private var arStatus: (text: String, symbol: String) {
        if !viewModel.isSurfaceFound {
            return ("Point at a table or the floor 📱", "viewfinder")
        } else if !viewModel.isPlaced {
            return ("Tap the table to place the toys! 👆", "hand.point.up.left.fill")
        } else {
            return ("Tap the 3D objects to explore!", "hand.tap.fill")
        }
    }

    // MARK: - Completion Card
    /// Stars and the new sticker after the last "Find the …!" challenge.
    private var completionCard: some View {
        VStack(spacing: 12) {
            Text("Great Job! 🎉")
                .font(Theme.Typography.title(size: 28))
                .foregroundStyle(Theme.ColorPalette.primaryText)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < viewModel.starsEarned ? "star.fill" : "star")
                        .font(.system(size: 34))
                        .foregroundStyle(index < viewModel.starsEarned ? Theme.ColorPalette.starGold : Theme.ColorPalette.secondaryText.opacity(0.4))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(viewModel.starsEarned) of 3 stars")

            Text("You found \(viewModel.foundCount) of \(viewModel.totalRequired)!")
                .font(Theme.Typography.headline(size: 17))
                .foregroundStyle(Theme.ColorPalette.secondaryText)

            if let sticker = viewModel.newSticker {
                HStack(spacing: 10) {
                    Text(sticker.emoji)
                        .font(.system(size: 40))
                    Text("New sticker!")
                        .font(Theme.Typography.headline(size: 17))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(24)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
        .padding(Theme.Spacing.large)
        .accessibilityIdentifier("ar.completion")
    }
    
    // MARK: - Fallback Spatial Simulated View (Section 10 Fallback Requirement)
    private var fallbackSpatialView: some View {
        ZStack {
            // Simulated room background with grid
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    VStack {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.ColorPalette.secondaryText)
                            Text("Simulated Learning Room (AR Unavailable on this device)")
                                .font(Theme.Typography.caption(size: 12))
                                .foregroundStyle(Theme.ColorPalette.secondaryText)
                            Spacer()
                        }
                        .padding(12)
                        Spacer()
                    }
                )
            
            // Floating 3D/2D Learning Objects, spread to fit the room on any screen size
            // (positions are designed for a room about 280 × 260 pt and scale down when smaller)
            GeometryReader { proxy in
                // Keep the caption strip at the top free
                let captionHeight: CGFloat = 44
                let roomHeight = max(proxy.size.height - captionHeight, 1)
                let scale = min(1, proxy.size.width / 280, roomHeight / 260)
                ZStack {
                    ForEach(viewModel.targetObjects) { item in
                        arObjectCard(for: item)
                            .scaleEffect(max(scale, 0.7))
                            .offset(x: item.xPosition * scale, y: item.yPosition * scale)
                    }
                }
                .frame(width: proxy.size.width, height: roomHeight)
                .position(x: proxy.size.width / 2, y: captionHeight + roomHeight / 2)
            }
        }
        .frame(minHeight: 200, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    // MARK: - AR Virtual Object Card
    private func arObjectCard(for item: ARObjectItem) -> some View {
        Button {
            viewModel.tapObject(item)
        } label: {
            ZStack {
                Circle()
                    .fill(
                        item.isDiscovered
                        ? Theme.ColorPalette.successGreen.opacity(0.3)
                        : Theme.ColorPalette.cardBackground
                    )
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                item.isDiscovered
                                ? Theme.ColorPalette.successGreen
                                : Theme.ColorPalette.arOrange,
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: Theme.ColorPalette.arOrange.opacity(0.2), radius: 6, y: 3)
                
                Text(item.display)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(item.isDiscovered ? Theme.ColorPalette.successGreen : Theme.ColorPalette.primaryText)
            }
            .scaleEffect(item.isDiscovered ? 1.15 : 1.0)
            .floating(yOffset: 5, duration: 1.8)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: item.isDiscovered)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(item.isDiscovered)
        .accessibilityLabel("\(item.name), \(item.isDiscovered ? "found" : "tap to discover")")
    }
}

// MARK: - ARKit + RealityKit View
struct ARRealityViewRepresentable: UIViewRepresentable {
    var viewModel: ARLearningViewModel

    func makeCoordinator() -> ARSceneController {
        ARSceneController(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.attach(to: arView)
        context.coordinator.update()
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Reading these tells SwiftUI to call update when the mode or found items change
        _ = viewModel.layoutID
        _ = viewModel.targetObjects
        context.coordinator.viewModel = viewModel
        context.coordinator.update()
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneController) {
        coordinator.pause()
    }
}
