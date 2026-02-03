import Foundation
import Combine

/// ViewModel for the Memory Game.
/// Players flip cards to find matching sight word pairs.
@MainActor
class MemoryGameViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All cards in the current game
    @Published private(set) var cards: [MemoryCard] = []

    /// Indices of currently flipped (face-up) cards that aren't matched yet
    @Published private(set) var flippedIndices: [Int] = []

    /// Number of moves (pairs flipped)
    @Published private(set) var moves = 0

    /// Current game state
    @Published private(set) var gameState: MemoryGameState = .notStarted

    /// Whether to show celebration animation
    @Published private(set) var showCelebration = false

    // MARK: - Level Properties

    /// Current level (1-based)
    @Published private(set) var currentLevel = 1

    /// Current level configuration
    var currentLevelConfig: SightWordLevel? {
        SightWordData.level(currentLevel)
    }

    // MARK: - Private Properties

    /// Timer for auto-flipping cards back
    private var flipBackTask: Task<Void, Never>?

    /// Delay before flipping non-matching cards back (seconds)
    private let flipBackDelay: TimeInterval = 1.0

    /// Best moves achieved (lowest is better)
    private(set) var bestMoves: Int?

    // MARK: - Computed Properties

    /// Number of matched pairs
    var matchedPairsCount: Int {
        cards.filter { $0.isMatched }.count / 2
    }

    /// Total number of pairs in current game
    var totalPairs: Int {
        cards.count / 2
    }

    /// Whether the current level is complete
    var isLevelComplete: Bool {
        gameState == .levelComplete
    }

    /// Progress through current level (0.0 to 1.0)
    var progress: Double {
        guard totalPairs > 0 else { return 0 }
        return Double(matchedPairsCount) / Double(totalPairs)
    }

    /// Number of columns for the current level grid
    var gridColumns: Int {
        currentLevelConfig?.gridColumns ?? 4
    }

    /// Number of rows for the current level grid
    var gridRows: Int {
        currentLevelConfig?.gridRows ?? 2
    }

    /// Whether there's a next level available
    var hasNextLevel: Bool {
        SightWordData.level(currentLevel + 1) != nil
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Starts a new game at the specified level
    /// - Parameter level: The level to start (defaults to current level)
    func startGame(level: Int? = nil) {
        if let level = level {
            currentLevel = level
        }

        guard let levelConfig = currentLevelConfig else { return }

        // Cancel any pending flip-back
        flipBackTask?.cancel()
        flipBackTask = nil

        // Generate cards for this level
        cards = SightWordData.generateCards(for: levelConfig)
        flippedIndices = []
        moves = 0
        showCelebration = false
        gameState = .playing
    }

    /// Flips a card at the given index
    /// - Parameter index: The index of the card to flip
    func flipCard(at index: Int) {
        guard gameState == .playing else { return }
        guard index >= 0 && index < cards.count else { return }
        guard !cards[index].isFlipped && !cards[index].isMatched else { return }
        guard flippedIndices.count < 2 else { return }

        // Flip the card
        cards[index].isFlipped = true
        flippedIndices.append(index)

        // Check for match if two cards are flipped
        if flippedIndices.count == 2 {
            moves += 1
            checkForMatch()
        }
    }

    /// Checks if the two flipped cards match
    func checkForMatch() {
        guard flippedIndices.count == 2 else { return }

        let firstIndex = flippedIndices[0]
        let secondIndex = flippedIndices[1]
        let firstCard = cards[firstIndex]
        let secondCard = cards[secondIndex]

        gameState = .checking

        if firstCard.matches(secondCard) {
            // Match found
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            flippedIndices = []
            gameState = .playing

            // Check for level completion
            if cards.allSatisfy({ $0.isMatched }) {
                handleLevelComplete()
            }
        } else {
            // No match - flip back after delay
            flipBackTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(flipBackDelay * 1_000_000_000))

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    flipBackCards()
                }
            }
        }
    }

    /// Advances to the next level
    func nextLevel() {
        guard hasNextLevel else { return }
        currentLevel += 1
        startGame()
    }

    /// Resets the game to initial state
    func resetGame() {
        flipBackTask?.cancel()
        flipBackTask = nil

        cards = []
        flippedIndices = []
        moves = 0
        currentLevel = 1
        showCelebration = false
        gameState = .notStarted
        bestMoves = nil
    }

    /// Restarts the current level
    func restartLevel() {
        startGame()
    }

    // MARK: - Private Methods

    /// Flips non-matching cards back face-down
    private func flipBackCards() {
        for index in flippedIndices {
            cards[index].isFlipped = false
        }
        flippedIndices = []
        gameState = .playing
    }

    /// Handles level completion
    private func handleLevelComplete() {
        gameState = .levelComplete

        // Update best moves
        if let best = bestMoves {
            bestMoves = min(best, moves)
        } else {
            bestMoves = moves
        }

        // Trigger celebration for good performance
        let perfectMoves = totalPairs // minimum possible moves
        if moves <= perfectMoves + 2 {
            showCelebration = true
        }
    }
}
