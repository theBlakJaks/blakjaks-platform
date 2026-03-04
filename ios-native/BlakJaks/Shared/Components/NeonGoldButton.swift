import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// NeonGoldButton
//
// The standard BlakJaks call-to-action button style.
//
// Usage:
//   NeonGoldButton("LOGIN / SIGN UP") { showLogin = true }
//       .padding(.horizontal, 24)
//
// The button fills available width and defaults to 54 pt tall.
// Override height with a standard .frame modifier:
//   NeonGoldButton("CONFIRM") { … }
//       .frame(height: 44)
//
// Font size and letter-spacing can be customised if needed:
//   NeonGoldButton("OK", fontSize: 12, tracking: 2) { … }
// ─────────────────────────────────────────────────────────────────────────────

struct NeonGoldButton: View {

    var title:    String
    var action:   () -> Void

    init(_ title: String, fontSize: CGFloat = 14, tracking: CGFloat = 3, height: CGFloat = 54, action: @escaping () -> Void) {
        self.title    = title
        self.fontSize = fontSize
        self.tracking = tracking
        self.height   = height
        self.action   = action
    }
    var fontSize: CGFloat = 14
    var tracking: CGFloat = 3
    var height:   CGFloat = 54

    // Neon flicker state — private to each button instance
    @State private var neonGlow: Double = 1.0

    private let gold       = Color.goldAmber
    private let goldBright = Color(red: 230/255, green: 170/255, blue: 50/255)

    var body: some View {
        Button(action: action) {
            ZStack {
                // Black background pill
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.black)

                // Neon border tube
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(
                        LinearGradient(stops: [
                            .init(color: goldBright.opacity(neonGlow * 0.85), location: 0.0),
                            .init(color: gold.opacity(neonGlow * 0.70),       location: 0.5),
                            .init(color: goldBright.opacity(neonGlow * 0.85), location: 1.0),
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)

                // Label with layered neon glow
                Text(title)
                    .font(BJFont.sora(fontSize, weight: .bold))
                    .tracking(tracking)
                    .foregroundColor(gold.opacity(0.55 + 0.45 * neonGlow))
                    .shadow(color: gold.opacity(neonGlow * 0.45), radius:  3, x: 0, y: 0)
                    .shadow(color: gold.opacity(neonGlow * 0.28), radius:  8, x: 0, y: 0)
                    .shadow(color: gold.opacity(neonGlow * 0.13), radius: 18, x: 0, y: 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            // Outer neon glow bleeding past the button edge
            .shadow(color: gold.opacity(neonGlow * 0.55), radius:  8, x: 0, y: 0)
            .shadow(color: gold.opacity(neonGlow * 0.25), radius: 20, x: 0, y: 0)
        }
        // Flicker loop — cancels automatically when the button leaves the view tree
        .task {
            while !Task.isCancelled {
                // Random idle gap between 3 – 8 seconds
                let idle = UInt64.random(in: 3_000_000_000...8_000_000_000)
                try? await Task.sleep(nanoseconds: idle)
                guard !Task.isCancelled else { break }

                // Burst of 2 – 4 rapid pulses
                let pulses = Int.random(in: 2...4)
                for p in 0..<pulses {
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.04)) {
                            neonGlow = Double.random(in: 0.08...0.28)
                        }
                    }
                    try? await Task.sleep(nanoseconds: 40_000_000)          // 40 ms dark
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
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NeonGoldButton("LOGIN / SIGN UP") {}
            .padding(.horizontal, 32)
    }
}
