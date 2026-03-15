// WireGuardKit stub for local development.
// Provides the public API surface used by PacketTunnelProvider
// without requiring the real WireGuard Go bridge to compile.

import Foundation
import NetworkExtension

// MARK: - Log Level
public enum WireGuardLogLevel: Int32 {
    case verbose = 0
    case info = 1
    case error = 2
}

// MARK: - Tunnel Configuration (WireGuardKit)
public class TunnelConfiguration {
    public let name: String?

    public init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        self.name = name
    }
}

// MARK: - WireGuard Adapter
public class WireGuardAdapter {
    public typealias LogHandler = (WireGuardLogLevel, String) -> Void

    private weak var packetTunnelProvider: NEPacketTunnelProvider?
    private let logHandler: LogHandler

    public init(with packetTunnelProvider: NEPacketTunnelProvider, logHandler: @escaping LogHandler) {
        self.packetTunnelProvider = packetTunnelProvider
        self.logHandler = logHandler
    }

    public func start(tunnelConfiguration: TunnelConfiguration, completionHandler: @escaping (Error?) -> Void) {
        logHandler(.info, "[Stub] WireGuardAdapter.start() — real WireGuardKit needed for VPN")
        completionHandler(WireGuardAdapterError.startFailed)
    }

    public func stop(completionHandler: @escaping (Error?) -> Void) {
        logHandler(.info, "[Stub] WireGuardAdapter.stop()")
        completionHandler(nil)
    }

    public func update(tunnelConfiguration: TunnelConfiguration, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }

    public func getRuntimeConfiguration(completionHandler: @escaping (String?) -> Void) {
        completionHandler(nil)
    }
}

// MARK: - Adapter Error
public enum WireGuardAdapterError: Error {
    case startFailed
    case invalidConfiguration
}
