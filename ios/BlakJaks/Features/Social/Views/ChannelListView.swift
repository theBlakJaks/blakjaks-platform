import SwiftUI

// MARK: - ChannelListDrawerView
// Discord iOS-style channel list drawer.
// Shown as a left-side overlay from SocialHubView.

struct ChannelListDrawerView: View {
    @ObservedObject var socialVM: SocialViewModel
    @Binding var isPresented: Bool

    // Group channels by category
    private var grouped: [String: [Channel]] {
        Dictionary(grouping: socialVM.channels, by: \.category)
    }

    private var sortedCategories: [String] {
        grouped.keys.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            HStack {
                Text("BlakJaks")
                    .font(.headline)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)

            // MARK: Channel list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedCategories, id: \.self) { category in
                        // Category header
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                            .padding(.bottom, Spacing.xs)

                        ForEach(grouped[category] ?? []) { channel in
                            channelRow(channel)
                        }
                    }
                }
            }
        }
        .background(Color.backgroundPrimary)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Channel Row

    private func channelRow(_ channel: Channel) -> some View {
        let isActive = channel.id == socialVM.selectedChannel?.id
        return Button {
            Task { await socialVM.selectChannel(channel) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                // Gold left border accent for active
                Rectangle()
                    .fill(isActive ? Color.gold : Color.clear)
                    .frame(width: 3)

                // Lock icon for tier-restricted channels
                let isRestricted = channel.category == "tier"
                if isRestricted {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Text("#\(channel.name)")
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .primary : .secondary)

                Spacer()

                // Member count badge
                Text("\(channel.memberCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
            .background(isActive ? Color.gold.opacity(0.08) : Color.clear)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 0) {
        ChannelListDrawerView(
            socialVM: {
                let vm = SocialViewModel(apiClient: MockAPIClient())
                return vm
            }(),
            isPresented: .constant(true)
        )
        .frame(width: 280)
        Spacer()
    }
    .background(Color.backgroundPrimary)
}
