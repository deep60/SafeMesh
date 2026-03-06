//
//  StatusObserver.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//
import Foundation
import NetworkExtension
import Combine

// MARK: - Status Observing Protocol
protocol StatusObserving: ObservableObject {
    var status: VPNStatus { get }
}

// MARK: - Status Observer
@MainActor
class StatusObserver: ObservableObject, StatusObserving {
    // MARK: - Singleton
    static let shared = StatusObserver()

    // MARK: - Published Properties
    @Published var status: VPNStatus = .disconnected
    @Published var previousStatus: VPNStatus = .disconnected
    @Published var lastUpdated: Date = Date()
    @Published var connectionHistory: [ConnectionEvent] = []

    // MARK: - Private Properties
    private let manager: NEVPNManager
    private var statusObserver: NSObjectProtocol?
    private var reachabilityObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private var statusPollingTimer: Timer?
    private var isObserving = false

    // MARK: - Types
    struct ConnectionEvent: Identifiable {
        let id: UUID
        let status: ConnectionEventStatus
        let timestamp: Date
        let serverId: String?
        let error: String?

        init(status: VPNStatus, serverId: String? = nil, error: String? = nil) {
            self.id = UUID()
            self.status = ConnectionEventStatus(from: status)
            self.timestamp = Date()
            self.serverId = serverId
            self.error = error
        }
    }

    struct ConnectionEventStatus: Codable {
        let rawValue: String
        let isError: Bool
        let errorMessage: String?

        init(from status: VPNStatus) {
            switch status {
            case .disconnected:
                self.rawValue = "disconnected"
                self.isError = false
                self.errorMessage = nil
            case .connecting:
                self.rawValue = "connecting"
                self.isError = false
                self.errorMessage = nil
            case .connected:
                self.rawValue = "connected"
                self.isError = false
                self.errorMessage = nil
            case .disconnecting:
                self.rawValue = "disconnecting"
                self.isError = false
                self.errorMessage = nil
            case .reasserting:
                self.rawValue = "reasserting"
                self.isError = false
                self.errorMessage = nil
            case .invalid(let message):
                self.rawValue = "invalid"
                self.isError = true
                self.errorMessage = message
            }
        }
    }

    // MARK: - Initialization
    private init() {
        self.manager = NEVPNManager.shared()
    }

    // MARK: - Lifecycle
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        setupVPNStatusObserver()
        setupReachabilityObserver()
        startStatusPolling()
    }

    func stopObserving() {
        isObserving = false

        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = reachabilityObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        statusPollingTimer?.invalidate()
        statusPollingTimer = nil
    }

    // MARK: - Setup
    private func setupVPNStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleStatusChange()
            }
        }
    }

    private func setupReachabilityObserver() {
        reachabilityObserver = NotificationCenter.default.addObserver(
            forName: .init("NetworkReachabilityDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleReachabilityChange()
            }
        }
    }

    private func startStatusPolling() {
        statusPollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self]
_ in
            Task { @MainActor in
                await self?.checkStatus()
            }
        }
    }

    // MARK: - Status Handling
    private func handleStatusChange() async {
        await checkStatus()
    }

    private func handleReachabilityChange() async {
        if status == .connected && !NetworkMonitor.shared.isConnected {
            recordEvent(status: .invalid("Network connection lost"), serverId: nil, error: "Network connection lost")
        }
    }

    private func checkStatus() async {
        let newStatus = VPNStatus(manager.connection.status)

        if newStatus != status {
            await updateStatus(newStatus)
        }
    }

    private func updateStatus(_ newStatus: VPNStatus) async {
        previousStatus = status
        status = newStatus
        lastUpdated = Date()

        let serverId = ConfigManager.shared.loadSelectedServerId()
        var errorMessage: String? = nil

        if case .invalid(let message) = newStatus {
            errorMessage = message
        }

        recordEvent(status: newStatus, serverId: serverId, error: errorMessage)

        await handleStatusSpecificActions(newStatus)

        if connectionHistory.count > 100 {
            connectionHistory = Array(connectionHistory.suffix(100))
        }
    }

    private func handleStatusSpecificActions(_ newStatus: VPNStatus) async {
        switch newStatus {
        case .connected:
            print("[StatusObserver] VPN connected")
            UsageTracker.shared.startTracking()
        case .disconnected:
            print("[StatusObserver] VPN disconnected")
            await UsageTracker.shared.stopTracking()
        case .connecting:
            print("[StatusObserver] VPN connecting...")
        case .disconnecting:
            print("[StatusObserver] VPN disconnecting...")
        case .reasserting:
            print("[StatusObserver] VPN reconnecting...")
        case .invalid(let message):
            print("[StatusObserver] VPN error: \(message)")
        }
    }

    private func recordEvent(status: VPNStatus, serverId: String?, error: String?) {
        let event = ConnectionEvent(status: status, serverId: serverId, error: error)
        connectionHistory.append(event)
    }

    func getRecentEvents(count: Int = 10) -> [ConnectionEvent] {
        Array(connectionHistory.suffix(count))
    }

    func getConnectionTimeToday() -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var totalDuration: TimeInterval = 0
        var sessionStart: Date?

        for event in connectionHistory where event.timestamp >= today {
            if event.status.rawValue == "connected" {
                sessionStart = event.timestamp
            } else if event.status.rawValue == "disconnected", let start = sessionStart {
                totalDuration += event.timestamp.timeIntervalSince(start)
                sessionStart = nil
            }
        }

        if case .connected = status, let start = sessionStart {
            totalDuration += Date().timeIntervalSince(start)
        }

        return totalDuration
    }
}

// MARK: - Usage Tracker
@MainActor
class UsageTracker {
    static let shared = UsageTracker()

    @Published var currentUsage: CurrentUsage = .initial
    private var startTime: Date?
    private var updateTimer: Timer?

    private init() {}

    func startTracking() {
        startTime = Date()
        currentUsage = CurrentUsage(
            sessionDuration: 0,
            bytesUploaded: 0,
            bytesDownloaded: 0,
            connectedAt: Date()
        )

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopTracking() async {
        updateTimer?.invalidate()
        updateTimer = nil

        if let start = startTime {
            currentUsage.sessionDuration = Date().timeIntervalSince(start)
            await uploadUsageStats()
        }

        startTime = nil
    }

    private func updateStats() {
        guard let start = startTime else { return }
        currentUsage.sessionDuration = Date().timeIntervalSince(start)

        Task {
            do {
                let stats = try await IPCManager.shared.requestStats()
                currentUsage.bytesUploaded = stats.bytesUploaded
                currentUsage.bytesDownloaded = stats.bytesDownloaded
            } catch {
                // Ignore errors
            }
        }
    }

    private func uploadUsageStats() async {
        do {
            let configManager = ConfigManager.shared
            let serverId = configManager.loadSelectedServerId()

            let request = UsageUploadRequest(
                bytesUploaded: currentUsage.bytesUploaded,
                bytesDownloaded: currentUsage.bytesDownloaded,
                duration: currentUsage.sessionDuration,
                serverId: serverId
            )

            _ = try await APIClient.shared.request(
                endpoint: "/usage/upload",
                method: .post,
                body: request
            ) as EmptyResponse
        } catch {
            print("[UsageTracker] Failed to upload usage: \(error)")
        }
    }
}

struct UsageUploadRequest: Codable {
    let bytesUploaded: Int64
    let bytesDownloaded: Int64
    let duration: TimeInterval
    let serverId: String?
}

