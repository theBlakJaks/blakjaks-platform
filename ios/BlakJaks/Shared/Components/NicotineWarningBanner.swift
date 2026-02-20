import SwiftUI

// MARK: - NicotineWarningBanner
// FDA-compliant nicotine warning per 21 CFR § 1143.3(b)(2).
// Required on: iOS splash screen, Shop, Cart, Checkout.
// NOT shown on: Insights, Social, Wallet, Scanner, Profile.
//
// Spec:
// - Occupies 20% of screen height (top)
// - Black background (#000000)
// - White text (#FFFFFF)
// - Helvetica Bold / Arial Bold font (FDA-specified)
// - Text dynamically sized to fill banner area without overflow
// - NEVER dismissible — no close button
//
// Usage: Add to top of required views, offset content by 20% screen height.
// Pages that include this MUST add .padding(.top, bannerHeight) to content below.

struct NicotineWarningBanner: View {
    private let warningText = "WARNING: This product contains nicotine. Nicotine is an addictive chemical."

    var body: some View {
        GeometryReader { geo in
            let bannerHeight = geo.size.height * 0.20

            ZStack {
                Color.black

                Text(warningText)
                    .font(.custom("Helvetica-Bold", size: dynamicFontSize(for: geo.size)))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, Spacing.md)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: bannerHeight)
            .frame(maxWidth: .infinity)
        }
        .frame(height: UIScreen.main.bounds.height * 0.20)
        .ignoresSafeArea(edges: .top)
    }

    // Dynamically size text to fill the banner without overflow
    private func dynamicFontSize(for size: CGSize) -> CGFloat {
        let bannerHeight = size.height * 0.20
        // Start large, let minimumScaleFactor handle reduction
        return min(bannerHeight * 0.22, 24)
    }
}

// MARK: - View modifier for pages that require the banner

struct NicotineWarningBannerModifier: ViewModifier {
    func body(content: Content) -> some View {
        let bannerHeight = UIScreen.main.bounds.height * 0.20
        ZStack(alignment: .top) {
            content
                .padding(.top, bannerHeight)
            NicotineWarningBanner()
        }
    }
}

extension View {
    /// Adds the FDA-required nicotine warning banner to the top of this view.
    /// Content is automatically offset by 20% screen height.
    /// Only apply to: Splash/Welcome, Shop, Cart, Checkout.
    func withNicotineWarning() -> some View {
        modifier(NicotineWarningBannerModifier())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        NicotineWarningBanner()
        ScrollView {
            VStack {
                Text("Shop Content")
                    .font(.largeTitle)
                    .padding(.top, 20)
            }
        }
    }
    .background(Color.backgroundPrimary)
}
