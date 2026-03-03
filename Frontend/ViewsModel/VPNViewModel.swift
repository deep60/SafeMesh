//
//  VPNViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import NetworkExtension
import Combine

@MainActor
class VPNViewModel: ObservableObject {
    // MARK: Published Properties
    @Published var status: VPNStatus = .disconnected
    @Published var isConnecting: Bool = false
    @Published var isDisconnecting: Bool = false
    @Published var currentServer: VPNServer?
    @Published var connectedDuration: String = "00:00:00"
    @Published var downloadBytes: Int64 = 0
    @Published var uploadBytes: Int64 = 0
    @Published var currentIP: String?
    
    // MARK: - Private Properties
    private let vpnManager: VPNManaging
    private let configManager: ConfigManaging
    private let statusObserver: StatusObserving
    private var cancellables = Set<AnyCancellable>()
    private var connectionTimer: Timer?
    private var startTime: Date?

    // MARK: - Initialization
    init(
        vpnManager: VPNManaging = VPNManager.shared,
        configManager: ConfigManaging = ConfigManager.shared,
        statusObserver: StatusObserving = StatusObserver.shared
    ) {
        self.vpnManager = vpnManager
        self.configManager = configManager
        self.statusObserver = statusObserver

        setupObservers()
        loadLastServer()
    }

    deinit {
        connectionTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observe VPN status changes
        statusObserver.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.handleStatusChange(newStatus)
            }
            .store(in: &cancellables)
    }

    private func handleStatusChange(_ newStatus: VPNStatus) {
        withAnimation {
            self.status = newStatus

            switch newStatus {
            case .connecting:
                isConnecting = true
                isDisconnecting = false
            case .connected:
                isConnecting = false
                isDisconnecting = false
                startTime = Date()
                startConnectionTimer()
            case .disconnecting:
                isConnecting = false
                isDisconnecting = true
            case .disconnected, .invalid:
                isConnecting = false
                isDisconnecting = false
                stopConnectionTimer()
                resetUsageStats()
            case .reasserting:
                isConnecting = false
                isDisconnecting = false
            }
        }
    }
    
    // MARK: - Public Methods
    func toggleConnection() {
        switch status {
        case .connected:
            disconnect()
        case .disconnected:
            connect()
        default:
            break
        }
    }

    func connect(to server: VPNServer? = nil) {
        guard let targetServer = server ?? currentServer else {
            return
        }

        Task {
            do {
                withAnimation {
                    isConnecting = true
                }

                // Generate or retrieve configuration
                let config = try await configManager.loadConfiguration(for: targetServer)

                // Save selected server
                currentServer = targetServer
                configManager.saveSelectedServerId(targetServer.id)

                // Connect via VPN manager
                try await vpnManager.connect(with: config)

            } catch {
                withAnimation {
                    isConnecting = false
                    status = .invalid(error.localizedDescription)
                }
            }
        }
    }

    func disconnect() {
        Task {
            do {
                withAnimation {
                    isDisconnecting = true
                }

                try await vpnManager.disconnect()

            } catch {
                withAnimation {
                    isDisconnecting = false
                    status = .invalid(error.localizedDescription)
                }
            }
        }
    }

    func changeServer(to server: VPNServer) {
        if status.isConnected {
            // First disconnect, then connect to new server
            disconnect()

            // Wait for disconnect, then connect
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.connect(to: server)
            }
        } else {
            connect(to: server)
        }
    }

    func loadCurrentServer() async {
        let serverId = configManager.loadSelectedServerId()

        if let serverId = serverId {
            // Fetch server details from API
            // For now, use mock data
            currentServer = VPNServer.mockServers.first { $0.id == serverId } ??
VPNServer.mock
        }
    }

    // MARK: - Connection Timer
    private func startConnectionTimer() {
        connectionTimer?.invalidate()

        connectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
 { [weak self] _ in
            self?.updateDuration()
        }
    }

    private func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
    }

    private func updateDuration() {
        guard let startTime = startTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) % 3600 / 60
        let seconds = Int(elapsed) % 60

        connectedDuration = String(format: "%02d:%02d:%02d", hours, minutes,
seconds)
    }

    // MARK: - Usage Stats
    private func resetUsageStats() {
        downloadBytes = 0
        uploadBytes = 0
        currentIP = nil
        startTime = nil
        connectedDuration = "00:00:00"
    }

    func updateUsageStats(download: Int64, upload: Int64, ip: String?) {
        downloadBytes = download
        uploadBytes = upload
        if let ip = ip {
            currentIP = ip
        }
    }

    // MARK: - Private Helpers
    private func loadLastServer() {
        let serverId = configManager.loadSelectedServerId()
        if let serverId = serverId {
            currentServer = VPNServer.mockServers.first { $0.id == serverId }
        }
    }
}

// MARK: - Protocol Definitions
protocol VPNManaging {
    func connect(with config: VPNConfiguration) async throws
    func disconnect() async throws
    var isConnected: Bool { get }
}

protocol ConfigManaging {
    func loadConfiguration(for server: VPNServer) async throws -> VPNConfiguration
    func saveSelectedServerId(_ id: String)
    func loadSelectedServerId() -> String?
}

protocol StatusObserving: ObservableObject {
    var status: VPNStatus { get }
}

// MARK: - Computed Properties
extension VPNStatus {
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
