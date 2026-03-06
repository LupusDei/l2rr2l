import SwiftUI

/// Main view for the Word Builder game.
/// Players see an emoji hint and build words by tapping letters from a bank.
struct WordBuilderView: View {
    @StateObject private var viewModel = WordBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var childProfileService = ChildProfileService.shared

    private let voiceService = VoiceService.shared
    private var childName: String { childProfileService.activeChild?.name ?? "Friend" }

    @State private var showConfetti = false
    @State private var showGameCompleteConfetti = false
    @State private var correctTrigger = false
    @State private var incorrectTrigger = false
    @State private var snapTrigger = false
    @State private var mascotState = MascotState()
    @State private var inactivityManager = InactivityHintManager()
    @State private var emojiAlive = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background
            LinearGradient.wordBuilder
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
                        .roundTransition(round: viewModel.round, label: "Puzzle")
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
                emojiAlive = false
                Task { await voiceService.speak("Build the word!") }
            } else if state == .correct {
                mascotState.celebrate()
                if !reduceMotion {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                        emojiAlive = true
                    }
                }
            } else if state == .incorrect {
                mascotState.encourage()
            } else if state == .gameComplete {
                showGameCompleteConfetti = true
                mascotState.proud(message: "You did it, \(childName)!")
                Task { await voiceService.speak("Great job!") }
            }
            if state == .correct, let word = viewModel.currentPuzzle?.word {
                Task { await voiceService.speak(word) }
            }
        }
        .onChange(of: viewModel.builtWord.count) { oldCount, newCount in
            if newCount > oldCount {
                snapTrigger = true
            }
        }
        .confetti(isActive: $showGameCompleteConfetti, configuration: .gameComplete)
        .onAppear { inactivityManager.setHintMessage("Tap letters to build!") }
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
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.closeButton)

            Spacer()

            // Score
            HStack(spacing: L2RTheme.Spacing.xs) {
                Text("Score:")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(viewModel.score)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Score: \(viewModel.score) points")

            Spacer()

            // Round and streak
            VStack(alignment: .trailing, spacing: L2RTheme.Spacing.xxs) {
                Text("Puzzle \(viewModel.round)/\(viewModel.totalRounds)")
                    .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                if viewModel.streak > 0 {
                    HStack(spacing: L2RTheme.Spacing.xxs) {
                        Text("\u{1F525}")
                        Text("\(viewModel.streak)")
                            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Streak: \(viewModel.streak)")
                }
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F3D7}")
                .font(.system(size: 80))

            Text("Word Builder")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Build words by tapping the letters!")
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
            .accessibilityHint("Begin the word builder game")
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.startButton)
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            // Emoji hint
            if let puzzle = viewModel.currentPuzzle {
                VStack(spacing: L2RTheme.Spacing.sm) {
                    Text(puzzle.emoji)
                        .font(.system(size: 80))
                        .scaleEffect(emojiAlive ? 1.3 : 1.0)
                        .rotationEffect(.degrees(emojiAlive ? 8 : 0))
                        .overlay {
                            if emojiAlive && !reduceMotion {
                                EmojiSparkles()
                            }
                        }
                        .accessibilityLabel("Hint: \(puzzle.emoji)")
                        .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.hintEmoji)

                    Text("What am I?")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    // Show word when correct
                    if viewModel.gameState == .correct {
                        Text(puzzle.word.uppercased())
                            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // Built word display
            builtWordArea

            // Letter controls
            letterControls

            // Letter bank
            letterBankArea
        }
        .animation(.easeInOut, value: viewModel.gameState)
    }

    // MARK: - Built Word Area

    private var builtWordArea: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            // Built word slots
            HStack(spacing: L2RTheme.Spacing.xs) {
                if viewModel.builtWord.isEmpty {
                    // Empty state placeholder
                    ForEach(0..<(viewModel.currentPuzzle?.length ?? 3), id: \.self) { _ in
                        emptySlot
                    }
                } else {
                    ForEach(Array(viewModel.builtWord.enumerated()), id: \.offset) { _, letter in
                        builtLetterTile(letter)
                            .transition(
                                .asymmetric(
                                    insertion: .offset(y: -30).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                )
                            )
                    }
                    // Add empty slots for remaining letters
                    if let puzzle = viewModel.currentPuzzle {
                        ForEach(viewModel.builtWord.count..<puzzle.length, id: \.self) { _ in
                            emptySlot
                        }
                    }
                }
            }
            .juicySnap(trigger: $snapTrigger)
            .juicyCorrect(trigger: $correctTrigger)
            .juicyIncorrect(trigger: $incorrectTrigger)
            .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65), value: viewModel.builtWord.count)
            .padding(.vertical, L2RTheme.Spacing.md)
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.builtWord)
        }
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
            .fill(Color.white.opacity(0.2))
            .frame(minWidth: 52, idealWidth: 60, minHeight: 60)
            .overlay(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
    }

    private func builtLetterTile(_ letter: Character) -> some View {
        let isCorrect = viewModel.gameState == .correct
        let isIncorrect = viewModel.gameState == .incorrect

        return Text(String(letter).uppercased())
            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 52, idealWidth: 60, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(
                        isCorrect ? L2RTheme.Status.success :
                        isIncorrect ? L2RTheme.Status.error :
                        L2RTheme.Game.builderStart
                    )
            )
            .shadow(
                color: (isCorrect ? L2RTheme.Status.success : isIncorrect ? L2RTheme.Status.error : L2RTheme.Game.builderShadow).opacity(0.5),
                radius: 4,
                y: 4
            )
    }

    // MARK: - Letter Controls

    private var letterControls: some View {
        HStack(spacing: L2RTheme.Spacing.lg) {
            // Delete button
            Button {
                viewModel.deleteLetter()
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: "delete.left.fill")
                    Text("Delete")
                }
                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.vertical, L2RTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
            }
            .disabled(!viewModel.hasBuiltLetters || viewModel.gameState != .playing)
            .opacity(viewModel.hasBuiltLetters && viewModel.gameState == .playing ? 1.0 : 0.5)
            .juicyButtonPress()
            .accessibilityLabel("Delete last letter")
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.deleteButton)

            // Clear button
            Button {
                viewModel.clearWord()
            } label: {
                HStack(spacing: L2RTheme.Spacing.xs) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Clear")
                }
                .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, L2RTheme.Spacing.lg)
                .padding(.vertical, L2RTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )
            }
            .disabled(!viewModel.hasBuiltLetters || viewModel.gameState != .playing)
            .opacity(viewModel.hasBuiltLetters && viewModel.gameState == .playing ? 1.0 : 0.5)
            .juicyButtonPress()
            .accessibilityLabel("Clear all letters")
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.clearButton)
        }
    }

    // MARK: - Letter Bank Area

    private var letterBankArea: some View {
        VStack(spacing: L2RTheme.Spacing.sm) {
            let columns = [
                GridItem(.adaptive(minimum: 64, maximum: 80), spacing: L2RTheme.Spacing.sm)
            ]

            LazyVGrid(columns: columns, spacing: L2RTheme.Spacing.sm) {
                ForEach(Array(viewModel.availableLetters.enumerated()), id: \.element.id) { index, tile in
                    letterBankTile(tile: tile, index: index)
                }
            }
            .padding(L2RTheme.Spacing.md)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large))
            .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.letterBank)
        }
    }

    private func letterBankTile(tile: WordBuilderTile, index: Int) -> some View {
        let tileColors = L2RTheme.Logo.all

        return Text(String(tile.letter).uppercased())
            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title, weight: .bold))
            .foregroundStyle(.white)
            .frame(minWidth: 56, idealWidth: 64, minHeight: 56, idealHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [
                                tileColors[index % tileColors.count].opacity(0.9),
                                tileColors[index % tileColors.count]
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(
                color: tileColors[index % tileColors.count].opacity(0.4),
                radius: tile.isUsed ? 0 : 4,
                y: tile.isUsed ? 0 : 4
            )
            .opacity(tile.isUsed ? 0.3 : 1.0)
            .scaleEffect(tile.isUsed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tile.isUsed)
            .juicyTap {
                guard !tile.isUsed, viewModel.gameState == .playing else { return }
                viewModel.selectLetter(at: index)
            }
            .allowsHitTesting(!tile.isUsed && viewModel.gameState == .playing)
            .accessibilityLabel("Letter \(String(tile.letter).uppercased())")
            .accessibilityHint(tile.isUsed ? "Already used" : "Tap to add to word")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            Spacer()

            if viewModel.gameState == .correct || viewModel.gameState == .incorrect {
                Button {
                    viewModel.nextPuzzle()
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(LinearGradient.ctaButton)
                            .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 4, y: 4)
                    )
                }
                .juicyButtonPress()
                .accessibilityLabel("Next puzzle")
                .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.nextButton)
            } else {
                Button {
                    let correct = viewModel.checkAnswer()
                    if correct {
                        correctTrigger = true
                    } else {
                        incorrectTrigger = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Check Answer")
                    }
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .callout, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(viewModel.hasBuiltLetters ? LinearGradient.ctaButton : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: viewModel.hasBuiltLetters ? L2RTheme.CTA.shadow.opacity(0.5) : .clear, radius: 4, y: 4)
                    )
                }
                .disabled(!viewModel.hasBuiltLetters)
                .juicyButtonPress()
                .accessibilityLabel("Check answer")
                .accessibilityHint(viewModel.hasBuiltLetters ? "Verify your word" : "Build a word first")
                .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.checkButton)
            }

            Spacer()
        }
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
                    .accessibilityLabel("Best streak: \(viewModel.bestStreak)")
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
                .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.playAgainButton)

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
                .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.doneButton)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.WordBuilder.gameComplete)
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

// MARK: - Emoji Sparkles

/// Sparkle particles that burst outward when the emoji "comes alive" on correct answer.
private struct EmojiSparkles: View {
    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let offsets: [(x: CGFloat, y: CGFloat)] = [
        (-35, -40), (30, -35), (-20, 30),
        (40, 15), (-40, 10), (15, -45)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Text(i % 2 == 0 ? "\u{2728}" : "\u{2B50}")
                    .font(.system(size: CGFloat(14 + (i % 3) * 4)))
                    .offset(
                        x: animate ? Self.offsets[i].x : 0,
                        y: animate ? Self.offsets[i].y : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.2 : 0.3)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Word Builder") {
    WordBuilderView()
}

#Preview("Playing State") {
    WordBuilderView()
}
