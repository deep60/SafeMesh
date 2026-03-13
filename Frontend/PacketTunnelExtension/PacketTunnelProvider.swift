//
//  PacketTunnelProvider.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension
import WireGuardKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    // MARK: - Properties
    private lazy var adapter: WireGuardAdapter = {
        return WireGuardAdapter(with: self) { logLevel, message in
            wg_log(logLevel, message: message)
        }
    }()
    
    private var startTime: Date?
    
    // MARK: - Tunnel Lifecycle
    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        // 1. Load the WireGuard config string from provider configuration
        guard let configString = loadWireGuardConfig() else {
            wg_log(.error, message: "Failed to load WireGuard configuration")
            completionHandler(PacketTunnelProviderError.invalidConfiguration)
            return
        }
        
        // 2. Parse into WireGuardKit's TunnelConfiguration
        let tunnelConfig: TunnelConfiguration
        do {
            tunnelConfig = try TunnelConfiguration(fromWgQuickConfig: configString, called: "SafeMesh")
        } catch {
            wg_log(.error, message: "Failed to parse WireGuard config: \(error)")
            completionHandler(PacketTunnelProviderError.invalidConfiguration)
            return
        }
        
        // 3. Start the adapter — WireGuardKit handles handshake, crypto, packet processing
        adapter.start(tunnelConfiguration: tunnelConfig) { [weak self] adapterError in
            if let error = adapterError {
                wg_log(.error, message: "Failed to start WireGuard adapter: \(error)")
                completionHandler(error)
            } else {
                self?.startTime = Date()
                wg_log(.info, message: "WireGuard tunnel started successfully")
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        wg_log(.info, message: "Stopping tunnel. Reason: \(reason)")
        
        adapter.stop { error in
            if let error = error {
                wg_log(.error, message: "Failed to stop WireGuard adapter: \(error)")
            } else {
                wg_log(.info, message: "WireGuard tunnel stopped")
            }
            completionHandler()
        }
    }
    
    // MARK: - IPC (App ↔ Extension Communication)
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
              let type = message["type"] as? String else {
            completionHandler?(nil)
            return
        }
        
        switch type {
        case "status":
            let response: [String: Any] = [
                "isConnected": true,
                "connectedAt": startTime?.timeIntervalSince1970 ?? 0
            ]
            let data = try? JSONSerialization.data(withJSONObject: response)
            completionHandler?(data)
            
        case "getRuntimeConfiguration":
            adapter.getRuntimeConfiguration { configString in
                completionHandler?(configString?.data(using: .utf8))
            }
            
        default:
            completionHandler?(nil)
        }
    }
    
    // MARK: - Configuration Loading
    private func loadWireGuardConfig() -> String? {
        guard let providerConfig = protocolConfiguration as? NETunnelProviderProtocol,
              let providerDict = providerConfig.providerConfiguration else {
            return nil
        }
        
        // Option A: Complete wg-quick config string (preferred)
        if let wgConfig = providerDict["wgQuickConfig"] as? String {
            return wgConfig
        }
        
        // Option B: Build config from individual fields (backwards compatibility)
        guard let serverAddress = providerDict["serverAddress"] as? String,
              let serverPort = providerDict["serverPort"] as? Int,
              let serverPublicKey = providerDict["serverPublicKey"] as? String,
              let privateKey = providerDict["privateKey"] as? String,
              let interfaceV4 = providerDict["interfaceAddressV4"] as? String,
              let interfaceV6 = providerDict["interfaceAddressV6"] as? String else {
            return nil
        }
        
        let dnsServers = (providerDict["dnsServers"] as? String) ?? "1.1.1.1, 1.0.0.1"
        let allowedIPs = (providerDict["allowedIPs"] as? String) ?? "0.0.0.0/0, ::/0"
        let mtu = providerDict["mtu"] as? Int ?? 1280
        let keepAlive = providerDict["keepAlive"] as? Int ?? 25
        let presharedKey = providerDict["presharedKey"] as? String
        
        var config = """
        [Interface]
        PrivateKey = \(privateKey)
        Address = \(interfaceV4), \(interfaceV6)
        DNS = \(dnsServers.replacingOccurrences(of: ",", with: ", "))
        MTU = \(mtu)
        
        [Peer]
        PublicKey = \(serverPublicKey)
        Endpoint = \(serverAddress):\(serverPort)
        AllowedIPs = \(allowedIPs.replacingOccurrences(of: ",", with: ", "))
        PersistentKeepalive = \(keepAlive)
        """
        
        if let psk = presharedKey, !psk.isEmpty {
            config += "\nPresharedKey = \(psk)"
        }
        
        return config
    }
}

// MARK: - Error Types
enum PacketTunnelProviderError: LocalizedError {
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid or missing WireGuard tunnel configuration"
        }
    }
}

// MARK: - Logging Helper
private func wg_log(_ level: WireGuardLogLevel, message: String) {
    let levelStr: String
    switch level {
    case .verbose: levelStr = "VERBOSE"
    case .error: levelStr = "ERROR"
    default: levelStr = "INFO"
    }
    NSLog("[WireGuard] [\(levelStr)] \(message)")
}
