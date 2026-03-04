import SwiftUI

// MARK: - LoginView
// Faithfully matches app-mockup.html #s-login:
//   - Two animated gold orb blobs (blurred circles, top-left and bottom-right)
//   - Back button ("← Back"), gray
//   - Playfair "Welcome back" header + Sora subtitle
//   - Email field with uppercase label (EMAIL), dark #111 bg, #222 border → gold on focus
//   - Password field with uppercase label (PASSWORD), SecureField
//   - "Forgot password?" right-aligned gold link
//   - GoldButton "LOG IN" (full width, 52pt, gradient, dark text)
//   - OR divider (lines + text)
//   - Face ID button (transparent, #333 border, gray)
//   - "Don't have an account? Sign up" switch link

// MARK: - OrbsBackground
// Isolated into its own struct so its per-frame @State changes don't
// cause LoginView to re-render, keeping keyboard focus snappy.
struct OrbsBackground: View {
    @State private var offset1: CGSize = .zero
    @State private var offset2: CGSize = .zero

    private let screenW = UIScreen.main.bounds.width
    private let screenH = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .position(x: 70 + offset1.width, y: 70 + offset1.height)
            Circle()
                .fill(Color(red: 212/255, green: 175/255, blue: 55/255).opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .position(x: screenW - 65 + offset2.width, y: screenH - 65 + offset2.height)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                offset1 = CGSize(width: 40, height: 30)
            }
            withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                offset2 = CGSize(width: -30, height: -20)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AuthViewModel()
    @FocusState private var focusedField: LoginField?

    @State private var showSignup = false
    @State private var enableFaceID = false
    @State private var showFaceIDRemovalAlert = false

    private let biometric = BiometricAuthManager.shared

    /// True when the typed email belongs to a DIFFERENT account than the one
    /// currently enrolled for Face ID. Safe to call during rendering — only
    /// reads the plaintext flag and email keys, never the token.
    private var isDifferentAccountEnrolled: Bool {
        guard let prevId = KeychainManager.shared.loggedInUserId,
              KeychainManager.shared.isBiometricEnabled(for: prevId),
              let enrolledEmail = KeychainManager.shared.enrolledEmail(for: prevId)
        else { return false }
        let typed = vm.email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return false }
        return typed != enrolledEmail
    }

    enum LoginField { case email, password }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            OrbsBackground()

            // MARK: Main content — scrollable, top-aligned, no spacer
            // Note: background tap dismisses keyboard without blocking field taps.
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(BJFont.sora(13))
                        }
                        .foregroundColor(Color.gold.opacity(0.7))
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back")
                            .font(BJFont.playfair(28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        Text("Sign in to your BlakJaks account.")
                            .font(BJFont.sora(13))
                            .foregroundColor(Color(white: 0.4))
                    }
                    .padding(.bottom, 28)

                    // Email field
                    VStack(alignment: .leading, spacing: 7) {
                        Text("EMAIL")
                            .font(BJFont.sora(10, weight: .medium))
                            .foregroundColor(Color(white: 0.35))
                            .tracking(1)
                        TextField("test@test.com", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(BJFont.sora(14))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .email ? Color.gold.opacity(0.4) : Color.gold.opacity(0.1), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }
                    .padding(.bottom, 16)

                    // Password field
                    VStack(alignment: .leading, spacing: 7) {
                        Text("PASSWORD")
                            .font(BJFont.sora(10, weight: .medium))
                            .foregroundColor(Color(white: 0.35))
                            .tracking(1)
                        SecureField("••••••••", text: $vm.password)
                            .font(BJFont.sora(14))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .password ? Color.gold.opacity(0.4) : Color.gold.opacity(0.1), lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { Task { await vm.login(authState: authState) } }
                    }

                    // Forgot password + Face ID toggle row
                    HStack {
                        // Enable Face ID toggle — only shown if biometrics available
                        // and user hasn't enrolled yet
                        let userId = KeychainManager.shared.loggedInUserId ?? ""
                        if biometric.isAvailable && !KeychainManager.shared.isBiometricEnabled(for: userId) {
                            Button {
                                enableFaceID.toggle()
                            } label: {
                                HStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(enableFaceID
                                                  ? LinearGradient(colors: [Color(red: 212/255, green: 175/255, blue: 55/255), Color(red: 201/255, green: 160/255, blue: 40/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                  : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 16, height: 16)
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(enableFaceID ? Color.clear : Color.white.opacity(0.2), lineWidth: 1))
                                        if enableFaceID {
                                            Text("✓").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                        }
                                    }
                                    Text("Enable \(biometric.displayName)")
                                        .font(BJFont.sora(12))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Button("Forgot password?") {}
                            .font(BJFont.sora(12))
                            .foregroundColor(Color.gold.opacity(0.6))
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                    // Error message
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(BJFont.caption)
                            .foregroundColor(Color.error)
                            .padding(.bottom, 12)
                    }

                    // LOG IN button
                    GoldButton(
                        title: "LOG IN",
                        action: {
                            if isDifferentAccountEnrolled {
                                showFaceIDRemovalAlert = true
                            } else {
                                Task { await vm.login(authState: authState, enableBiometric: enableFaceID) }
                            }
                        },
                        isLoading: vm.isLoading,
                        isDisabled: !vm.canLogin
                    )

                    // OR divider + Face ID button — only shown when biometrics enrolled
                    let userId = KeychainManager.shared.loggedInUserId ?? ""
                    if biometric.isAvailable && KeychainManager.shared.isBiometricEnabled(for: userId) {
                        HStack(spacing: 14) {
                            Rectangle().fill(Color.gold.opacity(0.1)).frame(height: 1)
                            Text("OR")
                                .font(BJFont.sora(11))
                                .foregroundColor(Color.white.opacity(0.2))
                                .tracking(1)
                            Rectangle().fill(Color.gold.opacity(0.1)).frame(height: 1)
                        }
                        .padding(.vertical, 20)

                        Button {
                            Task { await vm.biometricLogin(authState: authState) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: biometric.symbolName)
                                    .font(.system(size: 18))
                                Text("Sign in with \(biometric.displayName)")
                                    .font(BJFont.sora(13))
                            }
                            .foregroundColor(Color.gold.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gold.opacity(0.25), lineWidth: 1)
                            )
                        }
                    }

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(Color(white: 0.3))
                        Button("Sign up") { showSignup = true }
                            .foregroundColor(Color.gold)
                    }
                    .font(BJFont.sora(13))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
            }
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
                .environmentObject(authState)
        }
        .alert("Remove Face ID?", isPresented: $showFaceIDRemovalAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                Task { await vm.login(authState: authState, enableBiometric: enableFaceID) }
            }
        } message: {
            Text("Logging into a different account will remove Face ID from this device. You can re-enable Face ID after signing in.")
        }
    }

}

#Preview {
    LoginView()
        .environmentObject(AuthState())
}
