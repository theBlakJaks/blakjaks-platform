import SwiftUI

// MARK: - EmoteAutocomplete

/// Dropdown above the input bar showing up to 5 prefix-matched emotes.
/// Tapping inserts the emote name, replacing the partial word.

struct EmoteAutocomplete: View {

    let matches: [CachedEmote]
    let onSelect: (CachedEmote) -> Void

    var body: some View {
        if !matches.isEmpty {
            VStack(spacing: 0) {
                ForEach(matches) { emote in
                    Button {
                        onSelect(emote)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if let url = emote.url(size: "1x") {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 24, height: 24)
                                    default:
                                        Color.bgCard
                                            .frame(width: 24, height: 24)
                                    }
                                }
                            }

                            Text(emote.name)
                                .font(BJFont.sora(13, weight: .medium))
                                .foregroundColor(Color.textPrimary)

                            Spacer()
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    if emote.id != matches.last?.id {
                        Divider().background(Color.borderSubtle)
                    }
                }
            }
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.borderSubtle, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, y: -4)
            .padding(.horizontal, Spacing.md)
        }
    }
}
