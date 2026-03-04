import SwiftUI

// MARK: - ConnectionStatusBanner

/// Displays connection state and quality warnings at the top of the chat.

struct ConnectionStatusBanner: View {

    let connectionState: ChatConnectionState
    let quality: ConnectionQuality

    var body: some View {
        Group {
            if connectionState == .reconnecting || connectionState == .connecting {
                banner(
                    icon: nil,
                    text: "Reconnecting...",
                    showSpinner: true,
                    fg: Color.gold,
                    bg: Color.gold.opacity(0.08)
                )
            } else if connectionState == .disconnected {
                banner(
                    icon: "wifi.slash",
                    text: "Disconnected",
                    showSpinner: false,
                    fg: Color.textTertiary,
                    bg: Color.bgCard
                )
            } else if connectionState == .sessionExpired {
                banner(
                    icon: "exclamationmark.triangle.fill",
                    text: "Session expired — please sign in again",
                    showSpinner: false,
                    fg: .red,
                    bg: Color.red.opacity(0.08)
                )
            } else if quality == .poor {
                banner(
                    icon: "wifi.exclamationmark",
                    text: "Poor connection",
                    showSpinner: false,
                    fg: Color.gold,
                    bg: Color.gold.opacity(0.06)
                )
            }
        }
    }

    // MARK: - Banner

    private func banner(icon: String?, text: String, showSpinner: Bool, fg: Color, bg: Color) -> some View {
        HStack(spacing: 6) {
            if showSpinner {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(fg)
            }
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(fg)
            }
            Text(text)
                .font(BJFont.sora(11, weight: .medium))
                .foregroundColor(fg)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(bg)
    }
}
