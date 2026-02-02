import Foundation

/// Thread-safe API client for network requests
public actor APIClient {
    public static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var authToken: String?
    private let maxRetries: Int

    public init(
        baseURL: URL = URL(string: "https://l2rr2l.pages.dev/api")!,
        session: URLSession = .shared,
        maxRetries: Int = 2
    ) {
        self.baseURL = baseURL
        self.session = session
        self.maxRetries = maxRetries

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Auth Token Management

    public func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    public func getAuthToken() -> String? {
        return authToken
    }

    // MARK: - Request Execution

    /// Execute a request and decode the response
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        return try await executeWithRetry(request, retries: maxRetries)
    }

    /// Execute a request without expecting a response body
    public func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let _: EmptyResponse = try await executeWithRetry(request, retries: maxRetries)
    }

    /// Execute a request and return raw data (for audio/binary responses)
    public func requestData(_ endpoint: Endpoint) async throws -> Data {
        let request = try buildRequest(for: endpoint)
        return try await executeDataWithRetry(request, retries: maxRetries)
    }

    // MARK: - Private Methods

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            switch endpoint.contentType {
            case .json:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                do {
                    request.httpBody = try encoder.encode(AnyEncodable(body))
                } catch {
                    throw APIError.encodingError(error)
                }
            case .formData:
                // Form data encoding is handled separately
                break
            }
        }

        logRequest(request)
        return request
    }

    private func executeWithRetry<T: Decodable>(_ request: URLRequest, retries: Int) async throws -> T {
        var lastError: Error?

        for attempt in 0...retries {
            if attempt > 0 {
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                logDebug("Retrying request (attempt \(attempt + 1)/\(retries + 1))")
            }

            do {
                let (data, response) = try await session.data(for: request)
                logResponse(response, data: data)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError(URLError(.badServerResponse))
                }

                try handleStatusCode(httpResponse.statusCode, data: data)

                if T.self == EmptyResponse.self {
                    return EmptyResponse() as! T
                }

                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError {
                if shouldRetry(error: error), attempt < retries {
                    lastError = error
                    continue
                }
                throw error
            } catch {
                if shouldRetry(error: error), attempt < retries {
                    lastError = error
                    continue
                }
                throw APIError.networkError(error)
            }
        }

        throw lastError ?? APIError.unknown(statusCode: 0)
    }

    private func executeDataWithRetry(_ request: URLRequest, retries: Int) async throws -> Data {
        var lastError: Error?

        for attempt in 0...retries {
            if attempt > 0 {
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            do {
                let (data, response) = try await session.data(for: request)
                logResponse(response, data: data)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError(URLError(.badServerResponse))
                }

                try handleStatusCode(httpResponse.statusCode, data: data)
                return data
            } catch let error as APIError {
                if shouldRetry(error: error), attempt < retries {
                    lastError = error
                    continue
                }
                throw error
            } catch {
                if shouldRetry(error: error), attempt < retries {
                    lastError = error
                    continue
                }
                throw APIError.networkError(error)
            }
        }

        throw lastError ?? APIError.unknown(statusCode: 0)
    }

    private func handleStatusCode(_ statusCode: Int, data: Data) throws {
        switch statusCode {
        case 200...299:
            return
        case 400:
            let message = parseErrorMessage(from: data)
            throw APIError.badRequest(message: message)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            let message = parseErrorMessage(from: data)
            throw APIError.conflict(message: message)
        case 500...599:
            let message = parseErrorMessage(from: data)
            if statusCode == 503 {
                throw APIError.serviceUnavailable(message: message)
            }
            throw APIError.serverError(statusCode: statusCode, message: message)
        default:
            throw APIError.unknown(statusCode: statusCode)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
            return errorResponse.message ?? errorResponse.error
        }
        return nil
    }

    private func shouldRetry(error: Error) -> Bool {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError, .serverError, .serviceUnavailable:
                return true
            default:
                return false
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }

        return false
    }

    // MARK: - Debug Logging

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("[API] \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("[API] Body: \(bodyString)")
        }
        #endif
    }

    private func logResponse(_ response: URLResponse, data: Data) {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("[API] Response: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.prefix(500)
                print("[API] Data: \(truncated)\(responseString.count > 500 ? "..." : "")")
            }
        }
        #endif
    }

    private func logDebug(_ message: String) {
        #if DEBUG
        print("[API] \(message)")
        #endif
    }
}

// MARK: - Helper Types

/// Empty response for endpoints that return 204 No Content
private struct EmptyResponse: Decodable {}

/// Type-erased Encodable wrapper
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
