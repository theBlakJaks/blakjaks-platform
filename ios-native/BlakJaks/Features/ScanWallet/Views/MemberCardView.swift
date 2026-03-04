import SwiftUI

// MARK: - MemberCardView
// Renders a digital membership card styled like a luxury credit card.
// Reads user info from AuthState (EnvironmentObject) and fetches
// supplemental card data (wallet balance, masked card number etc.) via
// the getMemberCard() API.

struct MemberCardView: View {

    @EnvironmentObject private var authState: AuthState

    @State private var memberCard: MemberCard?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api: APIClientProtocol = APIClient.shared

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingState
            } else if let card = memberCard {
                cardFront(card: card)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                cardDetails(card: card)
            } else if let err = errorMessage {
                errorState(err)
            }
        }
        .padding(.horizontal, Spacing.md)
        .task { await loadCard() }
    }

    // MARK: - Card Front

    private func cardFront(card: MemberCard) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w / 1.6

            ZStack {
                // Base dark gradient
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 18/255, green: 16/255, blue: 12/255),
                                Color(red: 10/255, green: 10/255, blue: 8/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Gold shimmer overlay — subtle diagonal streak
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.goldMid.opacity(0.04),
                                Color.clear,
                                Color.goldMid.opacity(0.07),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Gold border
                RoundedRectangle(cornerRadius: Radius.xl)
                    .stroke(LinearGradient.goldShimmer, lineWidth: 0.8)

                // Watermark suit
                Text("♣")
                    .font(.system(size: h * 1.1, weight: .regular, design: .serif))
                    .foregroundColor(Color.gold.opacity(0.04))
                    .offset(x: w * 0.28, y: h * 0.05)

                VStack(alignment: .leading, spacing: 0) {
                    // Top row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BLAKJAKS")
                                .font(BJFont.sora(10, weight: .bold))
                                .tracking(4)
                                .foregroundColor(Color.gold)
                            Text("MEMBERS CLUB")
                                .font(BJFont.micro)
                                .tracking(2)
                                .foregroundColor(Color.textTertiary)
                        }
                        Spacer()
                        TierBadge(tier: card.tier)
                    }

                    Spacer()

                    // Member name (Playfair serif centre-piece)
                    Text(card.fullName.uppercased())
                        .font(BJFont.playfair(20, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .tracking(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // Masked card number
                    Text(maskedCardNumber(id: card.memberId))
                        .font(BJFont.outfit(14, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Color.textSecondary)
                        .padding(.top, 4)

                    Spacer()

                    // Bottom row
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MEMBER SINCE")
                                .font(BJFont.micro)
                                .tracking(2)
                                .foregroundColor(Color.textTertiary)
                            Text(formattedJoinDate(card.joinDate))
                                .font(BJFont.sora(11, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("BALANCE")
                                .font(BJFont.micro)
                                .tracking(2)
                                .foregroundColor(Color.textTertiary)
                            Text(card.walletBalance.usdFormatted)
                                .font(BJFont.outfit(15, weight: .bold))
                                .foregroundStyle(LinearGradient.goldShimmer)
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .frame(width: w, height: h)
            .shadow(color: Color.gold.opacity(0.15), radius: 24, y: 12)
        }
        .frame(height: UIScreen.main.bounds.width / 1.6)
    }

    // MARK: - Card Details (below card)

    private func cardDetails(card: MemberCard) -> some View {
        BlakJaksCard(padding: Spacing.md) {
            VStack(spacing: Spacing.sm) {
                detailRow(icon: "person.crop.circle",
                          label: "Member ID",
                          value: card.memberId.truncatedWalletAddress)

                Divider().background(Color.borderGold)

                detailRow(icon: "calendar",
                          label: "Join Date",
                          value: formattedJoinDate(card.joinDate))

                Divider().background(Color.borderGold)

                detailRow(icon: "shield.checkerboard",
                          label: "Tier",
                          value: card.tier.capitalized)
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.goldMid)
                .frame(width: 20)

            Text(label)
                .font(BJFont.caption)
                .foregroundColor(Color.textSecondary)

            Spacer()

            Text(value)
                .font(BJFont.sora(13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
    }

    // MARK: - Loading / Error

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(Color.bgCard)
                .frame(height: UIScreen.main.bounds.width / 1.6)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .overlay(
                    ProgressView().tint(Color.gold)
                )
            BlakJaksCard {
                Color.bgCard.frame(height: 80)
            }
            .redacted(reason: .placeholder)
        }
    }

    private func errorState(_ message: String) -> some View {
        BlakJaksCard {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(Color.error)
                Text(message)
                    .font(BJFont.caption)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                GhostButton(title: "Retry") {
                    Task { await loadCard() }
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Helpers

    private func loadCard() async {
        isLoading = true
        errorMessage = nil
        do {
            memberCard = try await api.getMemberCard()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func maskedCardNumber(id: String) -> String {
        // Extract last 4 chars of member ID, pad the rest as masked groups
        let last4 = String(id.suffix(4)).uppercased()
        return "••••  ••••  ••••  \(last4)"
    }

    private func formattedJoinDate(_ raw: String) -> String {
        let iso = ISO8601DateFormatter()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        if let d = iso.date(from: raw) { return fmt.string(from: d) }
        // Try plain date
        let plain = DateFormatter()
        plain.dateFormat = "yyyy-MM-dd"
        if let d = plain.date(from: raw) { return fmt.string(from: d) }
        return raw
    }
}

#Preview {
    ScrollView {
        MemberCardView()
            .environmentObject(AuthState())
    }
    .background(Color.bgPrimary)
}
