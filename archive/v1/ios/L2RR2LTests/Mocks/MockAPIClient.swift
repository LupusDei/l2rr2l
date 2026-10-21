import Foundation
@testable import L2RR2L

/// A mock API client for testing that allows configuring responses
/// Note: This mock is designed to be used when the full app types are available.
/// For basic testing, use protocol-based mocking instead.
final class MockAPIClient {
    // MARK: - Configuration

    /// Error to throw on next request
    var errorToThrow: Error?

    /// Simulated network delay in seconds
    var networkDelay: TimeInterval = 0

    /// Track all requests made
    private(set) var requestHistory: [RecordedRequest] = []

    // MARK: - Response Configuration

    private var responseHandlers: [String: () throws -> Any] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration Methods

    /// Configure a response for a specific path
    func setResponse<T: Encodable>(for path: String, response: T) {
        responseHandlers[path] = { response }
    }

    /// Configure an error for a specific path
    func setError(for path: String, error: Error) {
        responseHandlers[path] = { throw error }
    }

    /// Clear all configured responses
    func clearResponses() {
        responseHandlers.removeAll()
        errorToThrow = nil
    }

    /// Clear request history
    func clearHistory() {
        requestHistory.removeAll()
    }
}

// MARK: - Supporting Types

struct RecordedRequest {
    let path: String
    let method: String
    let timestamp: Date

    init(path: String, method: String, timestamp: Date = Date()) {
        self.path = path
        self.method = method
        self.timestamp = timestamp
    }
}

enum MockAPIError: Error, LocalizedError {
    case noResponseConfigured(path: String)
    case responseMismatch(expected: String, actual: String)

    var errorDescription: String? {
        switch self {
        case .noResponseConfigured(let path):
            return "No mock response configured for path: \(path)"
        case .responseMismatch(let expected, let actual):
            return "Response type mismatch: expected \(expected), got \(actual)"
        }
    }
}
