//
//  PacketTunnelProvider.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    // MARK: - Properties
    private var tunnel: WireGuardTunnel?
    private var packetHandler: PacketHandler?
    private let logger = ExtensionLogger.shared
    private var config: TunnelConfiguration?
    private var startTime: Date?
    private var isRunning = false

    // MARK: - Network Statistics
    private var bytesSent: UInt64 = 0
    private var bytesReceived: UInt64 = 0

    // MARK: - Lifecycle
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logger.log("Starting tunnel with options: \(options ?? [:])", level: .info)

        do {
            // Load configuration
            guard let config = try loadConfiguration() else {
                let error = TunnelError.invalidConfiguration
                logger.log("Failed to load configuration", level: .error)
                completionHandler(error)
                return
            }

            self.config = config
            self.startTime = Date()

            // Initialize packet handler
            packetHandler = PacketHandler(packetFlow: packetFlow)

            // Initialize WireGuard tunnel
            tunnel = WireGuardTunnel(configuration: config)
            try tunnel?.start()

            // Setup routing
            try setupRouting(for: config)

            // Start packet handling
            packetHandler?.start(tunnel: tunnel!)

            isRunning = true
            logger.log("Tunnel started successfully", level: .info)

            completionHandler(nil)

        } catch {
            logger.log("Failed to start tunnel: \(error)", level: .error)
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("Stopping tunnel with reason: \(reason.rawValue)", level: .info)

        isRunning = false

        // Stop packet handling
        packetHandler?.stop()
        packetHandler = nil

        // Stop WireGuard tunnel
        tunnel?.stop()
        tunnel = nil

        // Clean up routing
        cleanupRouting()

        // Save session statistics
        saveSessionStats()

        logger.log("Tunnel stopped", level: .info)

        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logger.log("Received app message: \(messageData.count) bytes", level: .debug)

        guard let message = try? IPCMessage.decode(from: messageData) else {
            completionHandler?(nil)
            return
        }

        // Handle message
        let response = handleIPCMessage(message)
        completionHandler?(response?.encode())
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        logger.log("Extension going to sleep", level: .info)

        // Save state before sleeping
        saveState()

        completionHandler()
    }

    override func wake() {
        logger.log("Extension woke up", level: .info)

        // Restore state if needed
        restoreState()
    }
}

// MARK: - Configuration Loading
extension PacketTunnelProvider {
    private func loadConfiguration() throws -> TunnelConfiguration? {
        guard let providerConfig = protocolConfiguration as? NETunnelProviderProtocol,
              let providerDict = providerConfig.providerConfiguration else {
            throw TunnelError.invalidConfiguration
        }

        let config = TunnelConfiguration(
            serverAddress: providerDict["serverAddress"] as? String ?? "",
            serverPort: providerDict["serverPort"] as? Int ?? 51820,
            serverPublicKey: providerDict["serverPublicKey"] as? String ?? "",
            privateKey: providerDict["privateKey"] as? String ?? "",
            presharedKey: providerDict["presharedKey"] as? String,
            interfaceAddressV4: providerDict["interfaceAddressV4"] as? String ?? "10.0.0.2",
            interfaceAddressV6: providerDict["interfaceAddressV6"] as? String ?? "fd00::2",
            allowedIPs: (providerDict["allowedIPs"] as? String ?? "").components(separatedBy: ","),
            dnsServers: (providerDict["dnsServers"] as? String ?? "").components(separatedBy: ","),
            mtu: providerDict["mtu"] as? Int ?? 1280,
            keepAlive: providerDict["keepAlive"] as? Int ?? 25
        )

        // Validate configuration
        guard !config.serverAddress.isEmpty,
              !config.serverPublicKey.isEmpty,
              !config.privateKey.isEmpty else {
            throw TunnelError.invalidConfiguration
        }

        return config
    }
}

// MARK: - Routing Setup
extension PacketTunnelProvider {
    private func setupRouting(for config: TunnelConfiguration) throws {
        // Create a new network settings object
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.serverAddress)

        // Set MTU
        networkSettings.mtu = NSNumber(value: config.mtu)

        // Configure IPv4 — use the interface IP assigned by the backend
        let ipv4Address = config.interfaceAddressV4.components(separatedBy: "/").first ?? config.interfaceAddressV4
        let ipv4Settings = NEIPv4Settings(
            addresses: [ipv4Address],
            subnetMasks: ["255.255.255.255"]
        )
        ipv4Settings.includedRoutes = config.allowedIPs.map { NEIPv4Route(destinationAddress: $0, subnetMask: "0.0.0.0") }
        networkSettings.ipv4Settings = ipv4Settings

        // Configure IPv6 — use the interface IP assigned by the backend
        let ipv6Address = config.interfaceAddressV6.components(separatedBy: "/").first ?? config.interfaceAddressV6
        let ipv6Settings = NEIPv6Settings(
            addresses: [ipv6Address],
            networkPrefixLengths: [128]
        )
        ipv6Settings.includedRoutes = config.allowedIPs.map { NEIPv6Route(destinationAddress: $0, networkPrefixLength: 0) }
        networkSettings.ipv6Settings = ipv6Settings

