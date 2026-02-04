import SwiftUI

/// Main view for the Spelling Game.
/// Players arrange scrambled letters to spell words based on emoji hints.
struct SpellingGameView: View {
    @StateObject private var viewModel = SpellingGameViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false
    @State private var showGameCompleteConfetti = false
    @State private var shakeAnswer = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.spellingGame
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

                // Bottom controls
                if viewModel.gameState != .notStarted && viewModel.gameState != .gameComplete {
                    bottomControls
                }
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
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.closeButton)

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

            Spacer()

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
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.sm)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F4DD}")
                .font(.system(size: 80))

            Text("Spelling Game")
                .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Arrange the letters to spell the word!")
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
            .accessibilityHint("Begin the spelling game")
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.startButton)
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.xxl) {
            // Hint emoji
            if let word = viewModel.currentWord {
                Text(word.hint)
                    .font(.system(size: 80))
                    .accessibilityLabel("Hint: \(word.hint)")

                // Word (shown when correct, hidden otherwise)
                if viewModel.gameState == .correct {
                    Text(word.word.uppercased())
                        .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.title1, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Drop zones
            dropZoneArea

            // Letter bank
            letterBankArea
        }
        .animation(.easeInOut, value: viewModel.gameState)
    }

    // MARK: - Drop Zone Area

    private var dropZoneArea: some View {
        DropZoneRow(
            wordLength: viewModel.currentWord?.length ?? 0,
            placedLetters: viewModel.placedLetters,
            lockedIndices: viewModel.gameState == .correct ? Set(0..<(viewModel.currentWord?.length ?? 0)) : [],
            activeIndex: viewModel.placedLetters.firstIndex(where: { $0 == nil }),
            onDrop: { index, char in
                viewModel.placeLetter(char, at: index)
            },
            onTap: { index in
                // Tapping a placed letter removes it
                viewModel.removeLetter(at: index)
            }
        )
        .modifier(SpellingShakeModifier(shake: shakeAnswer))
        .padding(.vertical, L2RTheme.Spacing.lg)
    }

    // MARK: - Letter Bank Area

    private var letterBankArea: some View {
        LetterBank(tiles: viewModel.scrambledLetters) { tile in
            viewModel.placeLetterInNextSlot(tile.letter)
        }
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            // Shuffle button
            Button {
                viewModel.scrambleLetters()
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.vertical, L2RTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
            }
            .disabled(viewModel.gameState != .playing)
            .accessibilityLabel("Shuffle letters")
            .accessibilityHint("Rearrange the available letters randomly")
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.shuffleButton)

            Spacer()

            // Check / Next button
            if viewModel.gameState == .correct || viewModel.gameState == .incorrect {
                Button {
                    viewModel.nextWord()
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.body, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(LinearGradient.ctaButton)
                            .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 4, y: 4)
                    )
                }
                .accessibilityLabel("Next word")
                .accessibilityHint("Move to the next word")
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.nextButton)
            } else {
                Button {
                    let correct = viewModel.checkAnswer()
                    if !correct {
                        triggerShake()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Check")
                    }
                    .font(L2RTheme.Typography.playful(size: L2RTheme.Typography.Size.body, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(viewModel.allLettersPlaced ? LinearGradient.ctaButton : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: viewModel.allLettersPlaced ? L2RTheme.CTA.shadow.opacity(0.5) : .clear, radius: 4, y: 4)
                    )
                }
                .disabled(!viewModel.allLettersPlaced)
                .accessibilityLabel("Check answer")
                .accessibilityHint(viewModel.allLettersPlaced ? "Verify your spelling" : "Place all letters first")
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.checkButton)
            }

            Spacer()

            // Clear button
            Button {
                viewModel.clearPlacedLetters()
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Clear")
                }
                .font(L2RTheme.Typography.system(size: L2RTheme.Typography.Size.body, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.vertical, L2RTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
            }
            .disabled(viewModel.gameState != .playing)
            .accessibilityLabel("Clear all")
            .accessibilityHint("Remove all placed letters")
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.clearButton)
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.bottom, L2RTheme.Spacing.md)
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
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.playAgainButton)

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
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.doneButton)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.gameComplete)
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

    private func triggerShake() {
        withAnimation(.default.speed(4).repeatCount(3, autoreverses: true)) {
            shakeAnswer = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeAnswer = false
        }
    }

    private func triggerCelebration() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showConfetti = false
        }
    }
}

// MARK: - Shake Modifier

private struct SpellingShakeModifier: ViewModifier {
    var shake: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -5 : 0)
    }
}

// MARK: - Preview

#Preview("Spelling Game") {
    SpellingGameView()
}

#Preview("Playing State") {
    SpellingGameView()
}
