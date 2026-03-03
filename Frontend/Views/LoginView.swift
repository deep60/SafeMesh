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
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)

                            Image(systemName: "shield.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        Text("Welcome Back")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                TextField("Enter your email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Button {
                                    showForgotPassword = true
                                } label: {
                                    Text("Forgot?")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }

                        // Login button
                        Button {
                            viewModel.login(email: email, password: password)
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("or continue with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VStack { Divider() }
                    }
                    .padding(.horizontal, 40)

                    // Social login
                    HStack(spacing: 16) {
                        SocialLoginButton(icon: "applelogo", title: "Apple") {
                            viewModel.signInWithApple()
                        }

                        SocialLoginButton(icon: "globe", title: "Google") {
                            viewModel.signInWithGoogle()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign up
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            showSignup = true
                        } label: {
                            Text("Sign Up")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Login Failed", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
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
            Form {
                Section("Create Account") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }

                        Button {
                            showConfirmPassword.toggle()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Password must be at least 8 characters")
                } footer: {
                    if password != confirmPassword && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Toggle("I agree to the Terms of Service and Privacy Policy", isOn: $agreeToTerms)
                }

                Section {
                    Button {
                        viewModel.signup(name: name, email: email, password: password)
                    } label: {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Sign Up")
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

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                } header: {
                    Text("Enter your email address and we'll send you a link to reset your password.")
                }

                Section {
                    Button("Send Reset Link") {
                        showSuccess = true
                    }
                    .disabled(email.isEmpty)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Email Sent", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Check your email for the password reset link.")
            }
        }
    }
}

#Preview {
    LoginView()
}

