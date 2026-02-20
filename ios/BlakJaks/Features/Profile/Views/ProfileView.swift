import SwiftUI

// MARK: - ProfileView
// Top-level profile screen: header card, stats strip, nav rows, and sign-out.

struct ProfileView: View {
    @StateObject private var profileVM = ProfileViewModel()

    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showAffiliateDashboard = false
    @State private var showOrderHistory = false

    var body: some View {
        NavigationStack {
            Group {
                if profileVM.isLoadingProfile && profileVM.profile == nil {
                    ProgressView("Loading profile…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.backgroundPrimary)
                } else if let profile = profileVM.profile {
                    profileContent(profile: profile)
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "Could Not Load Profile",
                        subtitle: "Check your connection and try again.",
                        actionTitle: "Retry"
                    ) {
                        Task { await profileVM.loadProfile() }
                    }
                    .background(Color.backgroundPrimary)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task { await profileVM.loadProfile() }
            .alert("Error", isPresented: Binding(
                get: { profileVM.error != nil },
                set: { if !$0 { profileVM.clearError() } }
            )) {
                Button("OK") { profileVM.clearError() }
            } message: {
                Text(profileVM.error?.localizedDescription ?? "An error occurred.")
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profileVM: profileVM)
            }
            .navigationDestination(isPresented: $showOrderHistory) {
                OrderHistoryView()
            }
            .navigationDestination(isPresented: $showAffiliateDashboard) {
                AffiliateDashboardView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Profile Content

    @ViewBuilder
    private func profileContent(profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                headerCard(profile: profile)
                statsStrip(profile: profile)
                navRows(profile: profile)
                logoutButton
            }
            .padding(.horizontal, Layout.screenMargin)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.backgroundPrimary)
    }

    // MARK: - Header Card

    private func headerCard(profile: UserProfile) -> some View {
        GoldAccentCard {
            VStack(spacing: Spacing.md) {
                // Avatar circle with gold ring
                ZStack {
                    Circle()
                        .fill(Color.backgroundTertiary)
                        .frame(width: 80, height: 80)

                    Text(String(profile.fullName.prefix(1)).uppercased())
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.gold)
                }
                .overlay(
                    Circle()
                        .stroke(Color.gold, lineWidth: 2.5)
                        .frame(width: 84, height: 84)
                )
                .padding(.top, Spacing.sm)

                // Full name
                Text(profile.fullName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                // Member ID — monospaced caption
                Text(profile.memberId)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)

                // Tier badge
                TierBadge(tier: profile.tier)

                // Gold chips
                HStack(spacing: Spacing.xs) {
                    Text("⚡")
                        .font(.caption)
                    Text("\(profile.goldChips.formatted()) Gold Chips")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gold)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Stats Strip

    private func statsStrip(profile: UserProfile) -> some View {
        HStack(spacing: Spacing.sm) {
            statCell(
                icon: "qrcode.viewfinder",
                value: "\(profile.scansThisQuarter)",
                label: "Scans"
            )
            statCell(
                icon: "chart.line.uptrend.xyaxis",
                value: formatCurrency(profile.lifetimeUsdt),
                label: "Lifetime"
            )
            statCell(
                icon: "wallet.pass",
                value: formatCurrency(profile.walletBalance),
                label: "Balance"
            )
        }
    }

    private func statCell(icon: String, value: String, label: String) -> some View {
        BlakJaksCard {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gold)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Nav Rows

    private func navRows(profile: UserProfile) -> some View {
        BlakJaksCard {
            VStack(spacing: 0) {
                navRow(icon: "person.crop.circle", title: "Edit Profile") {
                    showEditProfile = true
                }

                rowDivider

                navRow(icon: "bag", title: "Order History") {
                    showOrderHistory = true
                }

                if profile.isAffiliate {
                    rowDivider
                    navRow(icon: "person.2.badge.gearshape", title: "Affiliate Program") {
                        showAffiliateDashboard = true
                    }
                }

                rowDivider

                navRow(icon: "gearshape", title: "Settings") {
                    showSettings = true
                }
            }
        }
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 44)
    }

    private func navRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gold)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, Layout.listRowVerticalPadding)
        }
    }

    // MARK: - Logout Button

    private var logoutButton: some View {
        Button(role: .destructive) {
            Task { await profileVM.logout() }
        } label: {
            Text("Sign Out")
                .font(.body.weight(.semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0...2)))
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
