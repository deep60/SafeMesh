//
//  AuthViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var showEmailVerificationAlert: Bool = false

    // MARK: - Private Properties
    private let apiClient: APIClientProtocol
    private let secureStorage: SecureStorageProtocol
    private let authManager: AuthManaging
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        secureStorage: SecureStorageProtocol = SecureStorage.shared,
        authManager: AuthManaging = AuthManager.shared
    ) {
        self.apiClient = apiClient
        self.secureStorage = secureStorage
        self.authManager = authManager

        checkAuthenticationStatus()
    }

    // MARK: - Public Methods
    func login(email: String, password: String) {
        Task {
            await performLogin(email: email, password: password)
        }
    }

    func signup(name: String, email: String, password: String) {
        Task {
            await performSignup(name: name, email: email, password: password)
        }
    }

    func logout() {
        Task {
            await performLogout()
        }
    }

    func signInWithApple() {
        // Implement Apple Sign In
        Task {
            isLoading = true

            // Mock implementation
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let mockUser = User.mock
            await handleSuccessfulAuth(user: mockUser, token: "mock_token")

            isLoading = false
        }
    }

    func signInWithGoogle() {
        // Implement Google Sign In
        Task {
            isLoading = true

            // Mock implementation
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let mockUser = User.mockPremium
            await handleSuccessfulAuth(user: mockUser, token: "mock_token_google")

            isLoading = false
        }
    }

    func forgotPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Call API to send reset email
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/auth/forgot-password",
            method: .post,
            body: ForgotPasswordRequest(email: email)
        )
    }

    func resetPassword(token: String, newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/auth/reset-password",
            method: .post,
            body: ResetPasswordRequest(token: token, newPassword: newPassword)
        )
    }

    func refreshToken() async throws {
        guard let refreshToken = secureStorage.load(key: .refreshToken) else {
            throw AuthError.notAuthenticated
        }

        let response: RefreshTokenResponse = try await apiClient.request(
            endpoint: "/auth/refresh",
            method: .post,
            body: RefreshTokenRequest(refreshToken: refreshToken)
        )

        secureStorage.save(key: .accessToken, value: response.token)
        authManager.updateToken(response.token)
    }

    // MARK: - Private Methods
    private func checkAuthenticationStatus() {
        // In mock mode, auto-authenticate with mock user
        if AppConfiguration.useMockData {
            self.user = User.mock
            self.isAuthenticated = true
            return
        }

        if let token = secureStorage.load(key: .accessToken) {
            authManager.updateToken(token)

            // Validate token and load user
            Task {
                await loadCurrentUser()
            }
        }
    }

    private func performLogin(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        if AppConfiguration.useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let mockUser = User.mock
            await handleSuccessfulAuth(user: mockUser, token: "mock_token")
            isLoading = false
            return
        }

        do {
            let request = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await apiClient.request(
                endpoint: "/auth/login",
                method: .post,
                body: request
            )

            await handleSuccessfulAuth(response: response)

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    private func performSignup(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = SignupRequest(name: name, email: email, password: password)
            let response: AuthResponse = try await apiClient.request(
                endpoint: "/auth/signup",
                method: .post,
                body: request
            )

            if !response.user.isEmailVerified {
                showEmailVerificationAlert = true
            }

            await handleSuccessfulAuth(response: response)

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    private func performLogout() async {
        do {
            let _: EmptyResponse = try await apiClient.request(
                endpoint: "/auth/logout",
                method: .post,
                body: nil
            )
        } catch {
            // Ignore logout errors
        }

        clearAuthData()
    }

    private func loadCurrentUser() async {
        do {
            let response: APIResponse<User> = try await apiClient.request(
                endpoint: "/user/me",
                method: .get,
                body: nil
            )

            if let user = response.data {
                withAnimation {
                    self.user = user
                    self.isAuthenticated = true
                }
            }
        } catch {
            // Token might be expired
            clearAuthData()
        }
    }

    private func handleSuccessfulAuth(response: AuthResponse) async {
        await handleSuccessfulAuth(user: response.user, token: response.token)
    }

    private func handleSuccessfulAuth(user: User, token: String) async {
        // Save credentials
        secureStorage.save(key: .accessToken, value: token)

        withAnimation {
            self.user = user
            self.isAuthenticated = true
        }

        // Load subscription and other data
        await loadUserData()
    }

    private func loadUserData() async {
        // Load user profile, subscription, etc.
        // This would be expanded in a real app
    }

    private func clearAuthData() {
        secureStorage.delete(key: .accessToken)
        secureStorage.delete(key: .refreshToken)
        authManager.clearToken()

        withAnimation {
            self.user = nil
            self.isAuthenticated = false
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let name: String
    let email: String
    let password: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case invalidCredentials
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You are not authenticated"
        case .tokenExpired: return "Your session has expired"
        case .invalidCredentials: return "Invalid email or password"
        case .emailNotVerified: return "Please verify your email address"
        }
    }
}

// MARK: - Protocols
protocol AuthManaging {
    func updateToken(_ token: String)
    func clearToken()
    var currentToken: String? { get }
}

// MARK: - Mock Implementations
class MockSecureStorage: SecureStorageProtocol {
    static let shared = MockSecureStorage()

    private var storage: [String: String] = [:]

    func save(key: SecureKey, value: String) {
        storage[key.rawValue] = value
    }

    func load(key: SecureKey) -> String? {
        storage[key.rawValue]
    }

    func delete(key: SecureKey) {
        storage.removeValue(forKey: key.rawValue)
    }
}

class AuthManager: AuthManaging {
    static let shared = AuthManager()

    private(set) var currentToken: String?

    func updateToken(_ token: String) {
        currentToken = token
    }

    func clearToken() {
        currentToken = nil
    }
}


