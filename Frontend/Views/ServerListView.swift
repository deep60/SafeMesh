//
//  ServiceListView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ServerListView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil

    private var filteredServers: [VPNServer] {
        var servers = viewModel.servers

        if !searchText.isEmpty {
            servers = servers.filter { server in
                server.city.localizedCaseInsensitiveContains(searchText) ||
                server.country.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let region = selectedRegion {
            servers = servers.filter { $0.region.rawValue == region }
        }

        return servers
    }

    private var regions: [String] {
        Array(Set(viewModel.servers.map { $0.region.rawValue })).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Region filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(title: "All", isSelected: selectedRegion == nil)
                        {
                            selectedRegion = nil
                        }

                        ForEach(regions, id: \.self) { region in
                            FilterChip(title: region, isSelected: selectedRegion == region) {
                                selectedRegion = region
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                // Server list
                if viewModel.isLoading {
                    Spacer()
                    LoadingView(message: "Loading servers...")
                    Spacer()
                } else if filteredServers.isEmpty {
                    EmptyStateView(
                        icon: "server.rack",
                        title: "No servers found",
                        message: "Try a different search or filter"
                    )
                } else {
                    List(filteredServers) { server in
                        ServerCard(
                            server: server,
                            isSelected: viewModel.selectedServer?.id == server.id
                        ) {
                            viewModel.selectServer(server)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Server")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshServers()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.sortByLatency()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.loadServers()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .foregroundColor(Theme.Colors.neonCyan)
                .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)

            TextField("LOCATE NODE...", text: $text)
                .techFont(.body)
                .foregroundColor(.white)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.neonMagenta)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .themedCard(
            borderColor: Theme.Colors.neonCyan.opacity(0.5),
            borderWidth: 1
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title.uppercased())
                .techFont(.subheadline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.neonCyan.opacity(0.2) : Theme.Colors.secondaryBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Theme.Colors.neonCyan : Theme.Colors.statusGray, lineWidth: isSelected ? 2 : 1)
                )
                .foregroundColor(isSelected ? Theme.Colors.neonCyan : .white)
                .neonGlow(color: isSelected ? Theme.Colors.neonCyan : .clear, radius: .sm)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Theme.Colors.neonMagenta)
                .neonGlow(color: Theme.Colors.neonMagenta, radius: .md)

            Text(title.uppercased())
                .techFont(.headline)
                .foregroundColor(.white)
                .tracking(2)

            Text(message.uppercased())
                .techFont(.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ServerListView()
}
