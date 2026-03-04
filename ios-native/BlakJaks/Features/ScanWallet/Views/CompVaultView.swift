import SwiftUI

// MARK: - CompVaultView
// Displays the member's comp vault: top-line stats, milestone progress,
// and guaranteed monthly comp history.

struct CompVaultView: View {

    @ObservedObject var vm: ScanWalletViewModel

    var body: some View {
        Group {
            if let vault = vm.compVault {
                loadedContent(vault: vault)
            } else {
                loadingState
            }
        }
        .padding(.horizontal, Spacing.md)
        .task {
            if vm.compVault == nil {
                await vm.loadCompVault()
            }
        }
    }

    // MARK: - Loaded Content

    private func loadedContent(vault: CompVault) -> some View {
        VStack(spacing: Spacing.md) {
            statsCard(vault: vault)
            milestonesCard(milestones: vault.milestones)
            guaranteedCompsCard(comps: vault.guaranteedComps)
        }
    }

    // MARK: - Stats Card

    private func statsCard(vault: CompVault) -> some View {
        BlakJaksCard(padding: Spacing.lg) {
            VStack(spacing: Spacing.lg) {
                // Available balance — hero
                VStack(spacing: 4) {
                    Text("AVAILABLE COMP BALANCE")
                        .font(BJFont.eyebrow)
                        .tracking(4)
                        .foregroundColor(Color.textTertiary)
                    Text(vault.availableBalance.usdFormatted)
                        .font(BJFont.outfit(40, weight: .heavy))
                        .foregroundStyle(LinearGradient.goldShimmer)
                }
                .frame(maxWidth: .infinity)

                Divider().background(Color.borderGold)

                // Secondary stats row
                HStack(spacing: 0) {
                    statCell(
                        label: "LIFETIME COMPS",
                        value: vault.lifetimeComps.usdFormatted,
                        icon: "trophy"
                    )

                    Divider()
                        .background(Color.borderGold)
                        .frame(height: 40)

                    statCell(
                        label: "GOLD CHIPS",
                        value: "\(vault.goldChips)",
                        icon: "circle.hexagongrid"
                    )
                }
            }
        }
    }

    private func statCell(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.goldMid)
            Text(value)
                .font(BJFont.stat)
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(BJFont.micro)
                .tracking(1.5)
                .foregroundColor(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Milestones Card

    private func milestonesCard(milestones: [CompMilestone]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("MILESTONES")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.textTertiary)
                Spacer()
                Text("\(milestones.filter(\.achieved).count)/\(milestones.count)")
                    .font(BJFont.micro)
                    .foregroundColor(Color.goldMid)
            }
            .padding(.horizontal, 4)

            BlakJaksCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(milestones.enumerated()), id: \.element.id) { idx, milestone in
                        MilestoneRow(milestone: milestone)
                        if idx < milestones.count - 1 {
                            Divider()
                                .background(Color.borderGold)
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Guaranteed Comps Card

    private func guaranteedCompsCard(comps: [GuaranteedComp]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("GUARANTEED COMPS")
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.textTertiary)
                .padding(.horizontal, 4)

            if comps.isEmpty {
                BlakJaksCard {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(Color.textTertiary)
                        Text("No guaranteed comps on record yet.")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                    }
                }
            } else {
                BlakJaksCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(comps.enumerated()), id: \.element.id) { idx, comp in
                            GuaranteedCompRow(comp: comp)
                            if idx < comps.count - 1 {
                                Divider()
                                    .background(Color.borderGold)
                                    .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            BlakJaksCard(padding: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    ProgressView().tint(Color.gold)
                    Text("Loading Comp Vault…")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
    }
}

// MARK: - MilestoneRow

private struct MilestoneRow: View {

    let milestone: CompMilestone

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(milestone.achieved ? Color.success.opacity(0.12) : Color.bgCard)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(
                            milestone.achieved ? Color.success.opacity(0.3) : Color.borderGold,
                            lineWidth: 0.8
                        )
                    )
                Image(systemName: milestone.achieved ? "checkmark" : "lock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(milestone.achieved ? Color.success : Color.textTertiary)
            }

            // Label + threshold
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.label)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(milestone.achieved ? Color.textPrimary : Color.textSecondary)

                HStack(spacing: 4) {
                    Text(milestone.threshold.usdFormatted)
                        .font(BJFont.caption)
                        .foregroundColor(milestone.achieved ? Color.goldMid : Color.textTertiary)

                    if let date = milestone.achievedAt, milestone.achieved {
                        Text("· \(shortDate(date))")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                    }
                }
            }

            Spacer()

            if milestone.achieved {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gold)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func shortDate(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        let out = DateFormatter()
        out.dateFormat = "MMM d, yyyy"
        guard let d = fmt.date(from: iso) else { return iso }
        return out.string(from: d)
    }
}

// MARK: - GuaranteedCompRow

private struct GuaranteedCompRow: View {

    let comp: GuaranteedComp

    private var statusColor: Color {
        switch comp.status.lowercased() {
        case "paid":    return .success
        case "pending": return .pendingAmount
        default:        return .textTertiary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Calendar icon
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.goldMid.opacity(0.08))
                    .frame(width: 44, height: 44)
                VStack(spacing: 0) {
                    Text(monthAbbreviation)
                        .font(BJFont.micro)
                        .tracking(1)
                        .foregroundColor(Color.goldMid)
                    Text(yearSuffix)
                        .font(BJFont.outfit(11, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(comp.month)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                if let paid = comp.paidAt {
                    Text("Paid \(shortDate(paid))")
                        .font(BJFont.caption)
                        .foregroundColor(Color.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(comp.amount.usdFormatted)
                    .font(BJFont.outfit(15, weight: .bold))
                    .foregroundColor(statusColor)

                Text(comp.status.uppercased())
                    .font(BJFont.micro)
                    .tracking(1)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .overlay(Capsule().stroke(statusColor.opacity(0.25), lineWidth: 0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private var monthAbbreviation: String {
        String(comp.month.prefix(3)).uppercased()
    }

    private var yearSuffix: String {
        let parts = comp.month.split(separator: " ")
        return parts.last.map(String.init) ?? ""
    }

    private func shortDate(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        guard let d = fmt.date(from: iso) else { return iso }
        return out.string(from: d)
    }
}

#Preview {
    ScrollView {
        CompVaultView(vm: ScanWalletViewModel())
    }
    .background(Color.bgPrimary)
}
