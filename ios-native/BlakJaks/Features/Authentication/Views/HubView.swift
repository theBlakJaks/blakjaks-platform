import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants — computed once from screen width, never change at runtime
// ─────────────────────────────────────────────────────────────────────────────
private let kCardW: CGFloat = UIScreen.main.bounds.width * 0.62
private let kCardH: CGFloat = kCardW * 1.50
// Gap proof: adjacent card visual half-widths always sum to kCardW*(1+sideScale)/2.
// sideScale = 0.78 → sum = kCardW*0.89.
// kStep must exceed that sum to keep cards separated; +14 pt ensures a clear gap.
private let kStep:  CGFloat = kCardW * 0.89 + 14   // guaranteed 14 pt gap at all times
private let kLoop:  CGFloat = kStep * 4             // one full lap (4 cards)

// ─────────────────────────────────────────────────────────────────────────────
// HubView
// Three completely independent ZStack layers so no animation in one layer
// can ever shift another layer's position.
// ─────────────────────────────────────────────────────────────────────────────
struct HubView: View {
    @EnvironmentObject private var authState: AuthState

    // Navigation
    @State private var showLogin     = false
    @State private var showAbout     = false
    @State private var showLoyalty   = false
    @State private var showSocial    = false
    @State private var showAffiliate = false

    // Continuous scroll state
    private let scrollSpeed: CGFloat = kStep / 3.6      // one card every 3.6 s
    @State private var scrollRef  = Date()
    @State private var baseOffset: CGFloat = 0
    @State private var isDragging    = false
    @State private var frozenOffset: CGFloat = 0
    @State private var dragOffset:   CGFloat = 0

    // Flick momentum — exponential decay model
    // offset(t) = (baseOffset + V/k) - scrollSpeed*t  -  (V/k)*e^(-k*t)
    // As t→∞ this is pure auto-scroll; at t=0 velocity = V - scrollSpeed ✓
    private let flickDecay: CGFloat = 2.2               // lower = longer glide
    @State private var flickVelocity: CGFloat = 0       // pts/s at release

    private let decks: [HubDeck] = [
        HubDeck(rank: "A", suit: "♠", name: "About Us",   dest: .about),
        HubDeck(rank: "K", suit: "♥", name: "Loyalty",    dest: .loyalty),
        HubDeck(rank: "Q", suit: "♣", name: "Social",     dest: .social),
        HubDeck(rank: "J", suit: "♦", name: "Affiliates", dest: .affiliate),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Background: amber glow blobs + spotlight beams ───────────────
            HubBackground()

            // ── Layer 1: Logo — owns its own VStack, Spacer pushes it to top ──
            VStack(spacing: 0) {
                LogoAnimationView(width: 260)
                    .frame(width: 300, height: 140)
                    .clipped()
                    .allowsHitTesting(false)
                    .padding(.top, 16)
                Spacer(minLength: 0)
            }

            // ── Layer 2: Carousel — direct ZStack child, NOT inside any VStack ──
            // Being a direct ZStack child means it floats at the centre of the
            // screen and has NO layout relationship with the logo or button.
            TimelineView(.animation) { ctx in
                let raw = liveOffset(ctx.date)
                ZStack {
                    ForEach(decks.indices, id: \.self) { i in
                        let x = wrappedX(i, raw)
                        let t = CGFloat(max(0.0, 1.0 - Double(abs(x) / kStep)))
                        PlayingCardView(deck: decks[i], isFront: t > 0.82)
                            .frame(width: kCardW, height: kCardH)
                            // sideScale=0.78 at t=0, full size at t=1.
                            // kStep is derived from this exact value so cards
                            // are always 14+ pt apart — they never touch.
                            .scaleEffect(0.78 + 0.22 * t)
                            // No 3D rotation — rotation was making cards appear to
                            // pierce each other even when they weren't overlapping.
                            // Shadow and scale alone give plenty of depth.
                            .opacity(abs(x) > kStep * 1.9 ? 0 : 1)
                            .offset(x: x)
                            // Cubic curve: front card zIndex rises steeply to 100,
                            // side cards stay near 0 — no z-fighting during transition.
                            .zIndex(Double(t * t * t) * 100)
                            .onTapGesture {
                                navigate(decks[i].dest)
                            }
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: kCardH)
                .clipped()
            }
            // Hard fixed size — TimelineView never reports a different size to the ZStack
            .frame(width: UIScreen.main.bounds.width, height: kCardH)
            .offset(y: 20)          // nudge slightly below screen centre
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onChanged { v in
                        if !isDragging {
                            // Capture position BEFORE setting isDragging.
                            // liveOffset() returns frozenOffset+dragOffset when
                            // isDragging==true, which are both 0 on first drag —
                            // wrong. Reading it while isDragging==false gives the
                            // real current scroll position.
                            frozenOffset  = liveOffset(Date())
                            flickVelocity = 0
                            isDragging    = true
                        }
                        dragOffset = v.translation.width
                    }
                    .onEnded { v in
                        let currentPos = frozenOffset + dragOffset

                        // iOS 17+ gives us the real velocity in pts/s.
                        // On iOS 16 we estimate it from the predicted-end translation:
                        // predictedEndTranslation is ~35 ms ahead, so Δ/0.035 ≈ pts/s.
                        let vel: CGFloat
                        if #available(iOS 17, *) {
                            vel = v.velocity.width
                        } else {
                            let delta = v.predictedEndTranslation.width - v.translation.width
                            vel = delta / 0.035
                        }

                        // Absorb the full momentum displacement into baseOffset so the
                        // exponential decay term starts at exactly the right value.
                        flickVelocity = vel
                        baseOffset    = currentPos + vel / flickDecay
                        scrollRef     = Date()
                        dragOffset    = 0
                        isDragging    = false
                    }
            )

