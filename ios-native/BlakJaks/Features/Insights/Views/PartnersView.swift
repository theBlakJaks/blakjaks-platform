import SwiftUI

// MARK: - PartnersView
// Displays InsightsPartners: affiliate section (active count, Sunset Engine status,
// weekly pool, lifetime match total), tier floor pill badges, wholesale section.

struct PartnersView: View {
    @EnvironmentObject private var vm: InsightsViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoadingPartners && vm.partners == nil {
                InsightsLoadingView()
            } else if let error = vm.errorMessage, vm.partners == nil {
                InsightsErrorView(message: error) { Task { await vm.loadPartners() } }
            } else {
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await vm.loadPartners() }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 1) {
                Text("PARTNERS")
                    .font(BJFont.playfair(18, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .tracking(1)
                Text("AFFILIATE & WHOLESALE")
                    .font(BJFont.eyebrow)
                    .foregroundColor(Color.goldMid)
                    .tracking(2)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                if let partners = vm.partners {
                    affiliateSection(partners: partners)
                    tierFloorSection(partners: partners)
                    wholesaleSection(partners: partners)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable { await vm.loadPartners() }
    }

    // MARK: - Affiliate Section

    @ViewBuilder
    private func affiliateSection(partners: InsightsPartners) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "NETWORK", title: "Affiliate Program")

            // Hero metric — active affiliates
            BlakJaksCard {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.goldMid.opacity(0.1))
                            .frame(width: 52, height: 52)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.goldMid)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(partners.affiliateActiveCount)")
                            .font(BJFont.price)
                            .foregroundColor(Color.textPrimary)
                        Text("Active Affiliates")
                            .font(BJFont.sora(13, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                    }

                    Spacer()
                }
            }

            // Sunset Engine + pool stats
            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    // Sunset Engine status
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sunset Engine")
                                .font(BJFont.sora(13, weight: .medium))
                                .foregroundColor(Color.textSecondary)
                            Text("Match multiplier system")
                                .font(BJFont.caption)
                                .foregroundColor(Color.textTertiary)
                        }
                        Spacer()
                        SunsetEngineBadge(status: partners.sunsetEngineStatus)
                    }

                    Divider().background(Color.borderSubtle)

                    // Weekly pool + lifetime match
                    HStack(spacing: 0) {
                        PartnerStat(
                            label: "Weekly Pool",
                            value: partners.weeklyPool.compactUSDFormatted,
                            icon: "calendar.circle.fill",
                            color: Color.goldMid
                        )
                        Divider()
                            .frame(height: 44)
                            .background(Color.borderSubtle)
                            .padding(.horizontal, Spacing.md)
                        PartnerStat(
                            label: "Lifetime Match",
                            value: partners.lifetimeMatchTotal.compactUSDFormatted,
                            icon: "infinity.circle.fill",
                            color: Color.success
                        )
                    }
                }
            }
        }
    }

    // MARK: - Tier Floor Counts

    @ViewBuilder
    private func tierFloorSection(partners: InsightsPartners) -> some View {
        guard !partners.permanentTierFloorCounts.isEmpty else { return AnyView(EmptyView()) }
        let sorted = partners.permanentTierFloorCounts.sorted { $0.value > $1.value }

        return AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(eyebrow: "TIER LOCKS", title: "Permanent Floor Counts")

                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Members permanently locked into a tier floor via affiliate achievement.")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textTertiary)
                            .padding(.bottom, 4)

                        // Pill badges wrapped in a flow-style layout
                        TierFloorPillGrid(tiers: sorted)
                    }
                }
            }
        )
    }

    // MARK: - Wholesale Section

    @ViewBuilder
    private func wholesaleSection(partners: InsightsPartners) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(eyebrow: "DISTRIBUTION", title: "Wholesale")

            BlakJaksCard {
                VStack(spacing: Spacing.md) {
                    HStack(spacing: 0) {
                        // Active accounts
                        PartnerStat(
                            label: "Active Accounts",
                            value: "\(partners.wholesaleActiveAccounts)",
                            icon: "building.2.fill",
                            color: Color.goldMid
                        )

                        Divider()
                            .frame(height: 44)
                            .background(Color.borderSubtle)
                            .padding(.horizontal, Spacing.md)

                        // Monthly order value
                        PartnerStat(
                            label: "Monthly Orders",
                            value: partners.wholesaleOrderValueThisMonth.compactUSDFormatted,
                            icon: "shippingbox.fill",
                            color: Color.success
                        )
                    }

                    Divider().background(Color.borderSubtle)

                    // Performance callout
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 13))
                            .foregroundColor(Color.goldMid)
                        Text("Wholesale channel — active distribution network")
                            .font(BJFont.caption)
                            .foregroundColor(Color.textSecondary)
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - SunsetEngineBadge

private struct SunsetEngineBadge: View {
    let status: String

    private var isActive: Bool {
        status.lowercased() == "active" || status.lowercased() == "running"
    }

    private var dotColor: Color { isActive ? Color.success : Color.warning }
    private var bgColor: Color  { dotColor.opacity(0.1) }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            Text(status.uppercased())
                .font(BJFont.eyebrow)
                .foregroundColor(dotColor)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
    }
}

// MARK: - PartnerStat

private struct PartnerStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(BJFont.stat)
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - TierFloorPillGrid

private struct TierFloorPillGrid: View {
    let tiers: [(key: String, value: Int)]

    private let tierColors: [String: Color] = [
        "whale":       Color.gold,
        "high_roller": Color.purple,
        "highroller":  Color.purple,
        "high roller": Color.purple,
        "vip":         Color.blue,
        "standard":    Color(UIColor.systemGray)
    ]

    var body: some View {
        // Use a wrapping layout via flexible width pills
        FlowLayout(spacing: Spacing.xs) {
            ForEach(tiers, id: \.key) { tier, count in
                TierFloorPill(
                    tier: tier,
                    count: count,
                    color: tierColors[tier.lowercased()] ?? Color.textTertiary
                )
            }
        }
    }
}

// MARK: - TierFloorPill

private struct TierFloorPill: View {
    let tier: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(tier.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(color)
            Text("·")
                .font(BJFont.sora(11))
                .foregroundColor(color.opacity(0.5))
            Text("\(count)")
                .font(BJFont.outfit(11, weight: .bold))
                .foregroundColor(Color.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.pill)
                .stroke(color.opacity(0.25), lineWidth: 0.8)
        )
    }
}

// MARK: - FlowLayout
// Simple wrapping HStack for pill badges.

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PartnersView()
            .environmentObject(InsightsViewModel())
    }
    .preferredColorScheme(.dark)
}
