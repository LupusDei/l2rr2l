import Foundation
import Security
import LocalAuthentication

public enum KeychainError: Error, LocalizedError {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
    case biometricNotAvailable
    case biometricFailed

    public var errorDescription: String? {
        switch self {
        case .duplicateEntry:
            return "Item already exists in keychain"
        case .unknown(let status):
            return "Keychain error: \(status)"
        case .itemNotFound:
            return "Item not found in keychain"
        case .invalidData:
            return "Invalid data format"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricFailed:
            return "Biometric authentication failed"
        }
    }
}

public enum KeychainKey: String, CaseIterable {
    case authToken
    case refreshToken
    case userId
}

actor KeychainService {
    static let shared = KeychainService()

    private let service = "com.l2rr2l.app"

    private init() {}

    // MARK: - Public Methods

    func save(_ data: Data, for key: KeychainKey, requireBiometric: Bool = false) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        if requireBiometric {
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )
            if let access = access {
                query[kSecAttrAccessControl as String] = access
                query.removeValue(forKey: kSecAttrAccessible as String)
            }
        }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    func save(_ string: String, for key: KeychainKey, requireBiometric: Bool = false) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key, requireBiometric: requireBiometric)
    }

    func load(for key: KeychainKey) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    func loadString(for key: KeychainKey) throws -> String {
        let data = try load(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    func deleteAll() throws {
        for key in KeychainKey.allCases {
            try delete(for: key)
        }
    }

    // MARK: - Biometric Support

    nonisolated func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func loadWithBiometric(for key: KeychainKey, reason: String) async throws -> Data {
        let context = LAContext()
        context.localizedReason = reason

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        return try await withCheckedThrowingContinuation { continuation in
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecSuccess, let data = result as? Data {
                continuation.resume(returning: data)
            } else if status == errSecItemNotFound {
                continuation.resume(throwing: KeychainError.itemNotFound)
            } else if status == errSecUserCanceled || status == errSecAuthFailed {
                continuation.resume(throwing: KeychainError.biometricFailed)
            } else {
                continuation.resume(throwing: KeychainError.unknown(status))
            }
        }
    }

    func loadStringWithBiometric(for key: KeychainKey, reason: String) async throws -> String {
        let data = try await loadWithBiometric(for: key, reason: reason)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
}
