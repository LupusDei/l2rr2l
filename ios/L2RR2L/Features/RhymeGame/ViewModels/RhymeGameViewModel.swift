import Foundation
import Combine

/// ViewModel for the Rhyme Matching Game.
/// Players select which word rhymes with a target word.
@MainActor
class RhymeGameViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current target word that players must find a rhyme for
    @Published private(set) var currentWord: RhymeWord?

    /// Available answer options for the current round
    @Published private(set) var options: [RhymeOptionItem] = []

    /// Current score (number of correct answers)
    @Published private(set) var score = 0

    /// Current streak of consecutive correct answers
    @Published private(set) var streak = 0

    /// Current round number (1-based)
    @Published private(set) var round = 1

    /// Result of the last answer (nil if no answer submitted yet)
    @Published private(set) var isCorrect: Bool?

    /// Current game state
    @Published private(set) var gameState: RhymeGameState = .notStarted

    /// The selected answer option (for UI highlighting)
    @Published private(set) var selectedOption: RhymeOptionItem?

    /// The correct answer for the current round
    @Published private(set) var correctAnswer: RhymeWord?

    /// Current difficulty level
    @Published var difficulty: RhymeDifficulty = .easy

    /// Whether to show celebration overlay (streak milestones)
    @Published private(set) var showCelebration = false

    // MARK: - Configuration

    /// Total number of rounds per game session
    let totalRounds = 10

    /// Number of answer options per round (1 correct + distractors)
    private let optionsCount = 4

    // MARK: - Private Properties

    /// Words already used as targets in this session
    private var usedTargetWords: Set<String> = []

    /// Best streak achieved in this session
    private(set) var bestStreak = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Starts a new game session
    func startGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedTargetWords.removeAll()
        isCorrect = nil
        selectedOption = nil
        correctAnswer = nil

        gameState = .playing
        setupRound()
    }

    /// Advances to the next round
    func nextRound() {
        guard round < totalRounds else {
            gameState = .gameComplete
            return
        }

        round += 1
        isCorrect = nil
        selectedOption = nil
        correctAnswer = nil
        gameState = .playing
        setupRound()
    }

    /// Selects an answer option
    /// - Parameter option: The selected rhyme option
    /// - Returns: Whether the answer was correct
    @discardableResult
    func selectAnswer(_ option: RhymeOptionItem) -> Bool {
        guard gameState == .playing, selectedOption == nil else {
            return false
        }

        selectedOption = option
        gameState = .checking

        // Check if the selected option is the correct rhyming word
        let isAnswerCorrect: Bool
        if case .word(let selectedWord) = option,
           let correct = correctAnswer,
           selectedWord.id == correct.id {
            isAnswerCorrect = true
        } else {
            isAnswerCorrect = false
        }

        isCorrect = isAnswerCorrect

        if isAnswerCorrect {
            score += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            gameState = .correct
        } else {
            streak = 0
            gameState = .incorrect
        }

        return isAnswerCorrect
    }

    /// Resets the game to initial state
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedTargetWords.removeAll()
        isCorrect = nil
        selectedOption = nil
        currentWord = nil
        correctAnswer = nil
        options = []
        gameState = .notStarted
    }

    /// Plays audio for the target word (placeholder for TTS integration)
    func playTargetWordAudio() {
        guard let word = currentWord else { return }
        // Play sound effect as feedback
        SoundEffectService.shared.play(.buttonTap)
        // TODO: Integrate with VoiceService for TTS
        print("Playing audio for: \(word.word)")
    }

    /// Selects an option (alias for selectAnswer)
    func selectOption(_ option: RhymeOptionItem) {
        let wasCorrect = selectAnswer(option)
        // Trigger celebration for streak milestones
        if wasCorrect && streak > 0 && streak % 3 == 0 {
            showCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showCelebration = false
            }
        }
    }

    /// Advances to next question (alias for nextRound)
    func nextQuestion() {
        nextRound()
    }

    /// Progress through the game (0.0 to 1.0)
    var progress: Double {
        Double(round - 1) / Double(totalRounds)
    }

    /// Alias for round (used by view)
    var currentRound: Int {
        round
    }

    /// Current question combining target, correct answer, and options
    var currentQuestion: RhymeQuestion? {
        guard let target = currentWord, let correct = correctAnswer else {
            return nil
        }
        return RhymeQuestion(
            targetWord: target,
            correctAnswer: correct,
            distractors: options.filter { $0.id != correct.id },
            allOptions: options
        )
    }

    /// Whether the game is complete
    var isGameComplete: Bool {
        gameState == .gameComplete
    }

    /// Final score as a percentage
    var scorePercentage: Int {
        guard totalRounds > 0 else { return 0 }
        return Int(Double(score) / Double(totalRounds) * 100)
    }

    // MARK: - Private Methods

    /// Sets up a new round with a target word and options
    private func setupRound() {
        let maxDifficulty = difficulty.rawValue

        // Generate a rhyme question
        guard let question = generateQuestion(maxDifficulty: maxDifficulty) else {
            // Fallback: reset used words and try again
            usedTargetWords.removeAll()
            if let retryQuestion = generateQuestion(maxDifficulty: maxDifficulty) {
                currentWord = retryQuestion.targetWord
                correctAnswer = retryQuestion.correctAnswer
                options = retryQuestion.allOptions
                usedTargetWords.insert(retryQuestion.targetWord.id)
            }
            return
        }

        currentWord = question.targetWord
        correctAnswer = question.correctAnswer
        options = question.allOptions
        usedTargetWords.insert(question.targetWord.id)
    }

    /// Generates a rhyme question avoiding previously used target words
    private func generateQuestion(maxDifficulty: Int) -> RhymeQuestion? {
        let shuffledFamilies = RhymeData.wordFamilies.shuffled()

        for family in shuffledFamilies {
            let wordsInFamily = RhymeData.words(inFamily: family, maxDifficulty: maxDifficulty)
                .filter { !usedTargetWords.contains($0.id) }

            // Need at least 2 words in the family (target + correct answer)
            guard wordsInFamily.count >= 2 else { continue }

            let shuffled = wordsInFamily.shuffled()
            let targetWord = shuffled[0]
            let correctAnswer = shuffled[1]

            // Gather distractor options
            var availableDistractors: [RhymeOptionItem] = []

            // Add words from other families
            let otherFamilyWords = RhymeData.words.filter { word in
                word.wordFamily != family && word.difficulty <= maxDifficulty
            }
            availableDistractors.append(contentsOf: otherFamilyWords.map { .word($0) })

            // Add confusing distractors for this family
            let confusingDistractors = RhymeData.distractors(forFamily: family, maxDifficulty: maxDifficulty)
            availableDistractors.append(contentsOf: confusingDistractors.map { .distractor($0) })

            // Shuffle and select required number of distractors
            let distractorCount = optionsCount - 1
            let selectedDistractors = Array(availableDistractors.shuffled().prefix(distractorCount))

            // Combine correct answer with distractors and shuffle
            var allOptions = selectedDistractors
            allOptions.append(.word(correctAnswer))
            allOptions.shuffle()

            return RhymeQuestion(
                targetWord: targetWord,
                correctAnswer: correctAnswer,
                distractors: selectedDistractors,
                allOptions: allOptions
            )
        }

        return nil
    }
}

// MARK: - Difficulty Enum

/// Difficulty levels for the rhyme game
enum RhymeDifficulty: Int, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Simple word families"
        case .medium: return "More word families"
        case .hard: return "Blends and digraphs"
        }
    }
}
