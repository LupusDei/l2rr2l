import SwiftUI

/// Shared round transition overlay for all 6 games.
/// When the round number changes, the current content fades out briefly,
/// a "Round N!" counter bumps in with a spring animation, then content fades back.
///
/// Usage:
/// ```swift
/// gameContent
///     .roundTransition(round: viewModel.round, label: "Word")
/// ```
struct RoundTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let round: Int
    let label: String

    @State private var showBanner = false
    @State private var bannerScale: CGFloat = 0.3
    @State private var bannerOpacity: Double = 0
    @State private var contentOpacity: Double = 1
    @State private var previousRound: Int = 0

    func body(content: Content) -> some View {
        content
            .opacity(contentOpacity)
            .overlay {
                if showBanner {
                    roundBanner
                }
            }
            .onChange(of: round) { oldValue, newValue in
                guard newValue > 1, newValue != previousRound else {
                    previousRound = newValue
                    return
                }
                previousRound = newValue
                playTransition()
            }
            .onAppear {
                previousRound = round
            }
    }

    private var roundBanner: some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            Text("\(label) \(round)!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

            // Colorful dots showing progress
            HStack(spacing: L2RTheme.Spacing.xxs) {
                ForEach(0..<min(round, 5), id: \.self) { i in
                    Circle()
                        .fill(L2RTheme.Logo.all[i % L2RTheme.Logo.all.count])
                        .frame(width: 8, height: 8)
                }
            }
        }
        .scaleEffect(bannerScale)
        .opacity(bannerOpacity)
    }

    private func playTransition() {
        guard !reduceMotion else {
            // Minimal flash for reduced motion
            showBanner = true
            bannerScale = 1.0
            bannerOpacity = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showBanner = false
                bannerOpacity = 0
            }
            return
        }

        // Phase 1: Dim content
        withAnimation(.easeOut(duration: 0.15)) {
            contentOpacity = 0.3
        }

        // Phase 2: Show round banner with spring bump
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showBanner = true
            bannerScale = 0.3
            bannerOpacity = 0

            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                bannerScale = 1.0
                bannerOpacity = 1.0
            }

            HapticService.shared.buttonTap()
        }

        // Phase 3: Fade banner out, restore content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.25)) {
                bannerOpacity = 0
                bannerScale = 1.2
            }

            withAnimation(.easeIn(duration: 0.2)) {
                contentOpacity = 1.0
            }
        }

        // Phase 4: Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showBanner = false
            bannerScale = 0.3
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds an animated round transition overlay when the round number changes.
    /// - Parameters:
    ///   - round: The current round number (triggers animation on change).
    ///   - label: Label shown before the number (e.g., "Round", "Word", "Puzzle").
    func roundTransition(round: Int, label: String = "Round") -> some View {
        modifier(RoundTransitionModifier(round: round, label: label))
    }
}

// MARK: - Preview

#Preview("Round Transition") {
    RoundTransitionPreview()
}

private struct RoundTransitionPreview: View {
    @State private var round = 1

    var body: some View {
        ZStack {
            LinearGradient.spellingGame
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Game Content Here")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)

                Button("Next Round") {
                    round += 1
                }
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                .foregroundStyle(.white)
                .padding()
                .background(Capsule().fill(L2RTheme.Logo.blue))
            }
            .roundTransition(round: round, label: "Round")
        }
    }
}
