import SwiftUI

// MARK: - GoldButton
// Primary CTA button matching the mockup's .sc2-cta-btn style:
// gold gradient fill, dark text, pill shape, uppercase Sora label.

struct GoldButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.bgPrimary)
                } else {
                    Text(title.uppercased())
                        .font(BJFont.button)
                        .tracking(2.5)
                        .foregroundColor(Color.bgPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isDisabled
                    ? LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient.goldShimmer
            )
            .clipShape(Capsule())
            .shadow(color: Color.gold.opacity(isDisabled ? 0 : 0.25), radius: 12, y: 4)
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

// MARK: - GhostButton
// Secondary outline style — gold border, transparent fill.

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(BJFont.button)
                .tracking(2)
                .foregroundColor(Color.goldMid)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.clear)
                .overlay(
                    Capsule().stroke(Color.borderGold, lineWidth: 1)
                )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GoldButton(title: "Get Started", action: {})
        GoldButton(title: "Loading...", action: {}, isLoading: true)
        GhostButton(title: "Log In", action: {})
    }
    .padding()
    .background(Color.bgPrimary)
}
