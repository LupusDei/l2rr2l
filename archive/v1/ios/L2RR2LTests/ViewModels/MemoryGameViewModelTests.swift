import XCTest
@testable import L2RR2L

@MainActor
final class MemoryGameViewModelTests: XCTestCase {
    var sut: MemoryGameViewModel!

    override func setUp() async throws {
        sut = MemoryGameViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(sut.cards.isEmpty)
        XCTAssertTrue(sut.flippedIndices.isEmpty)
        XCTAssertEqual(sut.moves, 0)
        XCTAssertEqual(sut.gameState, .notStarted)
        XCTAssertEqual(sut.currentLevel, 1)
        XCTAssertFalse(sut.showCelebration)
    }

    // MARK: - Start Game Tests

    func testStartGameCreatesCards() {
        sut.startGame()

        XCTAssertFalse(sut.cards.isEmpty)
        XCTAssertEqual(sut.gameState, .playing)
        XCTAssertEqual(sut.moves, 0)
    }

    func testStartGameLevel1Has8Cards() {
        sut.startGame(level: 1)

        // Level 1 has 4 words = 8 cards
        XCTAssertEqual(sut.cards.count, 8)
        XCTAssertEqual(sut.totalPairs, 4)
    }

    func testStartGameLevel2Has16Cards() {
        sut.startGame(level: 2)

        // Level 2 has 8 words = 16 cards
        XCTAssertEqual(sut.cards.count, 16)
        XCTAssertEqual(sut.totalPairs, 8)
    }

    func testStartGameCardsAreNotFlipped() {
        sut.startGame()

        XCTAssertTrue(sut.cards.allSatisfy { !$0.isFlipped && !$0.isMatched })
    }

    // MARK: - Flip Card Tests

    func testFlipCardFlipsTheCard() {
        sut.startGame()

        sut.flipCard(at: 0)

        XCTAssertTrue(sut.cards[0].isFlipped)
        XCTAssertEqual(sut.flippedIndices, [0])
    }

    func testFlipSecondCardIncreasesMoves() {
        sut.startGame()

        sut.flipCard(at: 0)
        XCTAssertEqual(sut.moves, 0)

        sut.flipCard(at: 1)
        XCTAssertEqual(sut.moves, 1)
    }

    func testCannotFlipMoreThanTwoCards() {
        sut.startGame()

        sut.flipCard(at: 0)
        sut.flipCard(at: 1)
        sut.flipCard(at: 2)

        XCTAssertEqual(sut.flippedIndices.count, 2)
        XCTAssertFalse(sut.cards[2].isFlipped)
    }

    func testCannotFlipAlreadyFlippedCard() {
        sut.startGame()

        sut.flipCard(at: 0)
        let firstFlip = sut.cards[0].isFlipped

        sut.flipCard(at: 0)

        XCTAssertEqual(sut.flippedIndices.count, 1)
        XCTAssertTrue(firstFlip)
    }

    func testCannotFlipMatchedCard() {
        sut.startGame()

        // Find a matching pair
        guard let (first, second) = findMatchingPair() else {
            XCTFail("No matching pair found")
            return
        }

        sut.flipCard(at: first)
        sut.flipCard(at: second)

        // Cards should be matched
        XCTAssertTrue(sut.cards[first].isMatched)

        // Try to flip matched card
        sut.flipCard(at: first)

        // Should not add to flipped indices
        XCTAssertTrue(sut.flippedIndices.isEmpty)
    }

    // MARK: - Match Detection Tests

    func testMatchingPairsAreMarkedAsMatched() {
        sut.startGame()

        guard let (first, second) = findMatchingPair() else {
            XCTFail("No matching pair found")
            return
        }

        sut.flipCard(at: first)
        sut.flipCard(at: second)

        XCTAssertTrue(sut.cards[first].isMatched)
        XCTAssertTrue(sut.cards[second].isMatched)
        XCTAssertTrue(sut.flippedIndices.isEmpty)
    }

