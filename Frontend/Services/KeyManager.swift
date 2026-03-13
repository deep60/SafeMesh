//
//  KeyManager.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//


import Foundation
import CryptoKit
import Security
import UIKit

// MARK: - Key Manager
class KeyManager {
    // MARK: - Singleton
    static let shared = KeyManager()

    // MARK: - Private Properties
    private let keychain: KeychainAccessProtocol
    private let keyTag = "com.safemesh.vpn.keys"

    // MARK: - Initialization
    private init(keychain: KeychainAccessProtocol = KeychainHelper()) {
        self.keychain = keychain
    }

    // MARK: - WireGuard Key Generation (Curve25519)
    func generateWireGuardKeyPair() -> (privateKey: String, publicKey: String) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey

        return (
            privateKey: privateKey.rawRepresentation.base64EncodedString(),
            publicKey: publicKey.rawRepresentation.base64EncodedString()
        )
    }

    func generateWireGuardPrivateKey() -> String {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return privateKey.rawRepresentation.base64EncodedString()
    }

    func generatePublicKey(from privateKey: String) -> String? {
        guard let privateKeyData = Data(base64Encoded: privateKey) else {
            return nil
        }

        do {
            let privateKey = try Curve25519.KeyAgreement.PrivateKey(
                rawRepresentation: privateKeyData
            )
            return privateKey.publicKey.rawRepresentation.base64EncodedString()
        } catch {
            return nil
        }
    }

    func generatePresharedKey() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    // MARK: - Key Storage
    func savePrivateKey(_ key: String, forServer serverId: String) throws {
        let identifier = "\(keyTag).private.\(serverId)"
        try keychain.save(key: identifier, value: key)
    }

    func loadPrivateKey(forServer serverId: String) -> String? {
        let identifier = "\(keyTag).private.\(serverId)"
        return keychain.load(key: identifier)
    }

    func deletePrivateKey(forServer serverId: String) throws {
        let identifier = "\(keyTag).private.\(serverId)"
        try keychain.delete(key: identifier)
    }

    func savePublicKey(_ key: String, forServer serverId: String) {
        // Public keys can be stored in UserDefaults since they're not sensitive
        UserDefaults.standard.set(key, forKey: "\(keyTag).public.\(serverId)")
    }

    func loadPublicKey(forServer serverId: String) -> String? {
        UserDefaults.standard.string(forKey: "\(keyTag).public.\(serverId)")
    }

    // MARK: - Device Key Management
    func getOrCreateDeviceKeyPair() -> (privateKey: String, publicKey: String) {
        let deviceId = getDeviceIdentifier()

        // Try to load existing keys
        if let privateKey = loadPrivateKey(forServer: deviceId),
           let publicKey = loadPublicKey(forServer: deviceId) {
            return (privateKey, publicKey)
        }

        // Generate new keys
        let keyPair = generateWireGuardKeyPair()

        // Save keys
        try? savePrivateKey(keyPair.privateKey, forServer: deviceId)
        savePublicKey(keyPair.publicKey, forServer: deviceId)

        return keyPair
    }

    func getDevicePublicKey() -> String? {
        let deviceId = getDeviceIdentifier()
        return loadPublicKey(forServer: deviceId)
    }

    // MARK: - Key Validation
    func isValidWireGuardKey(_ key: String) -> Bool {
        guard let data = Data(base64Encoded: key) else { return false }
        return data.count == 32 // WireGuard keys are 32 bytes
    }

    // MARK: - Device Identification
    private func getDeviceIdentifier() -> String {
        // Use vendor ID as a stable device identifier
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    // MARK: - Key Rotation
    func rotateKeys(forServer serverId: String) throws -> (privateKey: String,
publicKey: String) {
        // Delete old keys
        try deletePrivateKey(forServer: serverId)
        UserDefaults.standard.removeObject(forKey: "\(keyTag).public.\(serverId)")

        // Generate new keys
        let keyPair = generateWireGuardKeyPair()

        // Save new keys
        try savePrivateKey(keyPair.privateKey, forServer: serverId)
        savePublicKey(keyPair.publicKey, forServer: serverId)

        return keyPair
    }
}

// MARK: - Keychain Protocol
protocol KeychainAccessProtocol {
    func save(key: String, value: String) throws
    func load(key: String) -> String?
    func delete(key: String) throws
}

// MARK: - Keychain Helper
class KeychainHelper: KeychainAccessProtocol {
    func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String:
kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status: status)
        }
    }

    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status: status)
        }
    }
}

// MARK: - Crypto Utilities
extension KeyManager {
    func hashData(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
}

