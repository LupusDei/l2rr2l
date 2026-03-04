import SwiftUI

/// Main home screen with animated background, logo, welcome message, and game grid.
struct HomeView: View {
    @ObservedObject private var router = NavigationRouter.shared
    @ObservedObject private var childProfileService = ChildProfileService.shared
    private let voiceService = VoiceService.shared

    private var childName: String {
        childProfileService.activeChild?.name ?? "Friend"
    }

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
        .onAppear {
            Task { await voiceService.speak("Hello, \(childName)!") }
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        HStack {
            Spacer()
            Button {
                router.navigateToSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(L2RTheme.textSecondary)
                    .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier(AccessibilityIdentifiers.Home.settingsButton)
        }
        .padding(.top, L2RTheme.Spacing.sm)
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        HStack(spacing: L2RTheme.Spacing.xs) {
            Text("Hello, \(childName)!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .semibold))
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
                    .font(.system(size: 24))
                Text("Continue Learning")
                    .font(L2RTheme.Typography.Scaled.system(.body, weight: .bold))
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
        .accessibilityLabel("Continue Learning")
        .accessibilityHint("Resume your current lesson")
        .accessibilityIdentifier(AccessibilityIdentifiers.Home.continueLearningButton)
        .pulsing()
        .padding(.horizontal, L2RTheme.Spacing.lg)
    }

    // MARK: - Actions

    private func handleContinueLearning() {
        guard let childId = childProfileService.activeChild?.id else {
            router.selectedTab = .lessons
            return
        }
        Task {
            // Find the most recent in-progress lesson
            if let progressList = try? await ProgressService.shared.fetchAllProgress(childId: childId) {
                let inProgress = progressList
                    .filter { $0.status == .inProgress }
                    .sorted { ($0.startedAt ?? "") > ($1.startedAt ?? "") }

                if let mostRecent = inProgress.first {
                    router.navigateToLesson(id: mostRecent.lessonId)
                    return
                }
            }
            // Fallback: navigate to lessons tab
            router.selectedTab = .lessons
        }
    }

    private func handleGameSelection(_ game: GameType) {
        router.selectedTab = .games
        router.gamesPath.append(game)
    }
}

#Preview {
    HomeView()
}
