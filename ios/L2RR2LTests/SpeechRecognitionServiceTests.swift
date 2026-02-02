import XCTest
@testable import L2RR2L

@MainActor
final class SpeechRecognitionServiceTests: XCTestCase {
    var service: SpeechRecognitionService!

    override func setUp() async throws {
        service = SpeechRecognitionService.shared
    }

    // MARK: - Pronunciation Checking Tests

    func testExactMatchReturnsOne() {
        let score = service.checkPronunciation(expected: "hello", actual: "hello")
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }

    func testCaseInsensitiveMatch() {
        let score = service.checkPronunciation(expected: "Hello", actual: "hello")
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }

    func testPunctuationIgnored() {
        let score = service.checkPronunciation(expected: "Hello!", actual: "hello")
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }

    func testWhitespaceNormalized() {
        let score = service.checkPronunciation(expected: "  hello  ", actual: "hello")
        XCTAssertEqual(score, 1.0, accuracy: 0.001)
    }

    func testSimilarWordsHighScore() {
        // "cat" vs "bat" - one character difference
        let score = service.checkPronunciation(expected: "cat", actual: "bat")
        XCTAssertGreaterThan(score, 0.6)
        XCTAssertLessThan(score, 1.0)
    }

    func testCompletelyDifferentWordsLowScore() {
        let score = service.checkPronunciation(expected: "cat", actual: "elephant")
        XCTAssertLessThan(score, 0.3)
    }

    func testEmptyStringReturnsZero() {
        let score = service.checkPronunciation(expected: "hello", actual: "")
        XCTAssertEqual(score, 0.0, accuracy: 0.001)
    }

    func testBothEmptyReturnsZero() {
        let score = service.checkPronunciation(expected: "", actual: "")
        XCTAssertEqual(score, 0.0, accuracy: 0.001)
    }

    // MARK: - isPronunciationCorrect Tests

    func testIsPronunciationCorrectWithExactMatch() {
        let result = service.isPronunciationCorrect(expected: "cat", actual: "cat")
        XCTAssertTrue(result)
    }

    func testIsPronunciationCorrectWithSimilarWord() {
        // "cat" vs "cap" - should pass default 0.7 threshold
        let result = service.isPronunciationCorrect(expected: "cat", actual: "cap")
        XCTAssertTrue(result)
    }

    func testIsPronunciationCorrectWithDifferentWord() {
        let result = service.isPronunciationCorrect(expected: "cat", actual: "elephant")
        XCTAssertFalse(result)
    }

    func testIsPronunciationCorrectWithCustomThreshold() {
        // "cat" vs "bat" with strict threshold
        let result = service.isPronunciationCorrect(expected: "cat", actual: "bat", threshold: 0.9)
        XCTAssertFalse(result)
    }

    func testIsPronunciationCorrectWithLenientThreshold() {
        // Even somewhat different words pass with low threshold
        let result = service.isPronunciationCorrect(expected: "hello", actual: "hallo", threshold: 0.5)
        XCTAssertTrue(result)
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(service.isRecording)
        XCTAssertEqual(service.audioLevel, 0)
        XCTAssertEqual(service.transcription, "")
    }
}
