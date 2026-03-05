import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Disables the interactive pop (swipe-back) gesture by placing a
    /// competing UIScreenEdgePanGestureRecognizer on the left edge that
    /// eats the touch before SwiftUI's navigation gesture can claim it.
    func disableSwipeBack() -> some View {
        background(SwipeBackDisabler())
    }
}

// MARK: - Disable Swipe-Back Navigation

private struct SwipeBackDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> EdgePanBlockerView {
        EdgePanBlockerView()
    }
    func updateUIView(_ uiView: EdgePanBlockerView, context: Context) {}
}

private class EdgePanBlockerView: UIView {

    private var blocker: UIScreenEdgePanGestureRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard blocker == nil, window != nil else { return }

        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgePanned))
        edge.edges = .left
        // Attach to the window so it sits above everything
        window?.addGestureRecognizer(edge)
        blocker = edge
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        // Clean up when removed
        if newWindow == nil, let b = blocker {
            b.view?.removeGestureRecognizer(b)
            blocker = nil
        }
    }

    @objc private func edgePanned(_ gesture: UIScreenEdgePanGestureRecognizer) {
        // No-op — just eat the gesture
    }
}
