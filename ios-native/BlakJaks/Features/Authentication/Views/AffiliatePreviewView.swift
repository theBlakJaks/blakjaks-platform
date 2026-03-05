import SwiftUI

// MARK: - AffiliatePreviewView
// Faithfully converted from the #s-affiliate React mockup section.
// All content is static / hardcoded. No API calls.

struct AffiliatePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    private let amber = Color.goldAmber

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        AffHeroSection()
                        AffGoldDivider()
                        AffHowItWorksSection()
                        AffGoldDivider()
                        AffMatchSection()
                        AffGoldDivider()
                        AffTierStatusSection()
                        AffGoldDivider()
                        AffiliateChipsSection()
                        AffGoldDivider()
                        AffiliatePoolSection()
                        AffGoldDivider()
                        AffTransparencyDashboard()
                        AffGoldDivider()
                        AffCalculatorSection()
                        AffGoldDivider()
                        AffSunsetWindow()
                        AffGoldDivider()
                        AffFAQSection()
                    }
                    .padding(.bottom, 40)
                    .frame(width: geo.size.width)
                    .clipped()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(amber)
                        Text("BACK")
                            .font(BJFont.sora(12, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(amber)
                    }
                }
            }
        }
        .toolbarBackground(Color(red: 10/255, green: 10/255, blue: 10/255).opacity(0.85), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .disableSwipeBack()
    }
}

// MARK: - Nav Bar

private struct AffNavBar: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.bgPrimary

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.goldAmber)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 8)

            Text("AFFILIATE")
                .font(BJFont.sora(13, weight: .bold))
                .tracking(3)
                .foregroundColor(Color.goldAmber)
        }
        .frame(height: 52)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.goldAmber.opacity(0.15)),
            alignment: .bottom
        )
    }
}

// MARK: - Gold Divider

private struct AffGoldDivider: View {
    var body: some View {
        LinearGradient(
            colors: [Color.clear, Color.goldAmber.opacity(0.2), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.horizontal, 40)
    }
}

// MARK: - Section Title

private struct AffSectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            LinearGradient(
                colors: [Color.clear, Color.goldAmber.opacity(0.3), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            Text(text)
                .font(BJFont.playfair(12, weight: .bold))
                .tracking(3)
                .foregroundColor(Color.goldAmber)
                .textCase(.uppercase)
                .fixedSize()

            LinearGradient(
                colors: [Color.clear, Color.goldAmber.opacity(0.3), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Card Container

private struct AffCard<Content: View>: View {
    var glow: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#111111"), Color.bgPrimary],
                        startPoint: .init(x: 0.15, y: 0),
                        endPoint: .init(x: 0.85, y: 1)
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.goldAmber.opacity(glow ? 0.35 : 0.15), lineWidth: 1)
                )

            // Top gold line
            LinearGradient(
                colors: [Color.clear, Color.goldAmber, Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            content()
        }
    }
}

// MARK: - Live Ticker Banner

private struct AffLiveTickerBanner: View {
    private let tickerItems: [(user: String, event: String, cut: String)] = [
        ("@mike_d",      "referral won $100 Comp",                  "$21"),
        ("@sarah_k",     "referral won $1,000 Comp",                "$210"),
        ("@crypto_c",    "hit 210 tins, VIP unlocked",             "tier"),
        ("@vegas_v",     "referral won Casino Package",             "$1,050"),
        ("@lucky_l",     "referral won $10K Comp",                  "$2,100"),
        ("@ace_a",       "hit 2,100 tins, High Roller unlocked",   "tier"),
        ("@high_h",      "referral won $200K Gold Chip Trip",       "$42,000"),
        ("@diana_d",     "earned 847 affiliate chips",              "chips"),
        ("@royal_r",     "referral won $10K Comp",                  "$2,100"),
        ("@jenny_j",     "hit 21,000 tins, Whale unlocked",        "tier"),
        ("@playboy_p",   "referral won $5K Casino Package",         "$1,050"),
        ("@golden_g",    "referral won Ducati Motorcycle",          "$6,300"),
        ("@silk_sam",    "hit 2,100 tins, High Roller unlocked",   "tier"),
        ("@stacks_s",    "referral won $50K Comp",                  "$10,500"),
        ("@neon_n",      "earned 2,400 affiliate chips",            "chips"),
    ]

    @State private var offset: CGFloat = 0
    @State private var totalWidth: CGFloat = 0

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color.bgPrimary, Color(hex: "#111111"), Color.bgPrimary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 38)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.goldAmber.opacity(0.2)),
                alignment: .bottom
            )

            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 0) {
                            ForEach(tickerItems.indices, id: \.self) { i in
                                tickerItemView(tickerItems[i])
                                    .padding(.horizontal, 12)
                            }
                        }
                        .background(
                            GeometryReader { inner in
                                Color.clear.onAppear {
                                    totalWidth = inner.size.width
                                }
                            }
                        )
                    }
                }
                .offset(x: offset)
                .onAppear {
                    startScrolling()
                }
            }

            // Fade + "NOT LIVE" label on left
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.goldAmber)
                    .frame(width: 6, height: 6)
                Text("NOT LIVE")
                    .font(BJFont.sora(9, weight: .regular))
                    .tracking(1)
                    .foregroundColor(Color.goldAmber)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.black, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .frame(height: 38)
        .clipped()
    }

    private func tickerItemView(_ item: (user: String, event: String, cut: String)) -> some View {
        HStack(spacing: 4) {
            Text(item.user)
                .font(BJFont.sora(11, weight: .bold))
                .foregroundColor(Color.goldAmber)
            Text(item.event + " →")
                .font(BJFont.sora(11, weight: .regular))
                .foregroundColor(Color.white.opacity(0.7))
            Text(cutDisplay(item.cut))
                .font(BJFont.sora(11, weight: .bold))
                .foregroundColor(cutColor(item.cut))
        }
    }

    private func cutColor(_ cut: String) -> Color {
        if cut == "tier"  { return Color.goldAmber }
        if cut == "chips" { return Color(hex: "#C0C0C0") }
        return Color(hex: "#00FF88")
    }

    private func cutDisplay(_ cut: String) -> String {
        if cut == "tier"  { return "★" }
        if cut == "chips" { return "⛁" }
        return cut
    }

    private func startScrolling() {
        guard totalWidth > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { startScrolling() }
            return
        }
        offset = 0
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            offset = -totalWidth
        }
    }
}