            // ── Layer 3: Button — owns its own VStack, Spacer pushes it to bottom ──
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                NeonGoldButton("LOGIN / SIGN UP") { showLogin = true }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .navigationBarHidden(true)
        .disableSwipeBack()
        .navigationDestination(isPresented: $showLogin)     { LoginView() }
        .navigationDestination(isPresented: $showAbout)     { AboutView() }
        .navigationDestination(isPresented: $showLoyalty)   { LoyaltyView() }
        .navigationDestination(isPresented: $showSocial)    { SocialPreviewView() }
        .navigationDestination(isPresented: $showAffiliate) { AffiliatePreviewView() }
    }

    // MARK: - Scroll helpers

    private func liveOffset(_ date: Date) -> CGFloat {
        if isDragging { return frozenOffset + dragOffset }

        let dt         = CGFloat(date.timeIntervalSince(scrollRef))
        let baseScroll = baseOffset - scrollSpeed * dt

        // Flick momentum decays exponentially and blends seamlessly into auto-scroll.
        // At t=0 the extra velocity equals the flick speed; at t=∞ it reaches 0.
        guard abs(flickVelocity) > 1 else { return baseScroll }
        let decay = -(flickVelocity / flickDecay) * exp(-flickDecay * dt)
        return baseScroll + decay
    }

    /// Maps card `idx` into the visible window [-kLoop/2, kLoop/2).
    private func wrappedX(_ idx: Int, _ raw: CGFloat) -> CGFloat {
        var x = (CGFloat(idx) * kStep + raw).truncatingRemainder(dividingBy: kLoop)
        if x < 0           { x += kLoop }
        if x > kLoop / 2   { x -= kLoop }
        return x
    }

    private func navigate(_ dest: HubDest) {
        switch dest {
        case .about:     showAbout     = true
        case .loyalty:   showLoyalty   = true
        case .social:    showSocial    = true
        case .affiliate: showAffiliate = true
        }
    }
}

// MARK: - Data types

enum HubDest { case about, loyalty, social, affiliate }

struct HubDeck {
    let rank: String
    let suit: String
    let name: String
    let dest: HubDest
}

// MARK: - PlayingCardView  (dark luxury casino theme)

private struct PlayingCardView: View {
    let deck: HubDeck
    let isFront: Bool

    // Amber gold palette — based on brand goldAmber #CC8F17
    private let goldBright = Color(red: 230/255, green: 170/255, blue: 50/255)
    private let gold       = Color(red: 204/255, green: 143/255, blue: 23/255)   // #CC8F17
    private let goldDeep   = Color(red: 140/255, green: 90/255,  blue: 10/255)
    private let cream      = Color(red: 224/255, green: 195/255, blue: 140/255)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Deep dark card face ───────────────────────────────────
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(stops: [
                        .init(color: Color(red: 14/255,  green: 11/255, blue:  5/255), location: 0.0),
                        .init(color: Color(red:  9/255,  green:  7/255, blue:  3/255), location: 0.5),
                        .init(color: Color(red: 16/255,  green: 13/255, blue:  4/255), location: 1.0),
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))

                // ── Outer gold border (gradient shimmer) ──────────────────
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        LinearGradient(stops: [
                            .init(color: goldBright.opacity(0.90), location: 0.00),
                            .init(color: gold.opacity(0.55),       location: 0.45),
                            .init(color: goldDeep.opacity(0.80),   location: 1.00),
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5)

                // ── Inner gold border (double-border luxury look) ─────────
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(gold.opacity(0.22), lineWidth: 0.75)
                    .padding(7)

                // ── Corner pips ───────────────────────────────────────────
                pip(h: h)
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .topLeading)
                    .padding(.leading, w * 0.09)
                    .padding(.top,    h * 0.028)

                pip(h: h)
                    .rotationEffect(.degrees(180))
                    .frame(maxWidth: .infinity, maxHeight: .infinity,
                           alignment: .bottomTrailing)
                    .padding(.trailing, w * 0.09)
                    .padding(.bottom,   h * 0.028)

