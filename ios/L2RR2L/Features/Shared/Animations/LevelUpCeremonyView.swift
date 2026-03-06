import SwiftUI

/// Full-screen "Level Up!" ceremony overlay with rising stars and mascot celebration.
/// Shown between levels in multi-level games (Memory Match).
struct LevelUpCeremonyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let currentLevel: Int
    let onContinue: () -> Void

    @State private var showTitle = false
    @State private var showStars = false
    @State private var showButton = false
    @State private var mascotState = MascotState()

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: L2RTheme.Spacing.xl) {
                Spacer()

                // Rising stars
                if showStars {
                    RisingStars()
                        .frame(height: 80)
                }

                // Mascot
                MascotView(state: mascotState, size: 140)
                    .scaleEffect(showTitle ? 1.0 : 0.5)
                    .opacity(showTitle ? 1.0 : 0)

                // "Level Up!" title
                VStack(spacing: L2RTheme.Spacing.sm) {
                    Text("Level Up!")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [L2RTheme.Logo.yellow, L2RTheme.Logo.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(showTitle ? 1.0 : 0.3)
                        .opacity(showTitle ? 1.0 : 0)

                    Text("Level \(currentLevel + 1)")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(showTitle ? 1.0 : 0.5)
                        .opacity(showTitle ? 1.0 : 0)
                }

                Spacer()

                // Continue button
                if showButton {
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: L2RTheme.Spacing.sm) {
                            Text("Let's Go!")
                                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, L2RTheme.Spacing.xxl)
                        .padding(.vertical, L2RTheme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(LinearGradient.ctaButton)
                                .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 6, y: 4)
                        )
                    }
                    .juicyButtonPress()
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Continue to level \(currentLevel + 1)")
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            startCeremony()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level up! Moving to level \(currentLevel + 1)")
    }

    private func startCeremony() {
        HapticService.shared.levelComplete()

        guard !reduceMotion else {
            showTitle = true
            showStars = true
            showButton = true
            mascotState.proud(message: "Level up!")
            return
        }

        // Phase 1: Stars rise
        withAnimation(.easeOut(duration: 0.4)) {
            showStars = true
        }

        // Phase 2: Title + mascot appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                showTitle = true
            }
            mascotState.proud(message: "Level up!")
        }

        // Phase 3: Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showButton = true
            }
        }
    }
}

// MARK: - Rising Stars

/// Stars that float upward with gentle sway, used behind the Level Up title.
private struct RisingStars: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    private static let stars: [(x: CGFloat, size: CGFloat, delay: Double)] = [
        (-80, 18, 0.0), (-40, 14, 0.1), (0, 20, 0.05),
        (40, 16, 0.15), (80, 14, 0.08), (-60, 12, 0.2),
        (60, 16, 0.12)
    ]

    private let colors = L2RTheme.Logo.all

    var body: some View {
        if reduceMotion {
            HStack(spacing: L2RTheme.Spacing.md) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(colors[i % colors.count])
                }
            }
        } else {
            ZStack {
                ForEach(0..<Self.stars.count, id: \.self) { i in
                    let star = Self.stars[i]
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size))
                        .foregroundStyle(colors[i % colors.count])
                        .offset(
                            x: star.x,
                            y: animate ? -40 : 40
                        )
                        .opacity(animate ? 0.3 : 1.0)
                        .scaleEffect(animate ? 0.5 : 1.0)
                        .animation(
                            .easeOut(duration: 1.5)
                                .delay(star.delay)
                                .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
    }
}

// MARK: - Preview

#Preview("Level Up Ceremony") {
    LevelUpCeremonyView(currentLevel: 2) {
        print("Continue!")
    }
}
