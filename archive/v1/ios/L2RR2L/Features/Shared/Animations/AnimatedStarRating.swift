import SwiftUI

/// Animated star rating that fills stars one-by-one with a spring bounce.
/// Used in game completion views to make the star reveal feel exciting.
struct AnimatedStarRating: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let starCount: Int
    let totalStars: Int

    @State private var revealedStars = 0

    init(starCount: Int, totalStars: Int = 3) {
        self.starCount = starCount
        self.totalStars = totalStars
    }

    var body: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            ForEach(0..<totalStars, id: \.self) { index in
                Image(systemName: index < revealedStars ? "star.fill" : "star")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)
                    .scaleEffect(index < revealedStars ? 1.0 : 0.7)
                    .opacity(index < revealedStars ? 1.0 : 0.3)
                    .shadow(
                        color: index < revealedStars ? .yellow.opacity(0.5) : .clear,
                        radius: 6,
                        y: 2
                    )
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5),
                        value: revealedStars
                    )
            }
        }
        .onAppear {
            revealStars()
        }
        .accessibilityLabel("\(starCount) out of \(totalStars) stars")
    }

    private func revealStars() {
        guard !reduceMotion else {
            revealedStars = starCount
            return
        }

        // Reveal stars one at a time with delay
        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4 + 0.3) {
                withAnimation {
                    revealedStars = i + 1
                }
                HapticService.shared.buttonTap()
            }
        }
    }
}

// MARK: - Preview

#Preview("Star Rating") {
    ZStack {
        Color.indigo.ignoresSafeArea()
        VStack(spacing: 30) {
            AnimatedStarRating(starCount: 1)
            AnimatedStarRating(starCount: 2)
            AnimatedStarRating(starCount: 3)
        }
    }
}
