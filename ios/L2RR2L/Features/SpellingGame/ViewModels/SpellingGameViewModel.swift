import Foundation
import Combine

/// ViewModel for the Spelling Game.
/// Players arrange scrambled letters to spell words.
@MainActor
class SpellingGameViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current word being spelled
    @Published private(set) var currentWord: SpellingWord?

    /// Scrambled letters available for placement
    @Published private(set) var scrambledLetters: [LetterTileModel] = []

    /// Letters placed in drop zones (nil = empty slot)
    @Published private(set) var placedLetters: [Character?] = []

    /// Current score (number of correct words)
    @Published private(set) var score = 0

    /// Current streak of consecutive correct answers
    @Published private(set) var streak = 0

    /// Result of the last check (nil if not checked yet)
    @Published private(set) var isCorrect: Bool?

    /// Whether to show celebration animation
    @Published private(set) var showCelebration = false

    /// Current game state
    @Published private(set) var gameState: SpellingGameState = .notStarted

    /// Current round number (1-based)
    @Published private(set) var round = 1

    // MARK: - Configuration

    /// Total number of rounds per game session
    let totalRounds = 10

    // MARK: - Private Properties

    /// Pool of words to use in the game
    private var wordPool: [SpellingWord] = []

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
        showCelebration = false

        // Build word pool
        wordPool = SpellingData.words

        gameState = .playing
        setupWord()
    }

    /// Advances to the next word
    func nextWord() {
        guard round < totalRounds else {
            gameState = .gameComplete
            return
        }

        round += 1
        isCorrect = nil
        showCelebration = false
        gameState = .playing
        setupWord()
    }

    /// Places a letter at a specific drop zone index
    /// - Parameters:
    ///   - letter: The letter to place
    ///   - index: The drop zone index
    /// - Returns: Whether the letter was placed successfully
    @discardableResult
    func placeLetter(_ letter: Character, at index: Int) -> Bool {
        guard gameState == .playing else { return false }
        guard index >= 0 && index < placedLetters.count else { return false }
        guard placedLetters[index] == nil else { return false }

        // Find the letter tile and mark as placed
        if let tileIndex = scrambledLetters.firstIndex(where: { $0.letter == letter && !$0.isPlaced }) {
            scrambledLetters[tileIndex].isPlaced = true
            placedLetters[index] = letter
            return true
        }
        return false
    }

    /// Places a letter in the next available drop zone
    /// - Parameter letter: The letter to place
    /// - Returns: Whether the letter was placed successfully
    @discardableResult
    func placeLetterInNextSlot(_ letter: Character) -> Bool {
        guard let nextIndex = placedLetters.firstIndex(where: { $0 == nil }) else {
            return false
        }
        return placeLetter(letter, at: nextIndex)
    }

    /// Removes a letter from a drop zone
    /// - Parameter index: The drop zone index
    func removeLetter(at index: Int) {
        guard gameState == .playing else { return }
        guard index >= 0 && index < placedLetters.count else { return }
        guard let letter = placedLetters[index] else { return }

        // Find the letter tile and mark as not placed
        if let tileIndex = scrambledLetters.firstIndex(where: { $0.letter == letter && $0.isPlaced }) {
            scrambledLetters[tileIndex].isPlaced = false
        }
        placedLetters[index] = nil
    }

    /// Checks if the current answer is correct
    /// - Returns: Whether the spelling is correct
    @discardableResult
    func checkAnswer() -> Bool {
        guard gameState == .playing else { return false }
        guard let word = currentWord else { return false }
        guard !placedLetters.contains(nil) else { return false }

        gameState = .checking

        let attempt = String(placedLetters.compactMap { $0 })
        let correct = attempt.lowercased() == word.word.lowercased()

        isCorrect = correct

        if correct {
            score += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            gameState = .correct

            // Trigger celebration for streaks
            if streak >= 3 && streak % 3 == 0 {
                showCelebration = true
            }
        } else {
            streak = 0
            gameState = .incorrect
        }

        return correct
    }

    /// Re-scrambles the available (not placed) letters
    func scrambleLetters() {
        guard gameState == .playing else { return }

        let unplacedIndices = scrambledLetters.indices.filter { !scrambledLetters[$0].isPlaced }
        var unplacedLetters = unplacedIndices.map { scrambledLetters[$0] }
        unplacedLetters.shuffle()

        for (i, originalIndex) in unplacedIndices.enumerated() {
            scrambledLetters[originalIndex] = unplacedLetters[i]
        }
    }

    /// Resets the game to initial state
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedWords.removeAll()
        isCorrect = nil
        showCelebration = false
        currentWord = nil
        scrambledLetters = []
        placedLetters = []
        gameState = .notStarted
    }

    /// Clears all placed letters back to the letter bank
    func clearPlacedLetters() {
        guard gameState == .playing else { return }

        for i in scrambledLetters.indices {
            scrambledLetters[i].isPlaced = false
        }
        placedLetters = Array(repeating: nil, count: placedLetters.count)
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

    /// Whether all letters have been placed
    var allLettersPlaced: Bool {
        !placedLetters.contains(nil)
    }

    // MARK: - Private Methods

    /// Sets up a new word for the current round
    private func setupWord() {
        // Select a word that hasn't been used yet
        let availableWords = wordPool.filter { !usedWords.contains($0.id) }

        guard let word = availableWords.randomElement() else {
            // If we've used all words, reshuffle
            usedWords.removeAll()
            currentWord = wordPool.randomElement()
            if let current = currentWord {
                usedWords.insert(current.id)
            }
            generateLetters()
            return
        }

        currentWord = word
        usedWords.insert(word.id)
        generateLetters()
    }

    /// Generates scrambled letters for the current word
    private func generateLetters() {
        guard let word = currentWord else {
            scrambledLetters = []
            placedLetters = []
            return
        }

        // Create letter tiles
        var tiles = word.letters.map { LetterTileModel(letter: $0) }

        // Shuffle until order is different from the word
        var attempts = 0
        repeat {
            tiles.shuffle()
            attempts += 1
        } while tiles.map({ $0.letter }) == word.letters && attempts < 10

        scrambledLetters = tiles
        placedLetters = Array(repeating: nil, count: word.length)
    }
}
