//
//  SettingsView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showAbout = false
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 50, height: 50)

                                Text(String(viewModel.userInitials))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.userName)
                                    .font(.headline)

                                Text(viewModel.userEmail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // VPN Settings
                Section("VPN Settings") {
                    Toggle("Auto-connect on launch", isOn: $viewModel.autoConnect)
                    Toggle("Kill Switch", isOn: $viewModel.killSwitch)
                    Toggle("Block LAN traffic", isOn: $viewModel.blockLAN)

                    NavigationLink {
                        ProtocolSelectionView(selectedVPNProtocol: $viewModel.vpnProtocol)
                    } label: {
                        HStack {
                            Text("Protocol")
                            Spacer()
                            Text(viewModel.vpnProtocol.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        DNSSettingsView()
                    } label: {
                        HStack {
                            Text("DNS Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // General Settings
                Section("General") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack {
                            Text("Appearance")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        HStack {
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Support
                Section("Support") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Subscription")
                        }
                    }

                    Button {
                        // Open help
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("Help Center")
                            Spacer()
                            Image(systemName: "externalLink")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        // Contact support
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "externalLink")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        // Privacy policy
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

struct ProtocolSelectionView: View {
    @Binding var selectedVPNProtocol: VPNProtocol  // Uses the global VPNProtocol enum
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(VPNProtocol.allCases) { item in
                Button {
                    selectedVPNProtocol = item
                } label: {
                    HStack {
                        Text(item.rawValue)
                        Spacer()
                        if selectedVPNProtocol == item {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Protocol")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DNSSettingsView: View {
    @State private var useCustomDNS = false
    @State private var customDNS = ""

    var body: some View {
        Form {
            Section {
                Toggle("Use Custom DNS", isOn: $useCustomDNS)

                if useCustomDNS {
                    TextField("DNS Server", text: $customDNS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("DNS Configuration")
            } footer: {
                Text("Default DNS servers protect your privacy. Only change this if you know what you're doing.")
            }

            Section("Recommended DNS") {
                DNSRow(name: "Cloudflare", server: "1.1.1.1") {
                    customDNS = "1.1.1.1"
                }
                DNSRow(name: "Google", server: "8.8.8.8") {
                    customDNS = "8.8.8.8"
                }
                DNSRow(name: "OpenDNS", server: "208.67.222.222") {
                    customDNS = "208.67.222.222"
                }
            }
        }
        .navigationTitle("DNS Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DNSRow: View {
    let name: String
    let server: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(name)
                Spacer()
                Text(server)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var theme: AppTheme = .system

    enum AppTheme: String, CaseIterable, Identifiable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var id: String { rawValue }
    }

    var body: some View {
        List {
            ForEach(AppTheme.allCases) { option in
                Button {
                    theme = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        Spacer()
                        if theme == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationsSettingsView: View {
    @State private var enableNotifications = true
    @State private var notifyDisconnection = true
    @State private var notifyReconnection = true

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $enableNotifications)
            }

            if enableNotifications {
                Section {
                    Toggle("Notify on disconnection", isOn: $notifyDisconnection)
                    Toggle("Notify on reconnection", isOn: $notifyReconnection)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)

                        Image(systemName: "shield.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    // App name
                    VStack(spacing: 4) {
                        Text("SafeMesh")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Version \(version) (Build \(build))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Developed by", value: "SafeMesh Inc.")
                        InfoRow(title: "Protocol", value: "WireGuard")
                        InfoRow(title: "Encryption", value: "ChaCha20-Poly1305")
                    }

                    Divider()

                    // Links
                    VStack(spacing: 16) {
                        LinkRow(icon: "globe", title: "Website", url: "https://safemesh.com")
                        LinkRow(icon: "twitter", title: "Twitter", url: "https://twitter.com/safemesh")
                        LinkRow(icon: "envelope", title: "Support", url: "mailto:support@safemesh.com")
                    }

                    // Copyright
                    Text("© 2026 SafeMesh Inc. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    SettingsView()
}

