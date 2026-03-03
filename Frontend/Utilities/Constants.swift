//
//  Constants.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - Constants
enum Constants {
    // MARK: - API Configuration
    enum API {
        #if DEBUG
        static let baseURL = "https://api-dev.safemesh.com"
        #else
        static let baseURL = "https://api.safemesh.com"
        #endif
        static let timeout: TimeInterval = 30
        static let version = "v1"
        static let maxRetries = 3
    }

    // MARK: - App Identifiers
    enum Identifiers {
        static let appGroupID = "group.com.safemesh.app"
        static let keychainService = "com.safemesh.app.keychain"
        static let loggerSubsystem = "com.safemesh.app"
        static let packetTunnelSuffix = ".PacketTunnel"
    }

    // MARK: - VPN Defaults
    enum VPN {
        static let defaultProtocol = "WireGuard"
        static let defaultDNS = ["1.1.1.1", "1.0.0.1"]
        static let defaultMTU = 1280
        static let defaultPort = 51820
        static let keepAliveInterval: TimeInterval = 25
        static let defaultAllowedIPs = ["0.0.0.0/0", "::/0"]
    }

    // MARK: - Timeouts
    enum Timeouts {
        static let connection: TimeInterval = 10
        static let pollingInterval: TimeInterval = 5
        static let reconnectDelay: TimeInterval = 5
        static let cacheTimeout: TimeInterval = 300
        static let statusCheckInterval: TimeInterval = 1
    }

    // MARK: - Limits
    enum Limits {
        static let minMTU = 576
        static let maxMTU = 1500
        static let passwordMinLength = 8
        static let maxLogSize: UInt64 = 10 * 1024 * 1024 // 10 MB
        static let maxLogFiles = 5
        static let maxRetries = 3
        static let reconnectAttempts = 5
    }

    // MARK: - Animation
    enum Animation {
        static let defaultDuration: TimeInterval = 0.3
        static let quickDuration: TimeInterval = 0.15
        static let slowDuration: TimeInterval = 0.5
    }

    // MARK: - UI
    enum UI {
        static let defaultSpacing: CGFloat = 16
        static let compactSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        static let defaultCornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 56
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 32
    }
}