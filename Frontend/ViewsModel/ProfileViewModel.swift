//
//  ProfileViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User = User.mock
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var memberSince: String = ""
    @Published var subscriptionPlan: String = "Free"
    @Published var subscriptionStatus: String = "Active"
    @Published var subscriptionExpiry: String?
    @Published var dataUsed: String = "0 GB"
    @Published var dataRemaining: String = "10 GB"
    @Published var showDeleteAlert: Bool = false

    // MARK: - Computed Properties
    var userInitials: String {
        userName.components(separatedBy: " ")
            .map { $0.first?.uppercased() ?? "" }
            .joined()
    }

    var hasSubscription: Bool {
        subscriptionPlan != "Free"
    }

    var subscriptionStatusColor: Color {
        switch subscriptionStatus.lowercased() {
        case "active": return .green
        case "past due": return .orange
        case "canceled", "expired": return .red
        default: return .gray
        }
    }

    var usagePercentage: Double {
        // Calculate from actual usage
        return 0.5 // Mock value
    }

    var usageColor: Color {
        if usagePercentage < 0.5 { return .green }
        if usagePercentage < 0.8 { return .orange }
        return .red
    }

    var dataRemainingColor: Color {
        hasSubscription ? .green : .gray
    }

    // MARK: - Private Properties
    private let apiClient: APIClientProtocol
    private var authViewModel: AuthViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        authViewModel: AuthViewModel? = nil
    ) {
        self.apiClient = apiClient
        self.authViewModel = authViewModel

        setupObservers()
        Task {
            await loadUserProfile()
        }
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observers setup for authViewModel if available
    }

    // MARK: - Public Methods
    func refreshProfile() async {
        await loadUserProfile()
    }

    func updateProfile(name: String, email: String) async throws {
        let request = UserProfileUpdate(name: name, avatarURL: nil)

        let response: APIResponse<User> = try await apiClient.request(
            endpoint: "/user/profile",
            method: .patch,
            body: request
        )

        if let updatedUser = response.data {
            user = updatedUser
            updateUserDisplayInfo()
        }
    }

    func deleteAccount() {
        showDeleteAlert = true
    }

    func confirmDeleteAccount() {
        Task {
            do {
                let _: EmptyResponse = try await apiClient.request(
                    endpoint: "/user/delete",
                    method: .delete,
                    body: nil
                )

                // Logout after deletion
                authViewModel?.logout()

            } catch {
                print("Failed to delete account: \(error)")
            }
        }
    }

    func refreshSubscription() async {
        // Reload subscription data
        await loadUserProfile()
    }

    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            let response: APIResponse<User> = try await apiClient.request(
                endpoint: "/user/me",
                method: .get,
                body: nil
            )

            if let loadedUser = response.data {
                user = loadedUser
                updateUserDisplayInfo()
            }

        } catch {
            // Use cached data or mock
            if let cachedUser = authViewModel?.user {
                user = cachedUser
                updateUserDisplayInfo()
            }
        }
    }

    private func updateUserDisplayInfo() {
        userName = user.name
        userEmail = user.email
        memberSince = formatDate(user.createdAt)

        // Update subscription info (would come from API)
        loadSubscriptionInfo()
        loadUsageInfo()
    }

    private func loadSubscriptionInfo() {
        // In a real app, fetch from API
        subscriptionPlan = "Free"
        subscriptionStatus = "Active"
        subscriptionExpiry = nil
    }

    private func loadUsageInfo() {
        // In a real app, fetch from API
        dataUsed = "2.5 GB"
        dataRemaining = "7.5 GB"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Profile Edit ViewModel
class ProfileEditViewModel: ObservableObject {
    @Published var name: String
    @Published var email: String
    @Published var avatarURL: String?
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let profileViewModel: ProfileViewModel
    private let apiClient: APIClientProtocol

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self.apiClient = APIClient.shared
        self.name = profileViewModel.userName
        self.email = profileViewModel.userEmail
    }

    func saveChanges() async {
        guard !name.isEmpty, !email.isEmpty else {
            showError(error: "Name and email are required")
            return
        }

        guard isValidEmail(email) else {
            showError(error: "Please enter a valid email address")
            return
        }

        isSaving = true

        do {
            try await profileViewModel.updateProfile(name: name, email: email)
            isSaving = false
        } catch {
            isSaving = false
            showError(error: error.localizedDescription)
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func showError(error: String) {
        errorMessage = error
        showError = true
    }
}

