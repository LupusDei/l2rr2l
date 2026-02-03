import Foundation
import Combine

/// ViewModel for the Word Builder game.
/// Players build words by selecting letters from a bank that includes distractors.
@MainActor
class WordBuilderViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The current puzzle being solved.
    @Published private(set) var currentPuzzle: WordPuzzle?

    /// Available letters in the letter bank (includes distractors).
    @Published private(set) var availableLetters: [WordBuilderTile] = []

    /// Letters that have been selected to build the word.
    @Published private(set) var builtWord: [Character] = []

    /// Current score.
    @Published private(set) var score = 0

    /// Current streak of consecutive correct answers.
    @Published private(set) var streak = 0

    /// Current game state.
    @Published private(set) var gameState: WordBuilderState = .notStarted

    /// Current round number (1-based).
    @Published private(set) var round = 1

    /// Whether to show celebration animation.
    @Published private(set) var showCelebration = false

    // MARK: - Configuration

    /// Total number of rounds per game session.
    let totalRounds = 15

    /// Number of distractor letters to add.
    private let distractorCount = 3

    // MARK: - Private Properties

    /// Puzzles already used in this session.
    private var usedPuzzles: Set<String> = []

    /// Best streak achieved in this session.
    private(set) var bestStreak = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Starts a new game session.
    func startGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedPuzzles.removeAll()
        showCelebration = false
        gameState = .playing
        setupPuzzle()
    }

    /// Advances to the next puzzle.
    func nextPuzzle() {
        guard round < totalRounds else {
            gameState = .gameComplete
            return
        }

        round += 1
        showCelebration = false
        gameState = .playing
        setupPuzzle()
    }

    /// Adds a letter to the built word.
    /// - Parameter index: The index of the letter in availableLetters.
    func selectLetter(at index: Int) {
        guard gameState == .playing else { return }
        guard index >= 0 && index < availableLetters.count else { return }
        guard !availableLetters[index].isUsed else { return }

        let letter = availableLetters[index].letter
        availableLetters[index].isUsed = true
        builtWord.append(letter)
    }

    /// Removes the last letter from the built word.
    func deleteLetter() {
        guard gameState == .playing else { return }
        guard !builtWord.isEmpty else { return }

        let removedLetter = builtWord.removeLast()

        // Find the first used tile with this letter and mark it as available
        if let index = availableLetters.firstIndex(where: { $0.letter == removedLetter && $0.isUsed }) {
            availableLetters[index].isUsed = false
        }
    }

    /// Clears all letters from the built word.
    func clearWord() {
        guard gameState == .playing else { return }

        builtWord.removeAll()
        for i in availableLetters.indices {
            availableLetters[i].isUsed = false
        }
    }

    /// Checks if the built word matches the puzzle.
    /// - Returns: Whether the word is correct.
    @discardableResult
    func checkAnswer() -> Bool {
        guard gameState == .playing else { return false }
        guard let puzzle = currentPuzzle else { return false }

        gameState = .checking

        let attempt = String(builtWord)
        let correct = attempt.lowercased() == puzzle.word.lowercased()

        if correct {
            score += 10 * (streak + 1)
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

    /// Resets the game to initial state.
    func resetGame() {
        score = 0
        streak = 0
        bestStreak = 0
        round = 1
        usedPuzzles.removeAll()
        showCelebration = false
        currentPuzzle = nil
        availableLetters = []
        builtWord = []
        gameState = .notStarted
    }

    /// Whether the built word is not empty.
    var hasBuiltLetters: Bool {
        !builtWord.isEmpty
    }

    /// Progress through the game (0.0 to 1.0).
    var progress: Double {
        Double(round - 1) / Double(totalRounds)
    }

    // MARK: - Private Methods

    /// Sets up a new puzzle for the current round.
    private func setupPuzzle() {
        // Select a puzzle that hasn't been used yet
        let availablePuzzles = WordBuilderData.puzzles.filter { !usedPuzzles.contains($0.id) }

        guard let puzzle = availablePuzzles.randomElement() else {
            // If we've used all puzzles, reshuffle
            usedPuzzles.removeAll()
            currentPuzzle = WordBuilderData.puzzles.randomElement()
            if let current = currentPuzzle {
                usedPuzzles.insert(current.id)
            }
            generateLetters()
            return
        }

        currentPuzzle = puzzle
        usedPuzzles.insert(puzzle.id)
        generateLetters()
    }

    /// Generates available letters including distractors.
    private func generateLetters() {
        guard let puzzle = currentPuzzle else {
            availableLetters = []
            builtWord = []
            return
        }

        // Start with the puzzle letters
        var letters = puzzle.letters

        // Add distractor letters that aren't in the word
        let distractors = WordBuilderData.distractorPool
            .filter { !puzzle.word.contains($0) }
            .shuffled()
            .prefix(distractorCount)
        letters.append(contentsOf: distractors)

        // Shuffle all letters
        letters.shuffle()

        // Create tiles
        availableLetters = letters.map { WordBuilderTile(letter: $0) }
        builtWord = []
    }
}
