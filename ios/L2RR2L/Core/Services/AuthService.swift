import Foundation

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let apiClient: APIClient
    private let keychain: KeychainService
    private let tokenKey = "auth_token"

    private init(apiClient: APIClient = .shared, keychain: KeychainService = .shared) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    // MARK: - Public Methods

    func register(email: String, password: String, name: String) async throws -> User {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = RegisterRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await apiClient.post("/auth/register", body: request)

        try saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true

        return response.user
    }

    func login(email: String, password: String) async throws -> User {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await apiClient.post("/auth/login", body: request)

        try saveToken(response.token)
        currentUser = response.user
        isAuthenticated = true

        return response.user
    }

    func logout() {
        do {
            try keychain.delete(for: tokenKey)
        } catch {
            // Ignore keychain errors on logout
        }

        apiClient.authToken = nil
        currentUser = nil
        isAuthenticated = false
    }

    func checkAuthState() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = try? keychain.loadString(for: tokenKey) else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        apiClient.authToken = token

        do {
            let response: UserResponse = try await apiClient.get("/auth/me", requiresAuth: true)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            // Token is invalid, clear it
            logout()
        }
    }

    func refreshSession() async throws {
        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }

        let response: UserResponse = try await apiClient.get("/auth/me", requiresAuth: true)
        currentUser = response.user
    }

    // MARK: - Private Methods

    private func saveToken(_ token: String) throws {
        try keychain.save(token, for: tokenKey)
        apiClient.authToken = token
    }
}

// MARK: - Supporting Types

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidCredentials:
            return "Invalid email or password"
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        }
    }
}

private struct UserResponse: Decodable {
    let user: User
}
