import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Learning View (Primary Emerging Technology)
// Integrates ARKit and RealityKit meaningfully into learning games for letters, shapes, and animals.

struct ARLearningView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = ARLearningViewModel()
    @State private var selectedTab: ARMode = .letterHunt
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.small) {
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
                
                // AR Camera View or Fallback Interactive Canvas
                if viewModel.isARSupported {
                    actualARCameraView
                } else {
                    fallbackSpatialView
                }
                
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
            
            // Confetti Burst Overlay
            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
        .navigationTitle("AR Learning Mode")
        .navigationBarTitleDisplayMode(.inline)
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
            Label(
                viewModel.isSurfaceFound ? "Tap the 3D cards on the table!" : "Point at a table or the floor 📱",
                systemImage: viewModel.isSurfaceFound ? "hand.tap.fill" : "viewfinder"
            )
            .font(Theme.Typography.headline(size: 15))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.black.opacity(0.45))
            .clipShape(Capsule())
            .padding(.top, 12)
            .allowsHitTesting(false)
        }
        .padding(.horizontal, Theme.Spacing.medium)
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
            
            // Floating 3D/2D Learning Objects
            ForEach(viewModel.targetObjects) { item in
                arObjectCard(for: item)
                    .offset(x: item.xPosition, y: item.yPosition)
            }
        }
        .frame(maxHeight: .infinity)
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
