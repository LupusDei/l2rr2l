import Foundation
@testable import L2RR2L

/// A mock keychain service for testing without touching actual keychain
final class MockKeychainService {
    // MARK: - Storage

    private var storage: [String: Data] = [:]

    // MARK: - Configuration

    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false
    var shouldThrowOnDelete = false

    // MARK: - Initialization

    init() {}

    // MARK: - Methods

    func save(_ data: Data, for key: String) throws {
        if shouldThrowOnSave {
            throw KeychainError.saveFailed
        }
        storage[key] = data
    }

    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, for: key)
    }

    func load(for key: String) throws -> Data {
        if shouldThrowOnLoad {
            throw KeychainError.loadFailed
        }
        guard let data = storage[key] else {
            throw KeychainError.notFound
        }
        return data
    }

    func loadString(for key: String) throws -> String {
        let data = try load(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        return string
    }

    func delete(for key: String) throws {
        if shouldThrowOnDelete {
            throw KeychainError.deleteFailed
        }
        storage.removeValue(forKey: key)
    }

    // MARK: - Test Helpers

    func clear() {
        storage.removeAll()
    }

    func hasKey(_ key: String) -> Bool {
        storage[key] != nil
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error, LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case notFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save to keychain"
        case .loadFailed:
            return "Failed to load from keychain"
        case .deleteFailed:
            return "Failed to delete from keychain"
        case .notFound:
            return "Key not found in keychain"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
