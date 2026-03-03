//
//  APIServer.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

  // MARK: - API Response Models

  // MARK: - Generic API Response
  struct APIResponse<T: Codable>: Codable {
      let success: Bool
      let data: T?
      let error: APIError?
      let message: String?

      enum CodingKeys: String, CodingKey {
          case success
          case data
          case error
          case message
      }
  }

  // MARK: - API Error
  struct APIError: Codable, LocalizedError {
      let code: String
      let message: String
      let details: [String]?

      var errorDescription: String? {
          if let details = details, !details.isEmpty {
              return "\(message)\n\n\(details.joined(separator: "\n"))"
          }
          return message
      }
  }

  // MARK: - Authentication Response
  struct AuthResponse: Codable {
      let token: String
      let refreshToken: String
      let expiresIn: TimeInterval
      let user: User
  }

  // MARK: - Refresh Token Response
  struct RefreshTokenResponse: Codable {
      let token: String
      let expiresIn: TimeInterval
  }

  // MARK: - Servers List Response
  struct ServersListResponse: Codable {
      let servers: [VPNServer]
      let lastUpdated: Date

      enum CodingKeys: String, CodingKey {
          case servers
          case lastUpdated = "last_updated"
      }
  }

  // MARK: - Server Detail Response
  struct ServerDetailResponse: Codable {
      let server: VPNServer
      let loadHistory: [LoadHistoryEntry]
      let uptime: TimeInterval
  }

  struct LoadHistoryEntry: Codable {
      let timestamp: Date
      let loadPercentage: Int
      let connectedUsers: Int
  }

  // MARK: - VPN Config Response
  struct VPNConfigResponse: Codable {
      let configuration: VPNConfiguration
      let expiresAt: Date
  }

  // MARK: - Usage Response
  struct UsageResponse: Codable {
      let current: CurrentUsage
      let summary: UsageSummary
      let history: [Usage]
  }

  // MARK: - Subscription Response
  struct SubscriptionResponse: Codable {
      let subscription: Subscription?
      let plans: [SubscriptionPlan]
  }

  // MARK: - Ping Result
  struct PingResult: Codable {
      let serverId: String
      let latency: TimeInterval
      let timestamp: Date
      let success: Bool
  }

  // MARK: - Health Check Response
  struct HealthCheckResponse: Codable {
      let status: String
      let version: String
      let timestamp: Date
      let services: [ServiceStatus]
  }

  struct ServiceStatus: Codable {
      let name: String
      let status: String
      let latency: TimeInterval?
  }

  // MARK: - Common HTTP Methods
  enum HTTPMethod: String {
      case get = "GET"
      case post = "POST"
      case put = "PUT"
      case patch = "PATCH"
      case delete = "DELETE"
  }

  // MARK: - API Error Codes
  enum APIErrorCode: String {
      case unauthorized = "UNAUTHORIZED"
      case forbidden = "FORBIDDEN"
      case notFound = "NOT_FOUND"
      case validationError = "VALIDATION_ERROR"
      case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
      case serverError = "SERVER_ERROR"
      case networkError = "NETWORK_ERROR"
      case invalidToken = "INVALID_TOKEN"
      case expiredToken = "EXPIRED_TOKEN"
      case subscriptionRequired = "SUBSCRIPTION_REQUIRED"
      case serverUnavailable = "SERVER_UNAVAILABLE"
  }
