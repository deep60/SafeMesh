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
        List {
            // Profile header
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .strokeBorder(Theme.Colors.neonCyan.opacity(0.8), lineWidth: 2)
                            .background(Circle().fill(Theme.Colors.secondaryBackground))
                            .frame(width: 80, height: 80)
                            .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)

                        Text(String(viewModel.userInitials))
                            .techFont(.title)
                            .foregroundColor(Theme.Colors.neonCyan)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userName.uppercased())
                            .techFont(.title2)
                            .foregroundColor(.white)
                            .tracking(2)

                        Text(viewModel.userEmail.uppercased())
                            .techFont(.subheadline)
                            .foregroundColor(Theme.Colors.neonCyan.opacity(0.8))
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            // User info
            Section(header: Text("OPERATIVE DATA").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                HStack {
                    Text("DESIGNATION")
                    Spacer()
                    Text(viewModel.userName.uppercased())
                        .foregroundColor(Theme.Colors.neonCyan)
                }

                HStack {
                    Text("CREDENTIAL")
                    Spacer()
                    Text(viewModel.userEmail.uppercased())
                        .foregroundColor(Theme.Colors.neonCyan)
                }

                HStack {
                    Text("INITIALIZED")
                    Spacer()
                    Text(viewModel.memberSince.uppercased())
                        .foregroundColor(Theme.Colors.neonCyan)
                }
            }
            .listRowBackground(Theme.Colors.secondaryBackground)
            .font(Theme.Typography.body.font.monospaced())
            .foregroundColor(.white)

            // Subscription
            Section(header: Text("CLEARANCE LEVEL").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.subscriptionPlan.uppercased())
                            .techFont(.headline)
                        Text(viewModel.subscriptionStatus.uppercased())
                            .techFont(.caption)
                            .foregroundColor(viewModel.subscriptionStatusColor)
                    }

                    Spacer()

                    if viewModel.hasSubscription {
                        Button {
                            // Manage subscription
                        } label: {
                            Text("MANAGE")
                                .techFont(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.neonCyan.opacity(0.2))
                                .foregroundColor(Theme.Colors.neonCyan)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Theme.Colors.neonCyan, lineWidth: 1)
                                )
                                .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)
                        }
                    }
                }

                if let expiryDate = viewModel.subscriptionExpiry {
                    HStack {
                        Text("RENEWAL CYCLE")
                        Spacer()
                        Text(expiryDate.uppercased())
                            .foregroundColor(Theme.Colors.neonCyan)
                    }
                }

                if !viewModel.hasSubscription {
                    Button {
                        // Upgrade
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Theme.Colors.neonOrange)
                                .neonGlow(color: Theme.Colors.neonOrange, radius: .sm)
                            Text("ELEVATE CLEARANCE")
                                .foregroundColor(Theme.Colors.neonOrange)
                        }
                    }
                }
            }
            .listRowBackground(Theme.Colors.secondaryBackground)
            .font(Theme.Typography.body.font.monospaced())
            .foregroundColor(.white)

            // Usage stats
            Section(header: Text("BANDWIDTH TELEMETRY").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRANSMITTED")
                            .techFont(.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text(viewModel.dataUsed.uppercased())
                            .techFont(.headline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ALLOCATION")
                            .techFont(.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text(viewModel.dataRemaining.uppercased())
                            .techFont(.headline)
                            .foregroundColor(viewModel.dataRemainingColor)
                            .neonGlow(color: viewModel.dataRemainingColor, radius: .sm)
                    }
                }

                ProgressView(value: viewModel.usagePercentage)
                    .tint(viewModel.usageColor)
            }
            .listRowBackground(Theme.Colors.secondaryBackground)
            .font(Theme.Typography.body.font.monospaced())
            .foregroundColor(.white)

            // Account actions
            Section(header: Text("SYSTEM CONTROLS").techFont(.footnote).foregroundColor(Theme.Colors.neonCyan)) {
                Button {
                    showEditProfile = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("MODIFY RECORD")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.Colors.neonCyan)
                    }
                }

                Button {
                    showChangePassword = true
                } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("ROTATE PASSPHRASE")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.Colors.neonCyan)
                    }
                }

                Button {
                    viewModel.deleteAccount()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(Theme.Colors.neonMagenta)
                            .neonGlow(color: Theme.Colors.neonMagenta, radius: .sm)
                        Text("PURGE RECORD")
                            .foregroundColor(Theme.Colors.neonMagenta)
                    }
                }
            }
            .listRowBackground(Theme.Colors.secondaryBackground)
            .font(Theme.Typography.body.font.monospaced())
            .foregroundColor(.white)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.primaryBackground)
        .navigationTitle("OPERATIVE")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: viewModel.user)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .preferredColorScheme(.dark)
        }
        .alert("PURGE RECORD", isPresented: $viewModel.showDeleteAlert) {
            Button("ABORT", role: .cancel) {}
            Button("CONFIRM PURGE", role: .destructive) {
                viewModel.confirmDeleteAccount()
            }
        } message: {
            Text("WARNING: ENTITY DATA WILL BE IRREVERSIBLY ERASED FROM THE MESH.")
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
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        NeonTextField(title: "DESIGNATION (NAME)", placeholder: "INPUT DATA...", text: $name, icon: "person.fill")
                        
                        NeonTextField(title: "CREDENTIAL (EMAIL)", placeholder: "INPUT DATA...", text: $email, icon: "terminal")
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Button {
                        // Save
                        dismiss()
                    } label: {
                        Text("COMMIT CHANGES")
                            .techFont(.headline)
                            .tracking(2)
                            .foregroundColor(Theme.Colors.primaryBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.buttonGradient(color: Theme.Colors.neonCyan))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                            .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("MODIFY RECORD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.Colors.neonCyan)
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
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
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
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        NeonSecureField(title: "CURRENT PASSPHRASE", placeholder: "INPUT DATA...", text: $currentPassword, isVisible: $showCurrentPassword)
                        NeonSecureField(title: "NEW PASSPHRASE", placeholder: "INPUT DATA...", text: $newPassword, isVisible: $showNewPassword)
                        NeonSecureField(title: "CONFIRM NEW PASSPHRASE", placeholder: "INPUT DATA...", text: $confirmPassword, isVisible: $showConfirmPassword)
                        
                        if let error = errorMessage {
                            Text(error.uppercased())
                                .techFont(.caption)
                                .foregroundColor(Theme.Colors.neonMagenta)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else if newPassword != confirmPassword && !confirmPassword.isEmpty {
                            Text("MISMATCH DETECTED")
                                .techFont(.caption)
                                .foregroundColor(Theme.Colors.neonMagenta)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("MINIMUM 8 CHARACTERS REQUIRED")
                                .techFont(.caption2)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Button {
                        // Change password
                        showSuccess = true
                    } label: {
                        Text("ROTATE KEY")
                            .techFont(.headline)
                            .tracking(2)
                            .foregroundColor(Theme.Colors.primaryBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.buttonGradient(color: Theme.Colors.neonCyan))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                            .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)
                            .opacity(isValid ? 1.0 : 0.5)
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, 24)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("ROTATE PASSPHRASE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.Colors.neonCyan)
                    }
                }
            }
            .alert("KEY ROTATION SUCCESS", isPresented: $showSuccess) {
                Button("ACKNOWLEDGE") { dismiss() }
            } message: {
                Text("PASSPHRASE HAS BEEN SUCCESSFULLY UPDATED IN THE SYSTEM.")
            }
        }
    }
}

#Preview {
    ProfileView()
}

