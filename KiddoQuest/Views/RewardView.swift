import SwiftUI

struct RewardView: View {
    @Binding var navigationPath: NavigationPath
    @State private var coreData = CoreDataManager.shared
    @State private var stickerBook = StickerBook.shared
    @State private var starScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Celebration Banner
                    VStack(spacing: 12) {
                        Text("🎉")
                            .font(.system(size: 60))
                        
                        Text("Great Job, Explorer!")
                            .font(Theme.Typography.title(size: 28))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                        
                        Text("You earned shiny stars and unlocked learning badges!")
                            .font(Theme.Typography.body(size: 16))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Large 3-Star Celebration Bar
                        HStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Theme.ColorPalette.starGold)
                                    .scaleEffect(starScale)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    stickerBookSection
                    
                    // Badges Grid
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Earned Badges")
                            .font(Theme.Typography.headline(size: 20))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                            .padding(.horizontal, Theme.Spacing.medium)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 140, maximum: 180), spacing: Theme.Spacing.medium)
                            ],
                            spacing: Theme.Spacing.medium
                        ) {
                            ForEach(coreData.badges) { badge in
                                badgeCard(for: badge)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.medium)
                    }
                    
                    // Bottom Navigation Buttons
                    VStack(spacing: 12) {
                        PrimaryChildButton(
                            title: "Back to World Map",
                            iconName: "globe.americas.fill",
                            backgroundColor: Theme.ColorPalette.lettersBlue
                        ) {
                            navigationPath = NavigationPath()
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.bottom, Theme.Spacing.xlarge)
                }
                .padding(.top, Theme.Spacing.medium)
            }
        }
        .navigationTitle("Rewards & Badges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            SoundService.shared.playRewardCelebration()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                starScale = 1.0
            }
        }
    }
    
    // MARK: - Sticker Book
    /// One page with a slot for every sticker; collected ones are shown, the rest wait as "?".
    private var stickerBookSection: some View {
        let collected = stickerBook.collectedEmojis
        
        return VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Text("My Sticker Book")
                    .font(Theme.Typography.headline(size: 20))
                    .foregroundStyle(Theme.ColorPalette.primaryText)
                Spacer()
                Text("\(collected.count) / \(StickerBook.allStickers.count)")
                    .font(Theme.Typography.headline(size: 16))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(StickerBook.allStickers, id: \.self) { emoji in
                    let isCollected = collected.contains(emoji)
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.minimum)
                            .fill(isCollected ? Theme.ColorPalette.numbersYellow.opacity(0.2) : Theme.ColorPalette.cardBorder.opacity(0.5))
                        if isCollected {
                            Text(emoji)
                                .font(.system(size: 40))
                        } else {
                            Text("?")
                                .font(Theme.Typography.title(size: 26))
                                .foregroundStyle(Theme.ColorPalette.secondaryText.opacity(0.5))
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel(isCollected ? "Sticker \(emoji)" : "Empty sticker space")
                }
            }
            
            if collected.isEmpty {
                Text("Finish a game to get your first sticker!")
                    .font(Theme.Typography.body(size: 15))
                    .foregroundStyle(Theme.ColorPalette.secondaryText)
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
        .padding(.horizontal, Theme.Spacing.medium)
    }
    
    // MARK: - Badge Card
    private func badgeCard(for badge: Badge) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Theme.ColorPalette.starGold.opacity(0.25) : Color.gray.opacity(0.15))
                    .frame(width: 58, height: 58)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(badge.isUnlocked ? Theme.ColorPalette.starGold : Color.gray)
            }
            
            Text(badge.name)
                .font(Theme.Typography.caption(size: 14))
                .foregroundStyle(Theme.ColorPalette.primaryText)
                .multilineTextAlignment(.center)
            
            Text(badge.isUnlocked ? "Unlocked" : "Locked")
                .font(Theme.Typography.caption(size: 11))
                .foregroundStyle(badge.isUnlocked ? Theme.ColorPalette.successGreen : Theme.ColorPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(badge.isUnlocked ? Theme.ColorPalette.starGold.opacity(0.4) : Theme.ColorPalette.cardBorder, lineWidth: 1.5)
        )
    }
}
