import Foundation

/// Errors that can occur during API requests
public enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case notFound
    case badRequest(message: String?)
    case conflict(message: String?)
    case serverError(statusCode: Int, message: String?)
    case serviceUnavailable(message: String?)
    case unknown(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in again"
        case .notFound:
            return "Resource not found"
        case .badRequest(let message):
            return message ?? "Invalid request"
        case .conflict(let message):
            return message ?? "Resource conflict"
        case .serverError(_, let message):
            return message ?? "Server error occurred"
        case .serviceUnavailable(let message):
            return message ?? "Service temporarily unavailable"
        case .unknown(let statusCode):
            return "Unknown error (status: \(statusCode))"
        }
    }
}

/// Standard error response from the API
struct APIErrorResponse: Decodable {
    let error: String?
    let message: String?
}
