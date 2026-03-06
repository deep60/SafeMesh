//
//  APIClient.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import Combine
import Network

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Codable>(endpoint: String, method: HTTPMethod, body: Encodable?) async throws -> T
}

// MARK: - API Client
final class APIClient: ObservableObject, APIClientProtocol {
    // MARK: - Singleton
    static let shared = APIClient()

    // MARK: - Published Properties
    @Published var isConnected: Bool = true
    @Published var lastError: Error?

    // MARK: - Private Properties
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var accessToken: String?
    private let config: AppConfiguration

    // MARK: - Initialization
    private init() {
        self.config = AppConfiguration.shared
        self.baseURL = config.apiBaseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.apiTimeout
        configuration.timeoutIntervalForResource = config.apiTimeout * 2
        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        loadStoredToken()
    }

    // MARK: - Public Methods
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws -> T {
        let request = try createRequest(endpoint: endpoint, method: method, body: body, requiresAuth: true)
        return try await performRequest(request)
    }

    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws -> T {
        let request = try createRequest(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
        return try await performRequest(request)
    }

    func upload<T: Codable>(
        endpoint: String,
        data: Data,
        fieldName: String = "file",
        fileName: String = "upload"
    ) async throws -> T {
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\";filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await performRequest(request)
    }

    func download(from url: String, to destination: URL) async throws {
        let request = URLRequest(url: URL(string: url)!)
        let (tempURL, response) = try await session.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError(code: "download_failed", message: "Download failed", details: nil)
        }

        try FileManager.default.moveItem(at: tempURL, to: destination)
    }

    // MARK: - Token Management
    func setAccessToken(_ token: String) {
        self.accessToken = token
        SecureStorage.shared.save(key: .accessToken, value: token)
    }

    func clearAccessToken() {
        self.accessToken = nil
        SecureStorage.shared.delete(key: .accessToken)
    }

    // MARK: - Private Methods
    private func createRequest(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) throws -> URLRequest {
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            addAuthHeaders(to: &request)
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func addAuthHeaders(to request: inout URLRequest) {
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func performRequest<T: Codable>(_ request: URLRequest) async throws -> T
 {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(code: "invalid_response", message: "Invalid response", details: nil)
        }

        // Handle different status codes
        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 401:
            clearAccessToken()
            throw APIError(code: "unauthorized", message: "Unauthorized", details: nil)
        case 429:
            throw APIError(code: "rate_limited", message: "Too many requests", details: nil)
        case 500...599:
            throw APIError(code: "server_error", message: "Server error", details: nil)
        default:
            let errorBody = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError(
                code: errorBody?.code ?? "unknown",
                message: errorBody?.message ?? "Unknown error",
                details: errorBody?.details
            )
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(code: "decode_error", message: "Failed to decode response", details: [error.localizedDescription])
        }
    }

    private func loadStoredToken() {
        accessToken = SecureStorage.shared.load(key: .accessToken)
    }
}

// MARK: - API Response Models
private struct APIErrorResponse: Codable {
    let code: String
    let message: String
    let details: [String]?
}

/// Empty response type for API calls that don't return data
struct EmptyResponse: Codable {}

//// MARK: - APIClientProtocol Implementation
//extension APIClient: APIClientProtocol {
//    func request<T: Codable>(
//        endpoint: String,
//        method: HTTPMethod,
//        body: Encodable?
//    ) async throws -> T {
//        try await request(endpoint: endpoint, method: method, body: body)
//    }
//}

// MARK: - Network Monitoring
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi, cellular, ethernet, unknown
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .ethernet
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}


