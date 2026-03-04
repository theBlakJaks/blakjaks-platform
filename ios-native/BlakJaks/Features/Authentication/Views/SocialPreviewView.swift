import SwiftUI

// MARK: - SocialPreviewView
// The BlakJaks Social Club onboarding/info page.
// Four pillars: Universal Chat · Weekly Livestreams · Partner Streamers · Governance

struct SocialPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    private let amber = Color.goldAmber
    private let bg = Color.bgPrimary

    // Scroll-triggered section visibility
    @State private var chatVisible = false
    @State private var streamsVisible = false
    @State private var partnersVisible = false
    @State private var governanceVisible = false

    var body: some View {
        ZStack(alignment: .top) {
            bg.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        chatSection
                        SCGoldDivider()
                        livestreamSection
                        SCGoldDivider()
                        partnerSection
                        SCGoldDivider()
                        governanceSection
                        Spacer().frame(height: Spacing.xxxl)
                    }
                    .frame(width: geo.size.width)
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
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Hero Section
    // ─────────────────────────────────────────────────────────────────────

    private var heroSection: some View {
        ZStack {
            bg.ignoresSafeArea()

            // 3D Globe with country outlines and beacon arcs
            GlobeSceneView()
                .allowsHitTesting(false)

            // Edge vignette so text stays readable over the globe
            RadialGradient(
                colors: [.clear, bg.opacity(0.15), bg.opacity(0.55)],
                center: .center,
                startRadius: 160,
                endRadius: 420
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Bottom fade
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
            }

            heroContent
        }
        .frame(height: UIScreen.main.bounds.height)
    }

    private var heroContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Text("THE SOCIAL CLUB")
                    .font(BJFont.sora(10, weight: .bold))
                    .tracking(6)
                    .foregroundColor(amber.opacity(0.55))

                Text("Where the Entire\nWorld Meets at\nOne Table.")
                    .font(BJFont.playfair(36, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Community. Entertainment. Governance.\nAll without borders.")
                    .font(BJFont.sora(15, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                // Four pillar icons
                HStack(spacing: Spacing.md) {
                    pillarBadge(icon: "bubble.left.and.bubble.right", label: "Chat")
                    pillarBadge(icon: "video", label: "Live")
                    pillarBadge(icon: "play.rectangle", label: "Stream")
                    pillarBadge(icon: "hand.raised", label: "Vote")
                }
                .padding(.top, Spacing.md)
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

    private func pillarBadge(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(amber.opacity(0.80))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(amber.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(amber.opacity(0.15), lineWidth: 0.5)
                )

            Text(label.uppercased())
                .font(BJFont.sora(9, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.45))
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Section 1: Universal Chat
    // ─────────────────────────────────────────────────────────────────────

    private var chatSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxxl)

            Text("UNIVERSAL CHAT")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("One Community.\nEvery Language.")
                .font(BJFont.playfair(30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("A familiar, modern chat system where every message is automatically translated into the reader's native language. In real time.")
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            // Mock chat UI
            chatMockup

            // Callout box
            neonCallout("Every member on the planet can talk to every other member, regardless of what language they speak. One community. One conversation. No barriers.")

            // Feature bullets
            VStack(spacing: Spacing.md) {
                featureBullet(icon: "number", text: "Organized rooms and channels you can browse and join")
                featureBullet(icon: "globe", text: "Real-time translation based on your language preference")
                featureBullet(icon: "person.3", text: "A single, unified global community with no regional segmentation")
            }
            .padding(.top, Spacing.sm)

            Spacer().frame(height: Spacing.xxxl)
        }
        .padding(.horizontal, Spacing.xl)
        .opacity(chatVisible ? 1 : 0)
        .offset(y: chatVisible ? 0 : 30)
        .background(scScrollTrigger(threshold: 0.85) { triggered in
            if triggered && !chatVisible {
                withAnimation(.easeOut(duration: 0.8)) { chatVisible = true }
            }
        })
    }

    private var chatMockup: some View {
        VStack(spacing: 0) {
            // Channel header
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(amber.opacity(0.6))
                Text("general")
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 6, height: 6)
                Text("4,218 online")
                    .font(BJFont.sora(10, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.white.opacity(0.03))

            Rectangle()
                .fill(amber.opacity(0.1))
                .frame(height: 0.5)

            // Messages
            VStack(spacing: Spacing.sm) {
                chatBubble(flag: "\u{1F1FA}\u{1F1F8}", name: "Jake", message: "Just scanned my 50th tin. Whale status incoming.", time: "2:14 PM")
                chatBubble(flag: "\u{1F1EF}\u{1F1F5}", name: "Yuki", message: "Welcome to the club! I hit Whale last month.", time: "2:14 PM", translated: "Japanese")
                chatBubble(flag: "\u{1F1E7}\u{1F1F7}", name: "Lucas", message: "The comps at Whale tier are insane. Trust the process.", time: "2:15 PM", translated: "Portuguese")
            }
            .padding(Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private func chatBubble(flag: String, name: String, message: String, time: String, translated: String? = nil) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(flag)
                .font(.system(size: 20))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(BJFont.sora(12, weight: .semibold))
                        .foregroundColor(amber.opacity(0.85))
                    Text(time)
                        .font(BJFont.sora(9, weight: .regular))
                        .foregroundColor(.white.opacity(0.25))
                }
                Text(message)
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(.white.opacity(0.70))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let lang = translated {
                    Text("translated from \(lang)")
                        .font(BJFont.sora(9, weight: .regular))
                        .foregroundColor(amber.opacity(0.35))
                        .italic()
                }
            }

            Spacer()
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Section 2: Weekly Livestreams
    // ─────────────────────────────────────────────────────────────────────

    private var livestreamSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxxl)

            Text("WEEKLY LIVESTREAMS")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("Appointment Viewing\nfor the Culture.")
                .font(BJFont.playfair(30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Every week, BlakJaks goes live. Company updates, live entertainment, interactive games, prizes, and giveaways.")
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            // Two cards side by side
            HStack(spacing: Spacing.sm) {
                livestreamCard(
                    icon: "briefcase",
                    title: "Company Updates",
                    desc: "Where we stand and where we're headed. Stay connected to the journey."
                )
                livestreamCard(
                    icon: "sparkles",
                    title: "Live Entertainment",
                    desc: "Casino broadcasts, events, random winner picks, games, and merch drops."
                )
            }

            // AI Translation feature block
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(amber)
                    Text("AI VOICE CLONING")
                        .font(BJFont.sora(10, weight: .bold))
                        .tracking(4)
                        .foregroundColor(amber.opacity(0.7))
                }

                Text("Hear every stream in your language, in the host's own voice.")
                    .font(BJFont.sora(16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("AI speech-to-text converts the audio, translates it into your language, then reconstructs the speech using the original speaker's cloned voice. Real-time. Every language.")
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                // Visual: language flags flowing from speaker
                HStack(spacing: Spacing.xs) {
                    Text("\u{1F399}")
                        .font(.system(size: 24))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(amber.opacity(0.4))
                    Text("\u{1F1FA}\u{1F1F8}")
                        .font(.system(size: 18))
                    Text("\u{1F1EF}\u{1F1F5}")
                        .font(.system(size: 18))
                    Text("\u{1F1E7}\u{1F1F7}")
                        .font(.system(size: 18))
                    Text("\u{1F1E9}\u{1F1EA}")
                        .font(.system(size: 18))
                    Text("\u{1F1EB}\u{1F1F7}")
                        .font(.system(size: 18))
                    Text("\u{1F1F0}\u{1F1F7}")
                        .font(.system(size: 18))
                }
                .padding(.top, Spacing.xs)
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(amber.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(amber.opacity(0.15), lineWidth: 0.5)
            )

            Spacer().frame(height: Spacing.xxxl)
        }
        .padding(.horizontal, Spacing.xl)
        .opacity(streamsVisible ? 1 : 0)
        .offset(y: streamsVisible ? 0 : 30)
        .background(scScrollTrigger(threshold: 0.85) { triggered in
            if triggered && !streamsVisible {
                withAnimation(.easeOut(duration: 0.8)) { streamsVisible = true }
            }
        })
    }

    private func livestreamCard(icon: String, title: String, desc: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(amber.opacity(0.75))
                .frame(height: 28)

            Text(title)
                .font(BJFont.sora(13, weight: .bold))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)

            Text(desc)
                .font(BJFont.sora(11, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Section 3: Partner Streamers
    // ─────────────────────────────────────────────────────────────────────

    private var partnerSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxxl)

            Text("PARTNER STREAMERS")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("Your Favorite Creators.\nZero Platform Fees.")
                .font(BJFont.playfair(30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Top creators from Twitch, Kick, and YouTube stream directly on BlakJaks. Better for them. Better for you.")
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            // Three benefit cards
            VStack(spacing: Spacing.sm) {
                streamerBenefitCard(
                    number: "01",
                    icon: "dollarsign.circle",
                    title: "100% Donations",
                    desc: "Streamers keep every dollar. No platform cut. Ever."
                )
                streamerBenefitCard(
                    number: "02",
                    icon: "globe",
                    title: "Auto-Translation",
                    desc: "Content automatically translated for a global audience at no cost to the streamer."
                )
                streamerBenefitCard(
                    number: "03",
                    icon: "link",
                    title: "Affiliate Revenue",
                    desc: "Viewers who sign up through a stream become the streamer's referrals, earning them ongoing affiliate income."
                )
            }

            // Platform callout
            VStack(spacing: Spacing.sm) {
                Text("Twitch. Kick. YouTube.")
                    .font(BJFont.sora(14, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                Text("Now BlakJaks.")
                    .font(BJFont.sora(18, weight: .bold))
                    .foregroundColor(amber)
            }
            .padding(.top, Spacing.md)

            Text("Watch your favorite creators without ever leaving the app.")
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(.white.opacity(0.50))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: Spacing.xxxl)
        }
        .padding(.horizontal, Spacing.xl)
        .opacity(partnersVisible ? 1 : 0)
        .offset(y: partnersVisible ? 0 : 30)
        .background(scScrollTrigger(threshold: 0.85) { triggered in
            if triggered && !partnersVisible {
                withAnimation(.easeOut(duration: 0.8)) { partnersVisible = true }
            }
        })
    }

    private func streamerBenefitCard(number: String, icon: String, title: String, desc: String) -> some View {
        HStack(spacing: Spacing.md) {
            // Number box
            Text(number)
                .font(BJFont.outfit(18, weight: .bold))
                .foregroundColor(amber)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(amber.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(amber.opacity(0.20), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(amber.opacity(0.7))
                    Text(title)
                        .font(BJFont.sora(14, weight: .bold))
                        .foregroundColor(.white.opacity(0.90))
                }
                Text(desc)
                    .font(BJFont.sora(12, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Section 4: Governance
    // ─────────────────────────────────────────────────────────────────────

    private var governanceSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer().frame(height: Spacing.xxxl)

            Text("GOVERNANCE")
                .font(BJFont.sora(10, weight: .bold))
                .tracking(6)
                .foregroundColor(amber.opacity(0.55))

            Text("Your Vote Is Law.")
                .font(BJFont.playfair(32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("BlakJaks puts real business decisions to a member vote. And the company follows the outcome. Every time.")
                .font(BJFont.sora(14, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.sm)

            // Mock voting cards
            VStack(spacing: Spacing.sm) {
                voteCard(question: "New Flavor Drop", optionA: "Mango Ice", optionB: "Wintermint", pctA: 0.62, status: "Closed")
                voteCard(question: "Loyalty System Update", optionA: "More frequent comps", optionB: "Higher comp values", pctA: 0.44, status: "Live Now")
                voteCard(question: "Take the Company Public?", optionA: "Yes, IPO", optionB: "Stay private", pctA: 0.38, status: "Coming Soon")
            }

            // Declaration callout
            neonCallout("You're not a customer. You're a stakeholder. Every member vote is binding. The company follows the outcome.")

            VStack(spacing: Spacing.md) {
                featureBullet(icon: "checkmark.seal", text: "Vote on new flavors, comp structures, and corporate direction")
                featureBullet(icon: "lock.shield", text: "Member votes are treated as law")
                featureBullet(icon: "person.3", text: "Direct influence over the future of the brand")
            }

            Spacer().frame(height: Spacing.xxxl)
        }
        .padding(.horizontal, Spacing.xl)
        .opacity(governanceVisible ? 1 : 0)
        .offset(y: governanceVisible ? 0 : 30)
        .background(scScrollTrigger(threshold: 0.85) { triggered in
            if triggered && !governanceVisible {
                withAnimation(.easeOut(duration: 0.8)) { governanceVisible = true }
            }
        })
    }

    private func voteCard(question: String, optionA: String, optionB: String, pctA: CGFloat, status: String) -> some View {
        let pctB = 1.0 - pctA
        let isLive = status == "Live Now"

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(question)
                    .font(BJFont.sora(13, weight: .bold))
                    .foregroundColor(.white.opacity(0.90))
                Spacer()
                Text(status.uppercased())
                    .font(BJFont.sora(9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(isLive ? Color.green : amber.opacity(0.5))
            }

            // Option A
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(optionA)
                        .font(BJFont.sora(12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(pctA * 100))%")
                        .font(BJFont.outfit(12, weight: .bold))
                        .foregroundColor(amber)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(amber.opacity(0.6))
                            .frame(width: geo.size.width * pctA, height: 4)
                    }
                }
                .frame(height: 4)
            }

            // Option B
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(optionB)
                        .font(BJFont.sora(12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(pctB * 100))%")
                        .font(BJFont.outfit(12, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(width: geo.size.width * pctB, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(isLive ? Color.green.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Shared Components
    // ─────────────────────────────────────────────────────────────────────

    private func neonCallout(_ text: String) -> some View {
        Text(text)
            .font(BJFont.sora(14, weight: .semibold))
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [amber, amber.opacity(0.3), amber.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: amber.opacity(0.15), radius: 12)
    }

    private func featureBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(amber.opacity(0.65))
                .frame(width: 20, height: 20, alignment: .center)

            Text(text)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Scroll Trigger
    // ─────────────────────────────────────────────────────────────────────

    private func scScrollTrigger(threshold: CGFloat, onTrigger: @escaping (Bool) -> Void) -> some View {
        GeometryReader { geo in
            Color.clear.onChange(of: geo.frame(in: .global).minY) { minY in
                if minY < UIScreen.main.bounds.height * threshold {
                    onTrigger(true)
                }
            }
        }
    }
}

// MARK: - Gold Divider (local)

private struct SCGoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.goldAmber.opacity(0.4), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SocialPreviewView()
    }
}
