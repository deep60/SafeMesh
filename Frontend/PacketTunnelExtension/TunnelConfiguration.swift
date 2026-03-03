//
//  TunnelConfiguration.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - Tunnel Configuration
struct TunnelConfiguration: Codable {
    // MARK: - Properties
    let serverAddress: String
    let serverPort: Int
    let serverPublicKey: String
    let privateKey: String
    let presharedKey: String?
    let allowedIPs: [String]
    let dnsServers: [String]
    let mtu: Int
    let keepAlive: Int

    // MARK: - Computed Properties
    var endpoint: String {
        "\(serverAddress):\(serverPort)"
    }

    var formattedDNS: String {
        dnsServers.joined(separator: ", ")
    }

    var formattedAllowedIPs: String {
        allowedIPs.joined(separator: ", ")
    }

    // MARK: - Validation
    func validate() throws {
        guard !serverAddress.isEmpty else {
            throw ConfigError.invalidServerAddress
        }

        guard serverPort > 0 && serverPort <= 65535 else {
            throw ConfigError.invalidPort
        }

        guard !serverPublicKey.isEmpty else {
            throw ConfigError.invalidPublicKey
        }

        guard !privateKey.isEmpty else {
            throw ConfigError.invalidPrivateKey
        }

        guard !allowedIPs.isEmpty else {
            throw ConfigError.invalidAllowedIPs
        }

        guard !dnsServers.isEmpty else {
            throw ConfigError.invalidDNSServers
        }

        guard mtu >= 576 && mtu <= 1500 else {
            throw ConfigError.invalidMTU
        }
    }

    // MARK: - Export
    func toWireGuardConfig() -> String {
        var config = """
        [Interface]
        PrivateKey = \(privateKey)
        Address = 10.0.0.2/32, fd00::2/128
        DNS = \(formattedDNS)
        MTU = \(mtu)
        """

        if keepAlive > 0 {
            config += "\nPersistentKeepalive = \(keepAlive)"
        }

        config += """

        [Peer]
        PublicKey = \(serverPublicKey)
        Endpoint = \(endpoint)
        AllowedIPs = \(formattedAllowedIPs)
        """

        if let psk = presharedKey {
            config += "\nPresharedKey = \(psk)"
        }

        return config
    }

    // MARK: - Import
    static func fromWireGuardConfig(_ configString: String) throws -> TunnelConfiguration {
        let lines = configString.components(separatedBy: "\n")

        var serverAddress = ""
        var serverPort = 51820
        var serverPublicKey = ""
        var privateKey = ""
        var presharedKey: String? = nil
        var allowedIPs: [String] = []
        var dnsServers: [String] = []
        var mtu = 1280
        var keepAlive = 25

        var currentSection: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast())
                continue
            }

            guard currentSection != nil else { continue }
            guard !trimmed.isEmpty else { continue }
            guard !trimmed.hasPrefix("#") else { continue }

            let components = trimmed.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            guard components.count == 2 else { continue }

            let key = components[0].lowercased()
            let value = components[1]

            switch (currentSection!, key) {
            case ("Interface", "privatekey"):
                privateKey = value
            case ("Interface", "address"):
                // Parse address
                break
            case ("Interface", "dns"):
                dnsServers = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            case ("Interface", "mtu"):
                mtu = Int(value) ?? 1280
            case ("Peer", "publickey"):
                serverPublicKey = value
            case ("Peer", "endpoint"):
                let endpointComponents = value.components(separatedBy: ":")
                if endpointComponents.count == 2 {
                    serverAddress = endpointComponents[0]
                    serverPort = Int(endpointComponents[1]) ?? 51820
                }
            case ("Peer", "allowedips"):
                allowedIPs = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            case ("Peer", "presharedkey"):
                presharedKey = value
            case ("Interface", "persistentkeepalive"):
                keepAlive = Int(value) ?? 25
            default:
                break
            }
        }

        let config = TunnelConfiguration(
            serverAddress: serverAddress,
            serverPort: serverPort,
            serverPublicKey: serverPublicKey,
            privateKey: privateKey,
            presharedKey: presharedKey,
            allowedIPs: allowedIPs,
            dnsServers: dnsServers,
            mtu: mtu,
            keepAlive: keepAlive
        )

        try config.validate()
        return config
    }
}

// MARK: - Config Errors
enum ConfigError: LocalizedError {
    case invalidServerAddress
    case invalidPort
    case invalidPublicKey
    case invalidPrivateKey
    case invalidAllowedIPs
    case invalidDNSServers
    case invalidMTU
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidServerAddress: return "Invalid server address"
        case .invalidPort: return "Invalid port number"
        case .invalidPublicKey: return "Invalid public key"
        case .invalidPrivateKey: return "Invalid private key"
        case .invalidAllowedIPs: return "Invalid allowed IPs"
        case .invalidDNSServers: return "Invalid DNS servers"
        case .invalidMTU: return "Invalid MTU value"
        case .parseError: return "Failed to parse configuration"
        }
    }
}

// MARK: - Configuration Builder
class TunnelConfigurationBuilder {
    private var serverAddress: String = ""
    private var serverPort: Int = 51820
    private var serverPublicKey: String = ""
    private var privateKey: String = ""
    private var presharedKey: String? = nil
    private var allowedIPs: [String] = ["0.0.0.0/0", "::/0"]
    private var dnsServers: [String] = ["1.1.1.1", "1.0.0.1"]
    private var mtu: Int = 1280
    private var keepAlive: Int = 25

    func setServerAddress(_ address: String) -> Self {
        self.serverAddress = address
        return self
    }

    func setServerPort(_ port: Int) -> Self {
        self.serverPort = port
        return self
    }

    func setServerPublicKey(_ key: String) -> Self {
        self.serverPublicKey = key
        return self
    }

    func setPrivateKey(_ key: String) -> Self {
        self.privateKey = key
        return self
    }

    func setPresharedKey(_ key: String?) -> Self {
        self.presharedKey = key
        return self
    }

    func setAllowedIPs(_ ips: [String]) -> Self {
        self.allowedIPs = ips
        return self
    }

    func setDNSServers(_ servers: [String]) -> Self {
        self.dnsServers = servers
        return self
    }

    func setMTU(_ mtu: Int) -> Self {
        self.mtu = mtu
        return self
    }

    func setKeepAlive(_ keepAlive: Int) -> Self {
        self.keepAlive = keepAlive
        return self
    }

    func build() throws -> TunnelConfiguration {
        let config = TunnelConfiguration(
            serverAddress: serverAddress,
            serverPort: serverPort,
            serverPublicKey: serverPublicKey,
            privateKey: privateKey,
            presharedKey: presharedKey,
            allowedIPs: allowedIPs,
            dnsServers: dnsServers,
            mtu: mtu,
            keepAlive: keepAlive
        )

        try config.validate()
        return config
    }
}

