//
//  SecureStorage.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import Security

// MARK: - Secure Storage
final class SecureStorage {
    // MARK: - Singleton
    static let shared = SecureStorage()

    // MARK: - Private Properties
    private let keychain: KeychainService
    private let appGroup: String

    // MARK: - Initialization
    private init() {
        self.keychain = KeychainService()

        guard let group = Bundle.main.object(forInfoDictionaryKey:
"AppGroupIdentifier") as? String else {
            self.appGroup = "group.com.safemesh.app"
            return
        }

        self.appGroup = group
    }

    // MARK: - Public Methods - String Storage
    func save(key: SecureKey, value: String) {
        try? keychain.save(key: key.rawValue, value: value)
    }

    func load(key: SecureKey) -> String? {
        return keychain.load(key: key.rawValue)
    }

    func delete(key: SecureKey) {
        try? keychain.delete(key: key.rawValue)
    }

    // MARK: - Public Methods - Data Storage
    func saveData(key: String, value: Data) {
        try? keychain.saveData(key: key, value: value)
    }

    func loadData(key: String) -> Data? {
        return keychain.loadData(key: key)
    }

    func deleteData(key: String) {
        try? keychain.delete(key: key)
    }

    // MARK: - Public Methods - UserDefaults (Non-sensitive)
    func saveNonSensitive(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func loadNonSensitive(key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    func deleteNonSensitive(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Public Methods - Batch Operations
    func clearAll() {
        // Clear all keys in the keychain with our prefix
        keychain.clearAll()

        // Clear UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
    }

    // MARK: - Public Methods - Backup/Restore
    func exportSecureData() -> [String: String]? {
        // Only export non-sensitive identifiers, not actual values
        var identifiers: [String] = []

        let keys: [SecureKey] = [.accessToken, .refreshToken, .userId]
        
        for key in keys {
            if load(key: key) != nil {
                identifiers.append(key.rawValue)
            }
        }

        return ["keys": identifiers.joined(separator: ",")]
    }

    // MARK: - Migration
    func migrateFromOldStorage() {
        // Migrate data from old storage if needed
        // This is a placeholder for any migration logic
    }
}

// MARK: - Keychain Service
class KeychainService {
    private let accessGroup: String?

    init() {
        #if DEBUG
        // For development, don't use access groups
        self.accessGroup = nil
        #else
        // For production, use app group for sharing with extension
        self.accessGroup = Bundle.main.object(forInfoDictionaryKey:
"AppGroupIdentifier") as? String
        #endif
    }

    // MARK: - String Operations
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        try saveData(key: key, value: data)
    }

    func load(key: String) -> String? {
        guard let data = loadData(key: key) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // MARK: - Data Operations
    func saveData(key: String, value: Data) throws {
        let query = createQuery(for: key)

        // Try to update first
        let status = SecItemUpdate(query as CFDictionary, [
            kSecValueData as String: value,
            kSecAttrAccessible as String:
kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            var createQuery = createQuery(for: key)
            createQuery[kSecValueData as String] = value
            createQuery[kSecAttrAccessible as String] =
kSecAttrAccessibleWhenUnlockedThisDeviceOnly

            let createStatus = SecItemAdd(createQuery as CFDictionary, nil)

            guard createStatus == errSecSuccess else {
                throw KeychainError.unableToStore(status: createStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unableToStore(status: status)
        }
    }

    func loadData(key: String) -> Data? {
        var query = createQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return data
    }

    func delete(key: String) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status: status)
        }
    }

    // MARK: - Query Helper
    private func createQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    // MARK: - Batch Operations
    func clearAll() {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case invalidData
    case unableToStore(status: OSStatus)
    case unableToDelete(status: OSStatus)
    case itemNotFound
    case duplicateItem

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .unableToStore(let status):
            return "Unable to store in keychain: \(status)"
        case .unableToDelete(let status):
            return "Unable to delete from keychain: \(status)"
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        }
    }
}

//// MARK: - Secure Storage Protocol Implementation
//extension SecureStorage: SecureStorageProtocol {
//    func save(key: SecureKey, value: String) {
//        save(key: key, value: value)
//    }
//
//    func load(key: SecureKey) -> String? {
//        load(key: key)
//    }
//
//    func delete(key: SecureKey) {
//        delete(key: key)
//    }
//}

// MARK: - Biometric Authentication
class BiometricAuthenticator {
    enum BiometricType {
        case none
        case touchID
        case faceID
    }

    static var available: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            @unknown default:
                return .none
            }
        }

        return .touchID
    }

    static func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "BiometricAuth", code: -1))
                }
            }
        }
    }
}

import LocalAuthentication

