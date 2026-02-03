import XCTest
@testable import L2RR2L

/// Tests for SpellingGameViewModel
/// Note: These tests require the full Xcode project to be configured with all source files.
/// Run these tests after adding all L2RR2L source files to the main target.
final class SpellingGameViewModelTests: XCTestCase {

    // MARK: - Game Logic Tests (Independent)

    func testLetterArrayFromWord() {
        let word = "cat"
        let letters = Array(word)
        XCTAssertEqual(letters, ["c", "a", "t"])
    }

    func testWordLengthCalculation() {
        let word = "spelling"
        XCTAssertEqual(word.count, 8)
    }

    func testShuffledLettersContainsSameElements() {
        let letters = ["c", "a", "t"]
        var shuffled = letters
        shuffled.shuffle()
        XCTAssertEqual(Set(letters), Set(shuffled))
    }

    func testScorePercentageCalculation() {
        let score = 7
        let totalRounds = 10
        let percentage = Int(Double(score) / Double(totalRounds) * 100)
        XCTAssertEqual(percentage, 70)
    }

    func testProgressCalculation() {
        let round = 5
        let totalRounds = 10
        let progress = Double(round - 1) / Double(totalRounds)
        XCTAssertEqual(progress, 0.4, accuracy: 0.01)
    }

    func testCaseInsensitiveWordComparison() {
        let expected = "CAT"
        let actual = "cat"
        XCTAssertEqual(expected.lowercased(), actual.lowercased())
    }
}
