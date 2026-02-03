import Foundation
import Combine

/// View model for the Rhyme Game.
/// Manages game state, scoring, and question generation.
@MainActor
final class RhymeGameViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var gameState: RhymeGameState = .notStarted
    @Published private(set) var currentQuestion: RhymeQuestion?
    @Published private(set) var score: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var currentRound: Int = 0
    @Published private(set) var selectedOption: RhymeOptionItem?
    @Published var showCelebration: Bool = false

    // MARK: - Configuration

    let totalRounds: Int = 10
    let difficulty: Int = 1
    private let distractorCount: Int = 3

    // MARK: - Computed Properties

    var isCorrectSelection: Bool {
        guard let selected = selectedOption,
              let question = currentQuestion else { return false }
        return selected.id == question.correctAnswer.id
    }

    // MARK: - Game Actions

    func startGame() {
        score = 0
        streak = 0
        bestStreak = 0
        currentRound = 0
        selectedOption = nil
        gameState = .playing
        nextQuestion()
    }

    func selectOption(_ option: RhymeOptionItem) {
        guard gameState == .playing else { return }

        selectedOption = option
        gameState = .checking

        let isCorrect = option.id == currentQuestion?.correctAnswer.id

        if isCorrect {
            score += 1
            streak += 1
            if streak > bestStreak {
                bestStreak = streak
            }
            gameState = .correct

            // Trigger celebration at milestone streaks
            if streak == 5 || streak == 10 {
                showCelebration = true
            }
        } else {
            streak = 0
            gameState = .incorrect
        }
    }

    func nextQuestion() {
        currentRound += 1
        selectedOption = nil

        if currentRound > totalRounds {
            gameState = .gameComplete
            return
        }

        if let question = RhymeData.generateQuestion(difficulty: difficulty, distractorCount: distractorCount) {
            currentQuestion = question
            gameState = .playing
        } else {
            // Fallback if question generation fails
            gameState = .gameComplete
        }
    }

    func playTargetWordAudio() {
        // Audio playback will be implemented later
        // For now, this is a no-op placeholder
    }
}
