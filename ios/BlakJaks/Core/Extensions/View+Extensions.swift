import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
