import XCTest
@testable import L2RR2L

@MainActor
final class SpellingGameViewModelTests: XCTestCase {
    var sut: SpellingGameViewModel!

    override func setUp() async throws {
        sut = SpellingGameViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(sut.currentWord)
        XCTAssertTrue(sut.scrambledLetters.isEmpty)
        XCTAssertTrue(sut.placedLetters.isEmpty)
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertNil(sut.isCorrect)
        XCTAssertFalse(sut.showCelebration)
        XCTAssertEqual(sut.gameState, .notStarted)
        XCTAssertEqual(sut.round, 1)
    }

    // MARK: - Start Game Tests

    func testStartGameSetsCurrentWord() {
        sut.startGame()

        XCTAssertNotNil(sut.currentWord)
        XCTAssertEqual(sut.gameState, .playing)
    }

    func testStartGameInitializesScrambledLetters() {
        sut.startGame()

        guard let word = sut.currentWord else {
            XCTFail("Expected current word to be set")
            return
        }

        XCTAssertEqual(sut.scrambledLetters.count, word.length)
        XCTAssertEqual(sut.placedLetters.count, word.length)

        // All placed letters should be nil initially
        XCTAssertTrue(sut.placedLetters.allSatisfy { $0 == nil })

        // All scrambled letters should not be placed initially
        XCTAssertTrue(sut.scrambledLetters.allSatisfy { !$0.isPlaced })
    }

