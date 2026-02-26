import SwiftUI

// MARK: - ChannelListDrawerView
// Discord iOS-style channel list drawer.
// Shown as a left-side overlay from SocialHubView.

struct ChannelListDrawerView: View {
    @ObservedObject var socialVM: SocialViewModel
    @Binding var isPresented: Bool

    @State private var showLiveStream = false

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
                VStack(alignment: .leading, spacing: 2) {
                    Text("BlakJaks")
                        .font(.system(.headline, design: .serif))
                    Text("Community Channels")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        // 44pt minimum touch target
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.backgroundSecondary)

            // MARK: LIVE button row
            Button {
                isPresented = false
                showLiveStream = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red)
                    Text("Live Stream")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showLiveStream) {
                LiveStreamView(stream: socialVM.currentLiveStream, socialVM: socialVM)
            }

            // MARK: Channel list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedCategories, id: \.self) { category in
                        // Category header — .caption weight .semibold, system design (not a section title but a sub-label)
                        Text(category.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                            .padding(.bottom, Spacing.xs)

                        ForEach(grouped[category] ?? []) { channel in
                            channelRow(channel)
                            Divider()
                                .padding(.leading, Spacing.md)
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
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text("#\(channel.name)")
                    .font(.body)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? .primary : .secondary)

                Spacer()
            }
            // Minimum 52pt row height per spec, 44pt touch target
            .frame(minHeight: 52)
            .padding(.horizontal, Spacing.sm)
            .background(isActive ? Color.gold.opacity(0.08) : Color.backgroundSecondary)
            .contentShape(Rectangle())
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
