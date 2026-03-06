//
//  ConfigManager.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import CryptoKit

// MARK: - Config Managing Protocol
protocol ConfigManaging {
    func loadConfiguration(for server: VPNServer) async throws -> VPNConfiguration
    func saveSelectedServerId(_ id: String)
    func loadSelectedServerId() -> String?
}

// MARK: - Config Manager
class ConfigManager: ConfigManaging {
    // MARK: - Singleton
    static let shared = ConfigManager()

    // MARK: - Private Properties
    private let userDefaults: UserDefaults
    private let keyManager: KeyManager
    private let apiClient: APIClientProtocol
    private let fileManager: FileManager
    private let configCache: ConfigCache

    private let serverConfigKey = "vpn.server.config"
    private let selectedServerKey = "vpn.selected.server"

    // MARK: - Initialization
    private init(
        userDefaults: UserDefaults = .standard,
        keyManager: KeyManager = .shared,
        apiClient: APIClientProtocol = APIClient.shared
    ) {
        self.userDefaults = userDefaults
        self.keyManager = keyManager
        self.apiClient = apiClient
        self.fileManager = FileManager.default
        self.configCache = ConfigCache()
    }

    // MARK: - Configuration Loading
    func loadConfiguration(for server: VPNServer) async throws -> VPNConfiguration {
        // Check cache first
        if let cached = configCache.get(forKey: server.id) {
            return cached
        }

        // Load or generate configuration
        let config: VPNConfiguration

        if let existingConfig = loadLocalConfig(for: server.id) {
            config = existingConfig
        } else {
            config = try await fetchConfiguration(for: server)
            saveLocalConfig(config, for: server.id)
        }

        // Cache the configuration
        configCache.set(config, forKey: server.id)

        return config
    }

    func fetchConfiguration(for server: VPNServer) async throws -> VPNConfiguration
{
        let deviceKeyPair = keyManager.getOrCreateDeviceKeyPair()
        let presharedKey = keyManager.generatePresharedKey()

        // Send device public key to server and get peer configuration
        let request = VPNConfigRequest(
            serverId: server.id,
            publicKey: deviceKeyPair.publicKey
        )

        let response: VPNConfigResponse = try await apiClient.request(
            endpoint: "/vpn/config",
            method: .post,
            body: request
        )

        return response.configuration
    }

    // MARK: - Local Storage
    private func loadLocalConfig(for serverId: String) -> VPNConfiguration? {
        guard let data = userDefaults.data(forKey: "\(serverConfigKey).\(serverId)") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(VPNConfiguration.self, from: data)
        } catch {
            return nil
        }
    }

    private func saveLocalConfig(_ config: VPNConfiguration, for serverId: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)
            userDefaults.set(data, forKey: "\(serverConfigKey).\(serverId)")
        } catch {
            Logger.shared.log("Failed to save config: \(error)", level: .error)
        }
    }

    func deleteLocalConfig(for serverId: String) {
        userDefaults.removeObject(forKey: "\(serverConfigKey).\(serverId)")
        configCache.remove(forKey: serverId)
    }

    // MARK: - Server Selection
    func saveSelectedServerId(_ id: String) {
        userDefaults.set(id, forKey: selectedServerKey)
    }

    func loadSelectedServerId() -> String? {
        userDefaults.string(forKey: selectedServerKey)
    }

    // MARK: - Configuration Validation
    func validateConfiguration(_ config: VPNConfiguration) -> ValidationResult {
        var errors: [String] = []

        // Validate private key
        if !keyManager.isValidWireGuardKey(config.privateKey) {
            errors.append("Invalid private key")
        }

        // Validate server public key
        if !keyManager.isValidWireGuardKey(config.server.publicKey) {
            errors.append("Invalid server public key")
        }

        // Validate allowed IPs
        if config.allowedIPs.isEmpty {
            errors.append("Allowed IPs cannot be empty")
        }

        // Validate DNS servers
        if config.dnsServers.isEmpty {
            errors.append("DNS servers cannot be empty")
        }

        // Validate MTU
        if config.mtu < 576 || config.mtu > 1500 {
            errors.append("MTU must be between 576 and 1500")
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Configuration Export/Import
    func exportConfiguration(_ config: VPNConfiguration) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            return String(data: data, encoding: .utf8)
        } catch {
            Logger.shared.log("Failed to export config: \(error)", level: .error)
            return nil
        }
    }

    func importConfiguration(from string: String) -> VPNConfiguration? {
        guard let data = string.data(using: .utf8) else { return nil }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(VPNConfiguration.self, from: data)
        } catch {
            Logger.shared.log("Failed to import config: \(error)", level: .error)
            return nil
        }
    }

    // MARK: - WireGuard Config File Generation
    func generateWireGuardConfigFile(_ config: VPNConfiguration) -> String {
        var configString = """
        [Interface]
        PrivateKey = \(config.privateKey)
        Address = 10.0.0.2/32, fd00::2/128
        DNS = \(config.dnsServers.joined(separator: ", "))
        MTU = \(config.mtu)
        """

        if config.keepAliveInterval > 0 {
            configString += "\nPersistentKeepalive = \(config.keepAliveInterval)"
        }

        configString += """

        [Peer]
        PublicKey = \(config.server.publicKey)
        Endpoint = \(config.server.endpoint)
        AllowedIPs = \(config.allowedIPs.joined(separator: ", "))
        """

        if let psk = config.presharedKey {
            configString += "\nPresharedKey = \(psk)"
        }

        return configString
    }

    // MARK: - Configuration Cache Management
    func clearCache() {
        configCache.removeAll()
    }

    func clearAllConfigurations() {
        clearCache()

        // Remove all stored configs
        if let bundleId = Bundle.main.bundleIdentifier {
            userDefaults.dictionaryRepresentation().keys
                .filter { $0.hasPrefix(serverConfigKey) }
                .forEach { userDefaults.removeObject(forKey: $0) }
        }
    }
}

// MARK: Custom Config cache
class ConfigCache {
    private var storage: [String: VPNConfiguration] = [:]
    private let lock = NSLock()
    
    func set(_ config: VPNConfiguration, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = config
    }
    
    func get(forKey key: String) -> VPNConfiguration? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
    
    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}

// MARK: - Supporting Types
struct VPNConfigRequest: Codable {
    let serverId: String
    let publicKey: String
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

// MARK: - ConfigManaging Implementation
//extension ConfigManager: ConfigManaging {
//    func loadConfiguration(for server: VPNServer) async throws -> VPNConfiguration {
//        try await loadConfiguration(for: server)
//    }
//
//    func saveSelectedServerId(_ id: String) {
//        saveSelectedServerId(id)
//    }
//
//    func loadSelectedServerId() -> String? {
//        loadSelectedServerId()
//    }
//}

