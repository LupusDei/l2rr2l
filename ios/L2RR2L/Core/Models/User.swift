import Foundation

// MARK: - User

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case createdAt = "created_at"
    }
}

// MARK: - Auth

struct AuthResponse: Codable, Equatable {
    let token: String
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}
