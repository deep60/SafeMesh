//
//  LoginView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignup = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo (Glowing Alien Shield)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .strokeBorder(Theme.Colors.neonCyan.opacity(0.5), lineWidth: 4)
                                .frame(width: 80, height: 80)
                                .neonGlow(color: Theme.Colors.neonCyan, radius: .lg)

                            Image(systemName: "shield.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.Colors.neonCyan)
                                .neonGlow(color: Theme.Colors.neonCyan, radius: .sm)
                        }

                        Text("MESH TERMINAL")
                            .techFont(.title)
                            .foregroundColor(.white)
                            .tracking(4)

                        Text("AUTHENTICATE TO CONTINUE")
                            .techFont(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .tracking(2)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 24) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CREDENTIAL (EMAIL)")
                                .techFont(.subheadline)
                                .foregroundColor(Theme.Colors.neonCyan)

                            HStack {
                                Image(systemName: "terminal")
                                    .foregroundColor(Theme.Colors.neonCyan)
                                    .frame(width: 24)

                                TextField("INPUT DATA...", text: $email)
                                    .techFont(.body)
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .themedCard(borderColor: Theme.Colors.neonCyan.opacity(0.3), borderWidth: 1)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PASSPHRASE")
                                    .techFont(.subheadline)
                                    .foregroundColor(Theme.Colors.neonCyan)

                                Spacer()

                                Button {
                                    showForgotPassword = true
                                } label: {
                                    Text("OVERRIDE?")
                                        .techFont(.caption)
                                        .foregroundColor(Theme.Colors.neonMagenta)
                                        .underline()
                                }
                            }

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Theme.Colors.neonCyan)
                                    .frame(width: 24)

                                if showPassword {
                                    TextField("INPUT DATA...", text: $password)
                                        .techFont(.body)
                                        .foregroundColor(.white)
                                } else {
                                    SecureField("INPUT DATA...", text: $password)
                                        .techFont(.body)
                                        .foregroundColor(.white)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(Theme.Colors.neonCyan)
                                }
                            }
                            .padding()
                            .themedCard(borderColor: Theme.Colors.neonCyan.opacity(0.3), borderWidth: 1)
                        }

                        // Login button
                        Button {
                            viewModel.login(email: email, password: password)
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primaryBackground))
                                } else {
                                    Text("INITIATE UPLINK")
                                        .techFont(.headline)
                                        .tracking(2)
                                }
                            }
                            .foregroundColor(Theme.Colors.primaryBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.buttonGradient(color: Theme.Colors.neonCyan))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                            .neonGlow(color: Theme.Colors.neonCyan, radius: .md)
                        }
                        .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        VStack { Divider().background(Theme.Colors.secondaryText) }
                        Text("OR BYPASS WITH")
                            .techFont(.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        VStack { Divider().background(Theme.Colors.secondaryText) }
                    }
                    .padding(.horizontal, 40)

                    // Social login
                    HStack(spacing: 16) {
                        SocialLoginButton(icon: "applelogo", title: "APPLE") {
                            viewModel.signInWithApple()
                        }

                        SocialLoginButton(icon: "globe", title: "GOOGLE") {
                            viewModel.signInWithGoogle()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign up
                    HStack(spacing: 8) {
                        Text("NO RECORD FOUND?")
                            .techFont(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)

                        Button {
                            showSignup = true
                        } label: {
                            Text("GENERATE KEY")
                                .techFont(.subheadline)
                                .foregroundColor(Theme.Colors.neonLime)
                                .neonGlow(color: Theme.Colors.neonLime, radius: .sm)
                        }
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSignup) {
            SignupView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .preferredColorScheme(.dark)
        }
        .alert("AUTH FAILED", isPresented: $viewModel.showError) {
            Button("ACKNOWLEDGE", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "SYSTEM ERROR")
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .techFont(.subheadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .themedCard(borderColor: .white.opacity(0.2), borderWidth: 1)
        }
    }
}

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreeToTerms = false

    private var isValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        agreeToTerms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("INITIATE NEW RECORD")
                        .techFont(.title2)
                        .foregroundColor(Theme.Colors.neonCyan)
                        .tracking(2)
                        .padding(.top, 24)

                    // Form Fields
                    VStack(spacing: 20) {
                        NeonTextField(title: "DESIGNATION (NAME)", placeholder: "INPUT DATA...", text: $name, icon: "person.fill")
                        
                        NeonTextField(title: "CREDENTIAL (EMAIL)", placeholder: "INPUT DATA...", text: $email, icon: "terminal")
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        
                        NeonSecureField(title: "PASSPHRASE", placeholder: "INPUT DATA...", text: $password, isVisible: $showPassword)
                        
                        NeonSecureField(title: "CONFIRM PASSPHRASE", placeholder: "INPUT DATA...", text: $confirmPassword, isVisible: $showConfirmPassword)
                        
                        if password != confirmPassword && !confirmPassword.isEmpty {
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

                    // Terms Toogle
                    Toggle(isOn: $agreeToTerms) {
                        Text("I ACCEPT THE PROTOCOLS AND PRIVACY DIRECTIVES")
                            .techFont(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .tint(Theme.Colors.neonCyan)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)

                    // Submit Button
                    Button {
                        viewModel.signup(name: name, email: email, password: password)
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primaryBackground))
                            } else {
                                Text("GENERATE KEY")
                                    .techFont(.headline)
                                    .tracking(2)
                            }
                        }
                        .foregroundColor(Theme.Colors.primaryBackground)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.buttonGradient(color: Theme.Colors.neonLime))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                        .neonGlow(color: Theme.Colors.neonLime, radius: .sm)
                        .opacity(isValid ? 1.0 : 0.5)
                    }
                    .disabled(!isValid || viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("REGISTER")
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

// Reusable Components for Form
struct NeonTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .techFont(.subheadline)
                .foregroundColor(Theme.Colors.neonCyan)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.Colors.neonCyan)
                    .frame(width: 24)

                TextField(placeholder, text: $text)
                    .techFont(.body)
                    .foregroundColor(.white)
            }
            .padding()
            .themedCard(borderColor: Theme.Colors.neonCyan.opacity(0.3), borderWidth: 1)
        }
    }
}

