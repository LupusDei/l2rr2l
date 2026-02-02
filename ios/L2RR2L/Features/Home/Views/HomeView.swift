import SwiftUI

/// Main home screen with animated background, logo, welcome message, and game grid.
struct HomeView: View {
    @State private var childName: String = "Friend"
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Animated background with floating decorations
            AnimatedBackgroundView()

            // Content
            VStack(spacing: 0) {
                // Settings button
                settingsButton

                Spacer()

                // Logo
                L2RLogoView()
                    .padding(.bottom, L2RTheme.Spacing.xl)

                // Welcome message
                welcomeMessage
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                // Primary CTA
                continueButton
                    .padding(.bottom, L2RTheme.Spacing.xxl)

                // Game grid
                GameGridView { game in
                    handleGameSelection(game)
                }
                .padding(.horizontal, L2RTheme.Spacing.lg)

                Spacer()
            }
            .padding(.horizontal, L2RTheme.Spacing.xl)
        }
        .sheet(isPresented: $showSettings) {
            SettingsPlaceholderView()
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        HStack {
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                    .contentShape(Rectangle())
            }
        }
        .padding(.top, L2RTheme.Spacing.sm)
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            Text("Hello, \(childName)!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)

            Text("\u{1F44B}")
                .font(.system(size: L2RTheme.Typography.Size.title2))
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            handleContinueLearning()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18))
                Text("Continue Learning")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: L2RTheme.TouchTarget.xlarge)
            .background(LinearGradient.ctaButton)
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .shadow(
                color: L2RTheme.CTA.shadow.opacity(0.4),
                radius: 6,
                x: 0,
                y: L2RTheme.Shadow.buttonDepth
            )
        }
        .pulsing()
        .padding(.horizontal, L2RTheme.Spacing.lg)
    }

    // MARK: - Actions

    private func handleContinueLearning() {
        // TODO: Navigate to current lesson or progress
    }

    private func handleGameSelection(_ game: GameType) {
        // TODO: Navigate to selected game
    }
}

/// Placeholder for settings screen
struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Settings")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title1, weight: .bold))
                Text("Coming soon...")
                    .foregroundStyle(L2RTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(L2RTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
