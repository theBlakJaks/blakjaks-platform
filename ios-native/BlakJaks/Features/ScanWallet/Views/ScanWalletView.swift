import SwiftUI

// MARK: - ScanWalletView
// Single-page scrollable screen matching the #s-scanwallet HTML mockup exactly.
// Sections in order: Header → Member Card → Scan Circle →
//   Wallet (divider + balance card) → Transactions → Scan History →
//   Comp Vault (divider + total card + sub-tabs + items)

struct ScanWalletView: View {

    @StateObject private var vm = ScanWalletViewModel()
    @StateObject private var scannerVM = ScannerViewModel()

    @State private var showScanner = false
    @State private var showPayoutChoice = false
    @State private var pendingComp: CompEarned?
    @State private var selectedCompTab: CompTab = .all

    // Pulse animation state for the scan circle
    @State private var scanPulse = false

    enum CompTab: String, CaseIterable {
        case all       = "All"
        case crypto    = "Crypto"
        case trips     = "Trips"
        case goldChips = "Gold Chips"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ──────────────────────────────────────────────
                    screenHeader
                        .padding(.top, Spacing.lg)
                        .padding(.horizontal, Spacing.md)

                    // ── Member Card ──────────────────────────────────────────
                    memberCard
                        .padding(.top, Spacing.md)
                        .padding(.horizontal, Spacing.md)

                    // ── Scan Circle ──────────────────────────────────────────
                    scanCircle
                        .padding(.top, Spacing.xl)

                    // ── Wallet Divider ───────────────────────────────────────
                    sectionDivider(title: "Wallet")
                        .padding(.horizontal, Spacing.md)

                    // ── Wallet Balance Card ──────────────────────────────────
                    walletBalanceCard
                        .padding(.horizontal, Spacing.md)

