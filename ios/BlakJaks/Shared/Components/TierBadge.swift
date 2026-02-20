import SwiftUI

// MARK: - TierBadge
// Displays member tier with appropriate color.
// Standard (gray) / VIP (blue) / High Roller (purple) / Whale (gold)

struct TierBadge: View {
    let tier: String

    var tierColor: Color {
        switch tier.lowercased() {
        case "vip":          return .tierVIP
        case "high_roller", "high roller": return .tierHighRoller
        case "whale":        return .tierWhale
        default:             return .tierStandard
        }
    }

    var tierLabel: String {
        switch tier.lowercased() {
        case "high_roller": return "High Roller"
        default: return tier.capitalized
        }
    }

    var body: some View {
        Text(tierLabel)
            .font(.caption.weight(.semibold))
            .foregroundColor(tier.lowercased() == "whale" ? .black : .white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(tierColor)
            .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        TierBadge(tier: "Standard")
        TierBadge(tier: "VIP")
        TierBadge(tier: "High Roller")
        TierBadge(tier: "Whale")
    }
    .padding()
    .background(Color.backgroundPrimary)
}