struct NeonSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .techFont(.subheadline)
                .foregroundColor(Theme.Colors.neonCyan)

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(Theme.Colors.neonCyan)
                    .frame(width: 24)

                if isVisible {
                    TextField(placeholder, text: $text)
                        .techFont(.body)
                        .foregroundColor(.white)
                } else {
                    SecureField(placeholder, text: $text)
                        .techFont(.body)
                        .foregroundColor(.white)
                }

                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(Theme.Colors.neonCyan)
                }
            }
            .padding()
            .themedCard(borderColor: Theme.Colors.neonCyan.opacity(0.3), borderWidth: 1)
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    Text("OVERRIDE PROTOCOL")
                        .techFont(.title2)
                        .foregroundColor(Theme.Colors.neonMagenta)
                        .tracking(2)
                        .padding(.top, 24)

                    Text("ENTER SYSTEM CREDENTIALS TO RECEIVE OVERRIDE LINK")
                        .techFont(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .tracking(1)

                    // Input Field
                    NeonTextField(title: "CREDENTIAL (EMAIL)", placeholder: "INPUT DATA...", text: $email, icon: "terminal")
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 24)

                    // Submit Button
                    Button {
                        showSuccess = true
                    } label: {
                        Text("TRANSMIT REQUEST")
                            .techFont(.headline)
                            .tracking(2)
                            .foregroundColor(Theme.Colors.primaryBackground)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.buttonGradient(color: Theme.Colors.neonMagenta))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                            .neonGlow(color: Theme.Colors.neonMagenta, radius: .sm)
                            .opacity(email.isEmpty ? 0.5 : 1.0)
                    }
                    .disabled(email.isEmpty)
                    .padding(.horizontal, 24)
                }
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle("RECOVERY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.Colors.neonMagenta)
                    }
                }
            }
            .alert("TRANSMISSION SUCCESS", isPresented: $showSuccess) {
                Button("ACKNOWLEDGE") { dismiss() }
            } message: {
                Text("OVERRIDE LINK SENT TO DESIGNATED ADDRESS")
            }
        }
    }
}

#Preview {
    LoginView()
}

