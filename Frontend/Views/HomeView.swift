//
//  HomeView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = VPNViewModel()
    @State private var showServerSelector = false

    var body: some View {
        ZStack {
            // Alien background gradient
            Theme.primaryGradient(isConnected: viewModel.status.isConnected)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Futuristic HUD Header
                    VStack(spacing: 8) {
                        Text("M E S H   U P L I N K")
                            .techFont(.caption2)
                            .foregroundColor(Theme.Colors.neonCyan.opacity(0.8))
                            .tracking(4)
                        
                        StatusIndicator(status: viewModel.status)
                    }
                    .padding(.horizontal)

                    // Alien Interface Core (Button & Server)
                    VStack(spacing: 24) {
                        ConnectionButton(
                            isConnected: viewModel.status.isConnected,
                            isConnecting: viewModel.isConnecting,
                            isDisconnecting: viewModel.isDisconnecting,
                            onTap: {
                                viewModel.toggleConnection()
                            }
                        )
                        .padding(.horizontal, 40)

                        // Current node config
                        if let currentServer = viewModel.currentServer {
                            ServerCard(server: currentServer, isSelected: true) {
                                showServerSelector = true
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer(minLength: 20)

                    // Telemetry
                    if viewModel.status.isConnected {
                        ConnectionStatsView(viewModel: viewModel)
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showServerSelector) {
            ServerListView()
                .preferredColorScheme(.dark)
        }
        .task {
            // Load server info asynchronously to avoid blocking UI
            await viewModel.loadCurrentServer()
        }
    }
}

struct ConnectionStatsView: View {
    @ObservedObject var viewModel: VPNViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "arrow.down.to.line.alt",
                    title: "DOWNLINK",
                    value: formatBytes(viewModel.downloadBytes),
                    color: Theme.Colors.neonLime
                )

                StatCard(
                    icon: "arrow.up.to.line.alt",
                    title: "UPLINK",
                    value: formatBytes(viewModel.uploadBytes),
                    color: Theme.Colors.neonCyan
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    icon: "timelapse",
                    title: "UPTIME",
                    value: viewModel.connectedDuration,
                    color: Theme.Colors.neonMagenta
                )

                StatCard(
                    icon: "network",
                    title: "G-NODE IP",
                    value: viewModel.currentIP ?? "AWAITING...",
                    color: Theme.Colors.neonOrange
                )
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2.weight(.light))
                .foregroundColor(color)
                .neonGlow(color: color, radius: .sm)

            Text(title)
                .techFont(.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
                .tracking(2)

            Text(value)
                .techFont(.headline)
                .foregroundColor(Theme.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .themedCard(
            borderColor: color.opacity(0.3),
            borderWidth: 1,
            glowColor: color.opacity(0.1),
            glowRadius: 10
        )
    }
}

#Preview {
    HomeView()
}
