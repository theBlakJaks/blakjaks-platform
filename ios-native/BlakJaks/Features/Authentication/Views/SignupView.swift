import SwiftUI

// MARK: - SignupView
// Faithfully matches app-mockup.html #s-signup:
//   - Same two animated gold orb blobs as LoginView
//   - Back button ("← Back"), gray
//   - Playfair "Create Account" header + Sora subtitle
//   - Full Name field (text)
//   - Email field (email)
//   - Date of Birth field (MM/DD/YYYY display, sheet DatePicker)
//   - Password field (secure)
//   - Referral Code (Optional) field (text)
//   - Age confirmation checkbox: gold checkmark box + terms text with gold "Terms of Service" link
//   - GoldButton "CREATE ACCOUNT" (full width, 52pt, gradient, dark text)
//   - "Already have an account? Log in" switch link

struct SignupView: View {
    @EnvironmentObject private var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AuthViewModel()
    @FocusState private var focusedField: SignupField?

    @State private var referralCode: String = ""
    @State private var ageConfirmed: Bool = true  // pre-checked per mockup ("checked" class)
    @State private var showDatePicker: Bool = false
    @State private var birthDate: Date = {
        // Default to 21 years ago
        Calendar.current.date(byAdding: .year, value: -21, to: Date()) ?? Date()
    }()

    enum SignupField { case fullName, username, email, dob, password, referral }

    // Input style colors matching CSS: bg #111111, border #222222
    private let inputBg     = Color(red: 0.067, green: 0.067, blue: 0.067)
    private let inputBorder = Color(red: 0.133, green: 0.133, blue: 0.133)

    // Date display formatter — MM/DD/YYYY per placeholder
    private let dobDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    // API date formatter — yyyy-MM-dd for vm.dateOfBirth
    private let dobAPIFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // Whether the signup form is complete (extends vm.canSignup with age gate)
    private var canCreate: Bool {
        vm.canSignup && ageConfirmed
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            OrbsBackground()

            // MARK: Main scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        Text("← Back")
                            .font(BJFont.sora(13))
                            .foregroundColor(Color(white: 0.533)) // #888888
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)

