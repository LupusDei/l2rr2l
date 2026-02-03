import XCTest
@testable import L2RR2L

/// Tests for WordBuilderViewModel
final class WordBuilderViewModelTests: XCTestCase {

    // MARK: - Game Logic Tests

    func testLetterArrayFromWord() {
        let word = "cat"
        let letters = Array(word)
        XCTAssertEqual(letters, ["c", "a", "t"])
    }

    func testWordLengthCalculation() {
        let word = "moon"
        XCTAssertEqual(word.count, 4)
    }

    func testShuffledLettersContainsSameElements() {
        let letters: [Character] = ["c", "a", "t"]
        var shuffled = letters
        shuffled.shuffle()
        XCTAssertEqual(Set(letters), Set(shuffled))
    }

    func testScorePercentageCalculation() {
        let score = 12
        let totalPuzzles = 15
        let percentage = Int(Double(score) / Double(totalPuzzles) * 100)
        XCTAssertEqual(percentage, 80)
    }

    func testProgressCalculation() {
        let puzzleIndex = 5
        let totalPuzzles = 15
        let progress = Double(puzzleIndex) / Double(totalPuzzles)
        XCTAssertEqual(progress, 5.0/15.0, accuracy: 0.01)
    }

    func testCaseInsensitiveWordComparison() {
        let expected = "CAT"
        let actual = "cat"
        XCTAssertEqual(expected.lowercased(), actual.lowercased())
    }

    func testWordPuzzleProperties() {
        let puzzle = WordPuzzle(word: "dog", emoji: "🐕", hint: "A pet that barks")
        XCTAssertEqual(puzzle.word, "dog")
        XCTAssertEqual(puzzle.emoji, "🐕")
        XCTAssertEqual(puzzle.hint, "A pet that barks")
        XCTAssertEqual(puzzle.length, 3)
        XCTAssertEqual(puzzle.letters, ["d", "o", "g"])
    }

    func testWordPuzzleDefaultHint() {
        let puzzle = WordPuzzle(word: "cat", emoji: "🐱")
        XCTAssertEqual(puzzle.hint, "Spell the word!")
    }

    func testWordBuilderDataHas15Puzzles() {
        XCTAssertEqual(WordBuilderData.puzzles.count, 15)
    }

    func testWordBuilderDataShufflePreservesElements() {
        let letters: [Character] = ["s", "t", "a", "r"]
        let shuffled = WordBuilderData.shuffle(letters)
        XCTAssertEqual(Set(letters), Set(shuffled))
        XCTAssertEqual(letters.count, shuffled.count)
    }

    // MARK: - ViewModel Integration Tests

