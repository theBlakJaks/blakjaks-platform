import SwiftUI

// MARK: - AffiliateDashboardView

struct AffiliateDashboardView: View {

    @StateObject private var vm = AffiliateViewModel()

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            if vm.isLoading && vm.dashboard == nil {
                LoadingView(message: "Loading affiliate data...")
            } else if let dashboard = vm.dashboard {
                mainContent(dashboard: dashboard)
            } else if let error = vm.errorMessage {
                InsightsErrorView(message: error) {
                    Task { await vm.loadAll() }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AFFILIATE")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.gold)
            }
        }
        .disableSwipeBack()
        .task {
            await vm.loadAll()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(dashboard: AffiliateDashboard) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Referral Code Card
                referralCodeCard(dashboard: dashboard)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.lg)

                // Sunset Engine Status
                sunsetEngineBadge(active: dashboard.sunsetEngineActive)
                    .padding(.horizontal, Spacing.md)

                // Stats Grid
                statsGrid(dashboard: dashboard)
                    .padding(.horizontal, Spacing.md)

                // Downline
                if !vm.downline.isEmpty {
                    downlineSection
                        .padding(.horizontal, Spacing.md)
                }

                // Payouts
                if !vm.payouts.isEmpty {
                    payoutsSection
                        .padding(.horizontal, Spacing.md)
                }

