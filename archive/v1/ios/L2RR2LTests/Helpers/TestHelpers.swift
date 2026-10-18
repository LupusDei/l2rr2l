import Foundation
import XCTest
@testable import L2RR2L

/// Protocol for testable async operations
protocol AsyncTestable {
    func performAsyncSetup() async throws
    func performAsyncTeardown() async throws
}

extension AsyncTestable where Self: XCTestCase {
    func performAsyncSetup() async throws {}
    func performAsyncTeardown() async throws {}
}
