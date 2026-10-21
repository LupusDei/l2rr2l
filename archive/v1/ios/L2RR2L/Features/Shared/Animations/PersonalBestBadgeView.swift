import SwiftUI

/// Animated "New Record!" badge that appears on personal best achievement.
/// Gold trophy with sparkle burst, spring-scaled entrance, and gentle pulse.
struct PersonalBestBadgeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var sparkle = false

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            Text("\u{1F3C6}")
                .font(.system(size: 28))

            Text("New Record!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [L2RTheme.Logo.yellow, L2RTheme.Logo.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal, L2RTheme.Spacing.xl)
        .padding(.vertical, L2RTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(.white)
                .shadow(color: L2RTheme.Logo.yellow.opacity(0.4), radius: 8, y: 2)
        )
        .overlay {
            if sparkle && !reduceMotion {
                SparkleRing()
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                appeared = true
            }
            sparkle = true
            HapticService.shared.levelComplete()
        }
        .accessibilityLabel("New personal record!")
    }
}

/// Small sparkle particles that burst outward around the badge.
private struct SparkleRing: View {
    @State private var animate = false

    private static let sparkleOffsets: [(x: CGFloat, y: CGFloat)] = [
        (-50, -20), (50, -15), (-35, 20), (45, 18),
        (-15, -30), (20, -28), (0, 25)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                Text(i % 2 == 0 ? "\u{2728}" : "\u{2B50}")
                    .font(.system(size: CGFloat(10 + (i % 3) * 3)))
                    .offset(
                        x: animate ? Self.sparkleOffsets[i].x : 0,
                        y: animate ? Self.sparkleOffsets[i].y : 0
                    )
                    .opacity(animate ? 0 : 0.9)
                    .scaleEffect(animate ? 1.2 : 0.2)
                    .animation(
                        .easeOut(duration: 0.7).delay(Double(i) * 0.05),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

// MARK: - Preview

#Preview("Personal Best Badge") {
    ZStack {
        Color.indigo.ignoresSafeArea()
        PersonalBestBadgeView()
    }
}
