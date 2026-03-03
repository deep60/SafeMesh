//
//  ProfileView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showChangePassword = false

    var body: some View {
        Form {
            // Profile header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)

                        Text(String(viewModel.userInitials))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userName)
                            .font(.headline)

                        Text(viewModel.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // User info
            Section("Account Information") {
                HStack {
                    Text("Username")
                    Spacer()
                    Text(viewModel.userName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Email")
                    Spacer()
                    Text(viewModel.userEmail)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Member Since")
                    Spacer()
                    Text(viewModel.memberSince)
                        .foregroundColor(.secondary)
                }
            }

            // Subscription
            Section("Subscription") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.subscriptionPlan)
                            .font(.headline)
                        Text(viewModel.subscriptionStatus)
                            .font(.caption)
                            .foregroundColor(viewModel.subscriptionStatusColor)
                    }

                    Spacer()

                    if viewModel.hasSubscription {
                        Button {
                            // Manage subscription
                        } label: {
                            Text("Manage")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }

                if let expiryDate = viewModel.subscriptionExpiry {
                    HStack {
                        Text("Renews on")
                        Spacer()
                        Text(expiryDate)
                            .foregroundColor(.secondary)
                    }
                }

                if !viewModel.hasSubscription {
                    Button {
                        // Upgrade
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Upgrade to Premium")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            // Usage stats
            Section("Usage This Month") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Used")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.dataUsed)
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.dataRemaining)
                            .font(.headline)
                            .foregroundColor(viewModel.dataRemainingColor)
                    }
                }

                ProgressView(value: viewModel.usagePercentage)
                    .tint(viewModel.usageColor)
            }

            // Account actions
            Section("Account") {
                Button {
                    showEditProfile = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    showChangePassword = true
                } label: {
                    HStack {
                        Image(systemName: "lock")
                        Text("Change Password")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    viewModel.deleteAccount()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: viewModel.user)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.confirmDeleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    @State private var name: String
    @State private var email: String

    init(user: User) {
        self.user = user
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }

                Section {
                    Button("Save Changes") {
                        // Save
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                } header: {
                    Text("Password must be at least 8 characters")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Change Password") {
                        // Change password
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }
}

#Preview {
    ProfileView()
}

