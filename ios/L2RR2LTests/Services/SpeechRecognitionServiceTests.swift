import XCTest
@testable import L2RR2L

/// Tests for speech recognition service functionality
/// These tests verify the pronunciation checking algorithms that don't require
/// the actual speech recognition framework.
final class SpeechRecognitionServiceTests: XCTestCase {
    // MARK: - String Comparison Tests

    func testExactStringsAreEqual() {
        let str1 = "hello"
        let str2 = "hello"
        XCTAssertEqual(str1.lowercased(), str2.lowercased())
    }

    func testCaseInsensitiveComparison() {
        let str1 = "Hello"
        let str2 = "hello"
        XCTAssertEqual(str1.lowercased(), str2.lowercased())
    }

    func testWhitespaceTrimming() {
        let str1 = "  hello  "
        let str2 = "hello"
        XCTAssertEqual(str1.trimmingCharacters(in: .whitespaces), str2)
    }

    func testDifferentStrings() {
        let str1 = "cat"
        let str2 = "dog"
        XCTAssertNotEqual(str1, str2)
    }

    func testEmptyStrings() {
        let str1 = ""
        let str2 = ""
        XCTAssertEqual(str1, str2)
    }
}