    func testNonMatchingPairsRemainsFlipped() {
        sut.startGame()

        guard let (first, second) = findNonMatchingPair() else {
            XCTFail("No non-matching pair found")
            return
        }

        sut.flipCard(at: first)
        sut.flipCard(at: second)

        // State should be checking (waiting to flip back)
        XCTAssertEqual(sut.gameState, .checking)
        XCTAssertTrue(sut.cards[first].isFlipped)
        XCTAssertTrue(sut.cards[second].isFlipped)
    }

    // MARK: - Progress Tests

    func testProgressStartsAtZero() {
        sut.startGame()

        XCTAssertEqual(sut.progress, 0)
        XCTAssertEqual(sut.matchedPairsCount, 0)
    }

    func testProgressIncreasesWithMatches() {
        sut.startGame(level: 1) // 4 pairs

        guard let (first, second) = findMatchingPair() else {
            XCTFail("No matching pair found")
            return
        }

        sut.flipCard(at: first)
        sut.flipCard(at: second)

        XCTAssertEqual(sut.matchedPairsCount, 1)
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.01)
    }

    // MARK: - Level Completion Tests

    func testLevelCompletesWhenAllPairsMatched() {
        sut.startGame(level: 1)

        matchAllPairs()

        XCTAssertEqual(sut.gameState, .levelComplete)
        XCTAssertTrue(sut.isLevelComplete)
    }

    func testNextLevelAdvancesToNextLevel() {
        sut.startGame(level: 1)
        matchAllPairs()

        sut.nextLevel()

        XCTAssertEqual(sut.currentLevel, 2)
        XCTAssertEqual(sut.gameState, .playing)
        XCTAssertEqual(sut.moves, 0)
    }

    // MARK: - Reset Tests

    func testResetGameClearsState() {
        sut.startGame()
        sut.flipCard(at: 0)

        sut.resetGame()

        XCTAssertTrue(sut.cards.isEmpty)
        XCTAssertTrue(sut.flippedIndices.isEmpty)
        XCTAssertEqual(sut.moves, 0)
        XCTAssertEqual(sut.currentLevel, 1)
        XCTAssertEqual(sut.gameState, .notStarted)
    }

    func testRestartLevelKeepsLevel() {
        sut.startGame(level: 2)
        sut.flipCard(at: 0)

        sut.restartLevel()

        XCTAssertEqual(sut.currentLevel, 2)
        XCTAssertEqual(sut.moves, 0)
        XCTAssertEqual(sut.gameState, .playing)
    }

    // MARK: - Grid Configuration Tests

    func testGridColumnsMatchLevel() {
        sut.startGame(level: 1)
        XCTAssertEqual(sut.gridColumns, 4)

        sut.startGame(level: 2)
        XCTAssertEqual(sut.gridColumns, 4)
    }

    func testGridRowsMatchLevel() {
        sut.startGame(level: 1)
        XCTAssertEqual(sut.gridRows, 2)

        sut.startGame(level: 2)
        XCTAssertEqual(sut.gridRows, 4)
    }

    // MARK: - Helpers

    private func findMatchingPair() -> (Int, Int)? {
        for i in 0..<sut.cards.count {
            for j in (i + 1)..<sut.cards.count {
                if sut.cards[i].matches(sut.cards[j]) {
                    return (i, j)
                }
            }
        }
        return nil
    }

    private func findNonMatchingPair() -> (Int, Int)? {
        for i in 0..<sut.cards.count {
            for j in (i + 1)..<sut.cards.count {
                if !sut.cards[i].matches(sut.cards[j]) {
                    return (i, j)
                }
            }
        }
        return nil
    }

    private func matchAllPairs() {
        var unmatchedIndices = Set(0..<sut.cards.count)

        while !unmatchedIndices.isEmpty {
            guard let firstIndex = unmatchedIndices.first else { break }
            unmatchedIndices.remove(firstIndex)

            // Find matching card
            guard let secondIndex = unmatchedIndices.first(where: {
                sut.cards[$0].matches(sut.cards[firstIndex])
            }) else { continue }
            unmatchedIndices.remove(secondIndex)

            sut.flipCard(at: firstIndex)
            sut.flipCard(at: secondIndex)
        }
    }
}