        // Configure DNS
        let dnsSettings = NEDNSSettings(servers: config.dnsServers)
        networkSettings.dnsSettings = dnsSettings

        // Proxy settings (none needed)
        networkSettings.proxySettings = nil

        // Apply settings
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                self.logger.log("Failed to set network settings: \(error)", level: .error)
            } else {
                self.logger.log("Network settings applied successfully", level: .info)
            }
        }
    }

    private func cleanupRouting() {
        // Network settings will be automatically cleaned up by the system
    }
}

// MARK: - IPC Message Handling
extension PacketTunnelProvider {
    private func handleIPCMessage(_ message: IPCMessage) -> IPCMessage? {
        var responsePayload: [String: Any] = [:]

        switch message.type {
        case .status:
            responsePayload["isConnected"] = isRunning
            responsePayload["connectedAt"] = startTime?.timeIntervalSince1970 ?? 0
            responsePayload["serverAddress"] = config?.serverAddress ?? ""

        case .stats:
            responsePayload["bytesUploaded"] = bytesSent
            responsePayload["bytesDownloaded"] = bytesReceived
            responsePayload["duration"] = startTime.map {
                Date().timeIntervalSince($0) } ?? 0

        case .ping:
            // Echo back with timestamp
            responsePayload["timestamp"] = message.payload["timestamp"] as? Double ?? Date().timeIntervalSince1970

        case .pong:
            // Pong received - handled elsewhere
            break
        
        case .config:
            break

        case .error:
            logger.log("Received error from app: \(message.payload)", level: .error)
        }

        return IPCMessage(type: message.type, payload: responsePayload)
    }
}

// MARK: - State Management
extension PacketTunnelProvider {
    private func saveState() {
        // Save current state for potential restoration
        let state: [String: Any] = [
            "startTime": startTime?.timeIntervalSince1970 ?? 0,
            "bytesSent": bytesSent,
            "bytesReceived": bytesReceived,
            "serverAddress": config?.serverAddress ?? ""
        ]

        UserDefaults.standard.set(state, forKey: "savedState")
    }

    private func restoreState() {
        guard let state = UserDefaults.standard.object(forKey: "savedState") as?
[String: Any] else {
            return
        }

        if let startTimeValue = state["startTime"] as? TimeInterval {
            startTime = Date(timeIntervalSince1970: startTimeValue)
        }

        bytesSent = state["bytesSent"] as? UInt64 ?? 0
        bytesReceived = state["bytesReceived"] as? UInt64 ?? 0
    }

    private func saveSessionStats() {
        // Upload session statistics to backend
        // This would be done in a real app
        logger.log("Session stats - Sent: \(bytesSent), Received: \(bytesReceived)",
 level: .info)
    }
}

// MARK: - Logger
class ExtensionLogger {
    static let shared = ExtensionLogger()

    private let logFile: URL?
    private let queue = DispatchQueue(label: "com.safemesh.extension.logger")

    init() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.safemesh.app"
        ) else {
            self.logFile = nil
            return
        }

        let logsDirectory = containerURL.appendingPathComponent("Logs", isDirectory:
 true)
        try? FileManager.default.createDirectory(at: logsDirectory,
withIntermediateDirectories: true)

        self.logFile = logsDirectory.appendingPathComponent("extension.log")
    }

    func log(_ message: String, level: LogLevel) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [\(level)] \(message)\n"

        queue.async { [weak self] in
            self?.writeToLog(logMessage)
        }
    }

    private func writeToLog(_ message: String) {
        guard let logFile = logFile else { return }

        if let data = message.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        }
    }

    enum LogLevel: String {
        case debug, info, warning, error
    }
}

// MARK: - Supporting Types
enum TunnelError: LocalizedError {
    case invalidConfiguration
    case tunnelFailed
    case routingFailed

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Invalid tunnel configuration"
        case .tunnelFailed: return "Failed to establish tunnel"
        case .routingFailed: return "Failed to configure routing"
        }
    }
}

// MARK: - IPC Message (Custom Codable implementation)
struct IPCMessage {
    let id: UUID
    let type: IPCMessageType
    let timestamp: TimeInterval
    let payload: [String: Any]

    init(type: IPCMessageType, payload: [String: Any]) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date().timeIntervalSince1970
        self.payload = payload
    }

    private init(id: UUID, type: IPCMessageType, timestamp: TimeInterval, payload: [String: Any]) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
    }

    static func decode(from data: Data) throws -> IPCMessage {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IPCError.decodingFailed
        }

        guard let idString = json["id"] as? String,
              let id = UUID(uuidString: idString),
              let typeRaw = json["type"] as? String,
              let type = IPCMessageType(rawValue: typeRaw),
              let timestamp = json["timestamp"] as? TimeInterval,
              let payload = json["payload"] as? [String: Any] else {

            throw IPCError.decodingFailed
        }

        return IPCMessage(id: id, type: type, timestamp: timestamp, payload: payload)
    }

    func encode() -> Data {
        let dict: [String: Any] = [
            "id": id.uuidString,
            "type": type.rawValue,
            "timestamp": timestamp,
            "payload": payload
        ]

        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }
}

enum IPCMessageType: String {
    case status, config, stats, error, ping, pong
}

enum IPCError: LocalizedError {
    case decodingFailed
}

