import SwiftUI

/// Avatar option with emoji and name for accessibility.
struct AvatarOption: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String

    var accessibilityLabel: String {
        "\(name) avatar"
    }
}

/// Avatar selection step of onboarding - lets the child pick their buddy.
struct AvatarSelectionView: View {
    @State private var selectedAvatar: AvatarOption?
    @State private var bounceAvatar: UUID?

    var onContinue: (String) -> Void

    private let avatars: [AvatarOption] = [
        AvatarOption(emoji: "🐻", name: "Bear"),
        AvatarOption(emoji: "🐰", name: "Bunny"),
        AvatarOption(emoji: "🦊", name: "Fox"),
        AvatarOption(emoji: "🦉", name: "Owl"),
        AvatarOption(emoji: "🐱", name: "Cat"),
        AvatarOption(emoji: "🐶", name: "Dog"),
        AvatarOption(emoji: "🐼", name: "Panda"),
        AvatarOption(emoji: "🦁", name: "Lion")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
        GridItem(.flexible(), spacing: L2RTheme.Spacing.md)
    ]

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Prompt
                promptView
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                // Avatar grid
                avatarGrid
                    .padding(.horizontal, L2RTheme.Spacing.lg)
                    .padding(.bottom, L2RTheme.Spacing.xl)

                // Selected avatar preview
                if let selected = selectedAvatar {
                    selectedPreview(avatar: selected)
                        .padding(.bottom, L2RTheme.Spacing.lg)
                        .transition(.opacity.combined(with: .scale))
                }

                // Continue button
                continueButton
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, L2RTheme.Spacing.lg)
        }
    }

    // MARK: - Prompt

    private var promptView: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            Text("🎉")
                .font(.system(size: 60))
                .bouncing()

            Text("Pick your buddy!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title1, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Avatar Grid

    private var avatarGrid: some View {
        LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.md) {
            ForEach(avatars) { avatar in
                avatarButton(avatar)
            }
        }
    }

    private func avatarButton(_ avatar: AvatarOption) -> some View {
        let isSelected = selectedAvatar?.id == avatar.id
        let isBouncing = bounceAvatar == avatar.id

        return Button {
            selectAvatar(avatar)
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(L2RTheme.primary, lineWidth: 4)
                }

                // Emoji
                Text(avatar.emoji)
                    .font(.system(size: 44))

                // Checkmark badge
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(L2RTheme.Status.success)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                )
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .frame(width: 80, height: 80)
            .scaleEffect(isBouncing ? 1.15 : (isSelected ? 1.05 : 1.0))
            .animation(L2RTheme.Animation.bounce, value: isBouncing)
            .animation(.easeInOut(duration: L2RTheme.Animation.fast), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(avatar.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Selected Preview

    private func selectedPreview(avatar: AvatarOption) -> some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            Text(avatar.emoji)
                .font(.system(size: L2RTheme.Typography.Size.title2))

            Text("\(avatar.name) is ready to learn with you!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .semibold))
                .foregroundStyle(L2RTheme.Status.success)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleContinue()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Text("Continue")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.xlarge)
            .background(
                Group {
                    if selectedAvatar != nil {
                        LinearGradient.ctaButton
                    } else {
                        Color.gray.opacity(0.4)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(
                color: selectedAvatar != nil ? L2RTheme.CTA.shadow.opacity(0.4) : .clear,
                radius: 6,
                x: 0,
                y: L2RTheme.Shadow.buttonDepth
            )
        }
        .disabled(selectedAvatar == nil)
        .animation(.easeInOut(duration: L2RTheme.Animation.fast), value: selectedAvatar != nil)
    }

    // MARK: - Actions

    private func selectAvatar(_ avatar: AvatarOption) {
        // Trigger bounce animation
        bounceAvatar = avatar.id

        // Update selection with animation
        withAnimation(L2RTheme.Animation.bounce) {
            selectedAvatar = avatar
        }

        // Reset bounce after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            bounceAvatar = nil
        }
    }

    private func handleContinue() {
        guard let avatar = selectedAvatar else { return }
        onContinue(avatar.emoji)
    }
}

#Preview {
    AvatarSelectionView { avatar in
        print("User selected avatar: \(avatar)")
    }
}
