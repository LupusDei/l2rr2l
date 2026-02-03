import SwiftUI

/// Main view for the Rhyme Game.
/// Players identify which word rhymes with a target word from multiple options.
struct RhymeGameView: View {
    @StateObject private var viewModel = RhymeGameViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false
    @State private var showGameCompleteConfetti = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.rhymeGame
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                Spacer()

                // Game content
                if viewModel.gameState == .notStarted {
                    startPrompt
                } else if viewModel.gameState == .gameComplete {
                    gameCompleteView
                } else {
                    gameContent
                }

                Spacer()
            }
            .padding()

            // Celebration overlay
            if showConfetti {
                celebrationOverlay
            }
        }
        .onChange(of: viewModel.showCelebration) { _, show in
            if show {
                triggerCelebration()
            }
        }
        .onChange(of: viewModel.gameState) { _, state in
            if state == .gameComplete {
                showGameCompleteConfetti = true
            }
        }
        .confetti(isActive: $showGameCompleteConfetti, configuration: .gameComplete)
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
            .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.closeButton)

            Spacer()

            // Score
            HStack(spacing: L2RTheme.Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(viewModel.score)")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Score: \(viewModel.score) points")
            .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.scoreLabel)

            Spacer()

            // Round indicator
            if viewModel.gameState != .notStarted && viewModel.gameState != .gameComplete {
                Text("Round \(viewModel.currentRound)/\(viewModel.totalRounds)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityLabel("Round \(viewModel.currentRound) of \(viewModel.totalRounds)")
                    .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.roundLabel)

                Spacer()
            }

            // Streak
            if viewModel.streak > 0 {
                HStack(spacing: L2RTheme.Spacing.xxs) {
                    Text("\u{1F525}")
                    Text("\(viewModel.streak)")
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title3, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak: \(viewModel.streak) correct answers in a row")
                .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.streakLabel)
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.sm)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F3B5}")
                .font(.system(size: 80))

            Text("Rhyme Time")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Find the word that rhymes!")
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
            .accessibilityHint("Begin the rhyme game")
            .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.startButton)
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            // Listen button
            listenButton

            // Target word prompt
            if let question = viewModel.currentQuestion {
                targetWordSection(question)
            }

            // Options grid
            optionsGrid
        }
        .animation(.easeInOut, value: viewModel.gameState)
    }

    // MARK: - Listen Button

    private var listenButton: some View {
        Button {
            viewModel.playTargetWordAudio()
        } label: {
            HStack(spacing: L2RTheme.Spacing.sm) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20))
                Text("Listen again")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, L2RTheme.Spacing.lg)
            .padding(.vertical, L2RTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(.white.opacity(0.2))
            )
        }
        .accessibilityLabel("Listen again")
        .accessibilityHint("Hear the target word spoken aloud")
        .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.listenButton)
    }

    // MARK: - Target Word Section

    private func targetWordSection(_ question: RhymeQuestion) -> some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            Text("What rhymes with")
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(question.targetWord.word.uppercased())
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityLabel("Target word: \(question.targetWord.word)")

            Text(question.targetWord.emoji)
                .font(.system(size: 60))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("What rhymes with \(question.targetWord.word)?")
        .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.targetWord)
    }

    // MARK: - Options Grid

    private var optionsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: L2RTheme.Spacing.md),
                GridItem(.flexible(), spacing: L2RTheme.Spacing.md)
            ],
            spacing: L2RTheme.Spacing.md
        ) {
            if let question = viewModel.currentQuestion {
                ForEach(question.allOptions) { option in
                    optionCard(option, question: question)
                }
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.optionsGrid)
    }

    // MARK: - Option Card

    private func optionCard(_ option: RhymeOptionItem, question: RhymeQuestion) -> some View {
        let isSelected = viewModel.selectedOption?.id == option.id
        let isCorrectAnswer = option.id == question.correctAnswer.id
        let showResult = viewModel.gameState == .correct || viewModel.gameState == .incorrect

        return Button {
            guard viewModel.gameState == .playing else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectOption(option)
            }
            // Auto-advance after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.nextQuestion()
            }
        } label: {
            VStack(spacing: L2RTheme.Spacing.sm) {
                Text(option.displayWord.uppercased())
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(.white)

                Text(option.emoji)
                    .font(.system(size: 40))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .fill(cardBackgroundColor(isSelected: isSelected, isCorrectAnswer: isCorrectAnswer, showResult: showResult))
            )
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                    .strokeBorder(cardBorderColor(isSelected: isSelected, isCorrectAnswer: isCorrectAnswer, showResult: showResult), lineWidth: isSelected || (showResult && isCorrectAnswer) ? 4 : 0)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.gameState != .playing)
        .accessibilityLabel("\(option.displayWord)")
        .accessibilityHint(viewModel.gameState == .playing ? "Double tap to select" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.optionCard(id: option.id))
    }

    // MARK: - Card Colors

    private func cardBackgroundColor(isSelected: Bool, isCorrectAnswer: Bool, showResult: Bool) -> Color {
        if showResult {
            if isSelected && isCorrectAnswer {
                return L2RTheme.Status.success
            } else if isSelected && !isCorrectAnswer {
                return L2RTheme.Status.error
            } else if isCorrectAnswer {
                return L2RTheme.Status.success.opacity(0.7)
            }
        }
        return .white.opacity(0.2)
    }

    private func cardBorderColor(isSelected: Bool, isCorrectAnswer: Bool, showResult: Bool) -> Color {
        if showResult {
            if isCorrectAnswer {
                return L2RTheme.Status.success
            } else if isSelected {
                return L2RTheme.Status.error
            }
        }
        return .clear
    }

    // MARK: - Game Complete View

    private var gameCompleteView: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F389}")
                .font(.system(size: 80))

            Text("Great Job!")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Score: \(viewModel.score) / \(viewModel.totalRounds)")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Final score: \(viewModel.score) out of \(viewModel.totalRounds)")

                Text("Best Streak: \(viewModel.bestStreak)")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.large, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityLabel("Best streak: \(viewModel.bestStreak) correct answers in a row")
            }

            HStack(spacing: L2RTheme.Spacing.lg) {
                Button {
                    viewModel.startGame()
                } label: {
                    Text("Play Again")
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
                .accessibilityLabel("Play Again")
                .accessibilityHint("Start a new game")
                .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.playAgainButton)

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
                .accessibilityLabel("Done")
                .accessibilityHint("Return to games menu")
                .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.doneButton)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.RhymeGame.gameComplete)
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: L2RTheme.Spacing.lg) {
                Text("\u{1F389}\u{2B50}\u{1F389}")
                    .font(.system(size: 60))

                Text("Amazing!")
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(viewModel.streak) in a row!")
                    .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.title2, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .scaleEffect(showConfetti ? 1.0 : 0.5)
            .opacity(showConfetti ? 1.0 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showConfetti)

            // Confetti particles
            ConfettiView(isActive: $showConfetti, configuration: .streakMilestone)
        }
        .onTapGesture {
            showConfetti = false
        }
    }

    // MARK: - Animations

    private func triggerCelebration() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showConfetti = false
        }
    }
}

// MARK: - Preview

#Preview("Rhyme Game") {
    RhymeGameView()
}

#Preview("Playing State") {
    RhymeGameView()
}
