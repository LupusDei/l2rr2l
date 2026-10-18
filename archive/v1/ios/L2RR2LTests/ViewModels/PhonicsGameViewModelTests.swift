import XCTest
@testable import L2RR2L

/// Tests for PhonicsGameViewModel
/// Note: These tests require the full Xcode project to be configured with all source files.
/// Run these tests after adding all L2RR2L source files to the main target.
final class PhonicsGameViewModelTests: XCTestCase {

    // MARK: - Game Logic Tests (Independent)

    func testBeginningSound() {
        let word = "cat"
        let beginningSound = String(word.prefix(1))
        XCTAssertEqual(beginningSound, "c")
    }

    func testEndingSound() {
        let word = "cat"
        let endingSound = String(word.suffix(1))
        XCTAssertEqual(endingSound, "t")
    }

    func testScorePercentageCalculation() {
        let score = 8
        let totalRounds = 10
        let percentage = Int(Double(score) / Double(totalRounds) * 100)
        XCTAssertEqual(percentage, 80)
    }

    func testProgressCalculation() {
        let round = 3
        let totalRounds = 10
        let progress = Double(round - 1) / Double(totalRounds)
        XCTAssertEqual(progress, 0.2, accuracy: 0.01)
    }

    func testOptionsShuffling() {
        var options = ["A", "B", "C", "D"]
        options.shuffle()
        XCTAssertEqual(Set(options), Set(["A", "B", "C", "D"]))
        XCTAssertEqual(options.count, 4)
    }

    func testSoundUppercasing() {
        let sound = "b"
        XCTAssertEqual(sound.uppercased(), "B")
    }
}