                    // Header — margin-bottom: 28
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create Account")
                            .font(BJFont.playfair(28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        Text("Join the BlakJaks community.")
                            .font(BJFont.sora(13))
                            .foregroundColor(Color(white: 0.4)) // #666666
                    }
                    .padding(.bottom, 28)

                    // MARK: Form fields

                    // Full Name
                    formField(label: "FULL NAME") {
                        TextField("Joshua Dunn", text: $vm.fullName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .font(BJFont.sora(15))
                            .foregroundColor(Color.textPrimary)
                            .focused($focusedField, equals: .fullName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .username }
                            .inputFieldStyle(
                                bg: inputBg,
                                border: focusedField == .fullName ? Color.gold : inputBorder
                            )
                    }
                    .padding(.bottom, 14)

                    // Username
                    formField(label: "USERNAME") {
                        TextField("blakjaks_user", text: $vm.username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(BJFont.sora(15))
                            .foregroundColor(Color.textPrimary)
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                            .inputFieldStyle(
                                bg: inputBg,
                                border: focusedField == .username ? Color.gold : inputBorder
                            )
                    }
                    .padding(.bottom, 14)

                    // Email
                    formField(label: "EMAIL") {
                        TextField("test@test.com", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .textContentType(.emailAddress)
                            .font(BJFont.sora(15))
                            .foregroundColor(Color.textPrimary)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .dob }
                            .inputFieldStyle(
                                bg: inputBg,
                                border: focusedField == .email ? Color.gold : inputBorder
                            )
                    }
                    .padding(.bottom, 14)

                    // Date of Birth — tappable row that opens sheet DatePicker
                    formField(label: "DATE OF BIRTH") {
                        Button {
                            focusedField = nil
                            showDatePicker = true
                        } label: {
                            HStack {
                                Text(vm.dateOfBirth.isEmpty ? "MM/DD/YYYY" : vm.dateOfBirth.isEmpty ? "MM/DD/YYYY" : dobDisplayString)
                                    .font(BJFont.sora(15))
                                    .foregroundColor(
                                        vm.dateOfBirth.isEmpty
                                            ? Color(white: 0.4) // placeholder color #666
                                            : Color.textPrimary
                                    )
                                Spacer()
                                Image(systemName: "calendar")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.4))
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(inputBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(inputBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.bottom, 14)

                    // Password
                    formField(label: "PASSWORD") {
                        SecureField("••••••••", text: $vm.password)
                            .textContentType(.newPassword)
                            .font(BJFont.sora(15))
                            .foregroundColor(Color.textPrimary)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .referral }
                            .inputFieldStyle(
                                bg: inputBg,
                                border: focusedField == .password ? Color.gold : inputBorder
                            )
                    }
                    .padding(.bottom, 14)

                    // Referral Code (Optional)
                    formField(label: "REFERRAL CODE (OPTIONAL)") {
                        TextField("BJ-XXXX", text: $referralCode)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .font(BJFont.sora(15))
                            .foregroundColor(Color.textPrimary)
                            .focused($focusedField, equals: .referral)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                            .inputFieldStyle(
                                bg: inputBg,
                                border: focusedField == .referral ? Color.gold : inputBorder
                            )
                    }
                    .padding(.bottom, 20)

                    // MARK: Bottom section — form-bot
                    VStack(spacing: 12) {

                        // Age confirmation checkbox
                        // CSS: .age-check — flex row, gap 10
                        // .age-check-box.checked — gold bg, checkmark
                        Button {
                            ageConfirmed.toggle()
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                // Checkbox box
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            ageConfirmed
                                                ? LinearGradient(
                                                    colors: [
                                                        Color(red: 212/255, green: 175/255, blue: 55/255),
                                                        Color(red: 201/255, green: 160/255, blue: 40/255)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [inputBg, inputBg],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(
                                                    ageConfirmed ? Color.clear : inputBorder,
                                                    lineWidth: 1
                                                )
                                        )
                                    if ageConfirmed {
                                        Text("✓")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(red: 0.039, green: 0.039, blue: 0.039)) // #0A0A0A
                                    }
                                }
                                .frame(width: 20, height: 20)
                                .padding(.top, 1) // align with first line of text

                                // Terms text with gold link
                                (
                                    Text("I confirm I am 21 years of age or older and agree to the ")
                                        .foregroundColor(Color(white: 0.533)) // #888
                                    + Text("Terms of Service")
                                        .foregroundColor(Color.gold)
                                )
                                .font(BJFont.sora(13))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .buttonStyle(.plain)

                        // Gold CREATE ACCOUNT button
                        GoldButton(
                            title: "CREATE ACCOUNT",
                            action: { Task { await vm.signup(authState: authState, referralCode: referralCode) } },
                            isLoading: vm.isLoading,
                            isDisabled: !canCreate
                        )

                        // Error message
                        if let error = vm.errorMessage {
                            Text(error)
                                .font(BJFont.caption)
                                .foregroundColor(Color.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        // Switch text — "Already have an account? Log in"
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(Color(white: 0.333)) // #555555
                            Button("Log in") {
                                dismiss()
                            }
                            .foregroundColor(Color.gold)
                        }
                        .font(BJFont.sora(13))
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // MARK: Date Picker sheet overlay
            if showDatePicker {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showDatePicker = false }

                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        // Toolbar
                        HStack {
                            Button("Cancel") {
                                showDatePicker = false
                            }
                            .font(BJFont.sora(14))
                            .foregroundColor(Color.textSecondary)

                            Spacer()

                            Button("Done") {
                                vm.dateOfBirth = dobAPIFormatter.string(from: birthDate)
                                showDatePicker = false
                            }
                            .font(BJFont.sora(14, weight: .semibold))
                            .foregroundColor(Color.gold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))

                        DatePicker(
                            "",
                            selection: $birthDate,
                            in: ...Calendar.current.date(byAdding: .year, value: -21, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .colorScheme(.dark)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 0)
                    .shadow(radius: 20)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.4), value: showDatePicker)
            }
        }
    }

    // MARK: Helpers

    // Display the stored API date (yyyy-MM-dd) as MM/dd/yyyy for the field
    private var dobDisplayString: String {
        guard !vm.dateOfBirth.isEmpty,
              let date = dobAPIFormatter.date(from: vm.dateOfBirth) else {
            return "MM/DD/YYYY"
        }
        return dobDisplayFormatter.string(from: date)
    }

    // Reusable field container: label above + content slot
    @ViewBuilder
    private func formField<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(BJFont.sora(11))
                .foregroundColor(Color(white: 0.4)) // #666666
                .tracking(2)
                .textCase(.uppercase)
            content()
        }
    }

}

// MARK: - Input Field Style
// Applies the .fi CSS style inline: bg #111, border #222 (or gold on focus),
// height 52, cornerRadius 10, padding horizontal 16.

private extension View {
    func inputFieldStyle(bg: Color, border: Color) -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthState())
}
