import SwiftUI

// MARK: - GovernanceVoteView

struct GovernanceVoteView: View {

    let vote: GovernanceVote
    @StateObject private var vm = GovernanceViewModel()

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoading {
                LoadingView(message: "Loading proposal...")
            } else if let detail = vm.detail {
                detailContent(detail: detail)
            } else if let error = vm.errorMessage {
                InsightsErrorView(message: error) {
                    Task { await vm.loadDetail(voteId: vote.id) }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("GOVERNANCE")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
        }
        .task {
            await vm.loadDetail(voteId: vote.id)
        }
        .alert("Success", isPresented: Binding(
            get: { vm.successMessage != nil },
            set: { if !$0 { vm.successMessage = nil } }
        )) {
            Button("OK") { vm.successMessage = nil }
        } message: {
            Text(vm.successMessage ?? "")
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil && !vm.isLoading },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private func detailContent(detail: GovernanceVoteDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Header
                voteHeader(detail: detail)

                // Description
                voteDescription

                // Options or Results
                if detail.userBallot != nil {
                    resultsSection(detail: detail)
                } else {
                    votingSection(detail: detail)
                }

                // Cast Vote Button (only if no ballot yet)
                if detail.userBallot == nil {
                    castVoteButton(voteId: detail.vote.id)
                }

                Spacer(minLength: Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
        }
    }

    // MARK: - Vote Header

    private func voteHeader(detail: GovernanceVoteDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TierBadge(tier: vote.tierEligibility)
                statusBadge(status: vote.status)
                Spacer()
            }

            Text(vote.title)
                .font(BJFont.playfair(26, weight: .bold))
                .foregroundColor(Color.textPrimary)

            HStack(spacing: Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textTertiary)
                    Text("Ends \(formattedEndDate)")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textTertiary)
                    Text("\(vote.totalBallots) ballots cast")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Vote Description

    private var voteDescription: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("PROPOSAL")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.goldMid)

            Text(vote.description)
                .font(BJFont.body)
                .foregroundColor(Color.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Voting Section (no ballot yet)

    private func votingSection(detail: GovernanceVoteDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SELECT YOUR VOTE")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.goldMid)

            ForEach(vote.options, id: \.self) { option in
                VoteOptionCard(
                    option: option,
                    isSelected: vm.selectedOption == option,
                    onSelect: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            vm.selectedOption = option
                        }
                    }
                )
            }
        }
    }

    // MARK: - Results Section (ballot already cast)

    private func resultsSection(detail: GovernanceVoteDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("RESULTS")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
                Spacer()
                if let ballot = detail.userBallot {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.success)
                        Text("You voted: \(ballot)")
                            .font(BJFont.micro)
                            .foregroundColor(Color.success)
                    }
                }
            }

            ForEach(vote.options, id: \.self) { option in
                ResultBar(
                    option: option,
                    count: detail.resultsByOption?[option] ?? 0,
                    totalBallots: vote.totalBallots,
                    isUserChoice: detail.userBallot == option
                )
            }
        }
    }

    // MARK: - Cast Vote Button

    private func castVoteButton(voteId: String) -> some View {
        GoldButton(
            title: "Cast Vote",
            action: { Task { await vm.castBallot(voteId: voteId) } },
            isLoading: vm.isCasting,
            isDisabled: vm.selectedOption == nil
        )
    }

    // MARK: - Helpers

    private func statusBadge(status: String) -> some View {
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

    private var formattedEndDate: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: vote.votingEndsAt) else { return vote.votingEndsAt }
        let display = DateFormatter()
        display.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return display.string(from: date)
    }
}

// MARK: - VoteOptionCard

private struct VoteOptionCard: View {
    let option: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.gold : Color.borderSubtle, lineWidth: isSelected ? 2 : 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(LinearGradient.goldShimmer)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(option)
                    .font(BJFont.sora(14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.textPrimary : Color.textSecondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.gold)
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.goldDim.opacity(0.08) : Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.borderGold : Color.borderSubtle, lineWidth: isSelected ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - ResultBar

private struct ResultBar: View {
    let option: String
    let count: Int
    let totalBallots: Int
    let isUserChoice: Bool

    private var percentage: Double {
        guard totalBallots > 0 else { return 0 }
        return Double(count) / Double(totalBallots)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    if isUserChoice {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gold)
                    }
                    Text(option)
                        .font(BJFont.sora(13, weight: isUserChoice ? .semibold : .regular))
                        .foregroundColor(isUserChoice ? Color.gold : Color.textSecondary)
                }
                Spacer()
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(BJFont.outfit(13, weight: .semibold))
                    .foregroundColor(isUserChoice ? Color.gold : Color.textSecondary)
                Text("(\(count))")
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.borderSubtle)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isUserChoice ? LinearGradient.goldShimmer : LinearGradient(colors: [Color.textTertiary, Color.textTertiary.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * percentage, height: 6)
                        .animation(.easeOut(duration: 0.6), value: percentage)
                }
            }
            .frame(height: 6)
        }
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(isUserChoice ? Color.borderGold : Color.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

#Preview {
    NavigationStack {
        GovernanceVoteView(vote: GovernanceVote(
            id: "preview-1",
            title: "Expand High Roller Tier Benefits",
            description: "This proposal seeks to expand the benefits available to High Roller tier members, including increased comp multipliers and exclusive event access.",
            voteType: "standard",
            tierEligibility: "VIP",
            options: ["Approve", "Reject", "Abstain"],
            status: "active",
            votingEndsAt: "2026-03-01T23:59:59Z",
            totalBallots: 847
        ))
    }
    .preferredColorScheme(.dark)
}
