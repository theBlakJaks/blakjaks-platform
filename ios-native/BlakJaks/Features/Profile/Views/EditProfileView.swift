import SwiftUI
import PhotosUI

// MARK: - EditProfileView

struct EditProfileView: View {

    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isUploadingAvatar = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case name, bio }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    avatarSection
                    formSection
                    feedbackSection
                    saveButton

                    Spacer(minLength: Spacing.xxxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EDIT PROFILE")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    focusedField = nil
                    Task { await vm.saveProfile() }
                }
                .font(BJFont.sora(14, weight: .semibold))
                .foregroundColor(Color.goldMid)
                .disabled(vm.isSaving)
            }
        }
        .disableSwipeBack()
        .onChange(of: selectedPhotoItem) { newItem in
            Task { await handlePhotoSelection(newItem) }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: Spacing.sm) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarView
                        .opacity(isUploadingAvatar ? 0.6 : 1)

                    if isUploadingAvatar {
                        ProgressView()
                            .tint(Color.gold)
                            .padding(6)
                            .background(Color.bgCard)
                            .clipShape(Circle())
                            .offset(x: 3, y: 3)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.bgCard)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.borderGold, lineWidth: 0.8))

                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.goldMid)
                        }
                        .offset(x: 3, y: 3)
                    }
                }
            }

            Text("Tap to change photo")
                .font(BJFont.caption)
                .foregroundColor(Color.textTertiary)
        }
    }

    private var avatarView: some View {
        ZStack {
            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let urlStr = vm.user?.avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsCircle
                }
            } else {
                initialsCircle
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.borderGold, lineWidth: 1.5))
        .shadow(color: Color.gold.opacity(0.18), radius: 12)
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(LinearGradient.goldShimmer)
            Text(initials)
                .font(BJFont.playfair(34, weight: .bold))
                .foregroundColor(Color.bgPrimary)
        }
    }

    private var initials: String {
        let name = vm.user?.displayName ?? ""
        let parts = name.split(separator: " ")
        return "\(parts.first?.prefix(1) ?? "")\(parts.dropFirst().first?.prefix(1) ?? "")".uppercased()
    }

    // MARK: - Form Section

    private var formSection: some View {
        VStack(spacing: Spacing.md) {
            // Full Name
            LabeledTextField(
                label: "Full Name",
                placeholder: "Your full name",
                text: $vm.editingFullName,
                focused: focusedField == .name
            )
            .focused($focusedField, equals: .name)
            .submitLabel(.next)
            .onSubmit { focusedField = .bio }

            // Bio
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("BIO")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.textTertiary)

                TextEditor(text: $vm.editingBio)
                    .font(BJFont.body)
                    .foregroundColor(Color.textPrimary)
                    .tint(Color.goldMid)
                    .scrollContentBackground(.hidden)
                    .background(Color.bgInput)
                    .frame(minHeight: 100, maxHeight: 180)
                    .padding(Spacing.sm)
                    .background(Color.bgInput)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(
                                focusedField == .bio ? Color.borderGold : Color.borderSubtle,
                                lineWidth: focusedField == .bio ? 1 : 0.5
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .focused($focusedField, equals: .bio)

                HStack {
                    Spacer()
                    Text("\(vm.editingBio.count)/280")
                        .font(BJFont.micro)
                        .foregroundColor(vm.editingBio.count > 260 ? Color.warning : Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackSection: some View {
        if let success = vm.successMessage {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.success)
                Text(success)
                    .font(BJFont.caption)
                    .foregroundColor(Color.success)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.success.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(Color.success.opacity(0.2), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }

        if let error = vm.errorMessage {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(Color.error)
                Text(error)
                    .font(BJFont.caption)
                    .foregroundColor(Color.error)
            }
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.error.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: Radius.sm).stroke(Color.error.opacity(0.2), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        GoldButton(
            title: "Save Changes",
            action: {
                focusedField = nil
                Task { await vm.saveProfile() }
            },
            isLoading: vm.isSaving
        )
    }

    // MARK: - Photo Handling

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isUploadingAvatar = true
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                avatarImage = image
                // Upload to server
                let compressedData = image.jpegData(compressionQuality: 0.8) ?? data
                _ = try? await APIClient.shared.uploadAvatar(imageData: compressedData, mimeType: "image/jpeg")
                await vm.loadProfile()
            }
        } catch {
            vm.errorMessage = "Failed to upload photo."
        }
        isUploadingAvatar = false
    }
}

// MARK: - LabeledTextField
// Local labeled variant used only in EditProfileView.

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focused: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.textTertiary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(BJFont.body)
            .foregroundColor(Color.textPrimary)
            .tint(Color.goldMid)
            .padding(.horizontal, Spacing.md)
            .frame(height: 52)
            .background(Color.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(focused ? Color.borderGold : Color.borderSubtle, lineWidth: focused ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}

#Preview {
    let vm = ProfileViewModel()
    return NavigationStack {
        EditProfileView(vm: vm)
    }
    .preferredColorScheme(.dark)
}
