import SwiftUI

// MARK: - GiphyPickerView
// GIPHY stub GIF selector sheet.
// Real GIPHY API search integration happens in production polish pass.

struct GiphyPickerView: View {

    @Binding var selectedGifUrl: String?
    @Environment(\.dismiss) private var dismiss

    @State private var search = ""

    private let trending = [
        "🎰", "🔥", "💰", "🎯", "🏆",
        "💎", "🥇", "🎉", "🚀", "💯",
        "✨", "👑", "🎮", "🃏", "⚡"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search GIFs...", text: $search)
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

            // Section header
            HStack {
                Text(search.isEmpty ? "TRENDING" : "SEARCH RESULTS (STUB)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xs)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(trending.enumerated()), id: \.offset) { index, emoji in
                        Button {
                            selectedGifUrl = "https://media.giphy.com/stub/\(index)"
                            dismiss()
                        } label: {
                            ZStack {
                                Color.backgroundSecondary
                                    .cornerRadius(8)
                                Text(trending[index % trending.count])
                                    .font(.largeTitle)
                            }
                            .frame(height: 80)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }

            // Footer note
            Text("Powered by GIPHY • Real GIF search in production polish")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(Spacing.md)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("GIFs")
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
        GiphyPickerView(selectedGifUrl: .constant(nil))
    }
}
