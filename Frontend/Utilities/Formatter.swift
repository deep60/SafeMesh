//
//  Formatter.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - Formatter
enum Formatter {
    // MARK: - Byte Formatting
    /// Formats bytes as a human-readable string (KB, MB, GB)
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats bytes as a human-readable string with specified precision
    static func formatBytes(_ bytes: Int64, precision: Int = 1) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return String(format: "%.\(precision)f %@", value, units[unitIndex])
    }

    // MARK: - Speed Formatting
    /// Formats speed in bytes per second as a human-readable string (MB/s)
    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }

    // MARK: - Duration Formatting
    /// Formats a time interval as HH:MM:SS
    static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Formats a time interval in abbreviated form (e.g., "2h 30m 15s")
    static func formatDurationAbbreviated(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        var components: [String] = []

        if hours > 0 {
            components.append("\(hours)h")
        }
        if minutes > 0 {
            components.append("\(minutes)m")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds)s")
        }

        return components.joined(separator: " ")
    }

    // MARK: - Date Formatting
    /// Formats a date using ISO8601 format
    static func formatDateISO8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// Formats a date using a short format (e.g., "Mar 2, 2026")
    static func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Formats a date with time (e.g., "Mar 2, 2026 at 3:30 PM")
    static func formatDateWithTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formats a date using a custom format string
    static func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// Parses an ISO8601 date string
    static func parseISO8601(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    // MARK: - Currency Formatting
    /// Formats a price with currency code
    static func formatCurrency(_ amount: Decimal, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// Formats a price with currency symbol
    static func formatCurrency(_ amount: Double, currencySymbol: String = "$") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    // MARK: - Number Formatting
    /// Formats a number with specified decimal places
    static func formatNumber(_ value: Double, decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Formats a percentage
    static func formatPercent(_ value: Double, decimalPlaces: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
    }

    // MARK: - Relative Time Formatting
    /// Returns a relative time string from a date
    static func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Returns a short relative time string from a date
    static func relativeTimeShort(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}