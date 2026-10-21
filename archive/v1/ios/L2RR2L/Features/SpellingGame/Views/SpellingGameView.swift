import SwiftUI

/// Main view for the Spelling Game.
/// Players arrange scrambled letters to spell words based on emoji hints.
struct SpellingGameView: View {
    @StateObject private var viewModel = SpellingGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var childProfileService = ChildProfileService.shared

    private let voiceService = VoiceService.shared
    private var childName: String { childProfileService.activeChild?.name ?? "Friend" }

    @State private var showConfetti = false
    @State private var showGameCompleteConfetti = false
    @State private var shakeAnswer = false
    @State private var correctTrigger = false
    @State private var incorrectTrigger = false
    @State private var mascotState = MascotState()
    @State private var inactivityManager = InactivityHintManager()
    @State private var emojiBounce = false

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
                        .roundTransition(round: viewModel.round, label: "Word")
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
        .overlay(alignment: .bottomLeading) {
            MascotView(state: mascotState)
                .padding(L2RTheme.Spacing.md)
        }
        .onChange(of: viewModel.showCelebration) { _, show in
            if show {
                triggerCelebration()
                mascotState.dance()
            }
        }
        .onChange(of: viewModel.gameState) { _, state in
            if state == .playing {
                Task { await voiceService.speak("Spell the word!") }
            } else if state == .correct {
                mascotState.celebrate()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { emojiBounce = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { emojiBounce = false }
                }
            } else if state == .incorrect {
                mascotState.encourage()
            } else if state == .gameComplete {
                showGameCompleteConfetti = true
                mascotState.proud(message: "You did it, \(childName)!")
                Task { await voiceService.speak("Great job!") }
            }
        }
        .onChange(of: viewModel.currentWord?.word) { _, newWord in
            if let word = newWord {
                Task { await voiceService.speak(word) }
            }
        }
        .confetti(isActive: $showGameCompleteConfetti, configuration: .gameComplete)
        .onAppear { inactivityManager.setHintMessage("Try tapping a letter!") }
        .onChange(of: viewModel.gameState) { _, _ in inactivityManager.resetTimer() }
        .onChange(of: inactivityManager.shouldWave) { _, wave in
            if wave { mascotState.wave() }
        }
        .onChange(of: inactivityManager.shouldHint) { _, hint in
            if hint { mascotState.hint(message: inactivityManager.hintMessage) }
        }
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
            .juicyButtonPress()
            .accessibilityLabel("Close game")
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.closeButton)

            Spacer()

            // Score
            HStack(spacing: L2RTheme.Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(viewModel.score)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
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
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak: \(viewModel.streak) correct answers in a row")
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F4DD}")
                .font(.system(size: 80))

            Text("Spelling Game")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Arrange the letters to spell the word!")
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
            .juicyButtonPress()
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
                    .scaleEffect(emojiBounce ? 1.2 : 1.0)
                    .accessibilityLabel("Hint: \(word.hint)")

                // Word (shown when correct, with rainbow shimmer)
                if viewModel.gameState == .correct {
                    RainbowShimmerText(text: word.word.uppercased())
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
        .juicyCorrect(trigger: $correctTrigger)
        .juicyIncorrect(trigger: $incorrectTrigger)
        .padding(.vertical, L2RTheme.Spacing.lg)
    }

    // MARK: - Letter Bank Area

    private var letterBankArea: some View {
        LetterBank(
            tiles: viewModel.scrambledLetters,
            hintedTileId: viewModel.hintLetterIndex.map { viewModel.scrambledLetters[$0].id }
        ) { tile in
            viewModel.placeLetterInNextSlot(tile.letter)
        }
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            // Shuffle button — icon-primary for pre-readers
            Button {
                viewModel.scrambleLetters()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.2))
                    )
            }
            .disabled(viewModel.gameState != .playing)
            .juicyButtonPress()
            .accessibilityLabel("Shuffle letters")
            .accessibilityHint("Rearrange the available letters randomly")
            .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.shuffleButton)

            Spacer()

            // Check / Next button — icon-primary for pre-readers
            if viewModel.gameState == .correct || viewModel.gameState == .incorrect {
                Button {
                    viewModel.nextWord()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                        .background(
                            Circle()
                                .fill(LinearGradient.ctaButton)
                                .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 4, y: 4)
                        )
                }
                .juicyButtonPress()
                .accessibilityLabel("Next word")
                .accessibilityHint("Move to the next word")
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.nextButton)
            } else {
                Button {
                    let correct = viewModel.checkAnswer()
                    if correct {
                        correctTrigger = true
                    } else {
                        incorrectTrigger = true
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                        .background(
                            Circle()
                                .fill(viewModel.allLettersPlaced ? LinearGradient.ctaButton : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: viewModel.allLettersPlaced ? L2RTheme.CTA.shadow.opacity(0.5) : .clear, radius: 4, y: 4)
                        )
                }
                .disabled(!viewModel.allLettersPlaced)
                .juicyButtonPress()
                .accessibilityLabel("Check answer")
                .accessibilityHint(viewModel.allLettersPlaced ? "Verify your spelling" : "Place all letters first")
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.checkButton)
            }

            Spacer()

            // Clear button — icon-primary for pre-readers
            Button {
                viewModel.clearPlacedLetters()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: L2RTheme.TouchTarget.comfortable, height: L2RTheme.TouchTarget.comfortable)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.2))
                    )
            }
            .disabled(viewModel.gameState != .playing)
            .juicyButtonPress()
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
            MascotView(state: mascotState, size: 120)

            Text("Great job, \(childName)!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            AnimatedStarRating(starCount: starRating(correct: viewModel.score, total: viewModel.totalRounds))

            if viewModel.personalBestResult?.isNewRecord == true {
                PersonalBestBadgeView()
            }

            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Score: \(viewModel.score) / \(viewModel.totalRounds)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Final score: \(viewModel.score) out of \(viewModel.totalRounds)")

                if viewModel.bestStreak > 1 {
                    HStack(spacing: L2RTheme.Spacing.xxs) {
                        Text("\u{1F525}")
                        Text("Best Streak: \(viewModel.bestStreak)")
                            .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .accessibilityLabel("Best streak: \(viewModel.bestStreak) correct answers in a row")
                }
            }

            HStack(spacing: L2RTheme.Spacing.lg) {
                Button {
                    viewModel.startGame()
                } label: {
                    Text("Play Again")
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
                .juicyButtonPress()
                .accessibilityLabel("Play Again")
                .accessibilityHint("Start a new game")
                .accessibilityIdentifier(AccessibilityIdentifiers.SpellingGame.playAgainButton)

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
                .juicyButtonPress()
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
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(viewModel.streak) in a row!")
                    .font(L2RTheme.Typography.Scaled.system(.title2, weight: .medium))
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

    /// Converts correct/total into a 1-3 star rating.
    private func starRating(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 1 }
        let pct = Double(correct) / Double(total)
        if pct >= 0.8 { return 3 }
        if pct >= 0.5 { return 2 }
        return 1
    }
}

// MARK: - Rainbow Shimmer Text

/// Text with a sweeping rainbow gradient animation using L2R logo colors.
private struct RainbowShimmerText: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1.0

    private let colors: [Color] = L2RTheme.Logo.all + [L2RTheme.Logo.all[0]]

    var body: some View {
        if reduceMotion {
            Text(text)
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))
                .foregroundStyle(L2RTheme.Logo.all[0])
        } else {
            animatedText
        }
    }

    private var animatedText: some View {
        Text(text)
            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: colors,
                    startPoint: UnitPoint(x: phase, y: 0.5),
                    endPoint: UnitPoint(x: phase + 1.0, y: 0.5)
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

// MARK: - Preview

#Preview("Spelling Game") {
    SpellingGameView()
}

#Preview("Playing State") {
    SpellingGameView()
}
