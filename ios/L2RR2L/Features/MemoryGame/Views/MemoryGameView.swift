import SwiftUI

/// Main view for the Memory Game.
/// Players flip cards to find matching sight word pairs.
struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var childProfileService = ChildProfileService.shared

    private let voiceService = VoiceService.shared
    private var childName: String { childProfileService.activeChild?.name ?? "Friend" }

    @State private var showConfetti = false
    @State private var matchCorrectTrigger = false
    @State private var mascotState = MascotState()
    @State private var inactivityManager = InactivityHintManager()
    @State private var showLevelUpCeremony = false

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
                        .roundTransition(round: viewModel.currentLevel, label: "Level")
                }

                Spacer()
            }
            .padding()
        }
        .overlay(alignment: .bottomLeading) {
            MascotView(state: mascotState)
                .padding(L2RTheme.Spacing.md)
        }
        .onChange(of: viewModel.gameState) { _, state in
            if state == .playing {
                Task { await voiceService.speak("Find the match!") }
            } else if state == .levelComplete {
                mascotState.proud(message: "You did it, \(childName)!")
                Task { await voiceService.speak("Great job!") }
            }
        }
        .onChange(of: viewModel.matchedPairsCount) { oldCount, newCount in
            if newCount > oldCount {
                mascotState.celebrate()
            }
        }
        .onChange(of: viewModel.showCelebration) { _, show in
            showConfetti = show
            if show { mascotState.dance() }
        }
        .confetti(isActive: $showConfetti, configuration: .gameComplete)
        .overlay {
            if showLevelUpCeremony {
                LevelUpCeremonyView(currentLevel: viewModel.currentLevel) {
                    showLevelUpCeremony = false
                    viewModel.nextLevel()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLevelUpCeremony)
        .overlay {
            if viewModel.showSpeedMatch {
                Text("Speed Match!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title2, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [L2RTheme.Logo.yellow, L2RTheme.Logo.orange], startPoint: .leading, endPoint: .trailing))
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if viewModel.comboCount >= 2 {
                Text("\(viewModel.comboCount)x Combo!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.lg)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(L2RTheme.Logo.purple)
                    )
                    .padding(.top, 120)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: viewModel.showSpeedMatch)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.comboCount)
        .onAppear { inactivityManager.setHintMessage("Tap a card to flip it!") }
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
            .juicyButtonPress()
            .accessibilityLabel("Start Game")
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: L2RTheme.Spacing.lg) {
            // Peek banner
            if viewModel.isPeeking {
                Text("Remember the cards!")
                    .font(L2RTheme.Typography.Scaled.playful(relativeTo: .title3, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, L2RTheme.Spacing.xl)
                    .padding(.vertical, L2RTheme.Spacing.sm)
                    .background(Capsule().fill(L2RTheme.Logo.blue.opacity(0.8)))
                    .transition(.opacity)
            }

            // Progress
            progressBar

            // Card grid
            cardGrid
        }
        .animation(.easeInOut, value: viewModel.isPeeking)
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
            .juicyCorrect(trigger: $matchCorrectTrigger)
            .padding(L2RTheme.Spacing.md)
        }
        .onChange(of: viewModel.matchedPairsCount) { _, _ in
            if viewModel.matchedPairsCount > 0 {
                matchCorrectTrigger = true
            }
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
            MascotView(state: mascotState, size: 120)

            Text("Great job, \(childName)!")
                .font(L2RTheme.Typography.Scaled.playful(relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(.white)

            AnimatedStarRating(starCount: memoryStarRating(moves: viewModel.moves, pairs: viewModel.totalPairs))

            if viewModel.personalBestResult?.isNewRecord == true {
                PersonalBestBadgeView()
            }

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
                        showLevelUpCeremony = true
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
                    .juicyButtonPress()
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
                .juicyButtonPress()

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
            }
        }
    }

    /// Converts moves efficiency into a 1-3 star rating for memory game.
    private func memoryStarRating(moves: Int, pairs: Int) -> Int {
        guard pairs > 0 else { return 1 }
        let ratio = Double(moves) / Double(pairs)
        if ratio <= 2.0 { return 3 }  // Near perfect memory
        if ratio <= 3.0 { return 2 }
        return 1
    }
}

#Preview {
    MemoryGameView()
}
