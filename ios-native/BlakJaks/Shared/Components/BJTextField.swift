import SwiftUI

// MARK: - BJTextField
// Reusable dark-themed text input matching the mockup's field style.
// Single definition — used across Auth, Profile, Shop, and other screens.

struct BJTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .textContentType(textContentType)
        .font(BJFont.sora(14))
        .foregroundColor(Color.textPrimary)
        .padding(.horizontal, Spacing.md)
        .frame(height: 52)
        .background(Color.bgInput)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.borderGold, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
