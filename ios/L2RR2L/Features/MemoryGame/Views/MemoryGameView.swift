import SwiftUI

/// Main view for the Memory Game.
/// Players flip cards to find matching sight word pairs.
struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.memoryGame
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                Spacer()

                // Game content
                if viewModel.gameState == .notStarted {
                    startPrompt
                } else if viewModel.gameState == .levelComplete {
                    levelCompleteView
                } else {
                    gameContent
                }

                Spacer()
            }
            .padding()
        }
        .onChange(of: viewModel.showCelebration) { _, show in
            showConfetti = show
        }
        .confetti(isActive: $showConfetti, configuration: .gameComplete)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityLabel("Close game")

            Spacer()

            // Level indicator
            if viewModel.gameState != .notStarted {
                Text("Level \(viewModel.currentLevel)")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Moves counter
            if viewModel.gameState != .notStarted {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Text("Moves:")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(viewModel.moves)")
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.sm)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("🧠")
                .font(.system(size: 80))

            Text("Memory Match")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Find matching sight word pairs!")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button {
                viewModel.startGame()
            } label: {
                Text("Start Game")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xxl)
                    .padding(.vertical, L2RTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(LinearGradient.ctaButton)
                            .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 4, y: 4)
                    )
            }
            .accessibilityLabel("Start Game")
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            // Progress
            progressBar

            // Card grid
            cardGrid
        }
    }

    private var progressBar: some View {
        VStack(spacing: L2RTheme.Spacing.xs) {
            HStack {
                Text("Pairs: \(viewModel.matchedPairsCount)/\(viewModel.totalPairs)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: geometry.size.width * viewModel.progress)
                        .animation(.easeInOut, value: viewModel.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
    }

    private var cardGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: L2RTheme.Spacing.sm), count: viewModel.gridColumns)

        return LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.sm) {
            ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                FlipCard(
                    word: card.word,
                    isFlipped: .constant(card.isFlipped || card.isMatched),
                    isMatched: card.isMatched,
                    onFlip: {
                        viewModel.flipCard(at: index)
                    }
                )
                .frame(height: cardHeight)
            }
        }
        .padding(L2RTheme.Spacing.md)
    }

    private var cardHeight: CGFloat {
        // Adjust card height based on grid size
        switch viewModel.gridRows {
        case 2: return 120
        case 3: return 100
        case 4: return 85
        default: return 80
        }
    }

    // MARK: - Level Complete View

    private var levelCompleteView: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("🎉")
                .font(.system(size: 80))

            Text("Level Complete!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Moves: \(viewModel.moves)")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(.white)

                if let best = viewModel.bestMoves {
                    Text("Best: \(best)")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            HStack(spacing: L2RTheme.Spacing.lg) {
                if viewModel.hasNextLevel {
                    Button {
                        viewModel.nextLevel()
                    } label: {
                        Text("Next Level")
                            .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, L2RTheme.Spacing.xl)
                            .padding(.vertical, L2RTheme.Spacing.md)
                            .background(
                                Capsule()
                                    .fill(LinearGradient.ctaButton)
                                    .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 4, y: 4)
                            )
                    }
                }

                Button {
                    viewModel.restartLevel()
                } label: {
                    Text("Play Again")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, L2RTheme.Spacing.xl)
                        .padding(.vertical, L2RTheme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title3, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, L2RTheme.Spacing.xl)
                        .padding(.vertical, L2RTheme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
            }
        }
    }
}

#Preview {
    MemoryGameView()
}
