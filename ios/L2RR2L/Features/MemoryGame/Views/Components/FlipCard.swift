import SwiftUI

/// A 3D flip card for the Memory Game that displays sight words.
/// Features smooth Y-axis rotation animation with distinct front (card back) and back (word) faces.
public struct FlipCard: View {
    let word: String
    @Binding var isFlipped: Bool
    let isMatched: Bool
    let onFlip: () -> Void

    /// Animation duration for the flip
    private let flipDuration: Double = 0.4

    public init(
        word: String,
        isFlipped: Binding<Bool>,
        isMatched: Bool,
        onFlip: @escaping () -> Void
    ) {
        self.word = word
        self._isFlipped = isFlipped
        self.isMatched = isMatched
        self.onFlip = onFlip
    }

    public var body: some View {
        ZStack {
            // Front face (card back - shown when not flipped)
            CardFront()
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 0 : 1)

            // Back face (word - shown when flipped)
            CardBack(word: word, isMatched: isMatched)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.easeInOut(duration: flipDuration), value: isFlipped)
        .scaleEffect(isMatched ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMatched)
        .onTapGesture {
            guard !isMatched else { return }
            onFlip()
        }
    }
}

// MARK: - Card Front (Back Design)

/// The front face of the card (what you see when it's face-down).
/// Features a colorful decorative design.
private struct CardFront: View {
    var body: some View {
        ZStack {
            // Base gradient
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(LinearGradient.memoryGame)

            // Decorative pattern overlay
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Center decoration (star pattern)
            VStack(spacing: L2RTheme.Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))

                Text("L2R")
                    .font(L2RTheme.Typography.playful(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Border
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .stroke(Color.white.opacity(0.5), lineWidth: 3)
        }
        .shadow(color: L2RTheme.Game.memoryShadow.opacity(0.4), radius: 4, x: 0, y: 4)
    }
}

// MARK: - Card Back (Word Display)

/// The back face of the card showing the sight word.
private struct CardBack: View {
    let word: String
    let isMatched: Bool

    var body: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .fill(Color.white)

            // Match highlight glow
            if isMatched {
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(L2RTheme.Status.success.opacity(0.15))
            }

            // Word text
            Text(word)
                .font(L2RTheme.Typography.playful(size: 28, weight: .bold))
                .foregroundStyle(isMatched ? L2RTheme.Status.success : L2RTheme.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(L2RTheme.Spacing.sm)

            // Border
            RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                .stroke(
                    isMatched ? L2RTheme.Status.success : L2RTheme.border,
                    lineWidth: isMatched ? 3 : 2
                )
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("Single Card") {
    @Previewable @State var isFlipped = false

    FlipCard(
        word: "the",
        isFlipped: $isFlipped,
        isMatched: false,
        onFlip: { isFlipped.toggle() }
    )
    .frame(width: 100, height: 140)
    .padding()
}

#Preview("Card Grid") {
    @Previewable @State var flippedCards: Set<Int> = []
    @Previewable @State var matchedCards: Set<Int> = [2, 5]

    let words = ["the", "and", "is", "it", "the", "and"]

    ZStack {
        LinearGradient.homeBackground
            .ignoresSafeArea()

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: L2RTheme.Spacing.md
        ) {
            ForEach(0..<6) { index in
                FlipCard(
                    word: words[index],
                    isFlipped: Binding(
                        get: { flippedCards.contains(index) || matchedCards.contains(index) },
                        set: { _ in }
                    ),
                    isMatched: matchedCards.contains(index),
                    onFlip: {
                        if flippedCards.contains(index) {
                            flippedCards.remove(index)
                        } else {
                            flippedCards.insert(index)
                        }
                    }
                )
                .frame(height: 120)
            }
        }
        .padding()
    }
}