// MARK: - Hero Section

private struct AffHeroSection: View {
    private let pillars = [
        (icon: "%",  label: "21% Match"),
        (icon: "★",  label: "Perm. Status"),
        (icon: "⛁", label: "Aff. Chips"),
    ]

    var body: some View {
        ZStack {
            // Background shimmer
            LinearGradient(
                colors: [
                    Color.goldAmber.opacity(0.06),
                    Color.clear,
                    Color.goldAmber.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Badge
                Text("Affiliate Program")
                    .font(BJFont.sora(10, weight: .regular))
                    .tracking(2)
                    .foregroundColor(Color.goldAmber)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .stroke(Color.goldAmber.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.bottom, 20)

                // Headline
                VStack(spacing: 0) {
                    Text("Three Ways to")
                        .font(BJFont.playfair(24, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    Text("Earn Forever")
                        .font(BJFont.playfair(24, weight: .bold))
                        .foregroundColor(Color.goldAmber)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.bottom, 12)

                // Subtext
                Text("Share your link. Your referrals buy tins and win comps. You earn in three ways:")
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // Three pillars
                HStack(spacing: 8) {
                    pillarBox(top: "21%", bottom: "Comp Matching")
                    pillarBox(top: "PERMANENT", bottom: "Tier Status")
                    pillarBox(top: "AFFILIATE", bottom: "Chips")
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 48)
            .padding(.bottom, 40)
        }
    }

    private func pillarBox(top: String, bottom: String) -> some View {
        VStack(spacing: 4) {
            Text(top)
                .font(BJFont.sora(15, weight: .bold))
                .tracking(1)
                .foregroundColor(Color.goldAmber)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(bottom)
                .font(BJFont.sora(9, weight: .regular))
                .tracking(0.5)
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 14)
        .background(Color.goldAmber.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - How It Works Section

private struct AffHowItWorksSection: View {
    private let steps = [
        (num: "01", title: "Get Your Link",       desc: "Sign up free and receive your unique affiliate referral link."),
        (num: "02", title: "Refer Customers",     desc: "Anyone who signs up through your link is permanently part of your network."),
        (num: "03", title: "They Buy Tins",       desc: "Every tin your referrals purchase is tracked to your account. Forever."),
        (num: "04", title: "You Earn Three Ways", desc: "21% of their reward winnings, permanent tier unlocks, and affiliate chips that lock in your share of the Affiliate Comps pool."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "How It Works")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.goldAmber.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
                                )
                            Text(steps[i].num)
                                .font(BJFont.outfit(18, weight: .bold))
                                .foregroundColor(Color.goldAmber)
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(steps[i].title)
                                .font(BJFont.sora(15, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            Text(steps[i].desc)
                                .font(BJFont.sora(12, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.6))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)

                    if i < steps.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.05))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
    }
}

// MARK: - 21% Match Section

private struct AffMatchSection: View {
    private let prizes = [
        (label: "$5 Comp",    display: "$5",         yours: "$1.05"),
        (label: "$100 Comp",  display: "$100",       yours: "$21"),
        (label: "$1K Comp",   display: "$1,000",     yours: "$210"),
        (label: "$10K Comp",  display: "$10,000",    yours: "$2,100"),
        (label: "Casino Pkg", display: "$5K Package",yours: "$1,050"),
        (label: "Gold Trip",  display: "$100K Trip", yours: "$21,000"),
    ]

    @State private var activeIndex: Int = 2

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "21% Match")

            Text("Every time one of your referrals scans a chip and wins, you automatically receive ")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))
            + Text("21% of that reward's value")
                .font(BJFont.sora(12, weight: .bold))
                .foregroundColor(Color.goldAmber)
            + Text(".")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))

