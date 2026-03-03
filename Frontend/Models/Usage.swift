//
//  Usage.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - Usage Statistics Model
struct Usage: Identifiable, Codable {
      let id: String
      let userId: String
      let serverId: String
      let sessionDuration: TimeInterval
      let bytesUploaded: Int64
      let bytesDownloaded: Int64
      let startTime: Date
      let endTime: Date

      // Computed properties
      var totalBytes: Int64 {
          bytesUploaded + bytesDownloaded
      }

      var formattedDuration: String {
          let formatter = DateComponentsFormatter()
          formatter.allowedUnits = [.hour, .minute, .second]
          formatter.unitsStyle = .abbreviated
          return formatter.string(from: sessionDuration) ?? "0s"
      }

      var averageSpeedMbps: Double {
          guard sessionDuration > 0 else { return 0 }
          let bits = totalBytes * 8
          let seconds = sessionDuration
          return Double(bits) / seconds / 1_000_000
      }
  }

// MARK: - Monthly Usage Summary
struct UsageSummary: Codable {
    let month: Int
    let year: Int
    let totalBytes: Int64
    let totalSessions: Int
    let totalDuration: TimeInterval
    let mostUsedServer: String?

    var formattedTotalBytes: String {
        ByteCountFormatter().string(fromByteCount: totalBytes)
    }

    var formattedTotalDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        return formatter.string(from: totalDuration) ?? "0 minutes"
    }

    var percentageUsed: Double {
        // Assuming 1TB limit for calculation
        let limit: Int64 = 1_099_511_627_776 // 1 TB
        return min(Double(totalBytes) / Double(limit), 1.0)
    }
}

// MARK: Real-time Usage
struct CurrentUsage: Codable {
      var sessionDuration: TimeInterval
      var bytesUploaded: Int64
      var bytesDownloaded: Int64
      var connectedAt: Date
      var currentServer: VPNServer?

      var totalBytes: Int64 {
          bytesUploaded + bytesDownloaded
      }

      var formattedSessionDuration: String {
          let elapsed = Date().timeIntervalSince(connectedAt)
          let formatter = DateComponentsFormatter()
          formatter.allowedUnits = [.hour, .minute, .second]
          formatter.unitsStyle = .positional
          formatter.zeroFormattingBehavior = .pad
          return formatter.string(from: elapsed) ?? "00:00:00"
      }

      var formattedUploadSpeed: String {
          formatSpeed(bytesUploaded)
      }

      var formattedDownloadSpeed: String {
          formatSpeed(bytesDownloaded)
      }

      private func formatSpeed(_ bytes: Int64) -> String {
          let elapsed = Date().timeIntervalSince(connectedAt)
          guard elapsed > 0 else { return "0 MB/s" }

          let bytesPerSecond = Double(bytes) / elapsed
          let mbPerSecond = bytesPerSecond / 1_048_576

          return String(format: "%.2f MB/s", mbPerSecond)
      }

      static var initial: CurrentUsage {
          CurrentUsage(
              sessionDuration: 0,
              bytesUploaded: 0,
              bytesDownloaded: 0,
              connectedAt: Date(),
              currentServer: nil
          )
      }
  }

// MARK: Mock Data
extension Usage {
      static let mock = Usage(
          id: "usage_1",
          userId: "user_123",
          serverId: "us-east-1",
          sessionDuration: 3600,
          bytesUploaded: 50 * 1024 * 1024,
          bytesDownloaded: 250 * 1024 * 1024,
          startTime: Date().addingTimeInterval(-3600),
          endTime: Date()
      )
  }

  extension UsageSummary {
      static let mock = UsageSummary(
          month: 2,
          year: 2026,
          totalBytes: 5 * 1024 * 1024 * 1024, // 5 GB
          totalSessions: 15,
          totalDuration: 86400 * 2, // 2 days
          mostUsedServer: "US-East-1"
      )
  }
