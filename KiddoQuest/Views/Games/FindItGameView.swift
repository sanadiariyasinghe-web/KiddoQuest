import PhotosUI
import SwiftUI

// MARK: - Find It! (Vision)
// "Find something in your house": children photograph a real object or colour,
// and on-device Vision image classification checks it.

struct FindItGameView: View, CompactAdaptable {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = FindItViewModel()
    @State private var isShowingCamera = false
    @State private var pickedItem: PhotosPickerItem?
    /// Set per layout branch by `CompactLayoutReader` (see `FitsOrScrolls`).
    var isCompact = false

    var body: some View {
        GameFlowContainer(
            instructions: .findIt,
            navigationPath: $navigationPath,
            isFinished: viewModel.isGameCompleted,
            result: viewModel.result,
            onPlayAgain: {
                viewModel = FindItViewModel()
            }
        ) {
            CompactLayoutReader { compact($0).gameContent }
        }
        .navigationTitle("Find It!")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker { image in
                Task { await viewModel.check(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await viewModel.check(image)
                }
                pickedItem = nil
            }
        }
    }

    // MARK: - Game Content
    private var gameContent: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()

            GameScreenLayout(spacing: Theme.Spacing.medium) {
                HStack {
                    ProgressStarBar(stars: viewModel.starsEarned, maxStars: 3, starSize: 18)
                    Spacer()
                    Text("Find \(viewModel.currentIndex + 1)/\(viewModel.targets.count)")
                        .font(Theme.Typography.headline(size: 15))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.ColorPalette.cardBackground)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Theme.Spacing.medium)

                targetCard
                    .padding(.horizontal, Theme.Spacing.medium)

                // Grows to fill tall screens; a photo never makes the layout taller than ideal
                photoArea
                    .padding(.horizontal, Theme.Spacing.medium)
                    .frame(minHeight: isCompact ? 110 : 160, idealHeight: isCompact ? 130 : 260, maxHeight: .infinity)

            } controls: {
                MascotView(mood: viewModel.mascotMood, customMessage: viewModel.mascotMessage, size: 56)
                    .padding(.horizontal, Theme.Spacing.medium)

                actionButtons
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.bottom, Theme.Spacing.medium)
            }
            .padding(.top, Theme.Spacing.small)

            ParticleBurstView(isEmitting: $viewModel.showConfetti)
        }
    }

    /// What to find: a big picture or colour swatch with a short prompt.
    private var targetCard: some View {
        HStack(spacing: 16) {
            switch viewModel.currentTarget {
            case .object(_, let emoji, _):
                Text(emoji).font(.system(size: AdaptiveMetric.size(56, compact: isCompact)))
            case .color(let color):
                Circle()
                    .fill(color.swatch)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: color.swatch.opacity(0.5), radius: 6)
            }
            Text(viewModel.currentTarget.prompt)
                .font(Theme.Typography.title(size: 26))
                .foregroundStyle(Theme.ColorPalette.primaryText)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier("findIt.prompt")
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .combine)
    }

    /// The photo the child took, with "checking" and success states.
    private var photoArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.ColorPalette.cardBackground)
            if let photo = viewModel.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.large)
                            .stroke(viewModel.isShowingSuccess ? Theme.ColorPalette.successGreen : .clear, lineWidth: 6)
                    )
                    .accessibilityLabel("Your photo")
            } else {
                VStack(spacing: 10) {
                    Text("📷").font(.system(size: AdaptiveMetric.size(70, compact: isCompact)))
                    Text("Your photo goes here")
                        .font(Theme.Typography.body(size: 17))
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                }
            }
            if viewModel.isChecking {
                ProgressView()
                    .controlSize(.large)
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .accessibilityLabel("Checking your photo")
            }
            if viewModel.isShowingSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(.white, Theme.ColorPalette.successGreen)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipped()
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.feedback)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if CameraPicker.isCameraAvailable {
                PrimaryChildButton(title: "Take a photo", iconName: "camera.fill", backgroundColor: Theme.ColorPalette.shapesPurple) {
                    isShowingCamera = true
                }
                .disabled(viewModel.isChecking || viewModel.isShowingSuccess)
                .hintTarget(!viewModel.isChecking && !viewModel.isShowingSuccess)
                .accessibilityIdentifier("findIt.camera")
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label(CameraPicker.isCameraAvailable ? "Choose a photo" : "Choose a photo 📷", systemImage: "photo.on.rectangle")
                        .font(Theme.Typography.headline(size: 17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.ColorPalette.lettersBlue)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .disabled(viewModel.isChecking || viewModel.isShowingSuccess)
                .hintTarget(!CameraPicker.isCameraAvailable && !viewModel.isChecking && !viewModel.isShowingSuccess)
                .accessibilityIdentifier("findIt.choosePhoto")

                Button {
                    viewModel.skip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .font(Theme.Typography.headline(size: 17))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                        .frame(width: 110, height: 56)
                        .background(Theme.ColorPalette.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(viewModel.isChecking || viewModel.isShowingSuccess)
                .accessibilityIdentifier("findIt.skip")
            }
        }
    }
}
