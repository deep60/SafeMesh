//
//  ServerViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ServerViewModel: ObservableObject {
    // MARK: Published properties
    @Published var servers: [VPNServer] = []
    @Published var selectedServer: VPNServer?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorMessage: Bool = false
    @Published var selectedRegion: String? = nil
    @Published var searchText: String = ""
    
    // MARK: Private properties
    private let apiClient: APIClientProtocol
    private let configManager: ConfigManaging
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Computed Properties
    var filteredServers: [VPNServer] {
        var result = servers
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { server in
                server.city.localizedCaseInsensitiveContains(searchText) ||
                server.country.localizedCaseInsensitiveContains(searchText) ||
                server.region.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by region
        if let region = selectedRegion {
            result = result.filter { $0.region.rawValue == region }
        }
        
        return result.sorted { $0.latency < $1.latency }
    }
    
    var regions: [String] {
        Array(Set(servers.map { $0.region.rawValue })).sorted()
    }
    
    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        configManager: ConfigManaging = ConfigManager.shared
    ) {
        self.apiClient = apiClient
        self.configManager = configManager

        setupSearchObserver()
    }
    
    // MARK: - Setup
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadServers() async {
        isLoading = true
        errorMessage = nil

        // When the local backend is not running use mock data directly to avoid DNS errors.
        if AppConfiguration.useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // brief delay to simulate loading
            withAnimation {
                self.servers = VPNServer.mockServers
                self.loadSelectedServer()
            }
            isLoading = false
            return
        }

        do {
            let response: ServersListResponse = try await apiClient.request(
                endpoint: "/servers",
                method: .get,
                body: nil
            )

            withAnimation {
                self.servers = response.servers
                self.loadSelectedServer()
            }

        } catch {
            // Graceful fallback to mock data on network failure
            withAnimation {
                self.servers = VPNServer.mockServers
                self.loadSelectedServer()
            }
        }

        isLoading = false
    }

    func refreshServers() async {
        await loadServers()
    }

    func selectServer(_ server: VPNServer) {
        withAnimation {
            selectedServer = server
            configManager.saveSelectedServerId(server.id)
        }
    }

    func sortByLatency() {
        withAnimation {
            servers.sort { $0.latency < $1.latency }
        }
    }

    func sortByLoad() {
        withAnimation {
            servers.sort { $0.loadPercentage < $1.loadPercentage }
        }
    }

    func sortByRegion() {
        withAnimation {
            servers.sort { $0.region.rawValue < $1.region.rawValue }
        }
    }

    func pingServers() async {
        withAnimation {
            // Simulate pinging
            for index in servers.indices {
                let randomLatency = Int.random(in: 30...300)
                servers[index] = VPNServer(
                    id: servers[index].id,
                    name: servers[index].name,
                    city: servers[index].city,
                    country: servers[index].country,
                    countryCode: servers[index].countryCode,
                    region: servers[index].region,
                    ipAddress: servers[index].ipAddress,
                    port: servers[index].port,
                    publicKey: servers[index].publicKey,
                    endpoint: servers[index].endpoint,
                    dnsServers: servers[index].dnsServers,
                    latency: randomLatency,
                    loadPercentage: servers[index].loadPercentage,
                    isActive: servers[index].isActive,
                    isPremium: servers[index].isPremium,
                    protocols: servers[index].protocols
                )
            }
        }
    }

    func getRecommendedServers(count: Int = 3) -> [VPNServer] {
        servers.filter { $0.isRecommended }.prefix(count).map { $0 }
    }

    // MARK: - Private Methods
    private func loadSelectedServer() {
        let serverId = configManager.loadSelectedServerId()
        selectedServer = servers.first { $0.id == serverId }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showErrorMessage = true
    }
}

// MARK: Mock API Client
class MockAPIClient: APIClientProtocol {
    static let shared = MockAPIClient()
    
    func request<T: Codable>(endpoint: String, method: HTTPMethod, body: Encodable? = nil) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))
        
        // Return mock response based on endpoint
        if endpoint == "/servers" {
            let response = ServersListResponse(servers: VPNServer.mockServers, lastUpdated: Date())
            return response as! T
        }
        
        throw APIError(code: "not_found", message: "Endpoint not found", details: nil)
    }
}
