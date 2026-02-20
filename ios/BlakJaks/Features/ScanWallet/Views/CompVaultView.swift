import SwiftUI

// MARK: - CompVaultView
// Lifetime comps hero, milestone cards, filter tabs, guaranteed comp list.

struct CompVaultView: View {
    let compVault: CompVault?
    @State private var filter: CompFilter = .all

    enum CompFilter: String, CaseIterable {
        case all = "All"
        case crypto = "Crypto"
        case trips = "Trips"
        case chips = "Gold Chips"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Comp Vault")
                .font(.title3.weight(.bold))
                .padding(.horizontal, Layout.screenMargin)

            if let vault = compVault {
                vaultContent(vault: vault)
            } else {
                EmptyStateView(
                    icon: "vault",
                    title: "No Comp Data",
                    subtitle: "Earn your first comp by reaching a scan milestone."
                )
                .padding(.horizontal, Layout.screenMargin)
            }
        }
        .padding(.bottom, Spacing.xxl)
    }

    private func vaultContent(vault: CompVault) -> some View {
        VStack(spacing: Spacing.md) {
            // Hero card
            GoldAccentCard {
                VStack(spacing: Spacing.sm) {
                    Text("Lifetime Comps")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Text("$\(vault.lifetimeComps.formatted(.number.precision(.fractionLength(2))))")
                        .font(.walletBalance)
                        .foregroundColor(.gold)
                    HStack(spacing: Spacing.md) {
                        Text("Crypto + Trips + Gold Chips")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("♠")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.gold)
                            Text("\(vault.goldChips) chips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
            }
            .padding(.horizontal, Layout.screenMargin)

            // Milestone progress
            BlakJaksCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Milestones")
                        .font(.headline)
                    ForEach(vault.milestones) { milestone in
                        milestoneRow(milestone)
                        if milestone.id != vault.milestones.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)

            // Filter tabs
            HStack(spacing: 0) {
                ForEach(CompFilter.allCases, id: \.self) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(filter == f ? .black : .secondary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(filter == f ? Color.gold : Color.clear)
                            )
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)

            // Guaranteed comps
            if !vault.guaranteedComps.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vault.guaranteedComps) { comp in
                        guaranteedCompRow(comp)
                        if comp.id != vault.guaranteedComps.last?.id {
                            Divider().padding(.horizontal, Layout.screenMargin)
                        }
                    }
                }
                .background(Color.backgroundSecondary)
                .cornerRadius(Layout.cardCornerRadius)
                .padding(.horizontal, Layout.screenMargin)
            }
        }
    }

    // MARK: - Milestone row

    private func milestoneRow(_ milestone: CompMilestone) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(milestone.achieved ? Color.gold.opacity(0.15) : Color.backgroundTertiary)
                    .frame(width: 36, height: 36)
                if milestone.achieved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gold)
                } else {
                    Image(systemName: "circle.dashed")
                        .foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.label)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(milestone.achieved ? .primary : .secondary)
                if let achieved = milestone.achievedAt {
                    Text("Achieved \(achieved.relativeTimeString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text("$\(milestone.threshold.formatted(.number.precision(.fractionLength(0))))")
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundColor(milestone.achieved ? .gold : .secondary)
        }
    }

    // MARK: - Guaranteed comp row

    private func guaranteedCompRow(_ comp: GuaranteedComp) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("♠")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Guaranteed Comp — \(comp.month)")
                    .font(.footnote.weight(.medium))
                if let paidAt = comp.paidAt {
                    Text("Paid \(paidAt.relativeTimeString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+$\(comp.amount.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(.success)
                statusCapsule(comp.status)
            }
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.md)
    }

    private func statusCapsule(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(status == "paid" ? .success : .warning)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule().fill((status == "paid" ? Color.success : Color.warning).opacity(0.15))
            )
    }
}
