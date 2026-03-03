//
//  Extensions.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Status Colors (convenience accessors matching Theme.Colors)
    static let statusBlue = Theme.Colors.statusBlue
    static let statusGreen = Theme.Colors.statusGreen
    static let statusOrange = Theme.Colors.statusOrange
    static let statusRed = Theme.Colors.statusRed
    static let statusYellow = Theme.Colors.statusYellow
    static let statusGray = Theme.Colors.statusGray
}

// MARK: - String Extensions
extension String {
    /// Extracts initials from a name string (e.g., "John Doe" -> "JD")
    var initials: String {
        let words = self.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }
        return String(initials).uppercased()
    }

    /// Converts a country code to a flag emoji (e.g., "US" -> "🇺🇸")
    var flagEmoji: String {
        let base: UInt32 = 127397
        var flagString = ""

        for scalar in self.uppercased().unicodeScalars {
            guard scalar.value >= 65 && scalar.value <= 90 else { return "🌐" }
            flagString.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
        }

        return flagString
    }

    /// Checks if string is a valid email address
    var isValidEmail: Bool {
        Validator.isValidEmail(self)
    }

    /// Checks if string is a valid password
    var isValidPassword: Bool {
        Validator.isValidPassword(self)
    }

    /// Checks if string is a valid IP address (IPv4 or IPv6)
    var isValidIPAddress: Bool {
        Validator.isValidIPAddress(self)
    }
}

// MARK: - Date Extensions
extension Date {
    /// Checks if this date is within the specified number of days from now
    func isWithin(days: Int) -> Bool {
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
            return false
        }
        return self <= futureDate
    }

    /// Returns the number of days until the specified date
    func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }

    /// Returns a relative time string (e.g., "2 hours ago", "in 3 days")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a short relative time string (e.g., "2h ago", "3d")
    var shortRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns ISO8601 formatted string
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }

    /// Returns a formatted date string
    func formatted(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
}

// MARK: - Bundle Extensions
extension Bundle {
    /// Returns the app version string (e.g., "1.0.0")
    var versionString: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Returns the build number (e.g., "1")
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Returns the full version string (e.g., "1.0.0 (1)")
    var fullVersionString: String {
        return "\(versionString) (\(buildNumber))"
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    /// Formats the time interval as a duration string (HH:MM:SS)
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// Formats the time interval as an abbreviated duration (e.g., "2h 30m")
    var abbreviatedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

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
}

// MARK: - Int64 Extensions (for byte counts)
extension Int64 {
    /// Formats bytes as a human-readable string (KB, MB, GB)
    var formattedBytes: String {
        Formatter.formatBytes(self)
    }
}

// MARK: - Double Extensions (for speeds)
extension Double {
    /// Formats as speed (MB/s)
    var formattedSpeed: String {
        Formatter.formatSpeed(self)
    }
}