import Foundation

/// A mock keychain service for testing without touching actual keychain.
/// This mock is standalone and doesn't depend on the main module's types.
actor MockKeychainService {
    // MARK: - Types

    enum MockKeychainKey: String {
        case authToken
        case refreshToken
        case userId
    }

    enum MockKeychainError: Error {
        case saveFailed
        case loadFailed
        case deleteFailed
        case notFound
        case invalidData
    }

    // MARK: - Storage

    private var storage: [String: Data] = [:]

    // MARK: - Configuration

    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false
    var shouldThrowOnDelete = false

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    func save(_ data: Data, for key: MockKeychainKey, requireBiometric: Bool = false) throws {
        if shouldThrowOnSave {
            throw MockKeychainError.saveFailed
        }
        storage[key.rawValue] = data
    }

    func save(_ string: String, for key: MockKeychainKey, requireBiometric: Bool = false) throws {
        guard let data = string.data(using: .utf8) else {
            throw MockKeychainError.invalidData
        }
        try save(data, for: key, requireBiometric: requireBiometric)
    }

    func load(for key: MockKeychainKey) throws -> Data {
        if shouldThrowOnLoad {
            throw MockKeychainError.loadFailed
        }
        guard let data = storage[key.rawValue] else {
            throw MockKeychainError.notFound
        }
        return data
    }

    func loadString(for key: MockKeychainKey) throws -> String {
        let data = try load(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw MockKeychainError.invalidData
        }
        return string
    }

    func delete(for key: MockKeychainKey) throws {
        if shouldThrowOnDelete {
            throw MockKeychainError.deleteFailed
        }
        storage.removeValue(forKey: key.rawValue)
    }

    func deleteAll() throws {
        if shouldThrowOnDelete {
            throw MockKeychainError.deleteFailed
        }
        storage.removeAll()
    }

    // MARK: - Biometric Support

    nonisolated func isBiometricAvailable() -> Bool {
        return false
    }

    func loadWithBiometric(for key: MockKeychainKey, reason: String) async throws -> Data {
        return try load(for: key)
    }

    func loadStringWithBiometric(for key: MockKeychainKey, reason: String) async throws -> String {
        return try loadString(for: key)
    }

    // MARK: - Test Helpers

    func clear() {
        storage.removeAll()
    }

    func hasKey(_ key: MockKeychainKey) -> Bool {
        storage[key.rawValue] != nil
    }
}
