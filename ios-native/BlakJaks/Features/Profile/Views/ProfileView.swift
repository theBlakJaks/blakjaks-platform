import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject private var authState: AuthState

    @State private var showEditProfile    = false
    @State private var showNotifications  = false
    @State private var showAffiliate      = false
    @State private var showWholesale      = false
    @State private var showSignOutAlert   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if vm.isLoading && vm.user == nil {
                    LoadingView(message: "Loading profile...")
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            profileHeader
                                .padding(.top, Spacing.lg)

                            if let user = vm.user {
                                statsCard(user: user)
                                    .padding(.top, Spacing.xl)
                                    .padding(.horizontal, Spacing.md)
                            }

                            menuSections
                                .padding(.top, Spacing.xl)

                            signOutButton
                                .padding(.top, Spacing.lg)
                                .padding(.horizontal, Spacing.md)

                            NicotineWarningBanner()
                                .padding(.top, Spacing.xxl)

                            Spacer(minLength: Spacing.xxxl)
                        }
                    }
                    .refreshable {
                        await vm.loadProfile()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("BlakJaks")
                            .font(BJFont.sora(9, weight: .bold))
                            .tracking(3)
                            .foregroundColor(Color.goldMid.opacity(0.7))
                        Text("Profile")
                            .font(BJFont.sora(13, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView(vm: vm)
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView(vm: vm)
            }
            .navigationDestination(isPresented: $showAffiliate) {
                AffiliateDashboardView()
            }
            .navigationDestination(isPresented: $showWholesale) {
                WholesaleDashboardView()
            }
        }
        .task {
            await vm.loadProfile()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { authState.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: Spacing.md) {
            avatarView

            VStack(spacing: Spacing.xs) {
                // Full name
                Text(vm.user?.displayName ?? "—")
                    .font(BJFont.playfair(26, weight: .bold))
                    .foregroundColor(Color.textPrimary)

                // Tier badge
                if let user = vm.user {
                    tierBadge(user.tier?.name ?? "Member")

                    // Member since
                    Text("Member since 2025")
                        .font(BJFont.sora(11, weight: .regular))
                        .foregroundColor(Color.textTertiary)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Avatar

    private var avatarView: some View {
        ZStack {
            if let urlStr = vm.user?.avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsAvatar
                }
            } else {
                initialsAvatar
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.gold, lineWidth: 2))
        .shadow(color: Color.gold.opacity(0.18), radius: 14)
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle().fill(LinearGradient.goldShimmer)
            Text(initials)
                .font(BJFont.playfair(32, weight: .bold))
                .foregroundColor(Color.bgPrimary)
        }
    }

    private var initials: String {
        let name = vm.user?.displayName ?? ""
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Tier Badge

    private func tierBadge(_ tier: String) -> some View {
        Text(tier)
            .font(BJFont.sora(11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(Color.gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.gold.opacity(0.1))
            .overlay(
                Capsule()
                    .stroke(Color.gold.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    // MARK: - Stats Card

    private func statsCard(user: UserProfile) -> some View {
        HStack(spacing: 0) {
            statCell(value: vm.totalScans.map { "\($0)" } ?? "—", label: "Total Scans")
            statDivider
            statCell(value: vm.walletBalance.map { "$\(String(format: "%.2f", $0))" } ?? "—", label: "Available Balance")
            statDivider
            statCell(value: vm.usdcBalance.map { String(format: "%.2f", $0) } ?? "—", label: "USDC Chips")
        }
        .padding(.vertical, Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(BJFont.outfit(18, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(BJFont.sora(9.5, weight: .semibold))
                .foregroundColor(Color.textTertiary)
                .tracking(0.3)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.borderSubtle)
            .frame(width: 0.5, height: 44)
    }

    // MARK: - Menu Sections

    private var menuSections: some View {
        VStack(spacing: Spacing.lg) {
            menuSection(items: [
                MenuItem(label: "Edit Profile",    icon: "person.fill")       { showEditProfile    = true },
                MenuItem(label: "Notifications",   icon: "bell.fill",
                         badge: vm.unreadCount > 0 ? "\(vm.unreadCount)" : nil) { showNotifications = true },
                MenuItem(label: "Affiliate Dashboard", icon: "person.3.fill") { showAffiliate      = true },
                MenuItem(label: "Wholesale Dashboard", icon: "bag.fill")      { showWholesale      = true }
            ])
        }
        .padding(.horizontal, Spacing.md)
    }

    private func menuSection(items: [MenuItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                menuRow(item)
                if idx < items.count - 1 {
                    Divider()
                        .background(Color.borderSubtle)
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func menuRow(_ item: MenuItem) -> some View {
        Button(action: item.action) {
            HStack(spacing: Spacing.md) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gold.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: item.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.goldMid)
                }

                Text(item.label)
                    .font(BJFont.sora(14, weight: .regular))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                if let badge = item.badge {
                    Text(badge)
                        .font(BJFont.micro)
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.error)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            Text("Sign Out")
                .font(BJFont.sora(15, weight: .semibold))
                .foregroundColor(Color.error)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.error.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.pill)
                        .stroke(Color.error.opacity(0.2), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
        }
    }

    // MARK: - Helpers

    private func formattedMemberSince(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fmt.date(from: iso) {
            let display = DateFormatter()
            display.dateFormat = "yyyy"
            return display.string(from: date)
        }
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        if let date = dateFmt.date(from: iso) {
            let display = DateFormatter()
            display.dateFormat = "yyyy"
            return display.string(from: date)
        }
        return iso
    }
}

// MARK: - MenuItem helper

private struct MenuItem {
    let label: String
    let icon: String
    var badge: String? = nil
    let action: () -> Void
}

// MARK: - ProfileNavItem / ProfileNavRow (kept for backward compat with sub-views)

struct ProfileNavItem {
    let icon: String
    let label: String
    let badge: String?
    var customTrailing: AnyView? = nil
    let action: () -> Void

    init(icon: String, label: String, badge: String?, customTrailing: (some View)? = Optional<EmptyView>.none, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.badge = badge
        self.customTrailing = customTrailing.map { AnyView($0) }
        self.action = action
    }
}

struct ProfileNavRow: View {
    let item: ProfileNavItem

    var body: some View {
        Button(action: item.action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.goldDim.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: item.icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.goldMid)
                }

                Text(item.label)
                    .font(BJFont.sora(14, weight: .regular))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                if let customTrailing = item.customTrailing {
                    customTrailing
                } else if let badge = item.badge {
                    Text(badge)
                        .font(BJFont.micro)
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.error)
                        .clipShape(Capsule())
                }

                if item.customTrailing == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthState())
        .preferredColorScheme(.dark)
}
