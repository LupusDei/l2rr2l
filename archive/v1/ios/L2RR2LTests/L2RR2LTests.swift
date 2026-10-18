import XCTest
@testable import L2RR2L

/// Base test case with common setup for L2RR2L tests
class L2RR2LTestCase: XCTestCase {
    /// Convenience method to wait for async operations with timeout
    func wait(for expectation: XCTestExpectation, timeout: TimeInterval = 5.0) {
        wait(for: [expectation], timeout: timeout)
    }
}

/// Basic sanity tests for the test infrastructure
final class L2RR2LTests: L2RR2LTestCase {
    func testTestInfrastructureWorks() throws {
        XCTAssertTrue(true, "Test infrastructure is functioning")
    }
}
