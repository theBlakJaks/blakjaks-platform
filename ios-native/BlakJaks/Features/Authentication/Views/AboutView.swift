import SwiftUI

// MARK: - AboutView
// Beat 1: Big Tobacco indictment (falling skulls)
// Beat 2: Meet BlakJaks (50% back, independently owned, values)
// Beat 3: Our Mission
// Beat 4: Who It's For
// Beat 5: The Declaration (rising chips)
// Beat 6: CTA

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    // Beat 2: BlakJaks intro
    @State private var introVisible = false

    // Beat 3: Mission
    @State private var missionVisible = false

    // Beat 4: Who it's for
    @State private var forVisible = false

    // Beat 5: Declaration
    @State private var declarationVisible = false
    @State private var chipsRising = false
    @State private var declarationPulse: CGFloat = 1.0

    // Constants
    private let amber = Color.goldAmber
    private let bg = Color.bgPrimary

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    introSection
                    valuesSection
                    forSection
                    declarationSection
                }
            }

            NoiseGrain()
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
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Beat 1: THE INDICTMENT
    // ─────────────────────────────────────────────────────────────────────

    private var heroSection: some View {
        ZStack {
            bg.ignoresSafeArea()

            SkullParticleView()
                .opacity(0.75)
                .allowsHitTesting(false)

            RadialGradient(
                colors: [.clear, bg.opacity(0.7), bg],
                center: .center,
                startRadius: 80,
                endRadius: 340
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }

            heroContent
        }
        .frame(height: UIScreen.main.bounds.height)
    }

    private var heroContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("They made billions.\nMillions paid with their lives.")
                    .font(BJFont.playfair(32, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)

                Text("For over a century, Big Tobacco didn't just profit off addiction. They destroyed lives, broke families, and created generational poverty. All by design.")
                    .font(BJFont.sora(15, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Now they're buying their way into nicotine pouches, a healthier alternative they didn't build, hoping to cash in on the hype and keep profiting off you without you ever noticing they're still the villain.")
                    .font(BJFont.sora(15, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Same playbook. Same players.\nDifferent product.")
                    .font(BJFont.sora(16, weight: .semibold))
                    .foregroundColor(amber)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 20, weight: .ultraLight))
                    .foregroundColor(amber.opacity(0.25))
            }
            .padding(.bottom, 50)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Beat 2: MEET BLAKJAKS
    // ─────────────────────────────────────────────────────────────────────

    private var introSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxxl)

            Text("ENTER BLAKJAKS")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("The First Entertainment\nPouch Empire.")
                .font(BJFont.playfair(30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // 50% promise
            fiftyPercentBlock

            // Core pillars
            VStack(spacing: Spacing.lg) {
                pillar(icon: "lock.shield", label: "Independently Owned. Forever.",
                       detail: "No corporate parent. No silent investors pulling strings. Just us and you.")

                pillar(icon: "gift", label: "Real Rewards.",
                       detail: "Not points that expire. Not coupons with fine print. Actual value returned to you every single time.")

                pillar(icon: "eye", label: "Radical Transparency.",
                       detail: "Open books. Real numbers. You see exactly where your money goes.")

                pillar(icon: "person.3", label: "Community Built.",
                       detail: "You shape the products. You influence the direction. Your voice has weight here.")
            }
            .padding(.top, Spacing.md)

            Spacer().frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
        .opacity(introVisible ? 1 : 0)
        .offset(y: introVisible ? 0 : 30)
        .background(scrollTrigger(threshold: 0.85) { triggered in
            if triggered && !introVisible {
                withAnimation(.easeOut(duration: 0.8)) { introVisible = true }
            }
        })
    }

    private var fiftyPercentBlock: some View {
        VStack(spacing: Spacing.sm) {
            Text("50%")
                .font(BJFont.outfit(64, weight: .heavy))
                .foregroundColor(amber)
                .shadow(color: amber.opacity(0.4), radius: 12)

            Text("of our profits returned\nback to our customers.")
                .font(BJFont.sora(15, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Every purchase. Every tin. No exceptions.")
                .font(BJFont.sora(11, weight: .semibold))
                .foregroundColor(amber.opacity(0.50))
                .padding(.top, 2)
        }
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(amber.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func pillar(icon: String, label: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(amber.opacity(0.70))
                .frame(width: 24, height: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(BJFont.sora(14, weight: .bold))
                    .foregroundColor(.white.opacity(0.90))
                Text(detail)
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Beat 3: OUR MISSION
    // ─────────────────────────────────────────────────────────────────────

    private var valuesSection: some View {
        VStack(spacing: Spacing.xl) {
            Rectangle()
                .fill(amber.opacity(0.2))
                .frame(width: 40, height: 0.5)

            Text("OUR MISSION")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("Build the largest customer\ndriven company in the world.")
                .font(BJFont.playfair(26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Where you share in our success, shape our products, and help us run the company alongside us.")
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.xxxl)
        .opacity(missionVisible ? 1 : 0)
        .offset(y: missionVisible ? 0 : 30)
        .background(scrollTrigger(threshold: 0.85) { triggered in
            if triggered && !missionVisible {
                withAnimation(.easeOut(duration: 0.8)) { missionVisible = true }
            }
        })
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Beat 4: WHO IT'S FOR
    // ─────────────────────────────────────────────────────────────────────

    private var forSection: some View {
        VStack(spacing: Spacing.xl) {
            Text("WHO IT'S FOR")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            VStack(alignment: .leading, spacing: Spacing.lg) {
                forLine("For those tired of boring products from faceless corporations.")
                forLine("For people who want to be treated like friends, not addicts.")
                forLine("For anyone who believes loyalty should mean something real.")
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.xxxl)
        .opacity(forVisible ? 1 : 0)
        .offset(y: forVisible ? 0 : 30)
        .background(scrollTrigger(threshold: 0.85) { triggered in
            if triggered && !forVisible {
                withAnimation(.easeOut(duration: 0.8)) { forVisible = true }
            }
        })
    }

    private func forLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("//")
                .font(BJFont.sora(14, weight: .bold))
                .foregroundColor(amber.opacity(0.50))
            Text(text)
                .font(BJFont.sora(15, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Beat 5: THE DECLARATION
    // ─────────────────────────────────────────────────────────────────────

    private var declarationSection: some View {
        ZStack {
            if chipsRising {
                ChipParticleView(risingMode: true)
                    .opacity(0.45)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            VStack(spacing: Spacing.lg) {
                Spacer().frame(height: 60)

                VStack(spacing: Spacing.xs) {
                    Text("You're not a customer.")
                        .font(BJFont.playfair(34, weight: .bold))
                        .foregroundColor(.white)
                    Text("You're the house.")
                        .font(BJFont.playfair(36, weight: .bold))
                        .foregroundColor(amber)
                        .shadow(color: amber.opacity(0.3), radius: 12)
                }
                .multilineTextAlignment(.center)
                .scaleEffect(declarationPulse)

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .frame(height: 300)
        .opacity(declarationVisible ? 1 : 0)
        .offset(y: declarationVisible ? 0 : 20)
        .background(scrollTrigger(threshold: 0.80) { triggered in
            if triggered && !declarationVisible {
                withAnimation(.easeOut(duration: 0.8)) { declarationVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 1.0)) { chipsRising = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.7)) { declarationPulse = 1.03 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeInOut(duration: 0.7)) { declarationPulse = 1.0 }
                    }
                }
            }
        })
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Scroll Trigger Helper
    // ─────────────────────────────────────────────────────────────────────

    private func scrollTrigger(threshold: CGFloat, onTrigger: @escaping (Bool) -> Void) -> some View {
        GeometryReader { geo in
            Color.clear.onChange(of: geo.frame(in: .global).minY) { minY in
                if minY < UIScreen.main.bounds.height * threshold {
                    onTrigger(true)
                }
            }
        }
    }
}

// MARK: - NoiseGrain

private struct NoiseGrain: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height * 0.003) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(Path(rect), with: .color(.white.opacity(Double.random(in: 0.02...0.05))))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .blendMode(.screen)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}
