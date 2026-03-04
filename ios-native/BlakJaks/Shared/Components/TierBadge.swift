import SwiftUI

// MARK: - TierBadge
// Pill badge showing membership tier. Matches the mockup's tier indicator style.

struct TierBadge: View {
    let tier: String

    var body: some View {
        Text(tier.uppercased())
            .font(BJFont.micro)
            .tracking(1.5)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch tier.lowercased() {
        case "whale":       return .gold
        case "highroller", "high roller": return .tierHighRoller
        case "vip":         return .tierVIP
        default:            return .tierStandard
        }
    }
}
