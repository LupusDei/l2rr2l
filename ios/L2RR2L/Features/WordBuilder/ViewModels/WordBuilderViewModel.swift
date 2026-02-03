import Foundation
import Combine

/// ViewModel for the Word Builder game.
/// Players unscramble letters to build words from emoji hints.
@MainActor
class WordBuilderViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current puzzle being solved
    @Published private(set) var currentPuzzle: WordPuzzle?

    /// Scrambled letters available for selection
    @Published private(set) var scrambledLetters: [Character] = []

    /// Letters the player has added to build the word
    @Published private(set) var builtWord: [Character] = []

    /// Current score (number of correct puzzles)
    @Published private(set) var score = 0

    /// Current streak of consecutive correct answers
    @Published private(set) var streak = 0

    /// Current puzzle index (0-based)
    @Published private(set) var puzzleIndex = 0

    /// Result of the last check (nil if not checked yet)
    @Published private(set) var isCorrect: Bool?

    /// Whether to show celebration animation
    @Published private(set) var showCelebration = false

    /// Current game state
    @Published private(set) var gameState: WordBuilderGameState = .notStarted

    // MARK: - Configuration

    /// Total number of puzzles per game session
    let totalPuzzles = 15

    // MARK: - Private Properties

    /// Puzzles for this game session
    private var sessionPuzzles: [WordPuzzle] = []

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
        puzzleIndex = 0
        isCorrect = nil
        showCelebration = false

        // Get shuffled puzzles for this session
        sessionPuzzles = WordBuilderData.shuffledPuzzles()

        gameState = .playing
        setupPuzzle()
    }

    /// Adds a letter from scrambled letters to the built word
    /// - Parameter letter: The letter to add
    func addLetter(_ letter: Character) {
        guard gameState == .playing else { return }

        // Find the letter in scrambled letters and remove it
        if let index = scrambledLetters.firstIndex(of: letter) {
            scrambledLetters.remove(at: index)
            builtWord.append(letter)
        }
    }

    /// Removes the last letter from the built word and returns it to scrambled
    func removeLast() {
        guard gameState == .playing else { return }
        guard !builtWord.isEmpty else { return }

        let letter = builtWord.removeLast()
        scrambledLetters.append(letter)
    }

    /// Clears all letters from the built word back to scrambled
    func clearWord() {
        guard gameState == .playing else { return }

        scrambledLetters.append(contentsOf: builtWord)
        builtWord.removeAll()
    }

    /// Checks if the built word matches the puzzle answer
    /// - Returns: Whether the answer is correct
    @discardableResult
    func checkAnswer() -> Bool {
        guard gameState == .playing else { return false }
        guard let puzzle = currentPuzzle else { return false }
        guard builtWord.count == puzzle.length else { return false }

        gameState = .checking

        let attempt = String(builtWord)
        let correct = attempt.lowercased() == puzzle.word.lowercased()

        isCorrect = correct

        if correct {
            score += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            gameState = .correct

            // Trigger celebration for streaks of 3 or more
            if streak >= 3 && streak % 3 == 0 {
                showCelebration = true
            }
        } else {
            streak = 0
            gameState = .incorrect
        }

        return correct
    }

    /// Advances to the next puzzle
    func nextPuzzle() {
        guard puzzleIndex < totalPuzzles - 1 else {
            gameState = .gameComplete
            return
        }

        puzzleIndex += 1
        isCorrect = nil
        showCelebration = false
        gameState = .playing
        setupPuzzle()
    }

    /// Re-scrambles the available letters
    func scrambleLetters() {
        guard gameState == .playing else { return }
        scrambledLetters = WordBuilderData.shuffle(scrambledLetters)
    }

    /// Resets the game to initial state
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        puzzleIndex = 0
        isCorrect = nil
        showCelebration = false
        currentPuzzle = nil
        scrambledLetters = []
        builtWord = []
        sessionPuzzles = []
        gameState = .notStarted
    }

    // MARK: - Computed Properties

    /// Progress through the game (0.0 to 1.0)
    var progress: Double {
        Double(puzzleIndex) / Double(totalPuzzles)
    }

    /// Whether the game is complete
    var isGameComplete: Bool {
        gameState == .gameComplete
    }

    /// Final score as a percentage
    var scorePercentage: Int {
        guard totalPuzzles > 0 else { return 0 }
        return Int(Double(score) / Double(totalPuzzles) * 100)
    }

    /// Whether the built word is complete (has same length as puzzle word)
    var isWordComplete: Bool {
        guard let puzzle = currentPuzzle else { return false }
        return builtWord.count == puzzle.length
    }

    /// Current puzzle number (1-based, for display)
    var currentPuzzleNumber: Int {
        puzzleIndex + 1
    }

    // MARK: - Private Methods

    /// Sets up a puzzle for the current index
    private func setupPuzzle() {
        guard puzzleIndex < sessionPuzzles.count else {
            gameState = .gameComplete
            return
        }

        currentPuzzle = sessionPuzzles[puzzleIndex]
        generateScrambledLetters()
    }

    /// Generates scrambled letters for the current puzzle
    private func generateScrambledLetters() {
        guard let puzzle = currentPuzzle else {
            scrambledLetters = []
            builtWord = []
            return
        }

        // Scramble the letters
        var letters = puzzle.letters
        var attempts = 0

        // Keep shuffling until order is different from original word
        repeat {
            letters = WordBuilderData.shuffle(letters)
            attempts += 1
        } while letters == puzzle.letters && attempts < 10

        scrambledLetters = letters
        builtWord = []
    }
}
