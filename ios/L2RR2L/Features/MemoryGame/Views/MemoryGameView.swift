import SwiftUI

/// Main view for the Memory Game.
/// Players flip cards to find matching sight word pairs.
struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    @Environment(\.dismiss) private var dismiss

    private let voiceService = VoiceService.shared

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
        .onChange(of: viewModel.gameState) { _, state in
            if state == .playing {
                Task { await voiceService.speak("Find the match!") }
            } else if state == .levelComplete {
                Task { await voiceService.speak("Great job!") }
            }
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
                    .frame(minWidth: L2RTheme.TouchTarget.minimum, minHeight: L2RTheme.TouchTarget.minimum)
            }
            .accessibilityLabel("Close game")

            Spacer()

            // Level indicator
            if viewModel.gameState != .notStarted {
                Text("Level \(viewModel.currentLevel)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Moves counter
            if viewModel.gameState != .notStarted {
                HStack(spacing: L2RTheme.Spacing.xxs) {
                    Text("\u{1F463}")
                        .font(.system(size: 18))
                    Text("\(viewModel.moves)")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.moves)
                }
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("🧠")
                .font(.system(size: 80))

            Text("Memory Match")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Find matching sight word pairs!")
                .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button {
                viewModel.startGame()
            } label: {
                Text("Start Game")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
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
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
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

        return GeometryReader { geometry in
            LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.sm) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    FlipCard(
                        word: card.word,
                        isFlipped: .constant(card.isFlipped || card.isMatched),
                        isMatched: card.isMatched,
                        onFlip: {
                            viewModel.flipCard(at: index)
                            if !card.isFlipped && !card.isMatched {
                                Task { await voiceService.speak(card.word) }
                            }
                        }
                    )
                    .frame(height: cardHeight(in: geometry))
                }
            }
            .padding(L2RTheme.Spacing.md)
        }
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private func cardHeight(in geometry: GeometryProxy) -> CGFloat {
        let rows = CGFloat(viewModel.gridRows)
        let spacing = L2RTheme.Spacing.md * (rows - 1) // spacing between rows
        let headerHeight: CGFloat = 80 // approximate header + padding
        let availableHeight = geometry.size.height - headerHeight - spacing
        let computed = availableHeight / rows
        return max(computed, 60) // minimum 60pt
    }

    // MARK: - Level Complete View

    private var levelCompleteView: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            HStack(spacing: L2RTheme.Spacing.xxs) {
                Text("\u{2728}")
                    .font(.system(size: 36))
                Text("\u{1F9E0}")
                    .font(.system(size: 80))
                Text("\u{2728}")
                    .font(.system(size: 36))
            }

            Text("Level Complete!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Moves: \(viewModel.moves)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)

                if let best = viewModel.bestMoves {
                    Text("Best: \(best)")
                        .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            HStack(spacing: L2RTheme.Spacing.lg) {
                if viewModel.hasNextLevel {
                    Button {
                        viewModel.nextLevel()
                    } label: {
                        Text("Next Level")
                            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
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
                        .font(L2RTheme.Typography.Scaled.system(.title3, weight: .semibold))
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
                        .font(L2RTheme.Typography.Scaled.system(.title3, weight: .semibold))
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
