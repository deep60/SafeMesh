//
//  VPNStatus.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import NetworkExtension
import SwiftUI

// MARK: - VPN Status Enum

enum VPNStatus: Equatable, Hashable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case reasserting
    case invalid(String)
    
    // Convert from NEVPNStatus
    init(_ neStatus: NEVPNStatus) {
        switch neStatus {
        case .disconnected:
            self = .disconnected
        case .connecting:
            self = .connecting
        case .connected:
            self = .connected
        case .reasserting:
            self = .reasserting
        case .disconnecting:
            self = .disconnecting
        @unknown default:
            self = .disconnected
        }
    }
    
    var neVPNStatus: NEVPNStatus {
        switch self {
        case .disconnected: return .disconnected
        case .connecting: return .connecting
        case .connected: return .connected
        case .disconnecting: return .disconnecting
        case .reasserting: return .reasserting
        case .invalid: return .disconnected
        }
    }
    
    // UI properties
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .disconnecting: return "Disconnecting..."
        case .reasserting: return "Reconnecting..."
        case .invalid(let message): return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .disconnecting: return .orange
        case .reasserting: return .yellow
        case .invalid: return .red
        }
    }
    
    var isStable: Bool {
        switch self {
        case .connected, .disconnected: return true
        default: return false
        }
    }
    
    var isTransitioning: Bool {
        switch self {
        case .connecting, .disconnecting, .reasserting: return true
        default: return false
        }
    }

    var isConnectedOrConnecting: Bool {
        switch self {
        case .connected, .connecting, .reasserting: return true
        default: return false
        }
    }
}

extension VPNStatus {
    var icon: String {
        switch self {
        case .disconnected: return "power"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .connected: return "checkmark.shield.fill"
        case .disconnecting: return "power"
        case .reasserting: return "arrow.clockwise"
        case .invalid: return "exclamationmark.triangle.fill"
        }
    }

    static func from(error: Error) -> VPNStatus {
        return .invalid(error.localizedDescription)
    }
}
