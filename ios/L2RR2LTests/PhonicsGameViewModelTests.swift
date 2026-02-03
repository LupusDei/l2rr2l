import XCTest
@testable import L2RR2L

@MainActor
final class PhonicsGameViewModelTests: XCTestCase {
    var sut: PhonicsGameViewModel!

    override func setUp() async throws {
        sut = PhonicsGameViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(sut.currentWord)
        XCTAssertEqual(sut.soundPosition, .beginning)
        XCTAssertTrue(sut.options.isEmpty)
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.round, 1)
        XCTAssertNil(sut.isCorrect)
        XCTAssertEqual(sut.gameState, .notStarted)
        XCTAssertNil(sut.selectedOption)
    }

    // MARK: - Start Game Tests

    func testStartGameSetsCurrentWord() {
        sut.startGame()

        XCTAssertNotNil(sut.currentWord)
        XCTAssertEqual(sut.gameState, .playing)
    }

    func testStartGameGeneratesOptions() {
        sut.startGame()

        XCTAssertFalse(sut.options.isEmpty)
        XCTAssertEqual(sut.options.count, 4)  // optionsCount = 4
    }

    func testStartGameIncludesCorrectOption() {
        sut.startGame()

        let correctOptions = sut.options.filter { $0.isCorrect }
        XCTAssertEqual(correctOptions.count, 1)
    }

    func testStartGameResetsState() {
        sut.startGame()

        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 0)
        XCTAssertEqual(sut.round, 1)
        XCTAssertNil(sut.isCorrect)
        XCTAssertNil(sut.selectedOption)
    }

    // MARK: - Option Generation Tests

    func testOptionsContainOneCorrectAnswer() {
        sut.startGame()

        let correctCount = sut.options.filter { $0.isCorrect }.count
        XCTAssertEqual(correctCount, 1, "Should have exactly one correct option")
    }

    func testOptionsContainThreeIncorrectAnswers() {
        sut.startGame()

        let incorrectCount = sut.options.filter { !$0.isCorrect }.count
        XCTAssertEqual(incorrectCount, 3, "Should have exactly three incorrect options")
    }

    func testCorrectOptionMatchesWordBeginningSound() {
        sut.startGame()

        guard let word = sut.currentWord else {
            XCTFail("Expected current word")
            return
        }

        let correctOption = sut.options.first { $0.isCorrect }
        XCTAssertNotNil(correctOption)
        XCTAssertEqual(correctOption?.sound.lowercased(), word.beginningSound.lowercased())
    }

    func testOptionsAreShuffled() {
        // Run multiple times to verify options aren't always in same position
        var firstPositionIsCorrectCount = 0

        for _ in 0..<20 {
            sut.startGame()
            if sut.options.first?.isCorrect == true {
                firstPositionIsCorrectCount += 1
            }
            sut.resetGame()
        }

        // If options weren't shuffled, correct would always be first (count = 20)
        // With shuffling, it should be roughly 1/4 of the time (5)
        // We'll just check it's not always first
        XCTAssertLessThan(firstPositionIsCorrectCount, 20, "Options should be shuffled")
    }

    // MARK: - Answer Selection Tests

    func testSelectCorrectAnswerIncrementsScore() {
        sut.startGame()

        guard let correctOption = sut.options.first(where: { $0.isCorrect }) else {
            XCTFail("Expected correct option")
            return
        }

        let result = sut.selectAnswer(correctOption)

        XCTAssertTrue(result)
        XCTAssertEqual(sut.score, 1)
    }

    func testSelectCorrectAnswerIncrementsStreak() {
        sut.startGame()

        guard let correctOption = sut.options.first(where: { $0.isCorrect }) else {
            XCTFail("Expected correct option")
            return
        }

        _ = sut.selectAnswer(correctOption)

        XCTAssertEqual(sut.streak, 1)
    }

    func testSelectIncorrectAnswerDoesNotIncrementScore() {
        sut.startGame()

        guard let incorrectOption = sut.options.first(where: { !$0.isCorrect }) else {
            XCTFail("Expected incorrect option")
            return
        }

        let result = sut.selectAnswer(incorrectOption)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.score, 0)
    }

    func testSelectIncorrectAnswerResetsStreak() {
        sut.startGame()

        // First, get a correct answer to build streak
        guard let correctOption = sut.options.first(where: { $0.isCorrect }) else {
            XCTFail("Expected correct option")
            return
        }
        _ = sut.selectAnswer(correctOption)
        XCTAssertEqual(sut.streak, 1)

        sut.nextRound()

        // Now select incorrect
        guard let incorrectOption = sut.options.first(where: { !$0.isCorrect }) else {
            XCTFail("Expected incorrect option")
            return
        }
        _ = sut.selectAnswer(incorrectOption)

        XCTAssertEqual(sut.streak, 0)
    }

    func testSelectAnswerSetsSelectedOption() {
        sut.startGame()

        guard let option = sut.options.first else {
            XCTFail("Expected options")
            return
        }

        _ = sut.selectAnswer(option)

        XCTAssertEqual(sut.selectedOption, option)
    }

    func testSelectAnswerSetsIsCorrect() {
        sut.startGame()

        guard let correctOption = sut.options.first(where: { $0.isCorrect }) else {
            XCTFail("Expected correct option")
            return
        }

        _ = sut.selectAnswer(correctOption)

        XCTAssertTrue(sut.isCorrect ?? false)
    }

    func testSelectAnswerSetsGameStateToRoundComplete() {
        sut.startGame()

        guard let option = sut.options.first else {
            XCTFail("Expected options")
            return
        }

        _ = sut.selectAnswer(option)

        if case .roundComplete = sut.gameState {
            // Success
        } else {
            XCTFail("Expected game state to be roundComplete")
        }
    }

    func testCannotSelectAnswerTwice() {
        sut.startGame()

        guard sut.options.count >= 2 else {
            XCTFail("Expected at least 2 options")
            return
        }

        let firstOption = sut.options[0]
        let secondOption = sut.options[1]

        _ = sut.selectAnswer(firstOption)
        let secondResult = sut.selectAnswer(secondOption)

        XCTAssertFalse(secondResult)
        XCTAssertEqual(sut.selectedOption, firstOption)
    }

    func testCannotSelectAnswerWhenNotPlaying() {
        // Game not started
        let dummyOption = SoundOption(sound: "B", isCorrect: true)
        let result = sut.selectAnswer(dummyOption)

        XCTAssertFalse(result)
    }

    // MARK: - Round Progression Tests

    func testNextRoundIncrementsRound() {
        sut.startGame()
        XCTAssertEqual(sut.round, 1)

        selectAnyAnswer()
        sut.nextRound()

        XCTAssertEqual(sut.round, 2)
    }

    func testNextRoundResetsSelectedOption() {
        sut.startGame()
        selectAnyAnswer()

        XCTAssertNotNil(sut.selectedOption)

        sut.nextRound()

        XCTAssertNil(sut.selectedOption)
    }

    func testNextRoundResetsIsCorrect() {
        sut.startGame()
        selectAnyAnswer()

        XCTAssertNotNil(sut.isCorrect)

        sut.nextRound()

        XCTAssertNil(sut.isCorrect)
    }

    func testNextRoundSetsNewWord() {
        sut.startGame()

        let firstWord = sut.currentWord

        selectAnyAnswer()
        sut.nextRound()

        // Word might be the same by chance, but we should at least have a word
        XCTAssertNotNil(sut.currentWord)

        // Options should be regenerated
        XCTAssertFalse(sut.options.isEmpty)
    }

    func testNextRoundSetsGameStateToPlaying() {
        sut.startGame()
        selectAnyAnswer()

        sut.nextRound()

        XCTAssertEqual(sut.gameState, .playing)
    }

    func testGameCompletesAfterFinalRound() {
        sut.startGame()

        // Play through all rounds
        for i in 1...sut.totalRounds {
            selectAnyAnswer()
            if i < sut.totalRounds {
                sut.nextRound()
            }
        }

        sut.nextRound()

        XCTAssertEqual(sut.gameState, .gameComplete)
        XCTAssertTrue(sut.isGameComplete)
    }

    // MARK: - Streak and Best Streak Tests

    func testBestStreakTracksHighestStreak() {
        sut.startGame()

        // Build streak of 2
        selectCorrectAnswer()
        sut.nextRound()
        selectCorrectAnswer()
        XCTAssertEqual(sut.bestStreak, 2)

        // Answer incorrectly
        sut.nextRound()
        selectIncorrectAnswer()
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 2)  // Best preserved

        // Build smaller streak
        sut.nextRound()
        selectCorrectAnswer()
        XCTAssertEqual(sut.bestStreak, 2)  // Still 2
    }

    func testStreakContinuesAcrossRounds() {
        sut.startGame()

        for i in 1...5 {
            selectCorrectAnswer()
            if i < 5 {
                sut.nextRound()
            }
        }

        XCTAssertEqual(sut.streak, 5)
        XCTAssertEqual(sut.bestStreak, 5)
    }

    // MARK: - Progress and Score Tests

    func testProgressCalculation() {
        sut.startGame()
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)

        selectAnyAnswer()
        sut.nextRound()
        XCTAssertEqual(sut.progress, 0.1, accuracy: 0.01)

        for _ in 2...5 {
            selectAnyAnswer()
            sut.nextRound()
        }
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01)
    }

    func testScorePercentageCalculation() {
        sut.startGame()

        // Answer 7 correct, 3 incorrect
        for i in 1...10 {
            if i <= 7 {
                selectCorrectAnswer()
            } else {
                selectIncorrectAnswer()
            }
            if i < 10 {
                sut.nextRound()
            }
        }

        XCTAssertEqual(sut.score, 7)
        XCTAssertEqual(sut.scorePercentage, 70)
    }

    // MARK: - Reset Game Tests

    func testResetGameClearsAllState() {
        sut.startGame()
        selectCorrectAnswer()
        sut.nextRound()
        selectCorrectAnswer()

        sut.resetGame()

        XCTAssertNil(sut.currentWord)
        XCTAssertTrue(sut.options.isEmpty)
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.streak, 0)
        XCTAssertEqual(sut.bestStreak, 0)
        XCTAssertEqual(sut.round, 1)
        XCTAssertNil(sut.isCorrect)
        XCTAssertNil(sut.selectedOption)
        XCTAssertEqual(sut.gameState, .notStarted)
    }

    // MARK: - Correct Sound Tests

    func testCorrectSoundReturnsBeginningSound() {
        sut.startGame()

        guard let word = sut.currentWord else {
            XCTFail("Expected current word")
            return
        }

        // Default sound position is .beginning
        XCTAssertEqual(sut.correctSound, word.beginningSound)
    }

    func testCorrectSoundReturnsNilWhenNoWord() {
        // Game not started
        XCTAssertNil(sut.correctSound)
    }

    // MARK: - Helper Methods

    private func selectAnyAnswer() {
        guard let option = sut.options.first else { return }
        _ = sut.selectAnswer(option)
    }

    private func selectCorrectAnswer() {
        guard let correctOption = sut.options.first(where: { $0.isCorrect }) else { return }
        _ = sut.selectAnswer(correctOption)
    }

    private func selectIncorrectAnswer() {
        guard let incorrectOption = sut.options.first(where: { !$0.isCorrect }) else { return }
        _ = sut.selectAnswer(incorrectOption)
    }
}