                    // ── Transactions Heading ─────────────────────────────────
                    HStack {
                        Text("Transactions")
                            .font(BJFont.sora(13, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                    .padding(.horizontal, Spacing.md)

                    // ── Transaction Rows ─────────────────────────────────────
                    txSection
                        .padding(.horizontal, Spacing.md)

                    // ── Scan History Divider ─────────────────────────────────
                    sectionDivider(title: "Scan History")
                        .padding(.top, 4)
                        .padding(.horizontal, Spacing.md)

                    // ── Scan History Rows ─────────────────────────────────────
                    scanHistorySection
                        .padding(.horizontal, Spacing.md)

                    // ── Comp Vault Divider ────────────────────────────────────
                    sectionDivider(title: "Comp Vault")
                        .padding(.horizontal, Spacing.md)

                    // ── Comp Vault Total Card ─────────────────────────────────
                    compVaultCard
                        .padding(.horizontal, Spacing.md)

                    // ── Sub-tabs ──────────────────────────────────────────────
                    compSubTabs
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)

                    // ── Comp Vault Items ──────────────────────────────────────
                    compVaultItems
                        .padding(.horizontal, Spacing.md)

                    Spacer(minLength: 80) // bottom nav clearance
                }
            }
            .refreshable {
                await vm.loadWallet()
                await vm.loadTransactions(refresh: true)
                await vm.loadCompVault()
            }
        }
        .task {
            await vm.loadWallet()
            await vm.loadTransactions()
            await vm.loadCompVault()
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2).repeatForever(autoreverses: true)
            ) {
                scanPulse = true
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScanModalView(vm: scannerVM) { result in
                showScanner = false
                if let comp = result.compEarned, comp.requiresPayoutChoice {
                    pendingComp = comp
                    showPayoutChoice = true
                }
                Task { await vm.loadWallet() }
            }
        }
        .sheet(isPresented: $showPayoutChoice) {
            if let comp = pendingComp {
                PayoutChoiceSheet(vm: vm, comp: comp) {
                    showPayoutChoice = false
                    pendingComp = nil
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Screen Header

    private var screenHeader: some View {
        VStack(spacing: 2) {
            Text("BlakJaks")
                .font(BJFont.playfair(9))
                .tracking(5)
                .foregroundColor(Color.gold.opacity(0.6))
                .textCase(.uppercase)

            Text("Scan & Wallet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - Member Card

    private var memberCard: some View {
        ZStack(alignment: .topLeading) {
            // Base gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 20/255, green: 20/255, blue: 20/255),
                            Color(red: 10/255, green: 10/255, blue: 10/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Diagonal stripe overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    ImagePaint(
                        image: stripeImage(),
                        scale: 1
                    )
                )
                .opacity(1)
                .allowsHitTesting(false)

            // Gold border
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gold.opacity(0.25), lineWidth: 1)

            // Content
            VStack(alignment: .leading, spacing: 0) {

                // Top row: name + tier icon
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BlakJaks")
                            .font(BJFont.playfair(9))
                            .tracking(5)
                            .foregroundColor(Color.gold.opacity(0.6))
                            .textCase(.uppercase)

                        Text("Joshua Dunn")
                            .font(BJFont.playfair(22, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                    }

                    Spacer()

                    Text("♣")
                        .font(.system(size: 28))
                        .foregroundColor(Color.gold.opacity(0.6))
                }

                // Meta row
                HStack(spacing: 0) {
                    mcMetaItem(label: "Member ID", value: "BJ-0001-HR", gold: false)
                    mcMetaItem(label: "Tier", value: "High Roller", gold: true)
                    mcMetaItem(label: "Since", value: "2025", gold: false)
                }
                .padding(.top, 14)
                .padding(.bottom, 12)
                .overlay(
                    Divider()
                        .background(Color.gold.opacity(0.08)),
                    alignment: .top
                )

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gold, Color(red: 1, green: 0.84, blue: 0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.494, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.bottom, 4)

                // Bar labels
                HStack {
                    Text("247 scans")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.33))
                    Spacer()
                    Text("500 for Whale")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.33))
                }

                // Oobit Spend Card row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Oobit Spend Card")
                            .font(.system(size: 9))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.4))
                            .textCase(.uppercase)

                        Text("•••• •••• •••• 4821")
                            .font(.custom("Courier New", size: 14).weight(.semibold))
                            .tracking(2)
                            .foregroundColor(Color.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.106, green: 0.369, blue: 0.125).opacity(0.2))
                            .cornerRadius(5)

                        Text("Visa")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.33))
                    }
                }
                .padding(.top, 14)
                .padding(.top, 12)
                .overlay(
                    Divider()
                        .background(Color.gold.opacity(0.12)),
                    alignment: .top
                )
            }
            .padding(20)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func mcMetaItem(label: String, value: String, gold: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9))
                .tracking(1.5)
                .foregroundColor(Color(white: 0.33))

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(gold ? Color.gold : Color(white: 0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Generates a stripe tile image for the member card background
    private func stripeImage() -> Image {
        let size = CGSize(width: 60, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { ctx in
            let stripe = UIColor(red: 212/255, green: 175/255, blue: 55/255, alpha: 0.02)
            stripe.setFill()
            // Diagonal stripes at 45°
            let path = UIBezierPath()
            let step: CGFloat = 30
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + step, y: 0))
                path.addLine(to: CGPoint(x: x + step + size.height, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                path.close()
                x += step * 2
            }
            path.fill()
        }
        return Image(uiImage: uiImage)
    }

    // MARK: - Scan Circle

    private var scanCircle: some View {
        Button {
            showScanner = true
        } label: {
            VStack(spacing: 0) {
                Text("♠")
                    .font(.system(size: 32))
                    .foregroundColor(Color.gold.opacity(0.7))

                Text("Tap to Scan")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(Color.textPrimary)
                    .padding(.top, 6)

                Text("QR or NFC")
                    .font(.system(size: 10))
                    .tracking(1)
                    .foregroundColor(Color(white: 0.33))
                    .padding(.top, 2)
            }
            .frame(width: 140, height: 140)
            .background(Color.gold.opacity(0.04))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        Color.gold.opacity(scanPulse ? 0.6 : 0.35),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: Color.gold.opacity(scanPulse ? 0.2 : 0.1),
                radius: scanPulse ? 50 : 30
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scanPulse)
    }

    // MARK: - Section Divider

    private func sectionDivider(title: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(white: 0.1))
                .frame(height: 1)

            Text(title.uppercased())
                .font(BJFont.sora(11))
                .tracking(2)
                .foregroundColor(Color(white: 0.267))

            Rectangle()
                .fill(Color(white: 0.1))
                .frame(height: 1)
        }
        .padding(.vertical, 18)
    }

    // MARK: - Wallet Balance Card

    private var walletBalanceCard: some View {
        VStack(spacing: 0) {
            Text("Available Balance")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(Color(white: 0.4))
                .textCase(.uppercase)

            Text(vm.wallet?.availableBalance.usdFormatted ?? "$1,847.50")
                .font(BJFont.playfair(34, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .padding(.top, 8)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.4), value: vm.wallet?.availableBalance)

            Text("USDC · Polygon")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
                .padding(.top, 4)

            HStack(spacing: 12) {
                // Send button — gold filled
                Button {
                    // send action
                } label: {
                    Text("Send")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.bgPrimary)
                        .frame(height: 38)
                        .padding(.horizontal, 22)
                        .background(LinearGradient.goldShimmer)
                        .clipShape(Capsule())
                }

                // Receive button — outline
                Button {
                    // receive action
                } label: {
                    Text("Receive")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.gold)
                        .frame(height: 38)
                        .padding(.horizontal, 22)
                        .overlay(
                            Capsule().stroke(Color.gold.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: Color.gold.opacity(0.08), radius: 16)
    }

    // MARK: - Transactions Section

    private var txSection: some View {
        VStack(spacing: 0) {
            // Use live data if available, otherwise display mock rows
            if vm.isLoadingTransactions && vm.transactions.isEmpty {
                ProgressView().tint(Color.gold).padding()
            } else if !vm.transactions.isEmpty {
                ForEach(vm.transactions.prefix(5)) { tx in
                    mockStyleTxRow(
                        desc: tx.description,
                        meta: tx.shortDate,
                        amount: tx.displayAmount,
                        isCredit: tx.isCredit
                    )
                }
            } else {
                // Hard-coded mock rows matching the mockup exactly
                mockStyleTxRow(desc: "Comp Payout",    meta: "Feb 12", amount: "+$125.00",  isCredit: true)
                mockStyleTxRow(desc: "Oobit Card Spend", meta: "Feb 11", amount: "-$43.20",  isCredit: false)
                mockStyleTxRow(desc: "Comp Payout",    meta: "Feb 8",  amount: "+$87.50",  isCredit: true)
                mockStyleTxRow(desc: "Oobit Card Spend", meta: "Feb 7",  amount: "-$156.80", isCredit: false)
                mockStyleTxRow(desc: "Wallet Fund",    meta: "Feb 5",  amount: "+$500.00", isCredit: true)
            }
        }
    }

    private func mockStyleTxRow(desc: String, meta: String, amount: String, isCredit: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(desc)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.8))

                Text(meta)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.267))
            }

            Spacer()

            Text(amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(
                    isCredit
                        ? Color(red: 0.298, green: 0.686, blue: 0.314)
                        : Color(red: 0.937, green: 0.325, blue: 0.314)
                )
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Color(white: 0.067))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Scan History Section

    private var scanHistorySection: some View {
        VStack(spacing: 0) {
            scanHistoryRow(
                desc: "BlakJaks Mint Ice",
                meta: "+$4.50 USDC · 2h ago"
            )
            scanHistoryRow(
                desc: "BlakJaks Wintergreen",
                meta: "+$4.50 USDC · Yesterday"
            )
        }
    }

    private func scanHistoryRow(desc: String, meta: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(desc)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.8))

                Text(meta)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.267))
            }

            Spacer()

            Text("✓")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
                .frame(width: 28, height: 28)
                .background(Color(red: 0.106, green: 0.369, blue: 0.125).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(Color(white: 0.067))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Comp Vault Card

    private var compVaultCard: some View {
        VStack(spacing: 4) {
            Text("Lifetime Comps")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(Color(white: 0.4))

            Text(vm.compVault?.lifetimeComps.usdFormatted ?? "$2,847.50")
                .font(BJFont.playfair(30, weight: .bold))
                .foregroundColor(Color.gold)

            Text("Crypto + Trips + Gold Chips")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.53))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .shadow(color: Color.gold.opacity(0.08), radius: 16)
    }

    // MARK: - Comp Sub-tabs

    private var compSubTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CompTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedCompTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(BJFont.sora(11))
                            .foregroundColor(
                                selectedCompTab == tab
                                    ? Color.gold
                                    : Color(white: 0.33)
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedCompTab == tab
                                    ? Color.gold.opacity(0.1)
                                    : Color.clear
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCompTab == tab
                                            ? Color.gold.opacity(0.3)
                                            : Color(white: 0.133),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Comp Vault Items

    private var compVaultItems: some View {
        VStack(spacing: 0) {
            compVaultItem(
                icon: "₮",
                desc: "$125.00 USDT · Crypto",
                date: "Feb 12",
                badge: "paid",
                badgeColor: Color(red: 0.298, green: 0.686, blue: 0.314),
                badgeBg: Color(red: 0.106, green: 0.369, blue: 0.125).opacity(0.2),
                show: selectedCompTab == .all || selectedCompTab == .crypto
            )
            compVaultItem(
                icon: "✈",
                desc: "Bellagio 2N Suite · Trip",
                date: "Feb 10",
                badge: "redeemed",
                badgeColor: Color(white: 0.53),
                badgeBg: Color(white: 0.1),
                show: selectedCompTab == .all || selectedCompTab == .trips
            )
            compVaultItem(
                icon: "₮",
                desc: "$87.50 USDT · Crypto",
                date: "Feb 8",
                badge: "paid",
                badgeColor: Color(red: 0.298, green: 0.686, blue: 0.314),
                badgeBg: Color(red: 0.106, green: 0.369, blue: 0.125).opacity(0.2),
                show: selectedCompTab == .all || selectedCompTab == .crypto
            )
            compVaultItem(
                icon: "♠",
                desc: "VIP Dinner Experience · Gold Chip",
                date: "Feb 5",
                badge: "available",
                badgeColor: Color.gold,
                badgeBg: Color.gold.opacity(0.12),
                show: selectedCompTab == .all || selectedCompTab == .goldChips
            )
            compVaultItem(
                icon: "₮",
                desc: "$62.00 USDT · Crypto",
                date: "Feb 1",
                badge: "paid",
                badgeColor: Color(red: 0.298, green: 0.686, blue: 0.314),
                badgeBg: Color(red: 0.106, green: 0.369, blue: 0.125).opacity(0.2),
                show: selectedCompTab == .all || selectedCompTab == .crypto
            )
        }
    }

    @ViewBuilder
    private func compVaultItem(
        icon: String,
        desc: String,
        date: String,
        badge: String,
        badgeColor: Color,
        badgeBg: Color,
        show: Bool
    ) -> some View {
        if show {
            HStack(spacing: Spacing.sm) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color.gold.opacity(0.08))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(Color.borderGold, lineWidth: 0.5)
                        )
                    Text(icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(desc)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(white: 0.8))

                    Text(date)
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.267))
                }

                Spacer()

                Text(badge)
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeBg)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .fill(Color(white: 0.067))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Transaction display helpers

private extension Transaction {
    var isCredit: Bool {
        let t = type.lowercased()
        return t.contains("credit") || t.contains("earn") || t.contains("comp") || t.contains("deposit") || t.contains("fund")
    }

    var displayAmount: String {
        let prefix = isCredit ? "+" : "-"
        return "\(prefix)\(amount.usdFormatted)"
    }

    var shortDate: String {
        let iso = ISO8601DateFormatter()
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        if let d = iso.date(from: createdAt) { return out.string(from: d) }
        return createdAt
    }
}

// MARK: - Formatting helpers

extension String {
    var truncatedWalletAddress: String {
        guard count > 12 else { return self }
        return "\(prefix(6))...\(suffix(4))"
    }
}

#Preview {
    ScanWalletView()
        .environmentObject(AuthState())
}
