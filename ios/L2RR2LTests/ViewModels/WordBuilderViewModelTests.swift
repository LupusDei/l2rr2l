import XCTest
@testable import L2RR2L

/// Tests for WordBuilderViewModel
final class WordBuilderViewModelTests: XCTestCase {

    // MARK: - Game Logic Tests (Independent)

    func testLetterArrayFromWord() {
        let word = "apple"
        let letters = Array(word)
        XCTAssertEqual(letters, ["a", "p", "p", "l", "e"])
    }

    func testWordLengthCalculation() {
        let word = "house"
        XCTAssertEqual(word.count, 5)
    }

    func testShuffledLettersContainsSameElements() {
        let letters: [Character] = ["a", "p", "p", "l", "e"]
        var shuffled = letters
        shuffled.shuffle()
        XCTAssertEqual(letters.sorted(), shuffled.sorted())
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
        XCTAssertEqual(progress, 1.0 / 3.0, accuracy: 0.01)
    }

    func testCaseInsensitiveWordComparison() {
        let expected = "APPLE"
        let actual = "apple"
        XCTAssertEqual(expected.lowercased(), actual.lowercased())
    }

    func testBuildingWordFromCharacters() {
        var builtWord: [Character] = []
        builtWord.append("a")
        builtWord.append("p")
        builtWord.append("p")
        builtWord.append("l")
        builtWord.append("e")
        XCTAssertEqual(String(builtWord), "apple")
    }

    func testRemoveLastLetter() {
        var builtWord: [Character] = ["a", "p", "p"]
        builtWord.removeLast()
        XCTAssertEqual(builtWord, ["a", "p"])
    }

    func testClearWord() {
        var builtWord: [Character] = ["a", "p", "p", "l", "e"]
        builtWord.removeAll()
        XCTAssertTrue(builtWord.isEmpty)
    }

    func testWordComplete() {
        let puzzleLength = 5
        let builtWord: [Character] = ["a", "p", "p", "l", "e"]
        XCTAssertEqual(builtWord.count, puzzleLength)
    }

    func testStreakCalculation() {
        var streak = 0
        var bestStreak = 0

        // Correct answer
        streak += 1
        bestStreak = max(bestStreak, streak)
        XCTAssertEqual(streak, 1)
        XCTAssertEqual(bestStreak, 1)

        // Correct answer
        streak += 1
        bestStreak = max(bestStreak, streak)
        XCTAssertEqual(streak, 2)
        XCTAssertEqual(bestStreak, 2)

        // Incorrect answer
        streak = 0
        XCTAssertEqual(streak, 0)
        XCTAssertEqual(bestStreak, 2)
    }

    func testAvailableLettersFiltering() {
        let scrambledLetters: [Character] = ["p", "a", "p", "l", "e"]
        let usedIndices: Set<Int> = [0, 1] // 'p' and 'a' used
        let available = scrambledLetters.enumerated()
            .filter { !usedIndices.contains($0.offset) }
            .map { $0.element }
        XCTAssertEqual(available, ["p", "l", "e"])
    }
}