            // Prize selector pills
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        prizePill(prizes[i], index: i)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(3..<6, id: \.self) { i in
                        prizePill(prizes[i], index: i)
                    }
                }
            }
            .padding(.vertical, 20)

            // Display card
            AffCard(glow: true) {
                VStack(spacing: 0) {
                    Text("Your referral wins")
                        .font(BJFont.sora(10, weight: .regular))
                        .tracking(1)
                        .foregroundColor(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                        .padding(.top, 28)
                        .padding(.bottom, 8)

                    Text(prizes[activeIndex].display)
                        .font(BJFont.playfair(34, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .animation(.easeInOut(duration: 0.3), value: activeIndex)

                    // × 21% divider
                    HStack(spacing: 8) {
                        LinearGradient(
                            colors: [Color.clear, Color.goldAmber.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40, height: 1)

                        Text("× 21%")
                            .font(BJFont.sora(10, weight: .regular))
                            .tracking(2)
                            .foregroundColor(Color.goldAmber)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.goldAmber.opacity(0.3), lineWidth: 1)
                            )

                        LinearGradient(
                            colors: [Color.goldAmber.opacity(0.4), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40, height: 1)
                    }
                    .padding(.vertical, 16)

                    Text("You receive")
                        .font(BJFont.sora(10, weight: .regular))
                        .tracking(1)
                        .foregroundColor(Color.goldAmber.opacity(0.7))
                        .textCase(.uppercase)
                        .padding(.bottom, 8)

                    Text(prizes[activeIndex].yours)
                        .font(BJFont.playfair(48, weight: .bold))
                        .foregroundColor(Color.goldAmber)
                        .shadow(color: Color.goldAmber.opacity(0.4), radius: 20)
                        .animation(.easeInOut(duration: 0.3), value: activeIndex)

                    Text("Paid automatically in crypto • No cap, no limit, forever")
                        .font(BJFont.sora(11, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private func prizePill(_ prize: (label: String, display: String, yours: String), index: Int) -> some View {
        Button(action: { activeIndex = index }) {
            Text(prize.label)
                .font(BJFont.sora(12, weight: .semibold))
                .foregroundColor(index == activeIndex ? Color.goldAmber : Color.white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    index == activeIndex
                        ? AnyView(LinearGradient(
                            colors: [Color.goldAmber.opacity(0.2), Color.goldAmber.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                        : AnyView(Color.white.opacity(0.03))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            index == activeIndex ? Color.goldAmber : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Tier Status Section

private struct AffTierStatusSection: View {
    struct TierInfo {
        let label: String
        let color: Color
        let bg: Color
        let border: Color
        let tins: String
        let perks: [String]
    }

    private let tiers: [TierInfo] = [
        TierInfo(
            label: "VIP",
            color: Color.white,
            bg: Color.white.opacity(0.08),
            border: Color.white.opacity(0.25),
            tins: "210",
            perks: [
                "Partner discount network",
                "BlakJaks merchandise",
                "Vote on flavors and events"
            ]
        ),
        TierInfo(
            label: "High Roller",
            color: Color(hex: "#C0C0C0"),
            bg: Color(hex: "#C0C0C0").opacity(0.08),
            border: Color(hex: "#C0C0C0").opacity(0.25),
            tins: "2,100",
            perks: [
                "Everything in VIP",
                "Vote on products and partnerships"
            ]
        ),
        TierInfo(
            label: "Whale",
            color: Color.goldAmber,
            bg: Color.goldAmber.opacity(0.08),
            border: Color.goldAmber.opacity(0.25),
            tins: "21,000",
            perks: [
                "Everything in High Roller",
                "Casino comp packages ($5K-$8K value)",
                "Full governance and strategy voting"
            ]
        ),
    ]

    @State private var activeIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "Permanent Status")

            (Text("Unlike regular customers who maintain tiers quarterly, affiliate tier status is ")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))
            + Text("locked in permanently")
                .font(BJFont.sora(12, weight: .bold))
                .foregroundColor(Color.goldAmber)
            + Text(" once earned.")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6)))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.bottom, 20)

            // Tier tab selector
            HStack(spacing: 4) {
                ForEach(tiers.indices, id: \.self) { i in
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { activeIndex = i } }) {
                        Text(tiers[i].label.uppercased())
                            .font(BJFont.playfair(11, weight: .bold))
                            .tracking(1)
                            .foregroundColor(i == activeIndex ? tiers[i].color : Color.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(i == activeIndex ? tiers[i].bg : Color.clear)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .padding(.bottom, 20)

            // Tier card
            let tier = tiers[activeIndex]
            AffCard {
                VStack(spacing: 0) {
                    // Milestone number
                    VStack(spacing: 6) {
                        Text("Referred Tin Milestone")
                            .font(BJFont.sora(10, weight: .regular))
                            .tracking(1)
                            .foregroundColor(Color.white.opacity(0.5))
                            .textCase(.uppercase)

                        Text(tier.tins)
                            .font(BJFont.playfair(44, weight: .bold))
                            .foregroundColor(tier.color)
                            .shadow(color: tier.color.opacity(0.2), radius: 15)

                        Text("tins sold by your referrals")
                            .font(BJFont.sora(12, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    // Permanent badge divider
                    HStack(spacing: 8) {
                        LinearGradient(
                            colors: [Color.clear, tier.color.opacity(0.27)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)

                        Text("Permanent \(tier.label)")
                            .font(BJFont.sora(10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(tier.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(tier.bg)
                            .overlay(
                                Capsule().stroke(tier.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                            .fixedSize()

                        LinearGradient(
                            colors: [tier.color.opacity(0.27), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                    }
                    .padding(.bottom, 20)

                    // Perks
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(tier.perks, id: \.self) { perk in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(tier.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(perk)
                                    .font(BJFont.sora(12, weight: .regular))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .lineSpacing(3)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Never resets badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Never resets • No quarterly maintenance required")
                            .font(BJFont.sora(11, weight: .regular))
                    }
                    .foregroundColor(Color(hex: "#00FF88"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#00FF88").opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#00FF88").opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: activeIndex)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}

// MARK: - Affiliate Chips Section

private struct AffiliateChipsSection: View {
    private let steps = [
        (icon: "01", title: "Referral buys a tin",          desc: "You earn 1 affiliate chip per tin purchased by anyone in your network."),
        (icon: "02", title: "Chips accumulate",             desc: "Your total affiliate chip count grows as your network keeps buying."),
        (icon: "03", title: "Comps proportionate to chips", desc: "Your share of the Affiliate Comps pool is based on your chip count relative to all affiliates."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "Affiliate Chips")

            (Text("Every tin your referrals buy earns you ")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))
            + Text("1 affiliate chip")
                .font(BJFont.sora(12, weight: .bold))
                .foregroundColor(Color.goldAmber)
            + Text(". These chips accumulate and determine your proportionate share of the ")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))
            + Text("Affiliate Comps pool")
                .font(BJFont.sora(12, weight: .bold))
                .foregroundColor(Color.goldAmber)
            + Text(".")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6)))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.bottom, 20)

            AffCard {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.goldAmber.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
                                    )
                                Text(steps[i].icon)
                                    .font(BJFont.outfit(18, weight: .bold))
                                    .foregroundColor(Color.goldAmber)
                            }
                            .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(steps[i].title)
                                    .font(BJFont.sora(13, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                Text(steps[i].desc)
                                    .font(BJFont.sora(12, weight: .regular))
                                    .foregroundColor(Color.white.opacity(0.55))
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}

// MARK: - Affiliate Pool Section

private struct AffiliatePoolSection: View {
    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "The Affiliate Comps Pool")
            poolIntroText
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 20)
            AffCard { poolCardContent }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private var poolIntroText: Text {
        Text("5% of BlakJaks gross profits")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(" goes directly into the Affiliate Comps pool. This pool is ")
            .font(BJFont.sora(12, weight: .regular))
            .foregroundColor(Color.white.opacity(0.6))
        + Text("active now")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(", and affiliates earn from it on an ongoing basis.")
            .font(BJFont.sora(12, weight: .regular))
            .foregroundColor(Color.white.opacity(0.6))
    }

    @ViewBuilder private var poolCardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            poolHowItWorks
            affGoldDivider
            poolBeforeAfter
            affGoldDivider
            poolExample
            affGoldDivider
            poolGreenNote
        }
        .padding(20)
    }

    @ViewBuilder private var poolHowItWorks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(BJFont.playfair(11, weight: .bold))
                .tracking(2)
                .foregroundColor(Color.goldAmber)
                .textCase(.uppercase)
            poolBullet {
                (Text("BlakJaks allocates ")
                    .font(BJFont.sora(12, weight: .regular))
                + Text("5% of gross profits")
                    .font(BJFont.sora(12, weight: .bold))
                    .foregroundColor(Color.goldAmber)
                + Text(" into the Affiliate Comps pool")
                    .font(BJFont.sora(12, weight: .regular)))
            }
            poolBullet {
                (Text("Payouts are ")
                    .font(BJFont.sora(12, weight: .regular))
                + Text("weekly")
                    .font(BJFont.sora(12, weight: .bold))
                    .foregroundColor(Color.goldAmber)
                + Text(". Your share is based on your current chip count relative to all affiliate chips")
                    .font(BJFont.sora(12, weight: .regular)))
            }
            poolBullet {
                Text("As you earn more chips, your share grows. More chips = larger cut of the pool.")
                    .font(BJFont.sora(12, weight: .regular))
            }
            poolBullet {
                (Text("Comps under $50K are paid automatically in crypto. Comps over ")
                    .font(BJFont.sora(12, weight: .regular))
                + Text("$50,000")
                    .font(BJFont.sora(12, weight: .bold))
                    .foregroundColor(Color.goldAmber)
                + Text(" can be paid via wire transfer in USD.")
                    .font(BJFont.sora(12, weight: .regular)))
            }
        }
    }

    @ViewBuilder private var poolBeforeAfter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before vs. After Sunset")
                .font(BJFont.playfair(11, weight: .bold))
                .tracking(2)
                .foregroundColor(Color.goldAmber)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 10) {
                // Before
                VStack(alignment: .leading, spacing: 8) {
                    Text("Before Sunset")
                        .font(BJFont.sora(9, weight: .regular))
                        .tracking(1)
                        .foregroundColor(Color.goldAmber)
                        .textCase(.uppercase)

                    (Text("Your share is ")
                        .font(BJFont.sora(12, weight: .regular))
                    + Text("fluid")
                        .font(BJFont.sora(12, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    + Text(". It shifts as you and other affiliates earn more chips. Comps paid ")
                        .font(BJFont.sora(12, weight: .regular))
                    + Text("weekly")
                        .font(BJFont.sora(12, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    + Text(".")
                        .font(BJFont.sora(12, weight: .regular)))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.goldAmber.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldAmber.opacity(0.12), lineWidth: 1)
                )
                .cornerRadius(10)

                // After
                VStack(alignment: .leading, spacing: 8) {
                    Text("After Sunset")
                        .font(BJFont.sora(9, weight: .regular))
                        .tracking(1)
                        .foregroundColor(Color(hex: "#FF5050"))
                        .textCase(.uppercase)

                    (Text("No new chips are issued. Your share ")
                        .font(BJFont.sora(12, weight: .regular))
                    + Text("locks in permanently")
                        .font(BJFont.sora(12, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    + Text(" at your final chip count. Weekly payouts continue forever.")
                        .font(BJFont.sora(12, weight: .regular)))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#FF3232").opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "#FF5050").opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(10)
            }
        }
    }

    @ViewBuilder private var affGoldDivider: some View {
        LinearGradient(
            colors: [Color.clear, Color.goldAmber.opacity(0.15), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }

    @ViewBuilder private var poolExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Example")
                .font(BJFont.playfair(11, weight: .bold))
                .tracking(2)
                .foregroundColor(Color.goldAmber)
                .textCase(.uppercase)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.goldAmber.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.goldAmber.opacity(0.12), lineWidth: 1)
                    )

                poolExampleText
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(4)
                    .padding(16)
            }
        }
    }

    private var poolExampleText: Text {
        Text("You hold ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("10,000 affiliate chips")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(" out of ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("1,000,000 total")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(" across all affiliates. That gives you ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("1% of the pool")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(". If BlakJaks does $2.5M in gross profit that week, the pool is $125K, and your weekly comp is")
            .font(BJFont.sora(12, weight: .regular))
        + Text("$1,250")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color(hex: "#00FF88"))
        + Text(". Before sunset, that share adjusts as chip counts change. After sunset, your 1% is locked in for life.")
            .font(BJFont.sora(12, weight: .regular))
    }

    @ViewBuilder private var poolGreenNote: some View {
        Text("You earn from the pool starting day one. The sunset just makes your share permanent")
            .font(BJFont.sora(12, weight: .regular))
            .foregroundColor(Color(hex: "#00FF88"))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#00FF88").opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#00FF88").opacity(0.15), lineWidth: 1)
            )
            .cornerRadius(10)
    }

    private func poolBullet<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.goldAmber)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            content()
                .foregroundColor(Color.white.opacity(0.8))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Transparency Dashboard

private struct AffTransparencyDashboard: View {
    private let weeklyHistory = [
        (week: "Feb 3",  gp: "$1.24M", pool: "$62,000"),
        (week: "Jan 27", gp: "$1.18M", pool: "$59,000"),
        (week: "Jan 20", gp: "$1.31M", pool: "$65,500"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "Transparency Dashboard")

            Text("Full visibility into the affiliate program. Shared across all affiliates, updated in real time.")
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 20)

            AffCard(glow: true) {
                VStack(spacing: 16) {
                    // Live label
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#00FF88"))
                            .frame(width: 6, height: 6)
                        Text("Live Program Data")
                            .font(BJFont.sora(9, weight: .regular))
                            .tracking(1.5)
                            .foregroundColor(Color.white.opacity(0.5))
                            .textCase(.uppercase)
                    }

                    // Top stats grid
                    HStack(spacing: 8) {
                        dashStat(value: "9.85M", label: "Total Chips Issued", valueColor: Color(hex: "#C0C0C0"))
                        dashStat(value: "1,842", label: "Active Affiliates",  valueColor: Color.textPrimary)
                    }

                    // Gross / pool row
                    HStack(spacing: 0) {
                        VStack(spacing: 3) {
                            Text("$1.24M")
                                .font(BJFont.playfair(26, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                            Text("Gross Profit This Week")
                                .font(BJFont.sora(8, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(Color.white.opacity(0.5))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.goldAmber.opacity(0.2))
                            .frame(width: 1, height: 36)

                        VStack(spacing: 3) {
                            Text("$62K")
                                .font(BJFont.playfair(26, weight: .bold))
                                .foregroundColor(Color.goldAmber)
                            Text("Affiliate Pool (5%)")
                                .font(BJFont.sora(8, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(Color.white.opacity(0.5))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                    .background(Color.goldAmber.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.goldAmber.opacity(0.12), lineWidth: 1)
                    )
                    .cornerRadius(10)

                    // Weekly history table
                    VStack(spacing: 0) {
                        HStack {
                            Text("Week")
                                .font(BJFont.sora(9, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(Color.white.opacity(0.35))
                                .textCase(.uppercase)
                            Spacer()
                            Text("Gross")
                                .font(BJFont.sora(9, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(Color.white.opacity(0.35))
                                .textCase(.uppercase)
                                .frame(width: 60, alignment: .trailing)
                            Text("Pool")
                                .font(BJFont.sora(9, weight: .regular))
                                .tracking(0.5)
                                .foregroundColor(Color.white.opacity(0.35))
                                .textCase(.uppercase)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.bottom, 6)
                        .overlay(
                            Rectangle().frame(height: 1).foregroundColor(Color.goldAmber.opacity(0.08)),
                            alignment: .bottom
                        )

                        ForEach(weeklyHistory.indices, id: \.self) { i in
                            let row = weeklyHistory[i]
                            HStack {
                                Text(row.week)
                                    .font(BJFont.sora(11, weight: .regular))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()
                                Text(row.gp)
                                    .font(BJFont.sora(11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.75))
                                    .frame(width: 60, alignment: .trailing)
                                Text(row.pool)
                                    .font(BJFont.sora(11, weight: .semibold))
                                    .foregroundColor(Color.goldAmber)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.vertical, 10)

                            if i < weeklyHistory.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.04))
                            }
                        }
                    }

                    // Totals panel
                    VStack(spacing: 6) {
                        dashRow(label: "Total Comps Distributed", value: "$2.41M", valueColor: Color(hex: "#00FF88"))
                        dashRow(label: "Total 21% Match Paid",    value: "$847K",  valueColor: Color(hex: "#00FF88"))
                        dashRow(label: "Capacity to Sunset",      value: "0%",     valueColor: Color(hex: "#FF5050"))
                    }
                    .padding(12)
                    .background(Color(hex: "#00FF88").opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#00FF88").opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .padding(20)
            }

            Text("Simulated preview. Live dashboard accessible to all affiliates")
                .font(BJFont.sora(11, weight: .regular))
                .italic()
                .foregroundColor(Color.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private func dashStat(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BJFont.playfair(24, weight: .bold))
                .foregroundColor(valueColor)
            Text(label)
                .font(BJFont.sora(9, weight: .regular))
                .tracking(0.5)
                .foregroundColor(Color.white.opacity(0.5))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.goldAmber.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.goldAmber.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func dashRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(BJFont.sora(11, weight: .regular))
                .foregroundColor(Color.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Calculator Section

private struct AffCalculatorSection: View {
    private let steps = [10, 25, 50, 100, 250, 500, 1_000, 2_500, 5_000, 10_000, 25_000, 50_000, 100_000]
    @State private var sliderIndex: Double = 6

    private var referrals: Int { steps[Int(sliderIndex)] }
    private var tinsPerYear: Int { referrals * 20 }
    private var matchEarnings: Double { Double(referrals) * 50.0 * 0.21 }
    private var tierLabel: String {
        if tinsPerYear >= 21_000 { return "Whale" }
        if tinsPerYear >= 2_100  { return "High Roller" }
        if tinsPerYear >= 210    { return "VIP" }
        return "Standard"
    }
    private var tierColor: Color {
        if tinsPerYear >= 21_000 { return Color.goldAmber }
        if tinsPerYear >= 2_100  { return Color(hex: "#C0C0C0") }
        if tinsPerYear >= 210    { return Color.white }
        return Color.white.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "Your Potential")

            AffCard {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Referrals You Bring")
                        .font(BJFont.sora(12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.bottom, 14)

                    Slider(value: $sliderIndex, in: 0...Double(steps.count - 1), step: 1)
                        .accentColor(Color.goldAmber)

                    // Referral count display
                    HStack(alignment: .firstTextBaseline) {
                        Text(fmtN(referrals))
                            .font(BJFont.playfair(44, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        Text("referrals")
                            .font(BJFont.sora(12, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.5))
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)

                    // Stats grid
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            calcStat(value: fmtD(matchEarnings), label: "21% Match / Year",   valueColor: Color.goldAmber)
                            calcStat(value: tierLabel,           label: "Status in Year 1",    valueColor: tierColor)
                        }
                        HStack(spacing: 10) {
                            calcStat(value: fmtN(tinsPerYear),   label: "Tins Referred / Year", valueColor: Color.textPrimary)
                            calcStat(value: fmtN(tinsPerYear),   label: "Affiliate Chips / Year", valueColor: Color(hex: "#C0C0C0"))
                        }
                    }

                    Text("Based on avg 20 tins/yr per referral, avg $50/yr in winnings")
                        .font(BJFont.sora(11, weight: .regular))
                        .italic()
                        .foregroundColor(Color.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
                .padding(24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private func calcStat(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BJFont.playfair(21, weight: .bold))
                .foregroundColor(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(BJFont.sora(9, weight: .regular))
                .tracking(0.5)
                .foregroundColor(Color.white.opacity(0.55))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.goldAmber.opacity(0.05))
        .cornerRadius(10)
    }

    private func fmtN(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000     { return String(format: "%.0fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func fmtD(_ n: Double) -> String {
        if n >= 1_000_000 { return String(format: "$%.1fM", n / 1_000_000) }
        if n >= 1_000     { return String(format: "$%.0fK", n / 1_000) }
        return "$\(Int(n))"
    }
}

// MARK: - FAQ Section

private struct AffFAQSection: View {
    private struct FAQItem {
        let question: String
        let answer: String
    }

    private let items: [FAQItem] = [
        FAQItem(
            question: "What is the 21% match?",
            answer: "Whenever anyone in your referral network scans a chip and wins a reward, whether a $5 crypto comp or a $200K Gold Chip Trip, you automatically receive 21% of that reward value. No cap, no limit, forever."
        ),
        FAQItem(
            question: "How does permanent tier status work?",
            answer: "Unlike regular loyalty members who maintain their tier through quarterly purchases, affiliates lock in their tier permanently. Hit 210 referred tins for VIP, 2,100 for High Roller, or 21,000 for Whale, and it is yours for life."
        ),
        FAQItem(
            question: "What are affiliate chips?",
            answer: "Every tin your referrals buy earns you 1 affiliate chip. Your chip count determines your proportionate share of the Affiliate Comps pool, which is 5% of BlakJaks gross profits, paid out weekly. After the sunset, your share locks in permanently."
        ),
        FAQItem(
            question: "How do I get paid?",
            answer: "Affiliate comps are paid out in USD or USDC via ACH or to your Crypto wallet."
        ),
        FAQItem(
            question: "What happens at the 10M tins/month sunset?",
            answer: "Once BlakJaks averages 10 million tins sold per month, affiliate chip earning stops permanently. No new chips are issued after that point. Your accumulated chips lock in your share of the Affiliate Comps pool forever."
        ),
        FAQItem(
            question: "Do I lose the 21% match after the sunset?",
            answer: "No. The sunset only applies to affiliate chip earning. Your 21% match on referral winnings and your permanent tier status are both unaffected. Those continue forever."
        ),
        FAQItem(
            question: "Does it cost anything to join?",
            answer: "Nothing. The affiliate program is completely free. You do not need to be a BlakJaks customer, though if you buy tins yourself, you also earn through the regular loyalty program separately."
        ),
        FAQItem(
            question: "If I also buy tins, do I earn double?",
            answer: "Your personal tin purchases count toward the regular loyalty program (quarterly tiers, chip scanning, rewards). Your referral network purchases count toward your affiliate milestones. They are separate tracks, and you benefit from both."
        ),
    ]

    @State private var openIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            AffSectionTitle(text: "FAQ")

            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    faqRow(item: items[i], index: i)

                    if i < items.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.06))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private func faqRow(item: FAQItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    openIndex = openIndex == index ? nil : index
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    Text(item.question)
                        .font(BJFont.sora(14, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(openIndex == index ? "×" : "+")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color.goldAmber)
                        .frame(width: 24, alignment: .center)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }

            if openIndex == index {
                Text(item.answer)
                    .font(BJFont.sora(12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.6))
                    .lineSpacing(5)
                    .padding(.bottom, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Sunset Window

private struct AffSunsetWindow: View {

    private var sunsetIntroText: Text {
        Text("When BlakJaks reaches an average of ")
            .font(BJFont.sora(14, weight: .regular))
            .foregroundColor(Color.white.opacity(0.9))
        + Text("10 million tins sold per month")
            .font(BJFont.sora(14, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(", two things happen permanently:")
            .font(BJFont.sora(14, weight: .regular))
            .foregroundColor(Color.white.opacity(0.9))
    }

    private var sunsetMiddleText: Text {
        Text("Your ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("21% match")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(", ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("permanent tier status")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(", and ")
            .font(BJFont.sora(12, weight: .regular))
        + Text("Affiliate Comps pool share")
            .font(BJFont.sora(12, weight: .bold))
            .foregroundColor(Color.goldAmber)
        + Text(" all continue forever. Only the ability to join and earn new chips ends.")
            .font(BJFont.sora(12, weight: .regular))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF3232").opacity(0.1), Color(hex: "#FF3232").opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FF5050").opacity(0.3), lineWidth: 1)
                    )

                // Top gradient bar
                LinearGradient(
                    colors: [Color(hex: "#FF5050"), Color.goldAmber, Color(hex: "#FF5050")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                sunsetCardContent
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    @ViewBuilder private var sunsetCardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sunset header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: "#FF5050"))
                    .frame(width: 10, height: 10)
                Text("Sunset Window")
                    .font(BJFont.playfair(14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color(hex: "#FF5050"))
                    .textCase(.uppercase)
            }
            .padding(.bottom, 14)

            sunsetIntroText
                .lineSpacing(4)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                sunsetRule(
                    number: "1.",
                    boldText: "No new affiliates",
                    restText: ". The program closes to all new signups. No exceptions."
                )
                sunsetRule(
                    number: "2.",
                    boldText: "No new affiliate chips",
                    restText: ". Chip earning stops. Your accumulated total is locked in permanently."
                )
            }
            .padding(.top, 16)
            .padding(.bottom, 16)

            // Middle note
            sunsetMiddleText
                .foregroundColor(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.goldAmber.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(10)
                .padding(.bottom, 16)

            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("Capacity to sunset")
                        .font(BJFont.sora(10, weight: .regular))
                        .tracking(0.5)
                        .foregroundColor(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                    Spacer()
                    Text("0%")
                        .font(BJFont.sora(10, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF5050"))
                }

                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF5050"), Color.goldAmber],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 0, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(24)
        .padding(.top, 3)
    }

    private func sunsetRule(number: String, boldText: String, restText: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(BJFont.sora(14, weight: .bold))
                .foregroundColor(Color(hex: "#FF5050"))
                .frame(width: 16, alignment: .leading)

            (Text(boldText)
                .font(BJFont.sora(12, weight: .bold))
                .foregroundColor(Color.goldAmber)
            + Text(restText)
                .font(BJFont.sora(12, weight: .regular))
                .foregroundColor(Color.white.opacity(0.85)))
            .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#FF3232").opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#FF5050").opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

// MARK: - Color Hex Extension (local, avoids duplication if already defined elsewhere)

private extension Color {
    init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    NavigationStack {
        AffiliatePreviewView()
    }
}