    @MainActor
    func testViewModelInitialState() async {
        let viewModel = WordBuilderViewModel()

        XCTAssertNil(viewModel.currentPuzzle)
        XCTAssertEqual(viewModel.scrambledLetters, [])
        XCTAssertEqual(viewModel.builtWord, [])
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.puzzleIndex, 0)
        XCTAssertNil(viewModel.isCorrect)
        XCTAssertEqual(viewModel.totalPuzzles, 15)
        XCTAssertEqual(viewModel.gameState, .notStarted)
    }

    @MainActor
    func testStartGame() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        XCTAssertNotNil(viewModel.currentPuzzle)
        XCTAssertFalse(viewModel.scrambledLetters.isEmpty)
        XCTAssertEqual(viewModel.builtWord, [])
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.puzzleIndex, 0)
        XCTAssertEqual(viewModel.gameState, .playing)
    }

    @MainActor
    func testAddLetter() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        guard let firstLetter = viewModel.scrambledLetters.first else {
            XCTFail("No scrambled letters")
            return
        }

        let initialCount = viewModel.scrambledLetters.count
        viewModel.addLetter(firstLetter)

        XCTAssertEqual(viewModel.scrambledLetters.count, initialCount - 1)
        XCTAssertEqual(viewModel.builtWord.count, 1)
        XCTAssertEqual(viewModel.builtWord.first, firstLetter)
    }

    @MainActor
    func testRemoveLast() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        guard let firstLetter = viewModel.scrambledLetters.first else {
            XCTFail("No scrambled letters")
            return
        }

        viewModel.addLetter(firstLetter)
        let countBefore = viewModel.scrambledLetters.count
        viewModel.removeLast()

        XCTAssertEqual(viewModel.scrambledLetters.count, countBefore + 1)
        XCTAssertEqual(viewModel.builtWord.count, 0)
    }

    @MainActor
    func testClearWord() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        // Add all letters
        let letters = viewModel.scrambledLetters
        for letter in letters {
            viewModel.addLetter(letter)
        }

        XCTAssertEqual(viewModel.builtWord.count, letters.count)
        XCTAssertEqual(viewModel.scrambledLetters.count, 0)

        viewModel.clearWord()

        XCTAssertEqual(viewModel.builtWord.count, 0)
        XCTAssertEqual(viewModel.scrambledLetters.count, letters.count)
    }

    @MainActor
    func testCheckCorrectAnswer() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        guard let puzzle = viewModel.currentPuzzle else {
            XCTFail("No puzzle")
            return
        }

        // Build the correct word
        for letter in puzzle.letters {
            viewModel.addLetter(letter)
        }

        let result = viewModel.checkAnswer()

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.isCorrect, true)
        XCTAssertEqual(viewModel.score, 1)
        XCTAssertEqual(viewModel.streak, 1)
        XCTAssertEqual(viewModel.gameState, .correct)
    }

    @MainActor
    func testCheckIncorrectAnswer() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        guard let puzzle = viewModel.currentPuzzle else {
            XCTFail("No puzzle")
            return
        }

        // Build incorrect word (reversed)
        let reversed = puzzle.letters.reversed()
        for letter in reversed {
            viewModel.addLetter(letter)
        }

        // Only check if it's actually different from the correct word
        let builtWord = String(viewModel.builtWord)
        if builtWord.lowercased() != puzzle.word.lowercased() {
            let result = viewModel.checkAnswer()
            XCTAssertFalse(result)
            XCTAssertEqual(viewModel.isCorrect, false)
            XCTAssertEqual(viewModel.score, 0)
            XCTAssertEqual(viewModel.streak, 0)
            XCTAssertEqual(viewModel.gameState, .incorrect)
        }
    }

    @MainActor
    func testNextPuzzle() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        let firstPuzzle = viewModel.currentPuzzle
        viewModel.nextPuzzle()

        XCTAssertEqual(viewModel.puzzleIndex, 1)
        XCTAssertNotEqual(viewModel.currentPuzzle?.word, firstPuzzle?.word)
        XCTAssertEqual(viewModel.gameState, .playing)
    }

    @MainActor
    func testGameComplete() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        // Advance to last puzzle
        for _ in 0..<14 {
            viewModel.nextPuzzle()
        }

        XCTAssertEqual(viewModel.puzzleIndex, 14)
        XCTAssertEqual(viewModel.currentPuzzleNumber, 15)

        // Try to advance past last puzzle
        viewModel.nextPuzzle()

        XCTAssertEqual(viewModel.gameState, .gameComplete)
        XCTAssertTrue(viewModel.isGameComplete)
    }

    @MainActor
    func testResetGame() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        // Make some progress
        viewModel.nextPuzzle()
        viewModel.nextPuzzle()

        viewModel.resetGame()

        XCTAssertNil(viewModel.currentPuzzle)
        XCTAssertEqual(viewModel.scrambledLetters, [])
        XCTAssertEqual(viewModel.builtWord, [])
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.streak, 0)
        XCTAssertEqual(viewModel.puzzleIndex, 0)
        XCTAssertEqual(viewModel.gameState, .notStarted)
    }

    @MainActor
    func testProgressCalculationInViewModel() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        XCTAssertEqual(viewModel.progress, 0.0, accuracy: 0.01)

        viewModel.nextPuzzle()
        XCTAssertEqual(viewModel.progress, 1.0/15.0, accuracy: 0.01)

        for _ in 0..<4 {
            viewModel.nextPuzzle()
        }
        XCTAssertEqual(viewModel.progress, 5.0/15.0, accuracy: 0.01)
    }

    @MainActor
    func testIsWordComplete() async {
        let viewModel = WordBuilderViewModel()
        viewModel.startGame()

        guard let puzzle = viewModel.currentPuzzle else {
            XCTFail("No puzzle")
            return
        }

        XCTAssertFalse(viewModel.isWordComplete)

        // Add all letters
        for letter in puzzle.letters {
            viewModel.addLetter(letter)
        }

        XCTAssertTrue(viewModel.isWordComplete)
    }
}
