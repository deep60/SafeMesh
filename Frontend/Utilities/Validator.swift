//
//  Validator.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation

// MARK: - Validator
enum Validator {
    // MARK: - Email Validation
    /// Validates an email address using RFC 5322 compliant regex
    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }

        let emailRegex = """
        ^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+\
        @[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\
        (?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$
        """

        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Password Validation
    /// Password validation options
    struct PasswordOptions: OptionSet {
        let rawValue: Int

        static let minLength = PasswordOptions(rawValue: 1 << 0)
        static let uppercase = PasswordOptions(rawValue: 1 << 1)
        static let lowercase = PasswordOptions(rawValue: 1 << 2)
        static let digit = PasswordOptions(rawValue: 1 << 3)
        static let specialCharacter = PasswordOptions(rawValue: 1 << 4)

        static let standard: PasswordOptions = [.minLength, .uppercase, .lowercase, .digit]
        static let strong: PasswordOptions = [.minLength, .uppercase, .lowercase, .digit, .specialCharacter]
    }

    /// Validates a password with specified requirements
    static func isValidPassword(
        _ password: String,
        options: PasswordOptions = .standard,
        minLength: Int = Constants.Limits.passwordMinLength
    ) -> Bool {
        guard !password.isEmpty else { return false }

        // Check minimum length if required
        if options.contains(.minLength) && password.count < minLength {
            return false
        }

        // Check for uppercase if required
        if options.contains(.uppercase) && !password.contains(where: { $0.isUppercase }) {
            return false
        }

        // Check for lowercase if required
        if options.contains(.lowercase) && !password.contains(where: { $0.isLowercase }) {
            return false
        }

        // Check for digit if required
        if options.contains(.digit) && !password.contains(where: { $0.isNumber }) {
            return false
        }

        // Check for special character if required
        if options.contains(.specialCharacter) {
            let specialCharacters = CharacterSet.punctuationCharacters
                .union(.symbols)
                .union(.nonBaseCharacters)
            if password.unicodeScalars.allSatisfy({ !specialCharacters.contains($0) }) {
                return false
            }
        }

        return true
    }

    /// Returns password strength score (0-4)
    static func passwordStrength(_ password: String) -> Int {
        var score = 0

        // Length
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }

        // Character variety
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }

        return min(score, 4)
    }

    // MARK: - WireGuard Key Validation
    /// Validates a WireGuard private or public key (base64 encoded, 32 bytes)
    static func isValidWireGuardKey(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }

        // WireGuard keys are 44 characters (32 bytes base64 encoded with padding)
        guard key.count == 44 else { return false }

        // Check if it's valid base64
        guard Data(base64Encoded: key) != nil else { return false }

        // Verify it decodes to exactly 32 bytes
        guard let data = Data(base64Encoded: key), data.count == 32 else { return false }

        return true
    }

    // MARK: - IP Address Validation
    /// Validates an IPv4 address
    static func isValidIPv4(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }

        for part in parts {
            guard let num = Int(part), (0...255).contains(num) else { return false }
            // Check for leading zeros (not allowed)
            if part.count > 1 && part.first == "0" { return false }
        }

        return true
    }

    /// Validates an IPv6 address
    static func isValidIPv6(_ ip: String) -> Bool {
        // Handle :: compression
        let compressedCount = ip.components(separatedBy: "::").count - 1
        guard compressedCount <= 1 else { return false }

        // Expand :: to appropriate number of zero groups
        var expanded = ip
        if compressedCount == 1 {
            let parts = ip.components(separatedBy: ":")
            let zeroGroups = 8 - parts.filter { !$0.isEmpty }.count
            let replacement = String(repeating: ":0", count: zeroGroups) + ":"
            expanded = ip.replacingOccurrences(of: "::", with: replacement)
        }

        let parts = expanded.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 8 else { return false }

        for part in parts {
            guard part.count <= 4 else { return false }
            guard Int(part, radix: 16) != nil else { return false }
        }

        return true
    }

    /// Validates an IP address (IPv4 or IPv6)
    static func isValidIPAddress(_ ip: String) -> Bool {
        return isValidIPv4(ip) || isValidIPv6(ip)
    }

    // MARK: - MTU Validation
    /// Validates MTU value (valid range: 576-1500)
    static func isValidMTU(_ mtu: Int) -> Bool {
        return mtu >= Constants.Limits.minMTU && mtu <= Constants.Limits.maxMTU
    }

    // MARK: - DNS Validation
    /// Validates a DNS server address (IP or hostname)
    static func isValidDNS(_ dns: String) -> Bool {
        // Check if it's a valid IP address
        if isValidIPAddress(dns) {
            return true
        }

        // Check if it's a valid hostname
        return isValidHostname(dns)
    }

    /// Validates a hostname
    static func isValidHostname(_ hostname: String) -> Bool {
        guard !hostname.isEmpty else { return false }

        // Hostname regex
        let hostnameRegex = "^([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)

        return predicate.evaluate(with: hostname)
    }

    // MARK: - Port Validation
    /// Validates a port number (1-65535)
    static func isValidPort(_ port: Int) -> Bool {
        return port >= 1 && port <= 65535
    }

    // MARK: - CIDR Validation
    /// Validates a CIDR notation (e.g., "192.168.1.0/24")
    static func isValidCIDR(_ cidr: String) -> Bool {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2 else { return false }

        let ip = String(parts[0])
        guard let prefix = Int(parts[1]) else { return false }

        // Validate IP part
        guard isValidIPv4(ip) else { return false }

        // Validate prefix length (0-32 for IPv4)
        guard prefix >= 0 && prefix <= 32 else { return false }

        return true
    }

    // MARK: - URL Validation
    /// Validates a URL string
    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
}