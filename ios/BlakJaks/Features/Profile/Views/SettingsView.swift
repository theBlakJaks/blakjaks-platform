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

            Section("Language") {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                    Text("Français").tag("fr")
                    Text("Deutsch").tag("de")
                    Text("日本語").tag("ja")
                    Text("中文").tag("zh")
                }
                .pickerStyle(.navigationLink)
            }

            // MARK: Notifications

            Section("Notifications") {
                Toggle("Comp Earned", isOn: $notifCompEarned)
                    .tint(.gold)
                Toggle("Tier Upgrades", isOn: $notifTierUpgrade)
                    .tint(.gold)
                Toggle("Mentions", isOn: $notifMentions)
                    .tint(.gold)
                Toggle("Replies", isOn: $notifReplies)
                    .tint(.gold)
            }

            // MARK: Security

            Section {
                Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
                    .tint(.gold)

                Text("Biometric unlock for app and transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Security")
            }

            // MARK: About

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (1)")
                        .foregroundColor(.secondary)
                }

                Button {
                    // Stub — open ToS URL in production polish pass
                } label: {
                    HStack {
                        Text("Terms of Service")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }

                Button {
                    // Stub — open Privacy Policy URL in production polish pass
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
