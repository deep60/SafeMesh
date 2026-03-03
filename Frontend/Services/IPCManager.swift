//
//  IPCManager.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension
import Combine

// MARK: - IPC Manager
class IPCManager: ObservableObject {
    // MARK: - Singleton
    static let shared = IPCManager()

    // MARK: - Published Properties
    @Published var connectionState: ConnectionState = .disconnected
    @Published var receivedMessages: [IPCMessage] = []

    // MARK: - Private Properties
    private let appGroup: String
    private var messageQueue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()
    private var session: NETunnelProviderSession?

    // MARK: - Types
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(Error)
    }

    enum MessageType: String, Codable {
        case status
        case config
        case stats
        case error
        case ping
        case pong
    }

    struct IPCMessage: Codable, Identifiable {
        let id: UUID
        let type: MessageType
        let timestamp: Date
        let payload: [String: String]

        init(type: MessageType, payload: [String: String]) {
            self.id = UUID()
            self.type = type
            self.timestamp = Date()
            self.payload = payload
        }
    }

    // MARK: - Initialization
    private init() {
        if let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String {
            self.appGroup = appGroup
        } else {
            self.appGroup = "group.com.safemesh.app"
        }

        self.messageQueue = DispatchQueue(label: "com.safemesh.ipc", qos: .utility)

        setupNotificationObservers()
    }

    // MARK: - Setup
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .init("com.safemesh.extension.message"))
            .sink { [weak self] notification in
                self?.handleMessage(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
    func sendMessage(_ message: IPCMessage) async throws {
        guard let data = try? JSONEncoder().encode(message) else {
            throw IPCManagerError.encodingFailed
        }

        try await sendRawMessage(data)
    }

    func sendRawMessage(_ data: Data) async throws {
        guard let session = session else {
            throw IPCManagerError.notConnected
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try session.sendProviderMessage(data) { responseData in
                    // responseData is Data? — handle response if needed
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func requestStatus() async throws -> ConnectionStatus {
        let message = IPCMessage(type: .status, payload: [:])
        try await sendMessage(message)

        // Wait for response
        let data = try await waitForMessage(ofType: .status, timeout: 5)
        return try JSONDecoder().decode(ConnectionStatus.self, from: data)
    }

    func requestStats() async throws -> ConnectionStats {
        let message = IPCMessage(type: .stats, payload: [:])
        try await sendMessage(message)
        
        let data = try await waitForMessage(ofType: .stats, timeout: 5)
        return try JSONDecoder().decode(ConnectionStats.self, from: data)
    }

    func pingExtension() async throws -> TimeInterval {
        let startTime = Date()

        let message = IPCMessage(type: .ping, payload: ["timestamp": String(Date().timeIntervalSince1970)])
        try await sendMessage(message)

        _ = try await waitForMessage(ofType: .pong, timeout: 5)

        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Session Management
    func setSession(_ session: NETunnelProviderSession) {
        self.session = session

        DispatchQueue.main.async {
            self.connectionState = .connected
        }
    }

    func clearSession() {
        self.session = nil

        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }

    // MARK: - Private Methods
    private func handleMessage(_ notification: Notification) {
        guard let data = notification.object as? Data,
              let message = try? JSONDecoder().decode(IPCMessage.self, from: data)
        else {
            return
        }

        DispatchQueue.main.async {
            self.receivedMessages.append(message)
        }
    }

    private func waitForMessage(ofType type: MessageType, timeout: TimeInterval)
async throws -> Data {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if let message = receivedMessages.first(where: { $0.type == type }) {
                if let data = try? JSONEncoder().encode(message.payload) {
                    receivedMessages.removeAll { $0.id == message.id }
                    return data
                }
            }

            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        throw IPCManagerError.timeout
    }
}

// MARK: - Supporting Types
struct ConnectionStatus: Codable {
    let isConnected: Bool
    let serverAddress: String
    let connectedAt: Date?
    let error: String?
}

struct ConnectionStats: Codable {
    let bytesUploaded: Int64
    let bytesDownloaded: Int64
    let duration: TimeInterval
    let currentSpeedUp: Double
    let currentSpeedDown: Double
}

// MARK: - IPC Errors
enum IPCManagerError: LocalizedError {
    case notConnected
    case encodingFailed
    case decodingFailed
    case timeout
    case invalidMessage

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Extension is not connected"
        case .encodingFailed: return "Failed to encode message"
        case .decodingFailed: return "Failed to decode message"
        case .timeout: return "Message timed out"
        case .invalidMessage: return "Invalid message format"
        }
    }
}

// MARK: - Darwin Notification Helper
class DarwinNotificationHelper {
    static let shared = DarwinNotificationHelper()

    func post(_ name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }

    func observe(_ name: String, using block: @escaping (Notification) -> Void) ->
NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: .init(name),
            object: nil,
            queue: .main,
            using: block
        )
    }
}

