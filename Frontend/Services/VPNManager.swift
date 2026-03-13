//
//  VPNManager.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension
import Combine

// MARK: VPN Manager
@MainActor
class VPNManager: ObservableObject {
    // MARK: Singleton
    static let shared = VPNManager()
    
    // MARK: Published Properties
    @Published var status: NEVPNStatus = .disconnected
    @Published var isConnected: Bool = false
    
    // MARK: Private Properties
    private let manager: NEVPNManager
    private var statusObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var vpnStatus: VPNStatus {
        VPNStatus(status)
    }
    
    // MARK: - Initialization
    private init() {
        self.manager = NEVPNManager.shared()
        setupStatusObserver()
    }

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup
    private func setupStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.status = self?.manager.connection.status ?? .disconnected
                self?.isConnected = self?.manager.connection.status == .connected
            }
        }
    }

    // MARK: - Public Methods
    func loadManager() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            manager.loadFromPreferences { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func connect(with config: VPNConfiguration, killSwitchEnabled: Bool = false) async throws {
        try await loadManager()

        // Configure the VPN
        let protocolConfiguration = try createProtocolConfiguration(config)

        manager.protocolConfiguration = protocolConfiguration
        manager.isEnabled = true

        // Configure Kill Switch (On-Demand rules)
        configureKillSwitch(enabled: killSwitchEnabled)

        // Save configuration
        try await saveManager()

        // Start the tunnel
        try await startTunnel()
    }

    func disconnect() async throws {
        manager.connection.stopVPNTunnel()

        // Wait for disconnect confirmation
        try await waitForStatus(.disconnected, timeout: 10)
    }

    func getConnectionInfo() async -> ConnectionInfo? {
        guard manager.connection.status == .connected else {
            return nil
        }

        // Get connection details from extension
        // In a real app, this would communicate with the extension
        return ConnectionInfo(
            serverAddress: manager.protocolConfiguration?.serverAddress ?? "Unknown",
            connectedAt: Date(),
            duration: 0
        )
    }

    // MARK: - Protocol Configuration
    private func createProtocolConfiguration(_ config: VPNConfiguration) throws -> NEVPNProtocol {
        let protocolConfig = NETunnelProviderProtocol()

        protocolConfig.serverAddress = config.server.ipAddress
        protocolConfig.providerBundleIdentifier = Bundle.main.bundleIdentifier! + ".PacketTunnel"

        // Pass the complete wg-quick config string
        // WireGuardKit's TunnelConfiguration(fromWgQuickConfig:) parses this format
        protocolConfig.providerConfiguration = [
            "wgQuickConfig": config.wireGuardConfig
        ]

        return protocolConfig
    }

    // MARK: - Private Methods
    private func saveManager() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            manager.saveToPreferences { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func startTunnel() async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try manager.connection.startVPNTunnel()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func waitForStatus(_ targetStatus: NEVPNStatus, timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if manager.connection.status == targetStatus {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        throw VPNError.timeout
    }

    // MARK: - Kill Switch
    /// Configures on-demand rules that act as a kill switch.
    /// When enabled, iOS will automatically reconnect the VPN if the tunnel drops,
    /// effectively blocking unprotected traffic.
    private func configureKillSwitch(enabled: Bool) {
        if enabled {
            // NEOnDemandRuleConnect: always reconnect if VPN drops
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any

            manager.onDemandRules = [connectRule]
            manager.isOnDemandEnabled = true
        } else {
            manager.onDemandRules = []
            manager.isOnDemandEnabled = false
        }
    }

    /// Toggle kill switch at runtime without a full reconnect.
    func setKillSwitch(enabled: Bool) async throws {
        try await loadManager()
        configureKillSwitch(enabled: enabled)
        try await saveManager()
    }
}

// MARK: - Supporting Types
struct ConnectionInfo {
    let serverAddress: String
    let connectedAt: Date
    var duration: TimeInterval

    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00:00"
    }
}

enum VPNError: LocalizedError {
    case notConfigured
    case failedToStart
    case timeout
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "VPN is not configured"
        case .failedToStart: return "Failed to start VPN connection"
        case .timeout: return "Connection timed out"
        case .invalidConfiguration: return "Invalid VPN configuration"
        }
    }
}

// MARK: - VPNManaging Implementation
extension VPNManager: VPNManaging {}
