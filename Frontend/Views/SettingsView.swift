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
                                    .strokeBorder(Theme.Colors.neonCyan.opacity(0.8), lineWidth: 2)
                                    .background(Circle().fill(Theme.Colors.secondaryBackground))
                                    .frame(width: 50, height: 50)
                                    .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)

                                Text(String(viewModel.userInitials))
                                    .techFont(.title2)
                                    .foregroundColor(Theme.Colors.neonCyan)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.userName.uppercased())
                                    .techFont(.headline)
                                    .foregroundColor(.white)
                                    .tracking(1)

                                Text(viewModel.userEmail.uppercased())
                                    .techFont(.caption)
                                    .foregroundColor(Theme.Colors.neonCyan.opacity(0.8))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Theme.Colors.secondaryBackground)
                }

                // VPN Settings
                Section(header: Text("UPLINK CONFIG").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                    Toggle("AUTO-CONNECT ON LAUNCH", isOn: $viewModel.autoConnect)
                    Toggle("KILL SWITCH", isOn: $viewModel.killSwitch)
                    Toggle("BLOCK LAN TRAFFIC", isOn: $viewModel.blockLAN)

                    NavigationLink {
                        ProtocolSelectionView(selectedVPNProtocol: $viewModel.vpnProtocol)
                    } label: {
                        HStack {
                            Text("PROTOCOL")
                            Spacer()
                            Text(viewModel.vpnProtocol.rawValue)
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }

                    NavigationLink {
                        DNSSettingsView()
                    } label: {
                        HStack {
                            Text("DNS ROUTING")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.secondaryBackground)
                .font(Theme.Typography.body.font.monospaced())
                .foregroundColor(.white)

                // General Settings
                Section(header: Text("SYSTEM").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        HStack {
                            Text("APPEARANCE")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }

                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        HStack {
                            Text("NOTIFICATIONS")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.secondaryBackground)
                .font(Theme.Typography.body.font.monospaced())
                .foregroundColor(.white)

                // Support
                Section(header: Text("SUPPORT").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Theme.Colors.neonOrange)
                                .neonGlow(color: Theme.Colors.neonOrange, radius: .sm)
                            Text("SUBSCRIPTION")
                        }
                    }

                    Button {
                        // Open help
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("HELP CENTER")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }

                    Button {
                        // Contact support
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                            Text("CONTACT SUPPORT")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.secondaryBackground)
                .font(Theme.Typography.body.font.monospaced())
                .foregroundColor(.white)

                // About
                Section(header: Text("ABOUT").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                    HStack {
                        Text("VERSION")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(Theme.Colors.neonCyan)
                    }

                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Text("TERMS OF SERVICE")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }

                    Button {
                        // Privacy policy
                    } label: {
                        HStack {
                            Text("PRIVACY POLICY")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Theme.Colors.neonCyan)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.secondaryBackground)
                .font(Theme.Typography.body.font.monospaced())
                .foregroundColor(.white)

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Text("TERMINATE SESSION")
                                .techFont(.headline)
                                .foregroundColor(Theme.Colors.neonMagenta)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Theme.Colors.secondaryBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("CONFIG")
            .navigationBarTitleDisplayMode(.large)
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
                        LinkRow(icon: "bird", title: "Twitter", url: "https://twitter.com/safemesh")
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
                .foregroundColor(Theme.Colors.neonCyan)
                .frame(width: 24)

            Text(title.uppercased())
                .techFont(.body)

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .foregroundColor(Theme.Colors.neonCyan)
        }
        .foregroundColor(.white)
    }
}

#Preview {
    SettingsView()
}

