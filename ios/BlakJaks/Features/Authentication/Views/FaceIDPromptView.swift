import SwiftUI
import LocalAuthentication

// MARK: - FaceIDPromptView
// Shown after first successful login/signup.
// Offers Face ID / Touch ID enrollment. Can be skipped.

struct FaceIDPromptView: View {
    @AppStorage("biometrics_enrolled") private var biometricsEnrolled = false
    @Environment(\.dismiss) private var dismiss

    @State private var enrolled = false
    @State private var errorMessage: String?

    private var biometricType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    private var biometricLabel: String {
        switch biometricType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return "Biometrics"
        }
    }

    private var biometricIcon: String {
        switch biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock.shield.fill"
        }
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.gold.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: biometricIcon)
                        .font(.largeTitle.weight(.light))
                        .imageScale(.large)
                        .foregroundColor(.gold)
                }

                // Copy
                VStack(spacing: Spacing.md) {
                    Text("Enable \(biometricLabel)")
                        .font(.system(.title2, design: .serif))
                        .foregroundColor(.primary)

                    Text("Sign in faster with \(biometricLabel). Your biometric data never leaves your device.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                if enrolled {
                    // Success state
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                        Text("\(biometricLabel) enabled")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.success)
                    }
                    .padding(.top, Spacing.sm)
                }

                if let errorMessage {
                    InlineErrorView(message: errorMessage)
                        .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                // Buttons
                VStack(spacing: Spacing.sm) {
                    if !enrolled {
                        GoldButton("Enable \(biometricLabel)") {
                            await enroll()
                        }
                    } else {
                        GoldButton("Continue") {
                            dismiss()
                        }
                    }

                    Button("Skip for Now") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
    }

    private func enroll() async {
        let context = LAContext()
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            errorMessage = authError?.localizedDescription ?? "\(biometricLabel) not available."
            return
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable \(biometricLabel) for BlakJaks sign-in"
            )
            if success {
                biometricsEnrolled = true
                enrolled = true
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FaceIDPromptView()
    }
}
