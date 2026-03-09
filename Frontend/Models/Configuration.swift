//
//  Configuration.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: VPN Configuration Model
struct VPNConfiguration: Codable {
      let server: VPNServer
      let vpnProtocol: VPNProtocol
      let interfaceAddressV4: String
      let interfaceAddressV6: String
      let privateKey: String
      let publicKey: String
      let presharedKey: String?
      let allowedIPs: [String]
      let dnsServers: [String]
      let keepAliveInterval: Int
      let mtu: Int
      let additionalSettings: [String: String]

      // WireGuard specific
      var wireGuardConfig: String {
          var config = """
          [Interface]
          PrivateKey = \(privateKey)
          Address = \(interfaceAddressV4)
          DNS = \(dnsServers.joined(separator: ", "))
          MTU = \(mtu)
          """

          if keepAliveInterval > 0 {
              config += "\nPersistentKeepalive = \(keepAliveInterval)"
          }

          config += """

          [Peer]
          PublicKey = \(server.publicKey)
          Endpoint = \(server.endpoint)
          AllowedIPs = \(allowedIPs.joined(separator: ", "))
          """

          if let psk = presharedKey {
              config += "\nPresharedKey = \(psk)"
          }

          return config
      }
  }

// MARK: VPN Protocol
enum VPNProtocol: String, Codable, CaseIterable, Identifiable {
      case wireGuard = "WireGuard"
      case openVPN = "OpenVPN"
      case ikev2 = "IKEv2"

      var id: String { rawValue }

      var description: String {
          switch self {
          case .wireGuard: return "Fast, modern, and secure"
          case .openVPN: return "Widely supported, very secure"
          case .ikev2: return "Best for mobile, stable"
          }
      }

      var icon: String {
          switch self {
          case .wireGuard: return "bolt.fill"
          case .openVPN: return "shield.fill"
          case .ikev2: return "lock.fill"
          }
      }
  }

// MARK: App Configuration
struct AppConfiguration {
      static let shared = AppConfiguration()

      // API Configuration
      let apiBaseURL: String
      let apiTimeout: TimeInterval
      let apiVersion: String

      // VPN Configuration
      let defaultProtocol: VPNProtocol
      let defaultDNS: [String]
      let defaultMTU: Int
      let keepAliveInterval: Int
      let reconnectAttempts: Int
      let reconnectDelay: TimeInterval

      // App Settings
      let maxRetries: Int
      let cacheTimeout: TimeInterval
      let analyticsEnabled: Bool

      private init() {
          #if DEBUG
          self.apiBaseURL = "http://localhost:8080/api/v1"
          #else
          self.apiBaseURL = "https://api.safemesh.com/api/v1"
          #endif

          self.apiTimeout = 30.0
          self.apiVersion = "v1"

          self.defaultProtocol = .wireGuard
          self.defaultDNS = ["1.1.1.1", "1.0.0.1"]
          self.defaultMTU = 1280
          self.keepAliveInterval = 25
          self.reconnectAttempts = 5
          self.reconnectDelay = 5.0

          self.maxRetries = 3
          self.cacheTimeout = 300
          self.analyticsEnabled = true
      }
  }

// MARK: User Preference
struct UserPreferences: Codable {
      var autoConnectOnLaunch: Bool
      var autoConnectOnWiFiChange: Bool
      var killSwitchEnabled: Bool
      var blockLANTraffic: Bool
      var selectedProtocol: VPNProtocol
      var customDNS: [String]?
      var notificationsEnabled: Bool
      var notifyOnDisconnection: Bool
      var notifyOnReconnection: Bool
      var selectedServerId: String?
      var theme: AppTheme
      var language: String

      static let `default` = UserPreferences(
          autoConnectOnLaunch: false,
          autoConnectOnWiFiChange: false,
          killSwitchEnabled: true,
          blockLANTraffic: false,
          selectedProtocol: .wireGuard,
          customDNS: nil,
          notificationsEnabled: true,
          notifyOnDisconnection: true,
          notifyOnReconnection: false,
          selectedServerId: nil,
          theme: .system,
          language: "en"
      )
  }

// MARK: App theme
enum AppTheme: String, Codable, CaseIterable, Identifiable {
      case system = "System"
      case light = "Light"
      case dark = "Dark"

      var id: String { rawValue }
  }

// MARK: Mock Data
extension VPNConfiguration {
      static let mock = VPNConfiguration(
          server: .mock,
          vpnProtocol: .wireGuard,
          privateKey: "private_key_placeholder",
          publicKey: "public_key_placeholder",
          presharedKey: nil,
          allowedIPs: ["0.0.0.0/0", "::/0"],
          dnsServers: ["1.1.1.1", "1.0.0.1"],
          keepAliveInterval: 25,
          mtu: 1280,
          additionalSettings: [:]
      )
  }
