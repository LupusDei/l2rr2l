import XCTest
@testable import L2RR2L

/// Tests for RhymeGameViewModel
final class RhymeGameViewModelTests: XCTestCase {

    // MARK: - Game Logic Tests

    @MainActor
    func testInitialState() {
        let viewModel = RhymeGameViewModel()

        XCTAssertNil(viewModel.currentWord)
        XCTAssertTrue(viewModel.options.isEmpty)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.round, 1)
        XCTAssertNil(viewModel.isCorrect)
        XCTAssertEqual(viewModel.gameState, .notStarted)
        XCTAssertEqual(viewModel.difficulty, .easy)
    }

    @MainActor
    func testStartGame() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        XCTAssertNotNil(viewModel.currentWord)
        XCTAssertFalse(viewModel.options.isEmpty)
        XCTAssertEqual(viewModel.gameState, .playing)
        XCTAssertEqual(viewModel.round, 1)
        XCTAssertEqual(viewModel.score, 0)
    }

    @MainActor
    func testCorrectAnswer() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        guard let correctAnswer = viewModel.correctAnswer else {
            XCTFail("No correct answer set")
            return
        }

        let correctOption = RhymeOptionItem.word(correctAnswer)
        let result = viewModel.selectAnswer(correctOption)

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.isCorrect, true)
        XCTAssertEqual(viewModel.score, 1)
        XCTAssertEqual(viewModel.streak, 1)
        XCTAssertEqual(viewModel.gameState, .correct)
    }

    @MainActor
    func testIncorrectAnswer() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Find a distractor option
        guard let distractorOption = viewModel.options.first(where: { option in
            if case .distractor = option { return true }
            if case .word(let word) = option,
               word.id != viewModel.correctAnswer?.id {
                return true
            }
            return false
        }) else {
            XCTFail("No distractor option found")
            return
        }

        let result = viewModel.selectAnswer(distractorOption)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.isCorrect, false)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.gameState, .incorrect)
    }

    @MainActor
    func testNextRound() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        let firstWord = viewModel.currentWord

        viewModel.nextRound()

        XCTAssertEqual(viewModel.round, 2)
        XCTAssertEqual(viewModel.gameState, .playing)
        XCTAssertNil(viewModel.isCorrect)
        XCTAssertNil(viewModel.selectedOption)
        // Word should change (though theoretically could be same, very unlikely)
        XCTAssertNotNil(viewModel.currentWord)
    }

    @MainActor
    func testGameCompletion() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Play through all rounds
        for _ in 1..<viewModel.totalRounds {
            viewModel.nextRound()
        }

        XCTAssertEqual(viewModel.round, viewModel.totalRounds)

        // Attempting next round after last should complete game
        viewModel.nextRound()

        XCTAssertEqual(viewModel.gameState, .gameComplete)
        XCTAssertTrue(viewModel.isGameComplete)
    }

    @MainActor
    func testResetGame() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Play a bit
        if let correctAnswer = viewModel.correctAnswer {
            viewModel.selectAnswer(.word(correctAnswer))
        }
        viewModel.nextRound()

        // Reset
        viewModel.resetGame()

        XCTAssertNil(viewModel.currentWord)
        XCTAssertTrue(viewModel.options.isEmpty)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.round, 1)
        XCTAssertNil(viewModel.isCorrect)
        XCTAssertEqual(viewModel.gameState, .notStarted)
    }

    @MainActor
    func testStreakTracking() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Get 2 correct in a row
        for _ in 0..<2 {
            if let correctAnswer = viewModel.correctAnswer {
                viewModel.selectAnswer(.word(correctAnswer))
            }
            viewModel.nextRound()
        }

        XCTAssertEqual(viewModel.streak, 2)
        XCTAssertEqual(viewModel.bestStreak, 2)

        // Get one wrong (use distractor)
        if let wrongOption = viewModel.options.first(where: { option in
            if case .distractor = option { return true }
            return false
        }) {
            viewModel.selectAnswer(wrongOption)
        }

        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.bestStreak, 2) // Best streak preserved
    }

    @MainActor
    func testDifficultySettings() {
        let viewModel = RhymeGameViewModel()

        viewModel.difficulty = .easy
        XCTAssertEqual(viewModel.difficulty.rawValue, 1)

        viewModel.difficulty = .medium
        XCTAssertEqual(viewModel.difficulty.rawValue, 2)

        viewModel.difficulty = .hard
        XCTAssertEqual(viewModel.difficulty.rawValue, 3)
    }

    @MainActor
    func testProgressCalculation() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01)

        viewModel.nextRound()
        XCTAssertEqual(viewModel.progress, 0.1, accuracy: 0.01)

        for _ in 2..<5 {
            viewModel.nextRound()
        }
        XCTAssertEqual(viewModel.progress, 0.4, accuracy: 0.01)
    }

    @MainActor
    func testScorePercentage() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Get 8 correct out of 10
        for i in 0..<10 {
            if i < 8, let correctAnswer = viewModel.correctAnswer {
                viewModel.selectAnswer(.word(correctAnswer))
            }
            if i < 9 {
                viewModel.nextRound()
            }
        }

        XCTAssertEqual(viewModel.score, 8)
        XCTAssertEqual(viewModel.scorePercentage, 80)
    }

    @MainActor
    func testOptionsCount() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        // Should always have 4 options
        XCTAssertEqual(viewModel.options.count, 4)

        // Options should include the correct answer
        let hasCorrectAnswer = viewModel.options.contains { option in
            if case .word(let word) = option,
               word.id == viewModel.correctAnswer?.id {
                return true
            }
            return false
        }
        XCTAssertTrue(hasCorrectAnswer)
    }

    @MainActor
    func testCannotSelectAfterAnswering() {
        let viewModel = RhymeGameViewModel()
        viewModel.startGame()

        guard let correctAnswer = viewModel.correctAnswer else {
            XCTFail("No correct answer")
            return
        }

        // First selection should work
        let firstResult = viewModel.selectAnswer(.word(correctAnswer))
        XCTAssertTrue(firstResult)

        // Second selection should fail
        if let anotherOption = viewModel.options.first(where: { option in
            if case .word(let word) = option, word.id != correctAnswer.id {
                return true
            }
            return false
        }) {
            let secondResult = viewModel.selectAnswer(anotherOption)
            XCTAssertFalse(secondResult)
        }
    }

    // MARK: - Rhyme Logic Tests (Independent)

    func testWordFamilyMatching() {
        let word1 = RhymeWord(id: "cat", word: "cat", wordFamily: "-at", difficulty: 1, image: "", emoji: "", audio: "")
        let word2 = RhymeWord(id: "hat", word: "hat", wordFamily: "-at", difficulty: 1, image: "", emoji: "", audio: "")
        let word3 = RhymeWord(id: "dog", word: "dog", wordFamily: "-og", difficulty: 1, image: "", emoji: "", audio: "")

        XCTAssertTrue(RhymeData.doWordsRhyme(word1, word2))
        XCTAssertFalse(RhymeData.doWordsRhyme(word1, word3))
        XCTAssertFalse(RhymeData.doWordsRhyme(word1, word1)) // Same word doesn't rhyme with itself
    }

    func testDifficultyDisplayNames() {
        XCTAssertEqual(RhymeDifficulty.easy.displayName, "Easy")
        XCTAssertEqual(RhymeDifficulty.medium.displayName, "Medium")
        XCTAssertEqual(RhymeDifficulty.hard.displayName, "Hard")
    }

    func testRhymeDataWordCount() {
        // Ensure we have enough words for a full game
        let easyWords = RhymeData.words(forDifficulty: 1)
        XCTAssertGreaterThanOrEqual(easyWords.count, 10, "Need at least 10 easy words for a full game")

        let allWords = RhymeData.words
        XCTAssertGreaterThan(allWords.count, 50, "Should have substantial word pool")
    }

    func testWordFamiliesExist() {
        XCTAssertFalse(RhymeData.wordFamilies.isEmpty)
        XCTAssertTrue(RhymeData.wordFamilies.contains("-at"))
        XCTAssertTrue(RhymeData.wordFamilies.contains("-an"))
    }

    func testDistractorsExist() {
        XCTAssertFalse(RhymeData.distractors.isEmpty)

        // Distractors should have confusedWith entries
        for distractor in RhymeData.distractors {
            XCTAssertFalse(distractor.confusedWith.isEmpty)
        }
    }
}
