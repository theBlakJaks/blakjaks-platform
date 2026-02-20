import SwiftUI

// MARK: - MemberCardView
// Premium full-width card: tier gradient, member ID, tier progress bar.

struct MemberCardView: View {
    let memberCard: MemberCard?

    var body: some View {
        Group {
            if let card = memberCard {
                cardContent(card: card)
            } else {
                cardPlaceholder
            }
        }
        .padding(.horizontal, Layout.screenMargin)
    }

    // MARK: - Card content

    private func cardContent(card: MemberCard) -> some View {
        ZStack(alignment: .topLeading) {
            // Gradient background
            LinearGradient(
                colors: cardGradientColors(tier: card.tier),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            // Subtle stripe pattern overlay
            GeometryReader { geo in
                Path { path in
                    var x: CGFloat = -geo.size.height
                    while x < geo.size.width + geo.size.height {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + geo.size.height, y: geo.size.height))
                        x += 32
                    }
                }
                .stroke(Color.white.opacity(0.04), lineWidth: 20)
            }
            .cornerRadius(20)

            // Card content
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header row
                HStack {
                    Text("BlakJaks")
                        .font(.brandLargeTitle.size(18))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    tierSuitIcon(tier: card.tier)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Name + tier
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.fullName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    HStack(spacing: Spacing.sm) {
                        Text(card.memberId)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        tierBadge(tier: card.tier)
                    }
                }

                // Tier progress bar (if not Whale)
                if let progress = tierProgressInfo(card: card) {
                    tierProgressBar(progress: progress)
                }

                // Balance
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("$\(card.walletBalance.formatted(.number.precision(.fractionLength(2))))")
                            .font(.system(.title3, design: .monospaced).weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Member Since")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(memberYear(from: card.joinDate))
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .frame(height: 220)
        .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)
    }

    // MARK: - Placeholder

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.backgroundSecondary)
            .frame(height: 220)
            .overlay(
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.secondary)
                    Text("Loading member card...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .shimmering()
    }

    // MARK: - Tier helpers

    private func cardGradientColors(tier: String) -> [Color] {
        switch tier.lowercased() {
        case "whale":        return [Color(red: 0.83, green: 0.69, blue: 0.22), Color(red: 0.60, green: 0.45, blue: 0.10)]
        case "high_roller", "high roller": return [Color(red: 0.45, green: 0.20, blue: 0.60), Color(red: 0.25, green: 0.10, blue: 0.40)]
        case "vip":          return [Color(red: 0.18, green: 0.35, blue: 0.65), Color(red: 0.10, green: 0.18, blue: 0.45)]
        default:             return [Color(red: 0.22, green: 0.22, blue: 0.25), Color(red: 0.12, green: 0.12, blue: 0.15)]
        }
    }

    private func tierSuitIcon(tier: String) -> Text {
        switch tier.lowercased() {
        case "whale":        return Text("♠")
        case "high_roller", "high roller": return Text("♥")
        case "vip":          return Text("♦")
        default:             return Text("♣")
        }
    }

    private func tierBadge(tier: String) -> some View {
        Text(tier.capitalized)
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.2)))
    }

    private func tierProgressInfo(card: MemberCard) -> (current: Int, next: Int, label: String)? {
        // Tier thresholds (scans per quarter)
        let tiers: [(name: String, min: Int, max: Int)] = [
            ("standard", 0, 4),
            ("vip", 5, 14),
            ("high_roller", 15, 29),
            ("whale", 30, Int.max)
        ]
        let tier = card.tier.lowercased().replacingOccurrences(of: " ", with: "_")
        guard tier != "whale",
              let current = tiers.first(where: { $0.name == tier }),
              let nextTier = tiers.first(where: { $0.min > current.min }) else { return nil }
        // Use walletBalance as proxy for scan count — real implementation uses TierProgress from scan result
        return (current: current.min, next: nextTier.min, label: "→ \(nextTier.name.replacingOccurrences(of: "_", with: " ").capitalized) at \(nextTier.min) scans/qtr")
    }

    private func tierProgressBar(progress: (current: Int, next: Int, label: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(
                            width: geo.size.width * CGFloat(min(Double(progress.current) / Double(progress.next), 1)),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
            Text(progress.label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func memberYear(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: dateString) else { return "" }
        return Calendar.current.component(.year, from: date).description
    }
}

// MARK: - Font size modifier

extension Font {
    func size(_ size: CGFloat) -> Font {
        // Can't change size of Font directly in SwiftUI without .custom
        // This is a no-op placeholder; views using brandLargeTitle use it as-is
        return self
    }
}

// MARK: - Preview

#Preview {
    VStack {
        MemberCardView(memberCard: MemberCard(
            memberId: "BJ-0001-VIP",
            fullName: "Alex Johnson",
            tier: "VIP",
            joinDate: "2024-01-15T10:00:00Z",
            avatarUrl: nil,
            walletBalance: 1250.75
        ))
    }
    .background(Color.backgroundPrimary)
    .padding()
}
