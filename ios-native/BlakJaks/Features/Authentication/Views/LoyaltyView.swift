import SwiftUI
import SceneKit

// MARK: - LoyaltyView
// Faithfully converts the #s-loyalty React component from app-mockup.html.
// All content is static/hardcoded. Scroll-reveal animations use .onAppear + .opacity + .offset.
// iOS 16 compatible.no SwiftUI 17-only APIs.

// MARK: - Shared data models (file-private)

private struct LoyaltyTrip {
    let title: String
    let value: String
    let icon: String
    let desc: String
}

private struct LoyaltyTierData {
    let name: String
    let color: Color
    let suit: String
    let headline: String
    let sub: String
    let perks: [String]
}

// MARK: - LoyaltyView

struct LoyaltyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        LoyaltyHeroSection()
                        LoyaltyIntroSection()
                        LoyaltyCollectChipsSection()
                        LoyaltyTierScannerSection()
                        LoyaltyTierPerksSection()
                        LoyaltyCasinoCompsSection()
                        LoyaltyTripCompsSection()
                        LoyaltyWalletSection()
                        LoyaltyLiveDashboardSection()
                        LoyaltyFaqSection()
                        Spacer().frame(height: Spacing.xxl)
                    }
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
                            .foregroundColor(Color.goldAmber)
                        Text("BACK")
                            .font(BJFont.sora(12, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color.goldAmber)
                    }
                }
            }
        }
        .toolbarBackground(Color(red: 10/255, green: 10/255, blue: 10/255).opacity(0.85), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .disableSwipeBack()
    }
}

// MARK: - Reveal animation modifier
// Mimics React IntersectionObserver: fade + slide up on appear.

private struct RevealModifier: ViewModifier {
    let delay: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 24)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(delay)) {
                    visible = true
                }
            }
    }
}

extension View {
    fileprivate func loyaltyReveal(delay: Double = 0) -> some View {
        modifier(RevealModifier(delay: delay))
    }
}

// MARK: - GoldDivider

private struct GoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.goldAmber, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - GoldTopLine
// 2-px gold line at top of cards (matches CSS top: 0 gradient border).

private struct GoldTopLine: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.goldAmber, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - SectionHeader

private struct LoyaltySectionHeader: View {
    let hook: String
    var sub: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(hook)
                .font(BJFont.playfair(23, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .loyaltyReveal()

            if let sub = sub {
                Text(sub)
                    .font(BJFont.outfit(15, weight: .regular))
                    .foregroundColor(Color.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.xxs)
                    .padding(.bottom, Spacing.xs)
                    .loyaltyReveal(delay: 0.1)
            } else {
                Spacer().frame(height: Spacing.xs)
            }

            GoldDivider()
        }
        .padding(.bottom, Spacing.xxs)
    }
}

// MARK: - SECTION: Hero

private struct LoyaltyHeroSection: View {
    var body: some View {
        ZStack {
            // Ambient gold glow at bottom
            RadialGradient(
                colors: [Color.goldAmber.opacity(0.32), Color.clear],
                center: UnitPoint(x: 0.5, y: 1.05),
                startRadius: 0,
                endRadius: 250
            )
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Side ambient orbs
            RadialGradient(
                colors: [Color.goldAmber.opacity(0.22), Color.clear],
                center: UnitPoint(x: 0, y: 0.2),
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                // Badge
                Text("Loyalty Program")
                    .font(BJFont.sora(10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Color.goldAmber)
                    .textCase(.uppercase)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .stroke(Color.goldAmber.opacity(0.4), lineWidth: 1)
                    )

                // Headline
                Group {
                    Text("Every Scan Brings You ")
                        .font(BJFont.playfair(28, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    + Text("Closer to Earning")
                        .font(BJFont.playfair(28, weight: .bold))
                        .foregroundColor(Color.goldAmber)
                }
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.lg)

                // Card stack
                LoyaltyHeroCardStack()
                    .padding(.vertical, Spacing.sm)

                // Guarantee text
                Group {
                    Text("Every VIP, High Roller and Whale member will be given ")
                        .foregroundColor(Color(white: 1, opacity: 0.7))
                    + Text("$50 in comps")
                        .foregroundColor(Color.goldAmber)
                    + Text(" their first year. GUARANTEED.")
                        .foregroundColor(Color(white: 1, opacity: 0.7))
                }
                .font(BJFont.sora(14, weight: .regular))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
            }
            .padding(.top, 68) // clearance for nav bar overlay
            .padding(.bottom, Spacing.xxxl)
        }
    }
}

// MARK: - Hero card stack with $50 reveal

private struct LoyaltyHeroCardStack: View {
    @State private var dealing = false

    private let cardW: CGFloat = 200
    private let cardH: CGFloat = 282

    var body: some View {
        ZStack {
            // Background card 1 (left)
            LoyaltyCardBackView()
                .frame(width: cardW - 10, height: cardH - 16)
                .offset(x: dealing ? -19 : -340, y: dealing ? 12 : -20)
                .rotationEffect(.degrees(dealing ? -14 : -28))
                .opacity(dealing ? 0.45 : 0)
                .zIndex(1)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: dealing)

            // Background card 2 (right)
            LoyaltyCardBackView()
                .frame(width: cardW - 10, height: cardH - 16)
                .offset(x: dealing ? 16 : 340, y: dealing ? 10 : -20)
                .rotationEffect(.degrees(dealing ? 10 : 28))
                .opacity(dealing ? 0.35 : 0)
                .zIndex(2)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55), value: dealing)

            // Background card 3 (left)
            LoyaltyCardBackView()
                .frame(width: cardW - 10, height: cardH - 16)
                .offset(x: dealing ? -10 : -340, y: dealing ? 6 : -20)
                .rotationEffect(.degrees(dealing ? -6 : -28))
                .opacity(dealing ? 0.25 : 0)
                .zIndex(3)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.8), value: dealing)

            // Main card.$50 front face
            LoyaltyCardFrontView()
                .frame(width: cardW, height: cardH)
                .zIndex(5)
                .shadow(color: Color.goldAmber.opacity(0.22), radius: 30, x: 0, y: 10)
                .opacity(dealing ? 1 : 0)
                .offset(y: dealing ? 0 : -20)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(1.1), value: dealing)
        }
        .frame(width: 260, height: 350)
        .onAppear { dealing = true }
    }
}

