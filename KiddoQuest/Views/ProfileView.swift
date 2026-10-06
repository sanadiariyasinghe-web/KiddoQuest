import SwiftUI

struct ProfileView: View {
    @Binding var navigationPath: NavigationPath
    @State private var coreData = CoreDataManager.shared
    @State private var isEditingName: Bool = false
    @State private var editedName: String = ""
    
    let sampleAvatars = ["🦁", "🐯", "🐼", "🦊", "🐰", "🚀", "🦄", "🐶"]
    
    var body: some View {
        ZStack {
            Theme.ColorPalette.mainBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Avatar & Name Card
                    VStack(spacing: 12) {
                        Text(coreData.currentProfile.avatar)
                            .font(.system(size: 80))
                            .padding()
                            .background(Theme.ColorPalette.animalsGreen.opacity(0.2))
                            .clipShape(Circle())
                        
                        HStack(spacing: 8) {
                            Text(coreData.currentProfile.name)
                                .font(Theme.Typography.title(size: 28))
                                .foregroundStyle(Theme.ColorPalette.primaryText)
                            
                            Button {
                                editedName = coreData.currentProfile.name
                                isEditingName = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.ColorPalette.lettersBlue)
                            }
                            .accessibilityLabel("Edit name")
                        }
                        
                        Text("Age \(coreData.currentProfile.age) • Little Adventurer")
                            .font(Theme.Typography.headline(size: 16))
                            .foregroundStyle(Theme.ColorPalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    // Choose Avatar Row
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pick Your Buddy Avatar")
                            .font(Theme.Typography.headline(size: 16))
                            .foregroundStyle(Theme.ColorPalette.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(sampleAvatars, id: \.self) { avatar in
                                    Button {
                                        withAnimation(.spring()) {
                                            coreData.updateProfile(
                                                name: coreData.currentProfile.name,
                                                avatar: avatar,
                                                age: coreData.currentProfile.age
                                            )
                                        }
                                        SoundService.shared.playButtonClick()
                                    } label: {
                                        Text(avatar)
                                            .font(.system(size: 32))
                                            .frame(width: 54, height: 54)
                                            .background(coreData.currentProfile.avatar == avatar ? Theme.ColorPalette.numbersYellow.opacity(0.3) : Theme.ColorPalette.cardBackground)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(coreData.currentProfile.avatar == avatar ? Theme.ColorPalette.numbersYellow : Color.clear, lineWidth: 3)
                                            )
                                    }
                                    .accessibilityLabel("Avatar \(avatar)")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.ColorPalette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .padding(.horizontal, Theme.Spacing.medium)
                    
                    // Stats Summary Card
                    HStack(spacing: Theme.Spacing.medium) {
                        statTile(title: "Total Stars", value: "\(coreData.currentProfile.totalStars)", icon: "star.fill", color: Theme.ColorPalette.starGold)
                        statTile(title: "Badges", value: "\(coreData.badges.filter { $0.isUnlocked }.count)", icon: "trophy.fill", color: Theme.ColorPalette.numbersYellow)
                        statTile(title: "Completed", value: "\(coreData.recentSessions.count)", icon: "checkmark.seal.fill", color: Theme.ColorPalette.successGreen)
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                }
                .padding(.top, Theme.Spacing.medium)
                // Comfortable reading width on iPad and in landscape
                .frame(maxWidth: Theme.Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Theme.Spacing.xlarge)
            }
        }
        .navigationTitle("Child Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Change Explorer Name", isPresented: $isEditingName) {
            TextField("Name", text: $editedName)
            Button("Save") {
                if !editedName.trimmingCharacters(in: .whitespaces).isEmpty {
                    coreData.updateProfile(
                        name: editedName.trimmingCharacters(in: .whitespaces),
                        avatar: coreData.currentProfile.avatar,
                        age: coreData.currentProfile.age
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(color)
            
            Text(value)
                .font(Theme.Typography.title(size: 22))
                .foregroundStyle(Theme.ColorPalette.primaryText)
            
            Text(title)
                .font(Theme.Typography.caption(size: 12))
                .foregroundStyle(Theme.ColorPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.ColorPalette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
