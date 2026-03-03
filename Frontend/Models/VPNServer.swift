//
//  VPNServer.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import CoreLocation
import SwiftUI


// MARK: - Main Server Model
struct VPNServer: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let city: String
    let country: String
    let countryCode: String
    let region: Region
    let ipAddress: String
    let port: Int
    let publicKey: String
    let endpoint: String
    let dnsServers: [String]
    let latency: Int
    let loadPercentage: Int
    let isActive: Bool
    let isPremium: Bool
    let protocols: [SupportedProtocol]
    
    // Computed properties
    var displayName: String {
        "\(city), \(country)"
    }
    
    var fullAddress: String {
        "\(ipAddress):\(port)"
    }
    
    var latencyCategory: LatencyCategory {
        switch latency {
        case 0...50: return .excellent
        case 51...100: return .good
        case 101...200: return .fair
        case 201...300: return .poor
        default: return .veryPoor
        }
    }
    
    var isRecommended: Bool {
        latency < 100 && loadPercentage < 50
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VPNServer, rhs: VPNServer) -> Bool {
        lhs.id == rhs.id
    }
}

//MARK: - Supporting Types
extension VPNServer {
    enum Region: String, Codable, CaseIterable, Identifiable {
        case northAmerica = "North America"
        case europe = "Europe"
        case asiaPacific = "Asia Pacific"
        case southAmerica = "South America"
        case middleEast = "Middle East"
        case africa = "Africa"
        
        var id: String { rawValue }
        
        var flag: String {
            switch self {
            case .northAmerica: return "🌎"
            case .europe: return "🌍"
            case .asiaPacific: return "🌏"
            case .southAmerica: return "🌎"
            case .middleEast: return "🌍"
            case .africa: return "🌍"
            }
        }
    }
    
    enum SupportedProtocol: String, Codable, CaseIterable {
        case wireGuard = "WireGuard"
        case openvpn = "OpenVPN"
        case ikev2 = "IKEV2"
    }
    
    enum LatencyCategory: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case veryPoor = "Very Poor"

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .poor: return .orange
            case .veryPoor: return .red
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "bolt.fill"
            case .good: return "speedometer"
            case .fair: return "speedometer"
            case .poor: return "turtle.fill"
            case .veryPoor: return "snail.fill"
            }
        }
    }
}

// MARK: - Mock Data
  extension VPNServer {
      static let mock = VPNServer(
          id: "us-east-1",
          name: "US-East-1",
          city: "New York",
          country: "United States",
          countryCode: "US",
          region: .northAmerica,
          ipAddress: "203.0.113.1",
          port: 51820,
          publicKey: "ABC123...",
          endpoint: "203.0.113.1:51820",
          dnsServers: ["1.1.1.1", "1.0.0.1"],
          latency: 45,
          loadPercentage: 35,
          isActive: true,
          isPremium: false,
          protocols: [.wireGuard, .openvpn]    // .openvpn
      )

      static let mockServers: [VPNServer] = [
          .mock,
          VPNServer(
              id: "us-west-1",
              name: "US-West-1",
              city: "Los Angeles",
              country: "United States",
              countryCode: "US",
              region: .northAmerica,
              ipAddress: "203.0.113.2",
              port: 51820,
              publicKey: "DEF456...",
              endpoint: "203.0.113.2:51820",
              dnsServers: ["1.1.1.1", "1.0.0.1"],
              latency: 85,
              loadPercentage: 45,
              isActive: true,
              isPremium: false,
              protocols: [.wireGuard]
          ),
          VPNServer(
              id: "eu-central-1",
              name: "EU-Central-1",
              city: "Frankfurt",
              country: "Germany",
              countryCode: "DE",
              region: .europe,
              ipAddress: "203.0.113.3",
              port: 51820,
              publicKey: "GHI789...",
              endpoint: "203.0.113.3:51820",
              dnsServers: ["1.1.1.1", "1.0.0.1"],
              latency: 110,
              loadPercentage: 25,
              isActive: true,
              isPremium: false,
              protocols: [.wireGuard, .openvpn, .ikev2]
          ),
          VPNServer(
              id: "ap-northeast-1",
              name: "AP-Northeast-1",
              city: "Tokyo",
              country: "Japan",
              countryCode: "JP",
              region: .asiaPacific,
              ipAddress: "203.0.113.4",
              port: 51820,
              publicKey: "JKL012...",
              endpoint: "203.0.113.4:51820",
              dnsServers: ["1.1.1.1", "1.0.0.1"],
              latency: 180,
              loadPercentage: 65,
              isActive: true,
              isPremium: true,
              protocols: [.wireGuard]
          ),
          VPNServer(
              id: "uk-south-1",
              name: "UK-South-1",
              city: "London",
              country: "United Kingdom",
              countryCode: "GB",
              region: .europe,
              ipAddress: "203.0.113.5",
              port: 51820,
              publicKey: "MNO345...",
              endpoint: "203.0.113.5:51820",
              dnsServers: ["1.1.1.1", "1.0.0.1"],
              latency: 95,
              loadPercentage: 40,
              isActive: true,
              isPremium: false,
              protocols: [.wireGuard, .openvpn]
          )
      ]
  }
