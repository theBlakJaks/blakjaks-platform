import SwiftUI

// MARK: - AffiliateDashboardView
// Affiliate dashboard: referral code, stats grid, payout history, and Sunset Engine badge.

struct AffiliateDashboardView: View {
    @StateObject private var profileVM = ProfileViewModel()

    private let twoColumnGrid = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {

                if profileVM.affiliateDashboard == nil {
                    ProgressView("Loading affiliate data…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    if let dashboard = profileVM.affiliateDashboard {
                        // 1. Referral code card
                        referralCodeCard(dashboard: dashboard)

                        // 4. Sunset Engine badge (shown before stats for prominence)
                        if dashboard.sunsetEngineActive {
                            sunsetEngineBadge
                        }

                        // 2. Stats grid
                        statsGrid(dashboard: dashboard)

                        // 3. Payouts list
                        payoutsCard
                    }
                }
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.backgroundPrimary)
        // "Affiliate" header in New York serif via toolbar principal
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Affiliate")
                    .font(.system(.title, design: .serif))
                    .foregroundColor(.primary)
            }
        }
        .task {
            await profileVM.loadProfile()
            await profileVM.loadAffiliateDashboard()
        }
        .alert("Error", isPresented: Binding(
            get: { profileVM.error != nil },
            set: { if !$0 { profileVM.clearError() } }
        )) {
            Button("OK") { profileVM.clearError() }
        } message: {
            Text(profileVM.error?.localizedDescription ?? "An error occurred.")
        }
    }

    // MARK: - Referral Code Card

    private func referralCodeCard(dashboard: AffiliateDashboard) -> some View {
        GoldAccentCard {
            VStack(spacing: Spacing.md) {
                Text("Referral Code")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Referral code: monospaced, gold, large — use monoTitle2 from Typography
                Text(dashboard.referralCode)
                    .font(.monoTitle2)
                    .foregroundColor(.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Referral URL caption — monospaced pill background
                Text("blakjaks.com/ref/\(dashboard.referralCode.lowercased())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Copy button — GoldButton component
                GoldButton("Copy Code") {
                    UIPasteboard.general.string = dashboard.referralCode
                    // TODO: UIActivityViewController share sheet in production polish pass
                }
            }
        }
    }

    // MARK: - Stats Grid

    private func statsGrid(dashboard: AffiliateDashboard) -> some View {
        LazyVGrid(columns: twoColumnGrid, spacing: Spacing.sm) {
            statCard(value: "\(dashboard.totalDownline)", label: "Total Downline")
            statCard(value: "\(dashboard.activeDownline)", label: "Active Downline")
            statCard(
                value: dashboard.weeklyPool.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                label: "Weekly Pool",
                isGold: true
            )
            statCard(
                value: dashboard.lifetimeEarnings.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                label: "Lifetime Earnings",
                isGold: true
            )
        }
    }

    private func statCard(value: String, label: String, isGold: Bool = false) -> some View {
        BlakJaksCard {
            VStack(spacing: Spacing.xs) {
                Text(value)
                    .font(.title2)
                    .foregroundColor(isGold ? .gold : .primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Payouts Card

    private var payoutsCard: some View {
        BlakJaksCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Payout History")
                    .font(.headline)
                    .foregroundColor(.primary)

                if profileVM.affiliatePayouts.isEmpty {
                    Text("No payouts yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.md)
                } else {
                    VStack(spacing: 0) {
                        ForEach(profileVM.affiliatePayouts) { payout in
                            payoutRow(payout: payout)

                            if payout.id != profileVM.affiliatePayouts.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func payoutRow(payout: AffiliatePayout) -> some View {
        HStack(spacing: Spacing.sm) {
            // Date
            Text(formatPayoutDate(payout.payoutDate))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(minWidth: 72, alignment: .leading)

            // Amount — monospaced gold
            Text(payout.amount.formatted(.currency(code: "USD")))
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .foregroundColor(.gold)

            Spacer()

            // Pool share
            Text("\((payout.poolShare * 100).formatted(.number.precision(.fractionLength(1))))%")
                .font(.caption)
                .foregroundColor(.secondary)

            // Status capsule
            payoutStatusCapsule(status: payout.status)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func payoutStatusCapsule(status: String) -> some View {
        let (label, color): (String, Color) = {
            switch status.lowercased() {
            case "processed": return ("Paid", .success)
            case "pending":   return ("Pending", .warning)
            case "failed":    return ("Failed", .failure)
            default:          return (status.capitalized, .secondary)
            }
        }()

        return Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(color)
            .cornerRadius(6)
    }

    // MARK: - Sunset Engine Badge

    private var sunsetEngineBadge: some View {
        GoldAccentCard {
            HStack(spacing: Spacing.md) {
                Text("⚡")
                    .font(.title2)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sunset Engine Active")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.gold)
                    Text("Your earnings are compounding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Helpers

    private func formatPayoutDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: isoDate) {
            let display = DateFormatter()
            display.dateStyle = .short
            return display.string(from: date)
        }
        // Fallback — return the raw string
        return isoDate
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AffiliateDashboardView()
    }
}
