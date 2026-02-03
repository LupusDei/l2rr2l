import Foundation
import Combine

/// ViewModel for the Word Builder Game.
/// Players build words by selecting letters in the correct order.
@MainActor
class WordBuilderViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current puzzle being solved
    @Published private(set) var currentPuzzle: WordPuzzle?

    /// Scrambled letters available for selection
    @Published private(set) var scrambledLetters: [Character] = []

    /// Letters the player has built so far
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

    /// Pool of puzzles to use in the game
    private var puzzlePool: [WordPuzzle] = []

    /// Puzzles already used in this session
    private var usedPuzzles: Set<String> = []

    /// Best streak achieved in this session
    private(set) var bestStreak = 0

    /// Tracks which scrambled letter indices have been used
    private var usedLetterIndices: Set<Int> = []

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Starts a new game session
    func startGame() {
        score = 0
        streak = 0
        bestStreak = 0
        puzzleIndex = 0
        usedPuzzles.removeAll()
        isCorrect = nil
        showCelebration = false

        // Build puzzle pool
        puzzlePool = WordBuilderData.puzzles

        gameState = .playing
        setupPuzzle()
    }

    /// Adds a letter to the built word
    /// - Parameter letter: The letter to add
    func addLetter(_ letter: Character) {
        guard gameState == .playing else { return }
        guard let puzzle = currentPuzzle else { return }
        guard builtWord.count < puzzle.length else { return }

        // Find the first unused index of this letter in scrambledLetters
        for (index, scrambledLetter) in scrambledLetters.enumerated() {
            if scrambledLetter == letter && !usedLetterIndices.contains(index) {
                usedLetterIndices.insert(index)
                builtWord.append(letter)
                return
            }
        }
    }

    /// Removes the last letter from the built word
    func removeLast() {
        guard gameState == .playing else { return }
        guard !builtWord.isEmpty else { return }

        let removedLetter = builtWord.removeLast()

        // Find the index of this letter to mark as unused (prefer higher indices)
        for index in usedLetterIndices.sorted().reversed() {
            if scrambledLetters[index] == removedLetter {
                usedLetterIndices.remove(index)
                return
            }
        }
    }

    /// Clears all letters from the built word
    func clearWord() {
        guard gameState == .playing else { return }
        builtWord.removeAll()
        usedLetterIndices.removeAll()
    }

    /// Checks if the built word is correct
    /// - Returns: Whether the word is correct
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

    /// Re-scrambles the available (not used) letters
    func scrambleLetters() {
        guard gameState == .playing else { return }
        guard let puzzle = currentPuzzle else { return }

        // Only scramble if word is not built yet
        guard builtWord.isEmpty else { return }

        scrambledLetters = WordBuilderData.scramble(puzzle.letters)
        usedLetterIndices.removeAll()
    }

    /// Resets the game to initial state
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        puzzleIndex = 0
        usedPuzzles.removeAll()
        isCorrect = nil
        showCelebration = false
        currentPuzzle = nil
        scrambledLetters = []
        builtWord = []
        usedLetterIndices.removeAll()
        gameState = .notStarted
    }

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

    /// Whether the built word is complete (all letters placed)
    var wordComplete: Bool {
        guard let puzzle = currentPuzzle else { return false }
        return builtWord.count == puzzle.length
    }

    /// Available letters (not yet used in built word)
    var availableLetters: [Character] {
        scrambledLetters.enumerated()
            .filter { !usedLetterIndices.contains($0.offset) }
            .map { $0.element }
    }

    // MARK: - Private Methods

    /// Sets up a new puzzle for the current round
    private func setupPuzzle() {
        // Select a puzzle that hasn't been used yet
        let availablePuzzles = puzzlePool.filter { !usedPuzzles.contains($0.id) }

        guard let puzzle = availablePuzzles.randomElement() else {
            // If we've used all puzzles, reshuffle
            usedPuzzles.removeAll()
            currentPuzzle = puzzlePool.randomElement()
            if let current = currentPuzzle {
                usedPuzzles.insert(current.id)
            }
            generateScrambledLetters()
            return
        }

        currentPuzzle = puzzle
        usedPuzzles.insert(puzzle.id)
        generateScrambledLetters()
    }

    /// Generates scrambled letters for the current puzzle
    private func generateScrambledLetters() {
        guard let puzzle = currentPuzzle else {
            scrambledLetters = []
            builtWord = []
            usedLetterIndices.removeAll()
            return
        }

        scrambledLetters = WordBuilderData.scramble(puzzle.letters)
        builtWord = []
        usedLetterIndices.removeAll()
    }
}
