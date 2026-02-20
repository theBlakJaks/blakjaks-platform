import SwiftUI

// MARK: - EditProfileView
// Sheet presented from ProfileView to edit full name and bio.
// Avatar upload is stubbed — PhotosUI integration in production polish pass.

struct EditProfileView: View {
    @ObservedObject var profileVM: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var bio = ""
    @State private var showCharLimitWarning = false

    private let bioMaxLength = 200

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Avatar section
                    avatarSection

                    // Full Name field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Full Name")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        TextField("Full name", text: $fullName)
                            .textContentType(.name)
                            .padding(Spacing.md)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(Layout.cardCornerRadius)
                    }

                    // Bio field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("Bio")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(bio.count) / \(bioMaxLength)")
                                .font(.caption2)
                                .foregroundColor(bio.count >= bioMaxLength ? .red : .secondary)
                        }

                        ZStack(alignment: .topLeading) {
                            if bio.isEmpty {
                                Text("Tell the community about yourself…")
                                    .font(.body)
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.sm + 2)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $bio)
                                .frame(minHeight: 96)
                                .padding(Spacing.xs)
                                .onChange(of: bio) { newValue in
                                    if newValue.count > bioMaxLength {
                                        bio = String(newValue.prefix(bioMaxLength))
                                    }
                                }
                        }
                        .background(Color.backgroundSecondary)
                        .cornerRadius(Layout.cardCornerRadius)
                    }

                    // Save button
                    saveButton

                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, Spacing.md)
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.top, Spacing.md)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                fullName = profileVM.profile?.fullName ?? ""
                bio = profileVM.profile?.bio ?? ""
            }
            .alert("Success", isPresented: Binding(
                get: { profileVM.successMessage != nil },
                set: { if !$0 { profileVM.clearSuccessMessage() } }
            )) {
                Button("OK") { profileVM.clearSuccessMessage() }
            } message: {
                Text(profileVM.successMessage ?? "")
            }
            .alert("Error", isPresented: Binding(
                get: { profileVM.error != nil },
                set: { if !$0 { profileVM.clearError() } }
            )) {
                Button("OK") { profileVM.clearError() }
            } message: {
                Text(profileVM.error?.localizedDescription ?? "An error occurred.")
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.backgroundTertiary)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(Color.gold, lineWidth: 2.5)
                    )

                Text(String((profileVM.profile?.fullName.prefix(1) ?? "?").uppercased()))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.gold)
            }

            // Stub: PhotosUI avatar picker wired in production polish pass
            Button {
                // TODO: present PHPickerViewController
            } label: {
                Label("Change Photo", systemImage: "camera.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.gold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.md)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await profileVM.updateProfile(fullName: fullName, bio: bio)
                if profileVM.error == nil {
                    dismiss()
                }
            }
        } label: {
            Group {
                if profileVM.isUpdatingProfile {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                        Text("Saving…")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.black)
                    }
                } else {
                    Text("Save Changes")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(fullName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gold.opacity(0.4) : Color.gold)
            .cornerRadius(Layout.buttonCornerRadius)
        }
        .disabled(profileVM.isUpdatingProfile || fullName.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

// MARK: - Preview

#Preview {
    let vm = ProfileViewModel()
    vm.profile = MockUser.current
    return EditProfileView(profileVM: vm)
}
