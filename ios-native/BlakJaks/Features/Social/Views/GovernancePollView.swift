import SwiftUI

// MARK: - GovernancePollView

/// Displays active governance votes as poll cards within the Social tab.
/// Navigates from governance-type channels in SocialHubView.

struct GovernancePollView: View {

    let channel: Channel
    @StateObject private var vm = GovernancePollViewModel()

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                if vm.isLoading {
                    ProgressView()
                        .tint(Color.gold)
                        .padding(Spacing.xl)
                } else if vm.votes.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(vm.votes) { vote in
                            NavigationLink(value: vote) {
                                pollCard(vote)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .disableSwipeBack()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("GOVERNANCE")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
        }
        .navigationDestination(for: GovernanceVote.self) { vote in
            GovernanceVoteView(vote: vote)
        }
        .task {
            await vm.loadVotes()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 40))
                .foregroundColor(Color.textTertiary)
            Text("No active proposals")
                .font(BJFont.sora(14, weight: .semibold))
                .foregroundColor(Color.textSecondary)
            Text("Check back later for community governance votes")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxxl)
    }

    // MARK: - Poll Card

    private func pollCard(_ vote: GovernanceVote) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TierBadge(tier: vote.tierEligibility)
                statusBadge(vote.status)
                Spacer()
                Text("\(vote.totalBallots) votes")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }

            Text(vote.title)
                .font(BJFont.outfit(16, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .lineLimit(2)

            Text(vote.description)
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.textSecondary)
                .lineLimit(2)

            // Options preview
            HStack(spacing: Spacing.sm) {
                ForEach(vote.options.prefix(3), id: \.self) { option in
                    Text(option)
                        .font(BJFont.sora(10, weight: .medium))
                        .foregroundColor(Color.goldMid)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.goldDim.opacity(0.08))
                        .clipShape(Capsule())
                }
                if vote.options.count > 3 {
                    Text("+\(vote.options.count - 3)")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                }
            }

            // Countdown
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.textTertiary)
                Text("Ends \(formattedDate(vote.votingEndsAt))")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Helpers

    private func statusBadge(_ status: String) -> some View {
        let isActive = status.lowercased() == "active"
        return Text(status.uppercased())
            .font(BJFont.micro)
            .tracking(1.5)
            .foregroundColor(isActive ? Color.success : Color.textTertiary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background((isActive ? Color.success : Color.textTertiary).opacity(0.1))
            .overlay(Capsule().stroke((isActive ? Color.success : Color.textTertiary).opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())
    }

    private func formattedDate(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}

// MARK: - GovernancePollViewModel

@MainActor
final class GovernancePollViewModel: ObservableObject {
    @Published var votes: [GovernanceVote] = []
    @Published var isLoading = false

    private let api: APIClientProtocol = APIClient.shared

    func loadVotes() async {
        isLoading = true
        do {
            votes = try await api.getActiveVotes()
        } catch {
            // Silently fail — show empty state
        }
        isLoading = false
    }
}
