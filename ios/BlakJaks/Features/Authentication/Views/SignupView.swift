import SwiftUI

// MARK: - SignupView
// Email, password, full name, date of birth (21+ validated), T&C checkbox.

struct SignupView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var viewModel = AuthViewModel()
    @State private var confirmPassword = ""
    @State private var agreedToTerms   = false
    @FocusState private var focusedField: Field?

    enum Field { case fullName, email, password, confirmPassword }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("Create Account")
                            .font(.title.weight(.bold))
                            .foregroundColor(.primary)
                        Text("Join the BlakJaks community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Spacing.xl)

                    // Form fields
                    VStack(spacing: Spacing.md) {
                        fieldLabel("Full Name") {
                            TextField("First Last", text: $viewModel.fullName)
                                .textContentType(.name)
                                .focused($focusedField, equals: .fullName)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .email }
                        }

                        fieldLabel("Email") {
                            TextField("you@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }

                        fieldLabel("Password") {
                            SecureField("Minimum 8 characters", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .confirmPassword }
                        }

                        fieldLabel("Confirm Password") {
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                        }

                        // Date of birth — must be 21+
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Date of Birth")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.secondary)
                            DatePicker(
                                "",
                                selection: $viewModel.dateOfBirth,
                                in: ...Calendar.current.date(byAdding: .year, value: -21, to: Date())!,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.gold)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(Layout.buttonCornerRadius)

                            if !viewModel.isOldEnough && viewModel.dateOfBirth != Calendar.current.date(byAdding: .year, value: -21, to: Date())! {
                                InlineErrorView(message: "You must be 21 or older.")
                            }
                        }

                        // Terms checkbox
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Button {
                                agreedToTerms.toggle()
                            } label: {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? .gold : .secondary)
                                    .font(.title3)
                            }

                            Text("I agree to the **Terms of Service** and **Privacy Policy**. I confirm I am 21 or older.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.top, Spacing.xs)
                    }

                    // Password mismatch
                    if !confirmPassword.isEmpty && viewModel.password != confirmPassword {
                        InlineErrorView(message: "Passwords do not match.")
                    }

                    // API/validation error
                    if let error = viewModel.error {
                        InlineErrorView(message: error.localizedDescription)
                    }

                    // Create Account CTA
                    GoldButton("Create Account", isLoading: viewModel.isLoading) {
                        await attemptSignup()
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.6)
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        agreedToTerms
        && viewModel.password == confirmPassword
        && viewModel.isOldEnough
        && !viewModel.isLoading
    }

    private func attemptSignup() async {
        focusedField = nil
        guard viewModel.password == confirmPassword else {
            viewModel.error = ValidationError.weakPassword
            return
        }
        let success = await viewModel.signup()
        if success {
            // Route to FaceID enrollment prompt
            isAuthenticated = true
        }
    }

    @ViewBuilder
    private func fieldLabel<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
            content()
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(Layout.buttonCornerRadius)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignupView(isAuthenticated: .constant(false))
    }
}
