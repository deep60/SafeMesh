//
//  SettingsViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var appVersion: String = ""

    // VPN Settings
    @Published var autoConnect: Bool = false
    @Published var killSwitch: Bool = true
    @Published var blockLAN: Bool = false
    @Published var vpnProtocol: VPNProtocol = .wireGuard

    // Appearance
    @Published var theme: AppTheme = .system

    // Notifications
    @Published var notificationsEnabled: Bool = true
    @Published var notifyOnDisconnection: Bool = true
    @Published var notifyOnReconnection: Bool = false

    // Computed Properties
    var userInitials: String {
        userName.components(separatedBy: " ")
            .map { $0.first?.uppercased() ?? "" }
            .joined()
    }

    // MARK: - Private Properties
    private let userDefaults: UserDefaults
    private var authViewModel: AuthViewModel?

    // MARK: - Initialization
    init(
        userDefaults: UserDefaults = .standard,
        authViewModel: AuthViewModel? = nil
    ) {
        self.userDefaults = userDefaults
        self.authViewModel = authViewModel

        loadSettings()
        loadUserInfo()
        loadAppVersion()
    }

    // MARK: - Public Methods
    func logout() {
        authViewModel?.logout()
    }

    func updateAutoConnect(_ enabled: Bool) {
        autoConnect = enabled
        saveSetting(key: "autoConnect", value: enabled)
    }

    func updateKillSwitch(_ enabled: Bool) {
        killSwitch = enabled
        saveSetting(key: "killSwitch", value: enabled)
    }

    func updateBlockLAN(_ enabled: Bool) {
        blockLAN = enabled
        saveSetting(key: "blockLAN", value: enabled)
    }

    func updateProtocol(_ newProtocol: VPNProtocol) {
        vpnProtocol = newProtocol
        saveSetting(key: "protocol", value: newProtocol.rawValue)
    }

    func updateTheme(_ newTheme: AppTheme) {
        theme = newTheme
        saveSetting(key: "theme", value: newTheme.rawValue)
        applyTheme()
    }

    func resetToDefaults() {
        autoConnect = false
        killSwitch = true
        blockLAN = false
        vpnProtocol = .wireGuard
        theme = .system
        notificationsEnabled = true
        notifyOnDisconnection = true
        notifyOnReconnection = false

        // Save all defaults
        userDefaults.set(autoConnect, forKey: "autoConnect")
        userDefaults.set(killSwitch, forKey: "killSwitch")
        userDefaults.set(blockLAN, forKey: "blockLAN")
        userDefaults.set(vpnProtocol.rawValue, forKey: "protocol")
        userDefaults.set(theme.rawValue, forKey: "theme")
        userDefaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        userDefaults.set(notifyOnDisconnection, forKey: "notifyOnDisconnection")
        userDefaults.set(notifyOnReconnection, forKey: "notifyOnReconnection")
    }

    func clearAllData() {
        // Clear all settings
        resetToDefaults()

        // Clear cached data
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
    }

    // MARK: - Private Methods
    private func loadSettings() {
        autoConnect = userDefaults.bool(forKey: "autoConnect")
        killSwitch = userDefaults.object(forKey: "killSwitch") as? Bool ?? true
        blockLAN = userDefaults.bool(forKey: "blockLAN")

        if let protocolString = userDefaults.string(forKey: "protocol"),
           let proto = VPNProtocol(rawValue: protocolString) {
            vpnProtocol = proto
        }

        if let themeString = userDefaults.string(forKey: "theme"),
           let themeValue = AppTheme(rawValue: themeString) {
            theme = themeValue
        }

        notificationsEnabled = userDefaults.object(forKey: "notificationsEnabled")
as? Bool ?? true
        notifyOnDisconnection = userDefaults.bool(forKey: "notifyOnDisconnection")
        notifyOnReconnection = userDefaults.bool(forKey: "notifyOnReconnection")
    }

    private func loadUserInfo() {
        if let user = authViewModel?.user {
            userName = user.name
            userEmail = user.email
        }
    }

    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = "\(version) (\(build))"
        }
    }

    private func saveSetting<T>(key: String, value: T) {
        userDefaults.set(value, forKey: key)
    }

    private func applyTheme() {
        // Apply theme to the app
        switch theme {
        case .system:
            // Use system setting
            break
        case .light:
            // Force light mode
            break
        case .dark:
            // Force dark mode
            break
        }
    }
}

// MARK: - Theme Manager
class ThemeManager {
    static let shared = ThemeManager()

    func applyTheme(_ theme: AppTheme) {
        switch theme {
        case .system:
            // Let system handle it
            break
        case .light:
            // Set light mode
            break
        case .dark:
            // Set dark mode
            break
        }
    }
}