                Spacer(minLength: Spacing.xxxl)
            }
        }
        .refreshable { await vm.loadAll() }
    }

    // MARK: - Referral Code Card

    private func referralCodeCard(dashboard: AffiliateDashboard) -> some View {
        BlakJaksCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("YOUR REFERRAL CODE")
                            .font(BJFont.eyebrow)
                            .tracking(3)
                            .foregroundColor(Color.goldMid)
                        Text(dashboard.referralCode)
                            .font(BJFont.playfair(28, weight: .bold))
                            .foregroundColor(Color.gold)
                            .tracking(4)
                    }
                    Spacer()
                    VStack(spacing: Spacing.xs) {
                        copyButton(code: dashboard.referralCode)
                        shareButton(code: dashboard.referralCode)
                    }
                }

                Divider().background(Color.borderSubtle)

                HStack(spacing: Spacing.xxl) {
                    statMini(value: "\(vm.referralCode?.totalUses ?? 0)", label: "Total Uses")
                    if let code = vm.referralCode {
                        statMini(value: code.referralUrl.isEmpty ? "—" : "Active", label: "Status")
                    }
                }
            }
        }
    }

    private func copyButton(code: String) -> some View {
        Button {
            UIPasteboard.general.string = code
            vm.copiedCode = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { vm.copiedCode = false }
        } label: {
            Label(vm.copiedCode ? "Copied" : "Copy", systemImage: vm.copiedCode ? "checkmark" : "doc.on.doc")
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(vm.copiedCode ? Color.success : Color.goldMid)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background((vm.copiedCode ? Color.success : Color.goldDim).opacity(0.1))
                .overlay(Capsule().stroke((vm.copiedCode ? Color.success : Color.borderGold), lineWidth: 0.5))
                .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.15), value: vm.copiedCode)
    }

    private func shareButton(code: String) -> some View {
        Button {
            let url = vm.referralCode?.referralUrl ?? "https://blakjaks.com/refer/\(code)"
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.rootViewController?
                .present(activity, animated: true)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(Color.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 6)
                .background(Color.bgCard)
                .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 0.5))
                .clipShape(Capsule())
        }
    }

    // MARK: - Sunset Engine Badge

    private func sunsetEngineBadge(active: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(active ? Color.success.opacity(0.12) : Color.bgCard)
                    .frame(width: 36, height: 36)
                Image(systemName: active ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 15))
                    .foregroundColor(active ? Color.success : Color.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("SUNSET ENGINE")
                    .font(BJFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(Color.textTertiary)
                Text(active ? "Active — Earning Commissions" : "Inactive")
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(active ? Color.success : Color.textSecondary)
            }

            Spacer()

            Text(active ? "ON" : "OFF")
                .font(BJFont.micro)
                .tracking(1.5)
                .foregroundColor(active ? Color.success : Color.textTertiary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background((active ? Color.success : Color.textTertiary).opacity(0.1))
                .overlay(Capsule().stroke((active ? Color.success : Color.textTertiary).opacity(0.25), lineWidth: 0.5))
                .clipShape(Capsule())
        }
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(active ? Color.success.opacity(0.2) : Color.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    // MARK: - Stats Grid

    private func statsGrid(dashboard: AffiliateDashboard) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                affiliateStat(
                    icon: "person.3.fill",
                    value: "\(dashboard.totalDownline)",
                    label: "Total Downline",
                    color: Color.goldMid
                )
                affiliateStat(
                    icon: "person.fill.checkmark",
                    value: "\(dashboard.activeDownline)",
                    label: "Active Members",
                    color: Color.success
                )
            }
            HStack(spacing: Spacing.sm) {
                affiliateStat(
                    icon: "dollarsign.circle.fill",
                    value: dashboard.weeklyPool.usdFormatted,
                    label: "Weekly Pool",
                    color: Color.gold
                )
                affiliateStat(
                    icon: "trophy.fill",
                    value: dashboard.lifetimeEarnings.usdFormatted,
                    label: "Lifetime Earnings",
                    color: Color.goldMid
                )
            }
            HStack(spacing: Spacing.sm) {
                affiliateStat(
                    icon: "hexagon.fill",
                    value: "\(dashboard.chipBalance)",
                    label: "Chip Balance",
                    color: Color.goldMid
                )
                affiliatePayoutCell(date: dashboard.nextPayoutDate)
            }
        }
    }

    private func affiliateStat(icon: String, value: String, label: String, color: Color) -> some View {
        BlakJaksCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(value)
                    .font(BJFont.outfit(20, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }

    private func affiliatePayoutCell(date: String) -> some View {
        BlakJaksCard {
            VStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18))
                    .foregroundColor(Color.goldMid)
                Text(formattedDate(date))
                    .font(BJFont.outfit(16, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Next Payout")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Downline Section

    private var downlineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(eyebrow: "YOUR NETWORK", title: "Downline Members")

            VStack(spacing: 0) {
                ForEach(vm.downline) { member in
                    DownlineRow(member: member)

                    if member.id != vm.downline.last?.id {
                        Divider()
                            .background(Color.borderSubtle)
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.borderGold, lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
    }

    // MARK: - Payouts Section

    private var payoutsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(eyebrow: "HISTORY", title: "Payouts")

            VStack(spacing: 0) {
                ForEach(vm.payouts) { payout in
                    PayoutRow(payout: payout)

                    if payout.id != vm.payouts.last?.id {
                        Divider()
                            .background(Color.borderSubtle)
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).stroke(Color.borderGold, lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
    }

    // MARK: - Helpers

    private func statMini(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BJFont.outfit(16, weight: .bold))
                .foregroundColor(Color.textPrimary)
            Text(label)
                .font(BJFont.micro)
                .foregroundColor(Color.textTertiary)
        }
    }

    private func formattedDate(_ iso: String) -> String {
        let fmts = [
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }()
        ]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                let d = DateFormatter(); d.dateFormat = "MMM d"
                return d.string(from: date)
            }
        }
        return iso
    }
}

// MARK: - DownlineRow

private struct DownlineRow: View {
    let member: AffiliateDownlineMember

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Active indicator
            Circle()
                .fill(member.activeStatus ? Color.success : Color.textTertiary)
                .frame(width: 8, height: 8)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(member.fullName)
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                HStack(spacing: Spacing.xs) {
                    TierBadge(tier: member.tier)
                    Text("Joined \(shortDate(member.joinDate))")
                        .font(BJFont.micro)
                        .foregroundColor(Color.textTertiary)
                }
            }

            Spacer()

            // Scans this quarter
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.scansThisQuarter)")
                    .font(BJFont.outfit(14, weight: .bold))
                    .foregroundColor(Color.goldMid)
                Text("scans / qtr")
                    .font(BJFont.micro)
                    .foregroundColor(Color.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func shortDate(_ iso: String) -> String {
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        if let date = dateFmt.date(from: String(iso.prefix(10))) {
            let d = DateFormatter(); d.dateFormat = "MMM yy"
            return d.string(from: date)
        }
        return iso
    }
}

// MARK: - PayoutRow

private struct PayoutRow: View {
    let payout: AffiliatePayout

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.success)

            VStack(alignment: .leading, spacing: 3) {
                Text(formattedDate(payout.payoutDate))
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(String(format: "Pool share: %.2f%%", payout.poolShare * 100))
                    .font(BJFont.caption)
                    .foregroundColor(Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(payout.amount.usdFormatted)
                    .font(BJFont.outfit(15, weight: .bold))
                    .foregroundColor(Color.success)
                payoutStatusBadge(payout.status)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func payoutStatusBadge(_ status: String) -> some View {
        let color: Color = status.lowercased() == "paid" ? Color.success : Color.warning
        return Text(status.uppercased())
            .font(BJFont.micro)
            .tracking(1)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
            .clipShape(Capsule())
    }

    private func formattedDate(_ iso: String) -> String {
        let fmts = [
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            { () -> ISO8601DateFormatter in
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }()
        ]
        for fmt in fmts {
            if let date = fmt.date(from: iso) {
                let d = DateFormatter(); d.dateFormat = "MMM d, yyyy"
                return d.string(from: date)
            }
        }
        return iso
    }
}

// MARK: - AffiliateViewModel

@MainActor
final class AffiliateViewModel: ObservableObject {
    @Published var dashboard: AffiliateDashboard?
    @Published var downline: [AffiliateDownlineMember] = []
    @Published var payouts: [AffiliatePayout] = []
    @Published var referralCode: ReferralCode?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var copiedCode = false

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let d = api.getAffiliateDashboard()
            async let dl = api.getAffiliateDownline(limit: 50, offset: 0)
            async let p = api.getAffiliatePayouts(limit: 20, offset: 0)
            async let rc = api.getAffiliateReferralCode()
            dashboard = try await d
            downline = (try? await dl) ?? []
            payouts = (try? await p) ?? []
            referralCode = try? await rc
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AffiliateDashboardView()
    }
    .preferredColorScheme(.dark)
}
