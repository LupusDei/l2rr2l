import SwiftUI

/// Onboarding completion celebration screen with confetti and profile summary.
struct OnboardingCompletionView: View {
    let childName: String
    let childAge: Int
    let childAvatar: String
    var onComplete: () -> Void

    @State private var showConfetti = false
    @State private var showContent = false
    @State private var avatarScale: CGFloat = 0.5
    @State private var hasSpokeGreeting = false

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackgroundView()

            // Confetti overlay
            ConfettiView(isActive: $showConfetti)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Celebration header
                celebrationHeader
                    .padding(.bottom, L2RTheme.Spacing.xl)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Large avatar display
                avatarDisplay
                    .padding(.bottom, L2RTheme.Spacing.xl)

                // Profile summary
                profileSummary
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.xxl)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // CTA button
                startButton
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.bottom, L2RTheme.Spacing.xxl)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, L2RTheme.Spacing.lg)
        }
        .onAppear {
            startCelebration()
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            Text("🎉")
                .font(.system(size: 60))
                .bouncing()

            Text("All set, \(childName)!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title1, weight: .bold))
                .foregroundStyle(L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Avatar Display

    private var avatarDisplay: some View {
        ZStack {
            // Glowing background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            L2RTheme.Logo.yellow.opacity(0.4),
                            L2RTheme.Logo.yellow.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)

            // Avatar circle
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(color: L2RTheme.primary.opacity(0.3), radius: 12, x: 0, y: 6)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: L2RTheme.Logo.all,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )

                Text(childAvatar)
                    .font(.system(size: 80))
            }
            .frame(width: 140, height: 140)
            .scaleEffect(avatarScale)
        }
    }

    // MARK: - Profile Summary

    private var profileSummary: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            // Summary card
            VStack(spacing: L2RTheme.Spacing.sm) {
                ProfileSummaryRow(icon: "person.fill", label: "Name", value: childName)
                ProfileSummaryRow(icon: "birthday.cake.fill", label: "Age", value: "\(childAge) years old")
                ProfileSummaryRow(icon: "face.smiling.fill", label: "Buddy", value: childAvatar)
            }
            .padding(L2RTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )

            // Ready message
            Text("You're ready to start your learning adventure!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.large, weight: .medium))
                .foregroundStyle(L2RTheme.Status.success)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Text("Let's Start Learning!")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .bold))
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
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
    }

    // MARK: - Animation Sequence

    private func startCelebration() {
        // Trigger confetti immediately
        withAnimation {
            showConfetti = true
        }

        // Animate avatar entrance
        withAnimation(L2RTheme.Animation.bounce.delay(0.2)) {
            avatarScale = 1.0
        }

        // Show content with stagger
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            showContent = true
        }

        // Speak greeting after short delay
        if !hasSpokeGreeting {
            hasSpokeGreeting = true
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                await VoiceService.shared.speak("Great job! Let's start learning!")
            }
        }
    }
}

// MARK: - Profile Summary Row

private struct ProfileSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(L2RTheme.primary)
                .frame(width: 28)

            Text(label)
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                .foregroundStyle(L2RTheme.textSecondary)

            Spacer()

            Text(value)
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(L2RTheme.textPrimary)
        }
    }
}

// ConfettiView is defined in Features/Shared/Components/ConfettiView.swift

#Preview {
    OnboardingCompletionView(
        childName: "Emma",
        childAge: 5,
        childAvatar: "🦊"
    ) {
        print("Onboarding complete!")
    }
}