                // ── Centre: suit glyph + ornamental rule + title ──────────
                VStack(spacing: h * 0.020) {
                    Text(deck.suit)
                        .font(.system(size: h * 0.25, weight: .regular))
                        .foregroundColor(gold)

                    // Ornamental divider  ── ◆ ──
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.clear, gold.opacity(0.6), Color.clear],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(height: 0.75)
                        Text("◆")
                            .font(.system(size: 6))
                            .foregroundColor(gold.opacity(0.8))
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.clear, gold.opacity(0.6), Color.clear],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(height: 0.75)
                    }
                    .frame(width: w * 0.55)

                    Text(deck.name.uppercased())
                        .font(BJFont.playfair(h * 0.044, weight: .bold))
                        .tracking(3)
                        .foregroundColor(cream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, w * 0.08)
                }
                .offset(y: -h * 0.015)

                // ── "TAP TO EXPLORE" hint on the front card ───────────────
                if isFront {
                    Text("TAP TO EXPLORE")
                        .font(BJFont.sora(h * 0.022, weight: .regular))
                        .tracking(2.5)
                        .foregroundColor(gold.opacity(0.50))
                        .frame(maxWidth: .infinity, maxHeight: .infinity,
                               alignment: .bottom)
                        .padding(.bottom, h * 0.058)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.50), radius: 12, x: 0, y: 5)
        }
    }

    @ViewBuilder
    private func pip(h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(deck.rank)
                .font(BJFont.playfair(h * 0.074, weight: .bold))
                .foregroundColor(gold)
            Text(deck.suit)
                .font(.system(size: h * 0.054))
                .foregroundColor(gold.opacity(0.80))
        }
    }
}

// MARK: - HubBackground
// Same amber glow blob + spotlight style as WelcomeBackground.
// Oversized frames ensure blur fully dissipates before the frame boundary.

private struct HubBackground: View {
    @State private var spot1Angle: Double = -8
    @State private var spot2Angle: Double = 0
    @State private var spot3Angle: Double = 8
    @State private var glowScale1: CGFloat = 1.0
    @State private var glowScale2: CGFloat = 1.0
    @State private var glowScale3: CGFloat = 1.0

    private let W = UIScreen.main.bounds.width
    private let H = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            // Glow blobs
            Circle()
                .fill(RadialGradient(
                    colors: [Color.goldAmber.opacity(0.30), Color.goldAmber.opacity(0.12), Color.clear],
                    center: .center, startRadius: 0, endRadius: 140
                ))
                .frame(width: 580, height: 580)
                .blur(radius: 60)
                .scaleEffect(glowScale1)
                .position(x: W * 0.85, y: H * 0.15)

            Circle()
                .fill(RadialGradient(
                    colors: [Color.goldAmber.opacity(0.25), Color.goldAmber.opacity(0.10), Color.clear],
                    center: .center, startRadius: 0, endRadius: 120
                ))
                .frame(width: 540, height: 540)
                .blur(radius: 60)
                .scaleEffect(glowScale2)
                .position(x: W * 0.10, y: H * 0.55)

            Circle()
                .fill(RadialGradient(
                    colors: [Color.goldAmber.opacity(0.22), Color.goldAmber.opacity(0.08), Color.clear],
                    center: .center, startRadius: 0, endRadius: 100
                ))
                .frame(width: 480, height: 480)
                .blur(radius: 60)
                .scaleEffect(glowScale3)
                .position(x: W * 0.55, y: H * 0.88)

            // Spotlight beams
            HubSpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.15 + 110, y: H / 2)
                .rotationEffect(.degrees(spot1Angle), anchor: .top)

            HubSpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.50 + 110, y: H / 2)
                .rotationEffect(.degrees(spot2Angle), anchor: .top)

            HubSpotlightBeam()
                .frame(width: 220, height: H)
                .position(x: W * 0.85 + 110, y: H / 2)
                .rotationEffect(.degrees(spot3Angle), anchor: .top)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true))  { spot1Angle = 8  }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { spot2Angle = -6 }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true))  { spot3Angle = -8 }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true))  { glowScale1 = 1.18 }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true))  { glowScale2 = 1.14 }
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)){ glowScale3 = 1.12 }
        }
    }
}

private struct HubSpotlightBeam: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.goldAmber.opacity(0.30), location: 0.00),
                .init(color: Color.goldAmber.opacity(0.16), location: 0.20),
                .init(color: Color.goldAmber.opacity(0.08), location: 0.40),
                .init(color: Color.clear,                   location: 0.60),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 30)
    }
}

// MARK: - InfoPlaceholderView  (kept for any future use)

struct InfoPlaceholderView: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Text(title)
                    .font(BJFont.playfair(28, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                Text("Coming soon")
                    .font(BJFont.sora(14, weight: .regular))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HubView()
            .environmentObject(AuthState())
    }
}
