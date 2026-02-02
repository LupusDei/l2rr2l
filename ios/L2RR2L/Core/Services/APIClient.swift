import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return message ?? "HTTP error \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in again"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var authToken: String?

    private init() {
        // Default to localhost for development
        self.baseURL = URL(string: "http://localhost:3000/api")!
        self.session = URLSession.shared

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func setBaseURL(_ url: URL) {
        // For testing or configuration
    }

    func request<T: Decodable>(
        method: String,
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = authToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(ErrorResponse.self, from: data).error
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func get<T: Decodable>(_ path: String, requiresAuth: Bool = false) async throws -> T {
        try await request(method: "GET", path: path, requiresAuth: requiresAuth)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil, requiresAuth: Bool = false) async throws -> T {
        try await request(method: "POST", path: path, body: body, requiresAuth: requiresAuth)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil, requiresAuth: Bool = false) async throws -> T {
        try await request(method: "PUT", path: path, body: body, requiresAuth: requiresAuth)
    }

    func delete(_ path: String, requiresAuth: Bool = false) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, requiresAuth: requiresAuth)
    }
}

private struct ErrorResponse: Decodable {
    let error: String
}

private struct EmptyResponse: Decodable {}
