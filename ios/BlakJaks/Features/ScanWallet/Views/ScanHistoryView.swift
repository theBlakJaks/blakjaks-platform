import SwiftUI

// MARK: - ScanHistoryView
// List of recent QR scans: product name, USDC earned, relative timestamp.

struct ScanHistoryView: View {
    let scans: [Scan]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Scan History")
                .font(.system(.title2, design: .serif))
                .foregroundColor(.gold)
                .padding(.horizontal, Layout.screenMargin)

            if scans.isEmpty {
                EmptyStateView(
                    icon: "qrcode.viewfinder",
                    title: "No Scans Yet",
                    subtitle: "Scan your first BlakJaks product QR code to start earning USDC rewards."
                )
                .padding(.horizontal, Layout.screenMargin)
            } else {
                VStack(spacing: 0) {
                    ForEach(scans) { scan in
                        scanRow(scan)
                        if scan.id != scans.last?.id {
                            Divider().padding(.horizontal, Layout.screenMargin)
                        }
                    }
                }
                .background(Color.backgroundSecondary)
                .cornerRadius(Layout.cardCornerRadius)
                .padding(.horizontal, Layout.screenMargin)
            }
        }
    }

    private func scanRow(_ scan: Scan) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.success.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.circle.fill")
                    .font(.callout)
                    .foregroundColor(.success)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(scan.productName)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.primary)
                    TierBadge(tier: scan.tier)
                }
                HStack(spacing: Spacing.xs) {
                    Text(scan.createdAt.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(scan.tierMultiplier, specifier: "%.1f")x multiplier")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("+$\(scan.usdcEarned.formatted(.number.precision(.fractionLength(2)))) USDC")
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundColor(.success)
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.md)
    }
}
