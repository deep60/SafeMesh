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
            // Background gradient
            LinearGradient(
                colors: viewModel.status.isConnected
                    ? [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]
                    : [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Status indicator
                    StatusIndicator(status: viewModel.status)
                        .padding(.horizontal)

                    // Connection button
                    VStack(spacing: 20) {
                        ConnectionButton(
                            isConnected: viewModel.status.isConnected,
                            isConnecting: viewModel.isConnecting,
                            isDisconnecting: viewModel.isDisconnecting,
                            onTap: {
                                viewModel.toggleConnection()
                            }
                        )
                        .padding(.horizontal, 24)

                        // Current server info
                        if let currentServer = viewModel.currentServer {
                            ServerCard(server: currentServer, isSelected: true) {
                                showServerSelector = true
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer(minLength: 20)

                    // Connection stats
                    if viewModel.status.isConnected {
                        ConnectionStatsView(viewModel: viewModel)
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showServerSelector) {
            ServerListView()
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
            HStack {
                StatCard(
                    icon: "arrow.down.circle.fill",
                    title: "Download",
                    value: formatBytes(viewModel.downloadBytes),
                    color: .green
                )

                StatCard(
                    icon: "arrow.up.circle.fill",
                    title: "Upload",
                    value: formatBytes(viewModel.uploadBytes),
                    color: .blue
                )
            }

            HStack {
                StatCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: viewModel.connectedDuration,
                    color: .purple
                )

                StatCard(
                    icon: "location.fill",
                    title: "IP Address",
                    value: viewModel.currentIP ?? "Unknown",
                    color: .orange
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4)
        )
    }
}

#Preview {
    HomeView()
}
