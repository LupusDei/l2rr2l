import Foundation
import Combine

/// ViewModel for the Phonics Sound Matching Game.
/// Players identify the beginning (or ending) sound of displayed words.
@MainActor
class PhonicsGameViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current word being displayed
    @Published private(set) var currentWord: PhonicsWord?

    /// Position of the sound to identify (beginning/ending)
    @Published private(set) var soundPosition: SoundPosition = .beginning

    /// Available answer options for the current round
    @Published private(set) var options: [SoundOption] = []

    /// Current score (number of correct answers)
    @Published private(set) var score = 0

    /// Current streak of consecutive correct answers
    @Published private(set) var streak = 0

    /// Current round number (1-based)
    @Published private(set) var round = 1

    /// Result of the last answer (nil if no answer submitted yet)
    @Published private(set) var isCorrect: Bool?

    /// Current game state
    @Published private(set) var gameState: PhonicsGameState = .notStarted

    /// The selected answer option (for UI highlighting)
    @Published private(set) var selectedOption: SoundOption?

    // MARK: - Configuration

    /// Total number of rounds per game session
    let totalRounds = 10

    /// Number of answer options per round
    private let optionsCount = 4

    /// Maximum difficulty level (1-3)
    private let maxDifficulty = 2

    // MARK: - Private Properties

    /// Pool of words to use in the game
    private var wordPool: [PhonicsWord] = []

    /// Words already used in this session
    private var usedWords: Set<String> = []

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
        usedWords.removeAll()
        isCorrect = nil
        selectedOption = nil

        // Build word pool with appropriate difficulty
        wordPool = PhonicsData.words(forDifficulty: maxDifficulty)

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
        gameState = .playing
        setupRound()
    }

    /// Selects an answer option
    /// - Parameter option: The selected sound option
    /// - Returns: Whether the answer was correct
    @discardableResult
    func selectAnswer(_ option: SoundOption) -> Bool {
        guard gameState == .playing, selectedOption == nil else {
            return false
        }

        selectedOption = option
        isCorrect = option.isCorrect

        if option.isCorrect {
            score += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }

        gameState = .roundComplete(correct: option.isCorrect)
        return option.isCorrect
    }

    /// Resets the game to initial state
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedWords.removeAll()
        isCorrect = nil
        selectedOption = nil
        currentWord = nil
        options = []
        gameState = .notStarted
    }

    /// Gets the correct sound for the current word
    var correctSound: String? {
        guard let word = currentWord else { return nil }
        switch soundPosition {
        case .beginning:
            return word.beginningSound
        case .ending:
            // For ending sounds, use the last phoneme
            return word.phonemes.last
        }
    }

    /// Progress through the game (0.0 to 1.0)
    var progress: Double {
        Double(round - 1) / Double(totalRounds)
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

    /// Sets up a new round with a word and options
    private func setupRound() {
        // Select a word that hasn't been used yet
        let availableWords = wordPool.filter { !usedWords.contains($0.id) }

        guard let word = availableWords.randomElement() else {
            // If we've used all words, reshuffle (shouldn't happen with 10 rounds and 30 words)
            usedWords.removeAll()
            currentWord = wordPool.randomElement()
            if let current = currentWord {
                usedWords.insert(current.id)
            }
            generateOptions()
            return
        }

        currentWord = word
        usedWords.insert(word.id)
        generateOptions()
    }

    /// Generates answer options for the current word
    private func generateOptions() {
        guard let word = currentWord else {
            options = []
            return
        }

        let correctSound: String
        switch soundPosition {
        case .beginning:
            correctSound = word.beginningSound
        case .ending:
            correctSound = word.phonemes.last ?? word.beginningSound
        }

        // Get incorrect sounds (different from the correct one)
        var incorrectSounds = PhonicsData.beginningSounds.filter { $0 != correctSound }
        incorrectSounds.shuffle()

        // Build options array
        var newOptions: [SoundOption] = [
            SoundOption(sound: correctSound.uppercased(), isCorrect: true)
        ]

        // Add incorrect options
        for sound in incorrectSounds.prefix(optionsCount - 1) {
            newOptions.append(SoundOption(sound: sound.uppercased(), isCorrect: false))
        }

        // Shuffle options so correct answer isn't always first
        options = newOptions.shuffled()
    }
}
