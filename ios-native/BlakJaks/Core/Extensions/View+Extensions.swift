import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Disables the interactive pop (swipe-back) gesture by attaching a
    /// high-priority no-op drag gesture that consumes horizontal swipes
    /// before SwiftUI's navigation gesture can claim them.
    func disableSwipeBack() -> some View {
        self.highPriorityGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { _ in }
                .onEnded { _ in }
        )
    }
}
