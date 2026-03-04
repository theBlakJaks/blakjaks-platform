import SwiftUI

// MARK: - NicotineWarningBanner
// Mimics the .warning-banner from the HTML mockup.
// Shown at the top of screens that need it (Welcome, Login, Signup, Shop).

struct NicotineWarningBanner: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10, weight: .bold))
            Text("WARNING: This product contains nicotine. Nicotine is an addictive chemical.")
                .font(BJFont.micro)
                .tracking(0.3)
        }
        .foregroundColor(Color.bgPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.goldMid)
    }
}
