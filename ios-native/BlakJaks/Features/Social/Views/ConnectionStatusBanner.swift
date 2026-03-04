import SwiftUI

// MARK: - ConnectionStatusBanner

/// Shows a banner ONLY when the session has fully expired (refresh token dead).
/// Normal 4001s (access token expired) are handled silently via auto-refresh.
/// This only appears when the 30-day refresh token has expired.

struct ConnectionStatusBanner: View {

    let connectionState: ChatConnectionState
    let onSignOut: () -> Void

    var body: some View {
        if connectionState == .sessionExpired {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                Text("Session expired — please sign in again")
                    .font(BJFont.sora(12, weight: .medium))
                    .foregroundColor(.red)
                Spacer()
                Button {
                    onSignOut()
                } label: {
                    Text("Sign In")
                        .font(BJFont.sora(11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.08))
        }
    }
}
