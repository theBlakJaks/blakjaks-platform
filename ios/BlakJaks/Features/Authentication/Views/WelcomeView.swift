import SwiftUI

// MARK: - WelcomeView
// Splash + 3-card onboarding carousel, then routes to LoginView or SignupView.

struct WelcomeView: View {
    @Binding var isAuthenticated: Bool
    @State private var currentPage = 0
    @State private var showLogin   = false
    @State private var showSignup  = false

    private let onboardingCards: [OnboardingCard] = [
        OnboardingCard(
            icon: "qrcode.viewfinder",
            title: "Earn USDC Rewards",
            subtitle: "Scan QR codes on every BlakJaks product and earn real crypto directly to your wallet."
        ),
        OnboardingCard(
            icon: "suit.spade.fill",
            title: "Gold Tier Benefits",
            subtitle: "Climb from Standard to Whale — unlock exclusive comps, guaranteed prizes, and trip rewards."
        ),
        OnboardingCard(
            icon: "chart.bar.xaxis",
            title: "Real-Time Insights",
            subtitle: "Full treasury transparency. Watch the platform grow with live on-chain data and analytics."
        )
    ]

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Brand header
                VStack(spacing: Spacing.sm) {
                    Text("BlakJaks")
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundColor(.gold)
                    // Gold accent rule beneath wordmark
                    Rectangle()
                        .fill(Color.gold)
                        .frame(width: 48, height: 2)
                    Text("Premium Nicotine Products")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.xxxl)

                // Onboarding cards
                TabView(selection: $currentPage) {
                    ForEach(Array(onboardingCards.enumerated()), id: \.offset) { index, card in
                        onboardingCardView(card: card)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 260)
                .padding(.top, Spacing.xl)

                // Page dots
                HStack(spacing: 6) {
                    ForEach(0..<onboardingCards.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.gold : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 20 : 6, height: 6)
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, Spacing.md)

                Spacer()

                // CTA buttons
                VStack(spacing: Spacing.sm) {
                    GoldButton("Sign Up") {
                        showSignup = true
                    }

                    SecondaryButton("Log In") {
                        showLogin = true
                    }

                    Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationDestination(isPresented: $showLogin) {
            LoginView(isAuthenticated: $isAuthenticated)
        }
        .navigationDestination(isPresented: $showSignup) {
            SignupView(isAuthenticated: $isAuthenticated)
        }
    }

    private func onboardingCardView(card: OnboardingCard) -> some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.gold.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: card.icon)
                    .font(.largeTitle.weight(.light))
                    .foregroundColor(.gold)
            }

            VStack(spacing: Spacing.sm) {
                Text(card.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                Text(card.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - OnboardingCard model

private struct OnboardingCard {
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WelcomeView(isAuthenticated: .constant(false))
    }
}