    func testStartGameResetsScoreAndStreak() {
        sut.startGame()

        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 0)
        XCTAssertEqual(sut.round, 1)
        XCTAssertNil(sut.isCorrect)
    }

    // MARK: - Letter Placement Tests

    func testPlaceLetterAddsToPosition() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        let result = sut.placeLetter(firstLetter, at: 0)

        XCTAssertTrue(result)
        XCTAssertEqual(sut.placedLetters[0], firstLetter)
    }

    func testPlaceLetterMarksLetterAsPlaced() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        _ = sut.placeLetter(firstLetter, at: 0)

        let placedTile = sut.scrambledLetters.first { $0.letter == firstLetter && $0.isPlaced }
        XCTAssertNotNil(placedTile)
    }

    func testPlaceLetterFailsWhenSlotOccupied() {
        sut.startGame()

        guard sut.scrambledLetters.count >= 2 else {
            XCTFail("Expected at least 2 scrambled letters")
            return
        }

        let firstLetter = sut.scrambledLetters[0].letter
        let secondLetter = sut.scrambledLetters[1].letter

        _ = sut.placeLetter(firstLetter, at: 0)
        let result = sut.placeLetter(secondLetter, at: 0)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.placedLetters[0], firstLetter)
    }

    func testPlaceLetterFailsWithInvalidIndex() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        let resultNegative = sut.placeLetter(firstLetter, at: -1)
        XCTAssertFalse(resultNegative)

        let resultOutOfBounds = sut.placeLetter(firstLetter, at: 100)
        XCTAssertFalse(resultOutOfBounds)
    }

    func testPlaceLetterFailsWhenNotPlaying() {
        // Game not started
        let result = sut.placeLetter("a", at: 0)
        XCTAssertFalse(result)
    }

    func testPlaceLetterInNextSlot() {
        sut.startGame()

        guard sut.scrambledLetters.count >= 2 else {
            XCTFail("Expected at least 2 scrambled letters")
            return
        }

        let firstLetter = sut.scrambledLetters[0].letter
        let secondLetter = sut.scrambledLetters[1].letter

        let result1 = sut.placeLetterInNextSlot(firstLetter)
        let result2 = sut.placeLetterInNextSlot(secondLetter)

        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
        XCTAssertEqual(sut.placedLetters[0], firstLetter)
        XCTAssertEqual(sut.placedLetters[1], secondLetter)
    }

    // MARK: - Remove Letter Tests

    func testRemoveLetterClearsPosition() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        _ = sut.placeLetter(firstLetter, at: 0)
        sut.removeLetter(at: 0)

        XCTAssertNil(sut.placedLetters[0])
    }

    func testRemoveLetterMarksLetterAsNotPlaced() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        _ = sut.placeLetter(firstLetter, at: 0)
        sut.removeLetter(at: 0)

        let placedTiles = sut.scrambledLetters.filter { $0.isPlaced }
        XCTAssertTrue(placedTiles.isEmpty)
    }

    func testRemoveLetterDoesNothingForEmptySlot() {
        sut.startGame()

        // Should not crash or change state
        sut.removeLetter(at: 0)
        XCTAssertNil(sut.placedLetters[0])
    }

    // MARK: - Answer Validation Tests

    func testCheckAnswerCorrectIncrementsScore() {
        sut.startGame()

        guard let word = sut.currentWord else {
            XCTFail("Expected current word")
            return
        }

        // Place letters in correct order
        for (index, letter) in word.letters.enumerated() {
            _ = sut.placeLetter(letter, at: index)
        }

        let result = sut.checkAnswer()

        XCTAssertTrue(result)
        XCTAssertTrue(sut.isCorrect ?? false)
        XCTAssertEqual(sut.score, 1)
        XCTAssertEqual(sut.gameState, .correct)
    }

    func testCheckAnswerIncorrectResetsStreak() {
        sut.startGame()

        guard let word = sut.currentWord, word.length >= 2 else {
            XCTFail("Expected current word with at least 2 letters")
            return
        }

        // Place letters in wrong order (swap first two)
        let letters = word.letters
        _ = sut.placeLetter(letters[1], at: 0)
        _ = sut.placeLetter(letters[0], at: 1)
        for i in 2..<letters.count {
            _ = sut.placeLetter(letters[i], at: i)
        }

        let result = sut.checkAnswer()

        XCTAssertFalse(result)
        XCTAssertFalse(sut.isCorrect ?? true)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.gameState, .incorrect)
    }

    func testCheckAnswerFailsWithIncompletePlacement() {
        sut.startGame()

        // Only place first letter
        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }
        _ = sut.placeLetter(firstLetter, at: 0)

        let result = sut.checkAnswer()
        XCTAssertFalse(result)
    }

    func testCheckAnswerFailsWhenNotPlaying() {
        // Game not started
        let result = sut.checkAnswer()
        XCTAssertFalse(result)
    }

    // MARK: - Streak Tracking Tests

    func testStreakIncrementsOnConsecutiveCorrectAnswers() {
        sut.startGame()

        // Answer correctly
        answerCorrectly()
        XCTAssertEqual(sut.streak, 1)

        sut.nextWord()
        answerCorrectly()
        XCTAssertEqual(sut.streak, 2)

        sut.nextWord()
        answerCorrectly()
        XCTAssertEqual(sut.streak, 3)
    }

    func testBestStreakTracksHighestStreak() {
        sut.startGame()

        // Build streak of 2
        answerCorrectly()
        sut.nextWord()
        answerCorrectly()
        XCTAssertEqual(sut.bestStreak, 2)

        // Answer incorrectly
        sut.nextWord()
        answerIncorrectly()
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 2)  // Best streak preserved

        // Build smaller streak
        sut.nextWord()
        answerCorrectly()
        XCTAssertEqual(sut.bestStreak, 2)  // Still 2
    }

    func testCelebrationShowsOnStreakMultipleOf3() {
        sut.startGame()

        // Build streak of 3
        answerCorrectly()
        XCTAssertFalse(sut.showCelebration)

        sut.nextWord()
        answerCorrectly()
        XCTAssertFalse(sut.showCelebration)

        sut.nextWord()
        answerCorrectly()
        XCTAssertTrue(sut.showCelebration)
    }

    // MARK: - Round Progression Tests

    func testNextWordIncrementsRound() {
        sut.startGame()
        XCTAssertEqual(sut.round, 1)

        answerCorrectly()
        sut.nextWord()
        XCTAssertEqual(sut.round, 2)
    }

    func testNextWordResetsIsCorrect() {
        sut.startGame()
        answerCorrectly()

        XCTAssertNotNil(sut.isCorrect)

        sut.nextWord()
        XCTAssertNil(sut.isCorrect)
    }

    func testGameCompletesAfterFinalRound() {
        sut.startGame()

        // Play through all rounds
        for _ in 1..<sut.totalRounds {
            answerCorrectly()
            sut.nextWord()
        }

        answerCorrectly()
        sut.nextWord()

        XCTAssertEqual(sut.gameState, .gameComplete)
        XCTAssertTrue(sut.isGameComplete)
    }

    // MARK: - Score Calculation Tests

    func testScorePercentageCalculation() {
        sut.startGame()

        // Answer 3 correct out of 10
        for i in 1...10 {
            if i <= 3 {
                answerCorrectly()
            } else {
                answerIncorrectly()
            }
            if i < 10 {
                sut.nextWord()
            }
        }

        XCTAssertEqual(sut.score, 3)
        XCTAssertEqual(sut.scorePercentage, 30)
    }

    func testProgressCalculation() {
        sut.startGame()
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)

        answerCorrectly()
        sut.nextWord()
        XCTAssertEqual(sut.progress, 0.1, accuracy: 0.01)

        for _ in 2...5 {
            answerCorrectly()
            sut.nextWord()
        }
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Reset Game Tests

    func testResetGameClearsAllState() {
        sut.startGame()
        answerCorrectly()
        sut.nextWord()
        answerCorrectly()

        sut.resetGame()

        XCTAssertNil(sut.currentWord)
        XCTAssertTrue(sut.scrambledLetters.isEmpty)
        XCTAssertTrue(sut.placedLetters.isEmpty)
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 0)
        XCTAssertEqual(sut.round, 1)
        XCTAssertNil(sut.isCorrect)
        XCTAssertFalse(sut.showCelebration)
        XCTAssertEqual(sut.gameState, .notStarted)
    }

    // MARK: - Clear Placed Letters Tests

    func testClearPlacedLettersResetsAllSlots() {
        sut.startGame()

        // Place all letters
        for (index, tile) in sut.scrambledLetters.enumerated() {
            _ = sut.placeLetter(tile.letter, at: index)
        }

        XCTAssertFalse(sut.placedLetters.contains(nil))

        sut.clearPlacedLetters()

        XCTAssertTrue(sut.placedLetters.allSatisfy { $0 == nil })
        XCTAssertTrue(sut.scrambledLetters.allSatisfy { !$0.isPlaced })
    }

    // MARK: - Scramble Letters Tests

    func testScrambleLettersRearrangesUnplacedLetters() {
        sut.startGame()

        guard sut.scrambledLetters.count >= 2 else {
            XCTFail("Expected at least 2 scrambled letters")
            return
        }

        let originalOrder = sut.scrambledLetters.map { $0.letter }

        // Scramble multiple times to increase chance of different order
        var foundDifferentOrder = false
        for _ in 0..<10 {
            sut.scrambleLetters()
            let newOrder = sut.scrambledLetters.map { $0.letter }
            if newOrder != originalOrder {
                foundDifferentOrder = true
                break
            }
        }

        // Note: This could theoretically fail if randomization gives same order
        // For 3+ letters, probability is very low
        if sut.scrambledLetters.count >= 3 {
            XCTAssertTrue(foundDifferentOrder, "Expected letters to be scrambled to different order")
        }
    }

    func testScrambleLettersPreservesPlacedLetters() {
        sut.startGame()

        guard let firstLetter = sut.scrambledLetters.first?.letter else {
            XCTFail("Expected scrambled letters")
            return
        }

        // Place first letter
        _ = sut.placeLetter(firstLetter, at: 0)

        let placedCount = sut.scrambledLetters.filter { $0.isPlaced }.count
        XCTAssertEqual(placedCount, 1)

        sut.scrambleLetters()

        // Still should have 1 placed letter
        let newPlacedCount = sut.scrambledLetters.filter { $0.isPlaced }.count
        XCTAssertEqual(newPlacedCount, 1)
    }

    // MARK: - All Letters Placed Tests

    func testAllLettersPlacedIsFalseInitially() {
        sut.startGame()
        XCTAssertFalse(sut.allLettersPlaced)
    }

    func testAllLettersPlacedIsTrueWhenComplete() {
        sut.startGame()

        guard let word = sut.currentWord else {
            XCTFail("Expected current word")
            return
        }

        for (index, letter) in word.letters.enumerated() {
            _ = sut.placeLetter(letter, at: index)
        }

        XCTAssertTrue(sut.allLettersPlaced)
    }

    // MARK: - Helper Methods

    private func answerCorrectly() {
        guard let word = sut.currentWord else { return }
        for (index, letter) in word.letters.enumerated() {
            _ = sut.placeLetter(letter, at: index)
        }
        _ = sut.checkAnswer()
    }

    private func answerIncorrectly() {
        guard let word = sut.currentWord, word.length >= 2 else { return }
        let letters = word.letters
        // Swap first two letters to make it wrong
        _ = sut.placeLetter(letters[1], at: 0)
        _ = sut.placeLetter(letters[0], at: 1)
        for i in 2..<letters.count {
            _ = sut.placeLetter(letters[i], at: i)
        }
        _ = sut.checkAnswer()
    }
}
