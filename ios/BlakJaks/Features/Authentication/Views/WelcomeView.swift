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
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Brand header
                VStack(spacing: Spacing.sm) {
                    Text("BlakJaks")
                        .font(.brandLargeTitle)
                        .foregroundColor(.gold)
                    Text("Premium Nicotine Products")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Spacing.xxl * 1.5)

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
                    GoldButton("Create Account") {
                        showSignup = true
                    }

                    SecondaryButton("Sign In") {
                        showLogin = true
                    }

                    Text("By continuing you agree to our Terms of Service and Privacy Policy.")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Layout.screenMargin)
                .padding(.bottom, Spacing.xxl)
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
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.gold)
            }

            VStack(spacing: Spacing.sm) {
                Text(card.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Text(card.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(.horizontal, Layout.screenMargin)
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
