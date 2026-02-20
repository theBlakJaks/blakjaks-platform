import SwiftUI

// MARK: - EmotePickerView
// 7TV emote stub selector sheet.
// Real 7TV API integration happens in production polish pass.

struct EmotePickerView: View {

    @Binding var selectedEmote: String?
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""

    private let emotes = [
        "KEKW", "PogChamp", "Pog", "OMEGALUL", "pepeD",
        "Clap", "monkaS", "LULW", "KEKL", "peepoHappy",
        "catJAM", "EZ", "NODDERS", "FeelsBadMan", "FeelsGoodMan",
        "monkaHmm", "WeirdChamp", "Hmm", "pepega", "Sadge"
    ]

    private var filteredEmotes: [String] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return emotes }
        return emotes.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search emotes...", text: $search)
                    .font(.body)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Spacing.sm)
            .background(Color.backgroundSecondary)
            .cornerRadius(10)
            .padding(Spacing.md)

            if filteredEmotes.isEmpty {
                Spacer()
                Text("No emotes match \"\(search)\"")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredEmotes, id: \.self) { emote in
                            Button {
                                selectedEmote = emote
                                dismiss()
                            } label: {
                                Text(":\(emote):")
                                    .font(.caption)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.6)
                                    .frame(width: 56, height: 40)
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }

            // Footer note
            Text("Powered by 7TV • Integration live in production polish")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(Spacing.md)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Emotes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmotePickerView(selectedEmote: .constant(nil))
    }
}
