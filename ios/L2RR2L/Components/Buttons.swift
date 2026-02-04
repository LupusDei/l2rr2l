import SwiftUI

// MARK: - Primary Button

/// Large, colorful button for main CTAs with gradient background and press animation.
struct PrimaryButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var gradient: LinearGradient = .ctaButton
    var shadowColor: Color = L2RTheme.CTA.shadow
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    private var effectiveDisabled: Bool {
        isDisabled || isLoading
    }

    var body: some View {
        Button(action: performAction) {
            buttonContent
        }
        .buttonStyle(PrimaryButtonStyle(
            isPressed: $isPressed,
            isDisabled: effectiveDisabled,
            gradient: gradient,
            shadowColor: shadowColor,
            reduceMotion: reduceMotion
        ))
        .disabled(effectiveDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(effectiveDisabled ? .isButton : [])
    }

    private var buttonContent: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            if isLoading {
                LoadingSpinner(size: .small, color: .white)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: L2RTheme.Layout.buttonHeight)
    }

    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), loading"
        } else if isDisabled {
            return "\(title), disabled"
        }
        return title
    }

    private func performAction() {
        guard !effectiveDisabled else { return }
        HapticService.shared.buttonTap()
        action()
    }
}

// MARK: - Primary Button Style

private struct PrimaryButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool
    let gradient: LinearGradient
    let shadowColor: Color
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(gradient)
                    .opacity(isDisabled ? 0.5 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            .shadow(
                color: shadowColor.opacity(isDisabled ? 0.2 : 0.4),
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Secondary Button

/// Outlined/subtle button for secondary actions.
struct SecondaryButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var color: Color = L2RTheme.primary
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    private var effectiveDisabled: Bool {
        isDisabled || isLoading
    }

    var body: some View {
        Button(action: performAction) {
            buttonContent
        }
        .buttonStyle(SecondaryButtonStyle(
            isPressed: $isPressed,
            isDisabled: effectiveDisabled,
            color: color,
            reduceMotion: reduceMotion
        ))
        .disabled(effectiveDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(effectiveDisabled ? .isButton : [])
    }

    private var buttonContent: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            if isLoading {
                LoadingSpinner(size: .small, color: color)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
        }
        .foregroundStyle(effectiveDisabled ? color.opacity(0.5) : color)
        .frame(maxWidth: .infinity)
        .frame(height: L2RTheme.Layout.buttonHeight)
    }

    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), loading"
        } else if isDisabled {
            return "\(title), disabled"
        }
        return title
    }

    private func performAction() {
        guard !effectiveDisabled else { return }
        HapticService.shared.buttonTap()
        action()
    }
}

// MARK: - Secondary Button Style

private struct SecondaryButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool
    let color: Color
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(isDisabled ? color.opacity(0.3) : color, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Game Button

/// Large, playful button for game selection with emoji icon support and bouncy animation.
struct GameButton: View {
    let title: String
    var emoji: String?
    var systemIcon: String?
    var gradient: LinearGradient = .ctaButton
    var shadowColor: Color = L2RTheme.CTA.shadow
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isWiggling = false

    var body: some View {
        Button(action: performAction) {
            VStack(spacing: L2RTheme.Spacing.sm) {
                iconView
                titleView
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, L2RTheme.Spacing.lg)
            .padding(.horizontal, L2RTheme.Spacing.md)
        }
        .buttonStyle(GameButtonStyle(
            gradient: gradient,
            shadowColor: shadowColor,
            reduceMotion: reduceMotion
        ))
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to play")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if !reduceMotion {
                isWiggling = true
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let emoji = emoji {
            Text(emoji)
                .font(.system(size: 48))
                .rotationEffect(.degrees(isWiggling ? 5 : -5))
                .animation(L2RTheme.Animation.wiggle, value: isWiggling)
        } else if let systemIcon = systemIcon {
            Image(systemName: systemIcon)
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(isWiggling ? 5 : -5))
                .animation(L2RTheme.Animation.wiggle, value: isWiggling)
        }
    }

    private var titleView: some View {
        Text(title)
            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    private func performAction() {
        HapticService.shared.mediumImpact()
        action()
    }
}

// MARK: - Game Button Style

private struct GameButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let shadowColor: Color
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.xlarge)
                    .fill(gradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.xlarge))
            .shadow(
                color: shadowColor.opacity(0.4),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: configuration.isPressed)
    }
}

// MARK: - Text Button

