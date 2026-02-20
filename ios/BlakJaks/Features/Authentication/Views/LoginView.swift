import SwiftUI

// MARK: - LoginView
// Email + password login with Face ID shortcut and forgot password link.

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var viewModel = AuthViewModel()
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Welcome Back")
                            .font(.title.weight(.bold))
                            .foregroundColor(.primary)
                        Text("Sign in to your BlakJaks account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Form
                    VStack(spacing: Spacing.md) {
                        // Email
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Email")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            TextField("you@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(Color.backgroundSecondary)
                                .cornerRadius(Layout.buttonCornerRadius)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }

                        // Password
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Password")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            SecureField("••••••••", text: $viewModel.password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .padding()
                                .background(Color.backgroundSecondary)
                                .cornerRadius(Layout.buttonCornerRadius)
                                .submitLabel(.go)
                                .onSubmit { Task { await attemptLogin() } }
                        }

                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.footnote)
                            .foregroundColor(.gold)
                        }
                    }

                    // Error
                    if let error = viewModel.error {
                        InlineErrorView(message: error.localizedDescription)
                            .padding(.horizontal, Spacing.xs)
                    }

                    // Sign In button
                    GoldButton("Sign In", isLoading: viewModel.isLoading) {
                        await attemptLogin()
                    }

                    // Divider
                    HStack {
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        Text("or").font(.caption).foregroundColor(.secondary)
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    }

                    // Face ID / Touch ID button
                    Button {
                        Task { await attemptBiometricLogin() }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: biometricIcon)
                                .font(.title3)
                            Text("Sign in with \(viewModel.biometricLabel)")
                                .font(.body.weight(.medium))
                        }
                        .foregroundColor(.gold)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                                .stroke(Color.gold, lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private func attemptLogin() async {
        focusedField = nil
        let success = await viewModel.login()
        if success { isAuthenticated = true }
    }

    private func attemptBiometricLogin() async {
        let success = await viewModel.loginWithBiometrics()
        if success { isAuthenticated = true }
    }

    private var biometricIcon: String {
        switch viewModel.biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock.open.fill"
        }
    }
}

// MARK: - ForgotPasswordView (sheet)

private struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent  = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                if sent {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "envelope.badge.checkmark")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.gold)
                        Text("Check your email")
                            .font(.title2.weight(.semibold))
                        Text("If an account exists for \(email), a reset link has been sent.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Layout.screenMargin)
                    GoldButton("Done") { dismiss() }
                        .padding(.horizontal, Layout.screenMargin)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Reset Password")
                            .font(.title2.weight(.bold))
                        Text("Enter your email address and we'll send a reset link.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, Layout.screenMargin)

                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Layout.buttonCornerRadius)
                        .padding(.horizontal, Layout.screenMargin)

                    GoldButton("Send Reset Link") {
                        // In production: call API. For now simulate success.
                        sent = true
                    }
                    .padding(.horizontal, Layout.screenMargin)
                }
                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoginView(isAuthenticated: .constant(false))
    }
}
