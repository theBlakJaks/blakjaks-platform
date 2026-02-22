import SwiftUI

// MARK: - SettingsView
// App preferences: language, push notification toggles, biometric lock, and about info.
// All settings persist via @AppStorage (UserDefaults).

struct SettingsView: View {

    // MARK: - Language

    @AppStorage("selectedLanguage") private var selectedLanguage = "en"

    // MARK: - Notifications

    @AppStorage("notifCompEarned")   private var notifCompEarned   = true
    @AppStorage("notifTierUpgrade")  private var notifTierUpgrade  = true
    @AppStorage("notifMentions")     private var notifMentions      = true
    @AppStorage("notifReplies")      private var notifReplies       = true

    // MARK: - Security

    // Biometric binding is a stub — Keychain-backed toggle wired in production polish pass.
    @State private var biometricEnabled = false

    // MARK: - Body

    var body: some View {
        List {

            // MARK: Language

            Section {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                    Text("Français").tag("fr")
                    Text("Deutsch").tag("de")
                    Text("日本語").tag("ja")
                    Text("中文").tag("zh")
                }
                .pickerStyle(.navigationLink)
                .font(.body)
                .foregroundColor(.primary)
            } header: {
                sectionHeader("Language")
            }

            // MARK: Notifications

            Section {
                Toggle("Comp Earned", isOn: $notifCompEarned)
                    .font(.body)
                    .foregroundColor(.primary)
                    .tint(.gold)
                Toggle("Tier Upgrades", isOn: $notifTierUpgrade)
                    .font(.body)
                    .foregroundColor(.primary)
                    .tint(.gold)
                Toggle("Mentions", isOn: $notifMentions)
                    .font(.body)
                    .foregroundColor(.primary)
                    .tint(.gold)
                Toggle("Replies", isOn: $notifReplies)
                    .font(.body)
                    .foregroundColor(.primary)
                    .tint(.gold)
            } header: {
                sectionHeader("Notifications")
            }

            // MARK: Security

            Section {
                Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
                    .font(.body)
                    .foregroundColor(.primary)
                    .tint(.gold)

                Text("Biometric unlock for app and transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                sectionHeader("Security")
            }

            // MARK: About

            Section {
                HStack {
                    Text("Version")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("1.0.0 (1)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Button {
                    // Stub — open ToS URL in production polish pass
                } label: {
                    HStack {
                        Text("Terms of Service")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    // Stub — open Privacy Policy URL in production polish pass
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                sectionHeader("About")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundSecondary)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption, design: .serif))
            .textCase(.uppercase)
            .foregroundColor(.gold)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