/// Simple text button for tertiary actions like "Skip" or "Cancel".
struct TextButton: View {
    let title: String
    var color: Color = L2RTheme.primary
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: performAction) {
            Text(title)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(isDisabled ? color.opacity(0.5) : color)
                .frame(minHeight: L2RTheme.TouchTarget.minimum)
        }
        .disabled(isDisabled)
        .accessibilityLabel(isDisabled ? "\(title), disabled" : title)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isDisabled ? .isButton : [])
    }

    private func performAction() {
        guard !isDisabled else { return }
        HapticService.shared.selectionFeedback()
        action()
    }
}

// MARK: - Icon Button

/// Circular button with an icon, useful for actions like close, back, settings.
struct IconButton: View {
    let icon: String
    var size: CGFloat = L2RTheme.TouchTarget.comfortable
    var iconSize: CGFloat = 20
    var backgroundColor: Color = L2RTheme.background
    var foregroundColor: Color = L2RTheme.textPrimary
    var isDisabled: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: performAction) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(isDisabled ? foregroundColor.opacity(0.5) : foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(IconButtonStyle(reduceMotion: reduceMotion))
        .disabled(isDisabled)
        .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " "))
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isDisabled ? .isButton : [])
    }

    private func performAction() {
        guard !isDisabled else { return }
        HapticService.shared.selectionFeedback()
        action()
    }
}

// MARK: - Icon Button Style

private struct IconButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? nil : L2RTheme.Animation.bounce, value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Primary Buttons") {
    VStack(spacing: L2RTheme.Spacing.lg) {
        PrimaryButton(title: "Start Learning", icon: "play.fill") {
            print("Primary tapped")
        }

        PrimaryButton(title: "Continue", isLoading: true) {
            print("Loading tapped")
        }

        PrimaryButton(title: "Disabled", isDisabled: true) {
            print("Disabled tapped")
        }

        PrimaryButton(
            title: "Custom Gradient",
            icon: "star.fill",
            gradient: .spellingGame,
            shadowColor: L2RTheme.Game.spellingShadow
        ) {
            print("Custom tapped")
        }
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("Secondary Buttons") {
    VStack(spacing: L2RTheme.Spacing.lg) {
        SecondaryButton(title: "Learn More", icon: "info.circle") {
            print("Secondary tapped")
        }

        SecondaryButton(title: "Loading...", isLoading: true) {
            print("Loading tapped")
        }

        SecondaryButton(title: "Disabled", isDisabled: true) {
            print("Disabled tapped")
        }

        SecondaryButton(title: "Success Style", color: L2RTheme.Status.success) {
            print("Success tapped")
        }
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("Game Buttons") {
    VStack(spacing: L2RTheme.Spacing.lg) {
        GameButton(title: "Spelling Bee", emoji: "🐝", gradient: .spellingGame, shadowColor: L2RTheme.Game.spellingShadow) {
            print("Spelling tapped")
        }

        GameButton(title: "Memory Match", emoji: "🧠", gradient: .memoryGame, shadowColor: L2RTheme.Game.memoryShadow) {
            print("Memory tapped")
        }

        GameButton(title: "Phonics Fun", systemIcon: "ear.fill", gradient: .phonicsGame, shadowColor: L2RTheme.Game.phonicsShadow) {
            print("Phonics tapped")
        }
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("Text and Icon Buttons") {
    VStack(spacing: L2RTheme.Spacing.lg) {
        HStack {
            TextButton(title: "Skip") {
                print("Skip tapped")
            }

            Spacer()

            TextButton(title: "Disabled", isDisabled: true) {
                print("Disabled tapped")
            }
        }

        HStack(spacing: L2RTheme.Spacing.md) {
            IconButton(icon: "xmark") {
                print("Close tapped")
            }

            IconButton(icon: "gearshape.fill") {
                print("Settings tapped")
            }

            IconButton(icon: "arrow.left", backgroundColor: L2RTheme.primary, foregroundColor: .white) {
                print("Back tapped")
            }

            IconButton(icon: "heart.fill", isDisabled: true) {
                print("Disabled tapped")
            }
        }
    }
    .padding()
    .background(L2RTheme.background)
}

#Preview("All Button Types") {
    ScrollView {
        VStack(spacing: L2RTheme.Spacing.xxl) {
            VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
                Text("Primary")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                PrimaryButton(title: "Get Started", icon: "arrow.right") {}
            }

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
                Text("Secondary")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                SecondaryButton(title: "Learn More") {}
            }

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
                Text("Game")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                GameButton(title: "Play Now", emoji: "🎮") {}
            }

            VStack(alignment: .leading, spacing: L2RTheme.Spacing.md) {
                Text("Text & Icon")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                HStack {
                    TextButton(title: "Cancel") {}
                    Spacer()
                    IconButton(icon: "xmark") {}
                }
            }
        }
        .padding()
    }
    .background(L2RTheme.background)
}
