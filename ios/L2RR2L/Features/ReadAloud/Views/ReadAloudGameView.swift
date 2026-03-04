import SwiftUI

/// Main view for the Read Aloud game.
/// Players read sight words aloud using speech recognition.
struct ReadAloudGameView: View {
    @StateObject private var viewModel = ReadAloudGameViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showGameCompleteConfetti = false
    @State private var micPulse = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.readAloudGame
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
        }
        .onChange(of: viewModel.gameState) { _, state in
            if state == .gameComplete {
                showGameCompleteConfetti = true
            }
        }
        .confetti(isActive: $showGameCompleteConfetti, configuration: .gameComplete)
        .onDisappear {
            viewModel.resetGame()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Close button
            Button {
                viewModel.resetGame()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(minWidth: L2RTheme.TouchTarget.minimum, minHeight: L2RTheme.TouchTarget.minimum)
            }
            .accessibilityLabel("Close game")
            .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.closeButton)

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
            .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.scoreLabel)

            Spacer()

            // Round indicator
            if viewModel.gameState != .notStarted && viewModel.gameState != .gameComplete {
                Text("Word \(viewModel.round)/\(viewModel.totalRounds)")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityLabel("Word \(viewModel.round) of \(viewModel.totalRounds)")
                    .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.roundLabel)

                Spacer()
            }

            // Streak
            if viewModel.streak > 0 {
                HStack(spacing: L2RTheme.Spacing.xxs) {
                    Text("\u{1F525}")
                    Text("\(viewModel.streak)")
                        .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak: \(viewModel.streak) correct in a row")
                .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.streakLabel)
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.md)
        .padding(.vertical, L2RTheme.Spacing.md)
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F4D6}")
                .font(.system(size: 80))

            Text("Read Aloud")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            Text("Read the word out loud!")
                .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            // Level selector
            levelSelector

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
            .accessibilityHint("Begin reading words aloud")
            .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.startButton)
        }
    }

    // MARK: - Level Selector

    private var levelSelector: some View {
        HStack(spacing: L2RTheme.Spacing.sm) {
            ForEach(ReadAloudLevel.allCases) { level in
                Button {
                    viewModel.selectedLevel = level
                } label: {
                    VStack(spacing: L2RTheme.Spacing.xxs) {
                        Text(level.emoji)
                            .font(.system(size: 24))
                        Text(level.displayName)
                            .font(L2RTheme.Typography.Scaled.system(.footnote, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                            .fill(viewModel.selectedLevel == level ? .white.opacity(0.3) : .white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.medium)
                            .strokeBorder(.white.opacity(viewModel.selectedLevel == level ? 0.8 : 0.2), lineWidth: 2)
                    )
                }
                .accessibilityLabel("\(level.displayName) level")
                .accessibilityHint(level.description)
            }
        }
        .padding(.horizontal, L2RTheme.Spacing.lg)
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.xxl) {
            // Target word
            wordDisplay

            // Microphone / feedback
            microphoneSection

            // Feedback text
            feedbackSection
        }
    }

    // MARK: - Word Display

    private var wordDisplay: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            Text("Read this word:")
                .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

            if let word = viewModel.currentWord {
                Text(word.uppercased())
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xxl)
                    .padding(.vertical, L2RTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: L2RTheme.CornerRadius.large)
                            .fill(.white.opacity(0.15))
                    )
                    .accessibilityLabel("Word: \(word)")
                    .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.targetWord)
            }
        }
    }

    // MARK: - Microphone Section

    private var microphoneSection: some View {
        VStack(spacing: L2RTheme.Spacing.md) {
            if viewModel.gameState == .recording {
                // Recording indicator with audio level
                ZStack {
                    // Audio level ring
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0 + CGFloat(viewModel.audioLevel) * 0.3)
                        .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)

                    Button {
                        viewModel.stopRecording()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(L2RTheme.Status.error)
                            )
                    }
                    .accessibilityLabel("Stop recording")
                    .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.micButton)
                }

                Text("Listening...")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

            } else if viewModel.gameState == .listening {
                // Microphone button
                Button {
                    Task {
                        await viewModel.startRecording()
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(LinearGradient.ctaButton)
                                .shadow(color: L2RTheme.CTA.shadow.opacity(0.5), radius: 6, y: 4)
                        )
                        .scaleEffect(micPulse ? 1.1 : 1.0)
                }
                .accessibilityLabel("Start recording")
                .accessibilityHint("Tap to read the word aloud")
                .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.micButton)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        micPulse = true
                    }
                }
                .onDisappear {
                    micPulse = false
                }

                Text("Tap the microphone and read the word!")
                    .font(L2RTheme.Typography.Scaled.system(.callout, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Feedback Section

    @ViewBuilder
    private var feedbackSection: some View {
        if viewModel.gameState == .correct || viewModel.gameState == .incorrect {
            VStack(spacing: L2RTheme.Spacing.md) {
                if viewModel.isCorrect == true {
                    // Correct feedback
                    HStack(spacing: L2RTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(L2RTheme.Status.success)
                        Text("Great job!")
                            .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Incorrect feedback
                    VStack(spacing: L2RTheme.Spacing.sm) {
                        HStack(spacing: L2RTheme.Spacing.sm) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.yellow)
                            Text("Try again next time!")
                                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        if let word = viewModel.currentWord {
                            Text("The word is: \(word)")
                                .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                // Next button
                Button {
                    viewModel.nextWord()
                } label: {
                    Text(viewModel.round >= viewModel.totalRounds ? "See Results" : "Next Word")
                        .font(L2RTheme.Typography.Scaled.system(.callout, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, L2RTheme.Spacing.xl)
                        .padding(.vertical, L2RTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.2))
                        )
                }
                .frame(minHeight: L2RTheme.TouchTarget.minimum)
                .accessibilityLabel(viewModel.round >= viewModel.totalRounds ? "See Results" : "Next Word")
            }
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.gameState)
        }
    }

    // MARK: - Game Complete View

    private var gameCompleteView: some View {
        VStack(spacing: L2RTheme.Spacing.xl) {
            Text("\u{1F389}")
                .font(.system(size: 80))

            Text("Great Job!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: L2RTheme.Spacing.sm) {
                Text("Score: \(viewModel.score)")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Final score: \(viewModel.score) points")

                Text("Best Streak: \(viewModel.bestStreak)")
                    .font(L2RTheme.Typography.Scaled.system(.body, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityLabel("Best streak: \(viewModel.bestStreak) correct in a row")
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
                .accessibilityLabel("Play Again")
                .accessibilityHint("Start a new game")
                .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.playAgainButton)

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
                .accessibilityLabel("Done")
                .accessibilityHint("Return to games menu")
                .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.doneButton)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.ReadAloud.gameComplete)
    }
}

// MARK: - Preview

#Preview("Read Aloud Game") {
    ReadAloudGameView()
}