private struct LoyaltyCardBackView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.105), Color(white: 0.051)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.goldAmber.opacity(0.25), lineWidth: 2)

            // Inner border
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.goldAmber.opacity(0.1), lineWidth: 1)
                .padding(8)

            // Subtle cross-hatch background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.goldAmber.opacity(0.03))
                .padding(20)

            // Center spade medallion
            ZStack {
                Circle()
                    .stroke(Color.goldAmber.opacity(0.25), lineWidth: 2)
                    .frame(width: 56, height: 56)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.goldAmber.opacity(0.06), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)
                Text("♠")
                    .font(.system(size: 28))
                    .foregroundColor(Color.goldAmber)
                    .shadow(color: Color.goldAmber.opacity(0.3), radius: 15)
            }

            // Top-left corner pip
            Text("♠")
                .font(.system(size: 13))
                .foregroundColor(Color.goldAmber.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(14)

            // Bottom-right corner pip (rotated)
            Text("♠")
                .font(.system(size: 13))
                .foregroundColor(Color.goldAmber.opacity(0.35))
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(14)
        }
    }
}

private struct LoyaltyCardFrontView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.067), Color(white: 0.039)],
                        startPoint: UnitPoint(x: 0.15, y: 0.1),
                        endPoint: UnitPoint(x: 0.85, y: 1.0)
                    )
                )

            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.goldAmber.opacity(0.5), lineWidth: 2)

            // Inner border
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.goldAmber.opacity(0.2), lineWidth: 1)
                .padding(8)

            // Radial glow
            RadialGradient(
                colors: [Color.goldAmber.opacity(0.08), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 140
            )

            // Corner $ signs
            Text("$")
                .font(BJFont.playfair(18, weight: .bold))
                .foregroundColor(Color.goldAmber)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)

            Text("$")
                .font(BJFont.playfair(18, weight: .bold))
                .foregroundColor(Color.goldAmber)
                .rotationEffect(.degrees(180))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(16)

            // Center content
            VStack(spacing: 14) {
                Text("$50")
                    .font(BJFont.playfair(62, weight: .bold))
                    .foregroundColor(Color.goldAmber)
                    .shadow(color: Color.goldAmber.opacity(0.5), radius: 40)
                    .shadow(color: Color.goldAmber.opacity(0.2), radius: 80)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.goldAmber, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 1)

                VStack(spacing: 3) {
                    Text("GUARANTEED")
                        .font(BJFont.sora(10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color.goldAmber.opacity(0.8))
                    Text("FIRST YEAR")
                        .font(BJFont.sora(10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color.goldAmber.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - SECTION: Intro ("The House Always Pays.")

private struct LoyaltyIntroSection: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
                .frame(height: 20)

            Text("The House\nAlways Pays.")
                .font(BJFont.playfair(42, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .loyaltyReveal(delay: 0.1)

            Text("Other brands keep everything they make. We give back over 50% of our profits straight to your wallet.")
                .font(BJFont.outfit(16, weight: .regular))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xl)
                .loyaltyReveal(delay: 0.2)

            GoldDivider()
                .padding(.top, Spacing.lg)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxl)
    }
}

// MARK: - SECTION: Collect Chips At All Costs

private struct LoyaltyCollectChipsSection: View {
    private struct ChipMethod {
        let title: String
        let desc: String
    }

    private let methods: [ChipMethod] = [
        ChipMethod(title: "CRACK A TIN",
                   desc: "Every BlakJaks tin ships with a chip inside. Pop the seal, pocket the chip. That simple."),
        ChipMethod(title: "GET HANDED ONE",
                   desc: "Someone in your circle slides you a chip. No reason needed. That's how the table grows."),
        ChipMethod(title: "FIND ONE IN THE WILD",
                   desc: "We drop chips in places you'd never expect. Stay sharp or miss out."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Centered header between two gold lines
            VStack(spacing: Spacing.md) {
                GoldDivider()
                Text("Collect Chips At All Costs")
                    .font(BJFont.playfair(23, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .loyaltyReveal()
                GoldDivider()
            }
            .padding(.bottom, Spacing.xxs)

            // 3D rotating chip
            SingleChipView()
                .frame(width: 160, height: 160)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .loyaltyReveal(delay: 0.05)

            // Three Ways card
            VStack(spacing: 0) {
                // Header row
                Text("Three Ways Chips Find You")
                    .font(BJFont.sora(10, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.goldAmber.opacity(0.5))
                    .textCase(.uppercase)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(Color.goldAmber.opacity(0.05))

                Rectangle()
                    .fill(Color.goldAmber.opacity(0.08))
                    .frame(height: 1)

                ForEach(methods.indices, id: \.self) { i in
                    let m = methods[i]
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.title)
                            .font(BJFont.sora(12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color.goldAmber)
                        Text(m.desc)
                            .font(BJFont.outfit(14, weight: .regular))
                            .foregroundColor(Color.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if i < methods.count - 1 {
                        Rectangle()
                            .fill(Color.goldAmber.opacity(0.06))
                            .frame(height: 1)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.051), Color(white: 0.031)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
            )
            .loyaltyReveal(delay: 0.15)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - SECTION: Tier Scanner (interactive)

private struct LoyaltyTierScannerSection: View {
    @State private var pouchIndex: Int = 3
    @State private var scanPhase: ScanPhase = .idle
    @State private var scanProgress: CGFloat = 0
    @State private var showResult: Bool = false

    private enum ScanPhase { case idle, scanning, processing, done }

    private let pLabels = ["0", "1", "2", "3", "4", "5", "6", "7+"]

    private var currentTierName: String {
        let tins = (pouchIndex * 90) / 20
        if tins >= 30 { return "Whale" }
        if tins >= 16 { return "High Roller" }
        if tins >= 1  { return "VIP" }
        return "Standard"
    }

    private var tierColor: Color {
        switch currentTierName {
        case "Whale":       return Color.goldAmber
        case "High Roller": return Color(white: 0.75)
        case "VIP":         return Color.white
        default:            return Color(white: 0.33)
        }
    }

    private var resultText: String {
        switch currentTierName {
        case "Whale":       return "$10,000 Crypto Comp!"
        case "High Roller": return "$1,000 Crypto Comp!"
        case "VIP":         return "$100 Crypto Comp!"
        default:            return "Chip Logged. Keep stacking."
        }
    }

    private var resultIcon: String {
        switch currentTierName {
        case "Whale":       return "💎"
        case "High Roller": return "🚀"
        case "VIP":         return "💰"
        default:            return "♠"
        }
    }

    private var isDisabled: Bool {
        pouchIndex == 0 || scanPhase == .scanning || scanPhase == .processing
    }

    private var buttonLabel: String {
        switch scanPhase {
        case .idle:       return pouchIndex == 0 ? "SELECT USAGE ABOVE" : "SCAN CHIP"
        case .scanning:   return "SCANNING..."
        case .processing: return "PROCESSING..."
        case .done:       return "SCAN AGAIN"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "Every Scan Hits Different",
                sub: "Every chip you scan stacks towards your next tier or helps you keep your current one. Every single scan is a real opportunity for comps. The more you scan, the higher you climb and stay at your well deserved status."
            )

            VStack(spacing: Spacing.md) {
                // Pouch slider label
                Text("How many pouches do you use per day?")
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(Color(white: 1, opacity: 0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Slider
                Slider(value: Binding(
                    get: { Double(pouchIndex) },
                    set: {
                        let newVal = Int($0.rounded())
                        if newVal != pouchIndex {
                            pouchIndex = newVal
                            scanPhase = .idle
                            showResult = false
                            scanProgress = 0
                        }
                    }
                ), in: 0...7, step: 1)
                .tint(Color.goldAmber)

                // Tick labels
                HStack(spacing: 0) {
                    ForEach(pLabels.indices, id: \.self) { i in
                        Text(pLabels[i])
                            .font(BJFont.sora(9, weight: pouchIndex == i ? .bold : .regular))
                            .foregroundColor(pouchIndex == i ? Color.goldAmber : Color(white: 1, opacity: 0.3))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Tier result row
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("POUCHES / DAY")
                            .font(BJFont.sora(9, weight: .regular))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 1, opacity: 0.4))
                        Text(pLabels[pouchIndex])
                            .font(BJFont.playfair(21, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("MEMBER TIER STATUS")
                            .font(BJFont.sora(9, weight: .regular))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 1, opacity: 0.4))
                        Text(currentTierName)
                            .font(BJFont.playfair(21, weight: .bold))
                            .foregroundColor(tierColor)
                            .animation(.easeInOut(duration: 0.3), value: pouchIndex)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.goldAmber.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(Radius.md)

                // Scanner viewport
                ZStack {
                    // Subtle grid background
                    Color(white: 0.031)

                    // Corner scan brackets
                    LoyaltyScanBrackets()

                    // Animated scan beam
                    if scanPhase == .scanning {
                        LoyaltyScanBeam()
                    }

                    // Center content per phase
                    VStack(spacing: Spacing.xs) {
                        switch scanPhase {
                        case .idle:
                            SingleChipView()
                                .frame(width: 72, height: 72)
                                .opacity(pouchIndex == 0 ? 0.4 : 1.0)
                            Text(pouchIndex == 0 ? "Select your daily pouch usage above" : "Ready to scan")
                                .font(BJFont.sora(12, weight: .regular))
                                .foregroundColor(Color(white: 1, opacity: 0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.lg)

                        case .scanning:
                            SingleChipView()
                                .frame(width: 72, height: 72)
                            VStack(spacing: 6) {
                                Text("Scanning... \(Int(scanProgress * 100))%")
                                    .font(BJFont.sora(12, weight: .semibold))
                                    .foregroundColor(Color.goldAmber)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(white: 1, opacity: 0.1))
                                            .frame(width: 120, height: 3)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(LinearGradient.goldShimmer)
                                            .frame(width: 120 * scanProgress, height: 3)
                                    }
                                    .frame(width: 120)
                                }
                                .frame(width: 120, height: 3)
                            }

                        case .processing:
                            Text("Processing...")
                                .font(BJFont.sora(12, weight: .semibold))
                                .foregroundColor(Color.goldAmber)

                        case .done:
                            if showResult {
                                VStack(spacing: Spacing.xs) {
                                    Text(resultIcon)
                                        .font(.system(size: 32))
                                    Text(resultText)
                                        .font(BJFont.playfair(17, weight: .bold))
                                        .foregroundColor(tierColor)
                                        .multilineTextAlignment(.center)
                                        .shadow(color: tierColor.opacity(0.4), radius: 20)
                                    if currentTierName != "Standard" {
                                        Text("Loaded to your BlakJaks Wallet")
                                            .font(BJFont.sora(11, weight: .regular))
                                            .foregroundColor(Color(white: 1, opacity: 0.5))
                                    }
                                }
                                .padding(.horizontal, Spacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(
                            scanPhase == .done ? Color.goldAmber.opacity(0.5) : Color(white: 1, opacity: 0.08),
                            lineWidth: 1
                        )
                )
                .cornerRadius(Radius.md)
                .animation(.easeInOut(duration: 0.3), value: scanPhase == .done)

                // Scan button
                NeonGoldButton(buttonLabel, height: 50) { startScan() }
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.45 : 1)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.067), Color(white: 0.039)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(Color.goldAmber.opacity(0.2), lineWidth: 1)
                    GoldTopLine()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                }
            )
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }

    private func startScan() {
        guard !isDisabled else { return }
        scanPhase = .scanning
        showResult = false
        scanProgress = 0

        let totalDuration = 2.2
        let steps = 50
        for i in 0...steps {
            let delay = (Double(i) / Double(steps)) * totalDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                scanProgress = CGFloat(i) / CGFloat(steps)
                if i == steps {
                    scanPhase = .processing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        scanPhase = .done
                        withAnimation(.easeOut(duration: 0.4)) {
                            showResult = true
                        }
                    }
                }
            }
        }
    }
}

private struct LoyaltyScanBrackets: View {
    var body: some View {
        GeometryReader { geo in
            let c = Color.goldAmber.opacity(0.35)
            let len: CGFloat = 22
            let thick: CGFloat = 2
            let pad: CGFloat = 12
            ZStack {
                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: pad, y: pad + len))
                    p.addLine(to: CGPoint(x: pad, y: pad))
                    p.addLine(to: CGPoint(x: pad + len, y: pad))
                }.stroke(c, lineWidth: thick)
                // Top-right
                Path { p in
                    let x = geo.size.width - pad
                    p.move(to: CGPoint(x: x - len, y: pad))
                    p.addLine(to: CGPoint(x: x, y: pad))
                    p.addLine(to: CGPoint(x: x, y: pad + len))
                }.stroke(c, lineWidth: thick)
                // Bottom-left
                Path { p in
                    let y = geo.size.height - pad
                    p.move(to: CGPoint(x: pad, y: y - len))
                    p.addLine(to: CGPoint(x: pad, y: y))
                    p.addLine(to: CGPoint(x: pad + len, y: y))
                }.stroke(c, lineWidth: thick)
                // Bottom-right
                Path { p in
                    let x = geo.size.width - pad
                    let y = geo.size.height - pad
                    p.move(to: CGPoint(x: x - len, y: y))
                    p.addLine(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x, y: y - len))
                }.stroke(c, lineWidth: thick)
            }
        }
    }
}

private struct LoyaltyScanBeam: View {
    @State private var yOffset: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.goldAmber, Color.goldAmber.opacity(0.8), Color.goldAmber, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .shadow(color: Color.goldAmber.opacity(0.6), radius: 12)
                .padding(.horizontal, Spacing.md)
                .offset(y: yOffset)
                .onAppear {
                    let maxY = geo.size.height - 14
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        yOffset = maxY
                    }
                }
        }
    }
}

// MARK: - SECTION: Tier Perks (tabbed)

private struct LoyaltyTierPerksSection: View {
    @State private var activeTab: Int = 0

    private let tiers: [LoyaltyTierData] = [
        LoyaltyTierData(
            name: "Standard", color: Color(white: 0.53), suit: "♠",
            headline: "Pull Up A Chair",
            sub: "Free entry. Full access to the Social Club. Everyone starts at the table.",
            perks: [
                "Free forever. No credit card, no catch",
                "Access to the BlakJaks Social Club",
                "Eligible to become a BlakJaks affiliate",
                "Shop BlakJaks tins in-app",
                "Scan one chip, instant VIP upgrade",
            ]
        ),
        LoyaltyTierData(
            name: "VIP", color: Color.white, suit: "♥",
            headline: "The Rope Just Lifted",
            sub: "Comps up to $100. Exclusive Social Club lounge. You're on the list now.",
            perks: [
                "Up to $100 crypto comp",
                "Exclusive VIP Social Club lounge",
                "10% partner discounts",
                "VIP merchandise",
                "Early access to new BlakJaks drops",
            ]
        ),
        LoyaltyTierData(
            name: "High Roller", color: Color(white: 0.75), suit: "♦",
            headline: "The Inner Circle",
            sub: "Comps up to $1K. Premium merch drops. Your own section in the lounge.",
            perks: [
                "Up to $1,000 crypto comp",
                "Exclusive High Roller Social Club lounge",
                "15% partner discounts",
                "Premium High Roller merch drops",
                "Dedicated account manager",
            ]
        ),
        LoyaltyTierData(
            name: "Whale", color: Color.goldAmber, suit: "♣",
            headline: "The House Comes To You",
            sub: "Comps up to $10K. Casino packages. Luxury merch. Trip shots. The full spread.",
            perks: [
                "Up to $10,000 crypto comp",
                "Casino Comp Packages ($5K–$8K)",
                "Exclusive Whale Social Club lounge",
                "20% partner discounts",
                "Luxury merch + trip comps",
            ]
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "Know Your Table Limits",
                sub: "Membership Tiers recalculate every 90 days. How much you scan determines your status."
            )

            VStack(spacing: Spacing.md) {
                // Tab row
                HStack(spacing: Spacing.xxs) {
                    ForEach(tiers.indices, id: \.self) { i in
                        let t = tiers[i]
                        let isActive = activeTab == i
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { activeTab = i }
                        }) {
                            Text(t.name == "High Roller" ? "High\nRoller" : t.name)
                                .font(BJFont.sora(9, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(isActive ? t.color : Color(white: 1, opacity: 0.35))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .frame(minHeight: 44)
                                .background(isActive ? t.color.opacity(0.13) : Color(white: 1, opacity: 0.04))
                                .overlay(
                                    Rectangle()
                                        .fill(isActive ? t.color : Color.clear)
                                        .frame(height: 2),
                                    alignment: .bottom
                                )
                                .cornerRadius(Radius.sm)
                        }
                    }
                }

                // Content card
                let tc = tiers[activeTab]
                ZStack(alignment: .topTrailing) {
                    // Watermark suit character
                    Text(tc.suit)
                        .font(.system(size: 100))
                        .foregroundColor(tc.color.opacity(0.06))
                        .allowsHitTesting(false)
                        .padding(.top, Spacing.sm)
                        .padding(.trailing, Spacing.sm)

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(tc.headline)
                            .font(BJFont.sora(18, weight: .bold))
                            .foregroundColor(tc.color)

                        ForEach(tc.perks, id: \.self) { perk in
                            HStack(alignment: .center, spacing: Spacing.sm) {
                                Circle()
                                    .fill(tc.color)
                                    .frame(width: 5, height: 5)
                                Text(perk)
                                    .font(BJFont.outfit(14, weight: .regular))
                                    .foregroundColor(Color(white: 1, opacity: 0.75))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.xl)
                }
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.067), Color(white: 0.039)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(tc.color.opacity(0.2), lineWidth: 1)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, tc.color, Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .animation(.easeInOut(duration: 0.25), value: activeTab)
            }
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - SECTION: Casino Comps (Whale-only)

private struct LoyaltyCasinoCompsSection: View {
    private struct CasinoPkg {
        let icon: String
        let label: String
        let value: String
    }

    private let packages: [CasinoPkg] = [
        CasinoPkg(icon: "🏨", label: "Suite King Room",   value: "2 Nights"),
        CasinoPkg(icon: "🍽️", label: "Fine Dining",        value: "4 Meals"),
        CasinoPkg(icon: "🛎️", label: "Room Service",       value: "$1,000"),
        CasinoPkg(icon: "🎰", label: "Free Play",          value: "$1,000"),
        CasinoPkg(icon: "🎭", label: "Shows + Nightlife",  value: "2 Tickets + Table"),
        CasinoPkg(icon: "✈️", label: "Flights",            value: "$900 Credit"),
    ]

    @State private var neonGlow: Double = 1.0
    private let gold       = Color.goldAmber
    private let goldBright = Color(red: 230/255, green: 170/255, blue: 50/255)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Whale live badge
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.goldAmber)
                    .frame(width: 8, height: 8)
                Text("Whale Exclusive Comp")
                    .font(BJFont.sora(11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color.goldAmber)
                    .textCase(.uppercase)
            }
            .loyaltyReveal()

            // Neon gold bordered container
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LoyaltySectionHeader(
                    hook: "Casino Comps Are Live!",
                    sub: "Once you achieve Whale status, you are now eligible for Casino Comps. Valued from $5,000 to $8,000, useable at participating partner Casinos."
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    ForEach(packages.indices, id: \.self) { i in
                        let pkg = packages[i]
                        VStack(spacing: Spacing.xs) {
                            Text(pkg.icon)
                                .font(.system(size: 24))
                            Text(pkg.label)
                                .font(BJFont.sora(13, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(pkg.value)
                                .font(BJFont.outfit(13, weight: .regular))
                                .foregroundColor(Color.goldAmber)
                        }
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.067), Color(white: 0.039)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.goldAmber.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(
                        LinearGradient(stops: [
                            .init(color: goldBright.opacity(neonGlow * 0.85), location: 0.0),
                            .init(color: gold.opacity(neonGlow * 0.70),       location: 0.5),
                            .init(color: goldBright.opacity(neonGlow * 0.85), location: 1.0),
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)
            )
            .shadow(color: gold.opacity(neonGlow * 0.35), radius: 8, x: 0, y: 0)
            .shadow(color: gold.opacity(neonGlow * 0.15), radius: 20, x: 0, y: 0)
            .loyaltyReveal(delay: 0.1)
            .task {
                while !Task.isCancelled {
                    let idle = UInt64.random(in: 3_000_000_000...8_000_000_000)
                    try? await Task.sleep(nanoseconds: idle)
                    guard !Task.isCancelled else { break }
                    let pulses = Int.random(in: 2...4)
                    for p in 0..<pulses {
                        await MainActor.run {
                            withAnimation(.linear(duration: 0.04)) {
                                neonGlow = Double.random(in: 0.08...0.28)
                            }
                        }
                        try? await Task.sleep(nanoseconds: 40_000_000)
                        await MainActor.run {
                            withAnimation(.linear(duration: 0.04)) { neonGlow = 1.0 }
                        }
                        if p < pulses - 1 {
                            let gap = UInt64.random(in: 55_000_000...130_000_000)
                            try? await Task.sleep(nanoseconds: gap)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - SECTION: Trip Comps

private struct LoyaltyTripCompsSection: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var dragPrev: CGFloat? = nil
    @State private var lastAutoTime: Date? = nil
    @State private var dragEndOffset: CGFloat = 0

    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 12
    /// Pixels per second for continuous auto-scroll
    private let scrollSpeed: CGFloat = 40

    private let trips: [LoyaltyTrip] = [
        LoyaltyTrip(title: "Luxury African Big Game Safari",       value: "$160,000", icon: "🦁", desc: "Private game drives, luxury lodges, and the ultimate wildlife expedition across Africa's most iconic reserves."),
        LoyaltyTrip(title: "Ultimate Luxury Disney World",         value: "$150,000", icon: "🏰", desc: "Unlimited family fun. VIP guides, luxury resort, private dining & all parks with no limits."),
        LoyaltyTrip(title: "Monaco F1 VIP Experience",             value: "$135,000", icon: "🏎️", desc: "Yacht access, paddock passes, champagne on the harbor & driver meet-and-greets."),
        LoyaltyTrip(title: "Ultimate Las Vegas High-Roller",       value: "$130,000", icon: "🎰", desc: "Penthouse suite, private gaming salon, Michelin dining, shows & the full Vegas treatment."),
        LoyaltyTrip(title: "Ultimate Hawaii Trip",                 value: "$110,000", icon: "🌺", desc: "Multi-island luxury tour. Private helicopters, ocean adventures & five-star resorts."),
        LoyaltyTrip(title: "Ultimate Alaska Trip",                 value: "$105,000", icon: "🏔️", desc: "Glaciers, grizzlies & the Northern Lights. Luxury lodges, bush planes & wilderness."),
        LoyaltyTrip(title: "F1 Las Vegas Grand Prix VIP",          value: "$100,000", icon: "🏁", desc: "The Strip under the lights. Premium suite, pit lane access, after-race concerts."),
        LoyaltyTrip(title: "Private Golf & Whiskey Tour, Scotland", value: "$85,000", icon: "🥃", desc: "St Andrews, rare distillery tours, castle stays & private Highland golf."),
        LoyaltyTrip(title: "Luxury Hunting Lodge",                 value: "$85,000", icon: "🦌", desc: "Premier hunting lodge. World-class guided hunts, gourmet dining & wilderness luxury."),
        LoyaltyTrip(title: "Bespoke Gunsmith Experience",          value: "$85,000", icon: "🎯", desc: "Commission a custom firearm from a master gunsmith. Hand-fitted, engraved & built to spec."),
        LoyaltyTrip(title: "Ritz Paris Imperial Suite",            value: "$85,000", icon: "🗼", desc: "Imperial Suite, Michelin dining, private shopping in the City of Light."),
        LoyaltyTrip(title: "Badrutt's Palace, Switzerland",        value: "$85,000", icon: "🏔️", desc: "The legendary St. Moritz palace. Alpine luxury, world-class skiing & European elegance."),
        LoyaltyTrip(title: "Ultimate Aspen Trip",                  value: "$85,000", icon: "⛷️", desc: "Ski-in luxury, private powder guides, après-ski dining & the Aspen VIP lifestyle."),
        LoyaltyTrip(title: "Masters Golf VIP",                     value: "$80,000", icon: "⛳", desc: "Augusta National badges, patron suites, private golf at top courses & luxury villa."),
        LoyaltyTrip(title: "NBA Finals Courtside VIP",             value: "$80,000", icon: "🏀", desc: "Courtside seats, locker room access, player meet-and-greets & exclusive after-party."),
        LoyaltyTrip(title: "Ultimate Super Bowl Experience",       value: "$80,000", icon: "🏈", desc: "Premium suite, field access, exclusive parties, player meet-and-greets & luxury hotel."),
        LoyaltyTrip(title: "MLB World Series VIP",                 value: "$75,000", icon: "⚾", desc: "Diamond seats, clubhouse access, batting practice & exclusive pre-game hospitality."),
        LoyaltyTrip(title: "Yellowstone & Grand Teton Adventure", value: "$75,000", icon: "🐻", desc: "Private guided tours, luxury glamping, wildlife encounters & stunning landscapes."),
        LoyaltyTrip(title: "Deep Sea Fishing Trip",                value: "$75,000", icon: "🎣", desc: "Charter a world-class vessel. Marlin, tuna & big game fishing in premier waters."),
        LoyaltyTrip(title: "Top Gun Fighter Jet Experience",       value: "$70,000", icon: "✈️", desc: "Fly a real fighter jet with a combat pilot. Mach-speed thrills. Once in a lifetime."),
        LoyaltyTrip(title: "UFC Championship VIP",                 value: "$65,000", icon: "🥊", desc: "Cageside seats, fighter meet-and-greets, after-party access & luxury hotel."),
    ]

    /// Total width of one full set of cards
    private var setWidth: CGFloat {
        CGFloat(trips.count) * (cardWidth + cardSpacing)
    }

    /// Current "real" index (0..<trips.count) based on scroll offset
    private var currentIndex: Int {
        let raw = Int(round(-scrollOffset / (cardWidth + cardSpacing)))
        let mod = raw % trips.count
        return mod < 0 ? mod + trips.count : mod
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "Trip Comps Take You Places.",
                sub: "Any member at any time can be comped 1 of 21 dream trips valued from $65k up to $200k each."
            )

            VStack(spacing: Spacing.sm) {
                TimelineView(.animation) { timeline in
                    GeometryReader { geo in
                        let screenWidth = geo.size.width
                        let leadingPad = (screenWidth - cardWidth) / 2
                        let autoOffset = continuousAutoOffset(at: timeline.date)

                        HStack(spacing: cardSpacing) {
                            ForEach(0..<trips.count * 3, id: \.self) { i in
                                let trip = trips[i % trips.count]
                                LoyaltyTripCard(trip: trip)
                                    .frame(width: cardWidth)
                            }
                        }
                        .offset(x: leadingPad + autoOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragEndOffset = continuousAutoOffset(at: Date())
                                    }
                                    scrollOffset = dragEndOffset + value.translation.width
                                }
                                .onEnded { value in
                                    // Snap to nearest card
                                    let step = cardWidth + cardSpacing
                                    let snapped = round(scrollOffset / step) * step
                                    scrollOffset = snapped
                                    normalizeOffset()
                                    // Resume auto-scroll from current position
                                    lastAutoTime = Date()
                                    dragEndOffset = scrollOffset
                                    isDragging = false
                                }
                        )
                    }
                }
                .frame(height: 320)
                .clipped()

                // Dot indicator
                HStack(spacing: 5) {
                    ForEach(trips.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.goldAmber : Color(white: 1, opacity: 0.18))
                            .frame(
                                width: i == currentIndex ? 7 : 4,
                                height: i == currentIndex ? 7 : 4
                            )
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
        .onAppear {
            scrollOffset = -setWidth
            dragEndOffset = scrollOffset
            lastAutoTime = Date()
        }
    }

    /// Computes current offset: base offset + continuous time-based drift
    private func continuousAutoOffset(at date: Date) -> CGFloat {
        guard !isDragging else { return scrollOffset }
        let elapsed = date.timeIntervalSince(lastAutoTime ?? date)
        let raw = dragEndOffset - CGFloat(elapsed) * scrollSpeed
        // Normalize into the middle set so it loops forever
        let totalSet = setWidth
        var o = raw
        while o > -totalSet { o -= totalSet }
        while o < -totalSet * 2 { o += totalSet }
        // Update currentIndex tracking
        DispatchQueue.main.async {
            scrollOffset = o
        }
        return o
    }

    /// Keep offset within the middle set range
    private func normalizeOffset() {
        let totalSet = setWidth
        var o = scrollOffset
        while o > -totalSet { o -= totalSet }
        while o < -totalSet * 2 { o += totalSet }
        if o != scrollOffset {
            scrollOffset = o
        }
    }
}

private struct LoyaltyTripCard: View {
    let trip: LoyaltyTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gold top line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.goldAmber, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            VStack(alignment: .leading, spacing: 0) {
                // Trip Comp badge
                Text("Trip Comp")
                    .font(BJFont.sora(8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(Color.goldAmber)
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.goldAmber.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .stroke(Color.goldAmber.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(Radius.pill)
                    .padding(.bottom, Spacing.sm)

                Spacer()

                // Icon + title + desc
                VStack(spacing: Spacing.xs) {
                    Text(trip.icon)
                        .font(.system(size: 36))
                    Text(trip.title)
                        .font(BJFont.playfair(15, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    Text(trip.desc)
                        .font(BJFont.outfit(11, weight: .regular))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                Spacer()

                // Value
                VStack(spacing: 3) {
                    Text("TRIP VALUE")
                        .font(BJFont.sora(7, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color.goldAmber.opacity(0.6))
                        .textCase(.uppercase)
                    Text(trip.value)
                        .font(BJFont.playfair(24, weight: .bold))
                        .foregroundColor(Color.goldAmber)
                        .shadow(color: Color.goldAmber.opacity(0.3), radius: 20)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 308)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.075), Color(white: 0.039)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.goldAmber.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 8)
    }
}

// MARK: - SECTION: Wallet

private struct LoyaltyWalletSection: View {
    private struct WalletTx {
        let label: String
        let amount: String
        let time: String
        let isCredit: Bool
    }

    private let transactions: [WalletTx] = [
        WalletTx(label: "Crypto Comp Received", amount: "+$100.00", time: "2 days ago",  isCredit: true),
        WalletTx(label: "Welcome Comp",          amount: "+$5.00",   time: "7 days ago",  isCredit: true),
        WalletTx(label: "Withdrawal to Bank",    amount: "-$150.00", time: "14 days ago", isCredit: false),
    ]

    private let bullets: [String] = [
        "Comps are automatically deposited as USDC or USD the moment they are given.",
        "Withdraw to your bank via ACH or to any crypto wallet, anytime.",
        "No fees. No minimums. No waiting. It's your money.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "It's Your Money. Take It!",
                sub: "Comps land automatically. No claims, no codes, no hoops. Pull to your bank or crypto whenever you want. It's your money the second it hits."
            )

            VStack(spacing: 0) {
                // Gold top accent line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.goldAmber, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Wallet header
                    HStack(spacing: Spacing.sm) {
                        Text("♠")
                            .font(BJFont.playfair(22, weight: .bold))
                            .foregroundColor(Color.goldAmber)
                        Text("BlakJaks Wallet")
                            .font(BJFont.sora(13, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color.goldAmber)
                            .textCase(.uppercase)
                    }

                    // Horizontal rule
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color.goldAmber.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)

                    // Balance block
                    VStack(spacing: 4) {
                        Text("AVAILABLE BALANCE")
                            .font(BJFont.sora(9, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(white: 1, opacity: 0.4))
                        Text("$247.50")
                            .font(BJFont.playfair(38, weight: .bold))
                            .foregroundColor(Color.goldAmber)
                            .shadow(color: Color.goldAmber.opacity(0.2), radius: 30)
                        Text("≈ 247.50 USDC")
                            .font(BJFont.sora(12, weight: .regular))
                            .foregroundColor(Color(white: 1, opacity: 0.35))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Transaction rows
                    VStack(spacing: 0) {
                        ForEach(transactions.indices, id: \.self) { i in
                            let tx = transactions[i]
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tx.label)
                                        .font(BJFont.sora(13, weight: .regular))
                                        .foregroundColor(Color(white: 1, opacity: 0.85))
                                    Text(tx.time)
                                        .font(BJFont.sora(11, weight: .regular))
                                        .foregroundColor(Color(white: 1, opacity: 0.3))
                                }
                                Spacer()
                                Text(tx.amount)
                                    .font(BJFont.playfair(15, weight: .bold))
                                    .foregroundColor(tx.isCredit ? Color.goldAmber : Color(white: 1, opacity: 0.4))
                            }
                            .padding(.vertical, Spacing.sm)

                            if i < transactions.count - 1 {
                                Rectangle()
                                    .fill(Color(white: 1, opacity: 0.05))
                                    .frame(height: 1)
                            }
                        }
                    }

                    // Gold divider
                    GoldDivider()

                    // Bullets
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(bullets, id: \.self) { text in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Circle()
                                    .fill(Color.goldAmber)
                                    .frame(width: 6, height: 6)
                                    .shadow(color: Color.goldAmber.opacity(0.6), radius: 4)
                                    .shadow(color: Color.goldAmber.opacity(0.3), radius: 8)
                                    .padding(.top, 5)
                                Text(text)
                                    .font(BJFont.outfit(14, weight: .regular))
                                    .foregroundColor(Color(white: 1, opacity: 0.65))
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(Spacing.xl)
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.051), Color(white: 0.031)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(Color.goldAmber.opacity(0.3), lineWidth: 1)
            )
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - SECTION: Live Dashboard

private struct LoyaltyLiveDashboardSection: View {
    private struct Metric {
        let label: String
        let display: String
    }

    private let metrics: [Metric] = [
        Metric(label: "GLOBAL SCANS TODAY",     display: "48,725"),
        Metric(label: "TOTAL LIQUID ASSETS",    display: "$8,112,507"),
        Metric(label: "LIFETIME COMPS AWARDED", display: "28,471"),
        Metric(label: "PAYOUT SUCCESS RATE",    display: "99.7%"),
        Metric(label: "ACTIVE AFFILIATES",      display: "1,283"),
    ]

    private let tickerItems: [String] = [
        "♠ @jaxon_k received $100 USDC · 2m ago",
        "♦ @mr_t_nicotine received $1,000 USDC · 5m ago",
        "♣ @vaultking received $10,000 USDC · 12m ago",
        "♥ @smokeless_ryan received $100 USDC · 18m ago",
        "♠ @wild_card_88 received Casino Comp · 24m ago",
    ]

    private let bars: [CGFloat] = [60, 80, 45, 90, 70, 55, 85, 40]

    @State private var tickerIndex: Int = 0
    private let tickerTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "We Play Face Up",
                sub: "Five live dashboards. Every dollar, every scan, every payout. Public and on-chain."
            )

            VStack(spacing: 0) {
                // Live indicator row
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(BJFont.outfit(10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color.green)
                    Spacer()
                    Text("Updates every 5s")
                        .font(BJFont.outfit(9, weight: .regular))
                        .foregroundColor(Color(white: 1, opacity: 0.25))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(white: 1, opacity: 0.03))

                Rectangle().fill(Color(white: 1, opacity: 0.05)).frame(height: 1)

                // Metrics
                ForEach(metrics.indices, id: \.self) { i in
                    let m = metrics[i]
                    HStack {
                        Text(m.label)
                            .font(BJFont.sora(10, weight: .regular))
                            .tracking(1)
                            .foregroundColor(Color(white: 0.53))
                            .textCase(.uppercase)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Text(m.display)
                            .font(BJFont.outfit(17, weight: .bold))
                            .foregroundColor(Color.goldAmber)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                    Rectangle().fill(Color(white: 1, opacity: 0.04)).frame(height: 1)
                }

                // Bar chart
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("COMP ACTIVITY")
                        .font(BJFont.sora(8, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 1, opacity: 0.25))
                        .textCase(.uppercase)

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(bars.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.goldAmber, Color.goldMid],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: (bars[i] / 100) * 40)
                                .opacity(0.7 + (Double(i) / Double(bars.count)) * 0.3)
                        }
                    }
                    .frame(height: 44, alignment: .bottom)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                Rectangle().fill(Color(white: 1, opacity: 0.04)).frame(height: 1)

                // Scrolling ticker
                Text(tickerItems[tickerIndex])
                    .font(BJFont.outfit(10, weight: .regular))
                    .foregroundColor(Color(white: 0.33))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(tickerIndex)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: tickerIndex)
            }
            .background(Color(white: 0.051))
            .overlay(
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.goldAmber.opacity(0.15), lineWidth: 1)
                    Rectangle()
                        .fill(Color.goldAmber)
                        .frame(height: 2)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
        .onReceive(tickerTimer) { _ in
            withAnimation {
                tickerIndex = (tickerIndex + 1) % tickerItems.count
            }
        }
    }
}

// MARK: - SECTION: FAQ ("No Fine Print")

private struct LoyaltyFaqSection: View {
    @State private var openIndex: Int? = nil

    private struct FaqItem {
        let question: String
        let answer: String
    }

    private let faqs: [FaqItem] = [
        FaqItem(question: "Is membership really free?",
                answer: "Yes. Always. No credit card. No catch. No subscription."),
        FaqItem(question: "Do I need to buy pouches to scan a chip?",
                answer: "No. You need a chip, not necessarily a purchase. Friends can share theirs."),
        FaqItem(question: "How will I know when I score a comp?",
                answer: "Push notification + email + in-app alert. The moment it happens."),
        FaqItem(question: "Is the $50 promise real?",
                answer: "Every new member scores at least $50 in comps their first year. That's a commitment, not marketing."),
        FaqItem(question: "How do tiers work?",
                answer: "We count your chips every quarter. Your tier locks for 90 days. Drop below threshold and your tier adjusts, but your balance stays yours forever."),
        FaqItem(question: "How are Trip Comp recipients chosen?",
                answer: "BlakJaks selects members at its sole discretion based on non-purchase factors: account tenure, community participation, and compliance history. Purchases don't factor in."),
        FaqItem(question: "Are comps taxable?",
                answer: "Comps over $600 get a 1099. We report, you handle. Standard stuff."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            LoyaltySectionHeader(
                hook: "No Fine Print",
                sub: "No gotchas. No asterisks. Just answers."
            )

            VStack(spacing: 0) {
                ForEach(faqs.indices, id: \.self) { i in
                    let faq = faqs[i]
                    let isOpen = openIndex == i

                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                openIndex = isOpen ? nil : i
                            }
                        }) {
                            HStack(alignment: .center, spacing: Spacing.sm) {
                                Text(faq.question)
                                    .font(BJFont.sora(14, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(isOpen ? "−" : "+")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(Color.goldAmber)
                                    .frame(width: 28, alignment: .center)
                            }
                            .padding(.vertical, Spacing.md)
                        }
                        .buttonStyle(.plain)

                        if isOpen {
                            Text(faq.answer)
                                .font(BJFont.outfit(14, weight: .regular))
                                .foregroundColor(Color(white: 1, opacity: 0.8))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, Spacing.md)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    if i < faqs.count - 1 {
                        Rectangle()
                            .fill(Color.goldAmber.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, Spacing.md)
                    }
                }
            }
            .loyaltyReveal(delay: 0.1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }
}

// MARK: - SingleChipView (3D rotating chip)

private struct SingleChipView: UIViewRepresentable {

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.backgroundColor = .clear
        v.isPlaying = true
        v.antialiasingMode = .multisampling4X
        v.isUserInteractionEnabled = false

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // Camera
        let camNode = SCNNode()
        let cam = SCNCamera()
        cam.fieldOfView = 30
        cam.zNear = 0.1
        cam.zFar = 100
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, 6)
        scene.rootNode.addChildNode(camNode)

        // Lighting
        let amb = SCNNode()
        let ambLight = SCNLight()
        ambLight.type = .ambient
        ambLight.color = UIColor(white: 1, alpha: 0.4)
        amb.light = ambLight
        scene.rootNode.addChildNode(amb)

        let keyNode = SCNNode()
        let key = SCNLight()
        key.type = .directional
        key.color = UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1)
        key.intensity = 1400
        keyNode.light = key
        keyNode.position = SCNVector3(5, 10, 7)
        keyNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(keyNode)

        let fillNode = SCNNode()
        let fill = SCNLight()
        fill.type = .directional
        fill.color = UIColor(red: 0.267, green: 0.533, blue: 1.0, alpha: 1)
        fill.intensity = 300
        fillNode.light = fill
        fillNode.position = SCNVector3(-5, 5, -5)
        fillNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(fillNode)

        let rimNode = SCNNode()
        let rim = SCNLight()
        rim.type = .omni
        rim.color = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1)
        rim.intensity = 600
        rim.attenuationStartDistance = 0
        rim.attenuationEndDistance = 50
        rimNode.light = rim
        rimNode.position = SCNVector3(0, -10, 10)
        scene.rootNode.addChildNode(rimNode)

        // Build chip
        let chip = makeChip()
        // Tilt slightly so face is toward the user
        chip.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(chip)

        // Continuous Y rotation (right to left)
        let spin = SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 2, z: 0, duration: 4.0)
        chip.runAction(SCNAction.repeatForever(spin))

        v.scene = scene
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func makeChip() -> SCNNode {
        let g = SCNNode()

        let gold = SCNMaterial()
        gold.lightingModel = .physicallyBased
        gold.diffuse.contents = UIColor(red: 204/255, green: 143/255, blue: 23/255, alpha: 1)
        gold.metalness.contents = NSNumber(value: 0.92)
        gold.roughness.contents = NSNumber(value: 0.18)
        gold.emission.contents = UIColor(red: 0.05, green: 0.028, blue: 0.002, alpha: 1)

        let dark = SCNMaterial()
        dark.lightingModel = .physicallyBased
        dark.diffuse.contents = UIColor(white: 0.10, alpha: 1)
        dark.metalness.contents = NSNumber(value: 0.3)
        dark.roughness.contents = NSNumber(value: 0.7)

        // Body
        let cyl = SCNCylinder(radius: 1.0, height: 0.15)
        cyl.radialSegmentCount = 64
        cyl.materials = [dark, dark, dark]
        g.addChildNode(SCNNode(geometry: cyl))

        // Outer rings
        let outerTorus = SCNTorus()
        outerTorus.ringRadius = 0.97
        outerTorus.pipeRadius = 0.04
        outerTorus.ringSegmentCount = 64
        outerTorus.pipeSegmentCount = 16
        outerTorus.materials = [gold]
        for yOff: Float in [0.075, -0.075] {
            let n = SCNNode(geometry: outerTorus)
            n.position = SCNVector3(0, yOff, 0)
            g.addChildNode(n)
        }

        // Inner rings
        let innerTorus = SCNTorus()
        innerTorus.ringRadius = 0.5
        innerTorus.pipeRadius = 0.025
        innerTorus.ringSegmentCount = 64
        innerTorus.pipeSegmentCount = 16
        innerTorus.materials = [gold]
        for yOff: Float in [0.078, -0.078] {
            let n = SCNNode(geometry: innerTorus)
            n.position = SCNVector3(0, yOff, 0)
            g.addChildNode(n)
        }

        // Edge inlays
        let box = SCNBox(width: 0.08, height: 0.16, length: 0.12, chamferRadius: 0.005)
        box.materials = [gold]
        for i in 0..<16 {
            let a = Float(i) / 16 * .pi * 2
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(cos(a) * 0.95, 0, sin(a) * 0.95)
            n.eulerAngles = SCNVector3(0, -a + .pi / 2, 0)
            g.addChildNode(n)
        }

        return g
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LoyaltyView()
    }
}
