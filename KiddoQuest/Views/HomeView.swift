import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @State private var viewModel = HomeViewModel()
    @State private var cloudOffset: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            // Decorative background clouds
            VStack {
                HStack {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(.white.opacity(0.4))
                        .offset(x: cloudOffset)
                    Spacer()
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.35))
                        .offset(x: -cloudOffset)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                Spacer()
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.large) {
                    // Top App Header & Quick Nav
                    headerBar
                    
                    // Welcome Title & Subtitle
                    VStack(spacing: 6) {
                        Text("KiddoQuest")
                            .font(Theme.Typography.title(size: 34))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                        
                        Text("Play • Learn • Discover!")
                            .font(Theme.Typography.headline(size: 18))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                    }
                    .padding(.top, 4)
                    
                    // Interactive Islands Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 160, maximum: 220), spacing: Theme.Spacing.medium)
                        ],
                        spacing: Theme.Spacing.medium
                    ) {
                        ForEach(viewModel.categories) { category in
                            islandCard(for: category)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    // AR Learning Banner
                    arBanner
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.bottom, Theme.Spacing.xlarge)
                }
                .padding(.vertical, Theme.Spacing.medium)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("KiddoQuest World")
                    .font(Theme.Typography.headline(size: 16))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                cloudOffset = 18
                bounceOffset = -6
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            // Profile Button
            Button {
                navigationPath.append(AppRoute.profile)
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedProfile.avatar)
                        .font(.system(size: 26))
                    Text(viewModel.selectedProfile.name)
                        .font(Theme.Typography.headline(size: 16))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }
            .accessibilityLabel("Child profile: \(viewModel.selectedProfile.name)")
            
            Spacer()
            
            // Total Stars Counter
            Button {
                navigationPath.append(AppRoute.rewards)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Theme.ColorPalette.starGold)
                    Text("\(viewModel.totalStars)")
                        .font(Theme.Typography.headline(size: 16))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.ColorPalette.cardBackground)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }
            .accessibilityLabel("Total stars: \(viewModel.totalStars)")
            
            // Parent Settings Button
            Button {
                navigationPath.append(AppRoute.parentSettings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            }
            .accessibilityLabel("Parent settings")
        }
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    // MARK: - Island Card
    private func islandCard(for category: IslandCategory) -> some View {
        let progress = viewModel.progressFor(category: category)
        
        return Button {
            navigationPath.append(AppRoute.category(category))
        } label: {
            VStack(spacing: 12) {
                // Island Icon with subtle bounce
                ZStack {
                    Circle()
                        .fill(category.themeColor.opacity(0.25))
                        .frame(width: 80, height: 80)
                    
                    Text(category.icon)
                        .font(.system(size: 42))
                        .offset(y: bounceOffset)
                }
                
                Text(category.shortTitle)
                    .font(Theme.Typography.headline(size: 18))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                
                // Stars Row
                HStack(spacing: 3) {
                    ForEach(0..<progress.maxStars, id: \.self) { index in
                        Image(systemName: index < progress.stars ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(index < progress.stars ? Theme.ColorPalette.starGold : Theme.ColorPalette.secondaryText.opacity(0.4))
                    }
                }
                
                // Completion Text
                Text("\(progress.percentage)% Complete")
                    .font(Theme.Typography.caption())
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(category.themeColor.opacity(0.4), lineWidth: 3)
            )
            .shadow(color: category.themeColor.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(category.title), \(progress.percentage) percent complete, \(progress.stars) of \(progress.maxStars) stars earned")
    }
    
    // MARK: - AR Banner
    private var arBanner: some View {
        Button {
            navigationPath.append(AppRoute.arLearning(nil))
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.ColorPalette.arOrange.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image(systemName: "arkit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.ColorPalette.arOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AR Learning Mode")
                        .font(Theme.Typography.headline(size: 18))
                        .foregroundStyle(Theme.ColorPalette.primaryText)
                    Text("Explore letters, shapes & animals in real 3D space!")
                        .font(Theme.Typography.caption())
                        .foregroundStyle(Theme.ColorPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.ColorPalette.arOrange)
            }
            .padding(16)
            .background(Theme.ColorPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.ColorPalette.arOrange.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Theme.ColorPalette.arOrange.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Open AR Learning Mode")
    }
}

// MARK: - Reusable Bouncy Button Style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
