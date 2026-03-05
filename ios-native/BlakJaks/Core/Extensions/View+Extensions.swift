import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Disables the interactive pop (swipe-back) gesture on the nearest
    /// UINavigationController. Apply to any view pushed inside a NavigationStack.
    func disableSwipeBack() -> some View {
        background(SwipeBackDisablerView())
    }
}

// MARK: - Disable Swipe-Back Navigation

/// UIViewRepresentable that walks the responder chain from the UIView level
/// to find the UINavigationController and hijack its pop gesture recognizer.
/// Sets itself as the gesture's delegate so `gestureRecognizerShouldBegin`
/// always returns false — SwiftUI cannot re-enable it.
private struct SwipeBackDisablerView: UIViewRepresentable {
    func makeUIView(context: Context) -> SwipeBackDisablerUIView {
        SwipeBackDisablerUIView()
    }
    func updateUIView(_ uiView: SwipeBackDisablerUIView, context: Context) {}
}

private class SwipeBackDisablerUIView: UIView, UIGestureRecognizerDelegate {

    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { self.hijackGesture() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hijackGesture()
    }

    private func hijackGesture() {
        guard let nav = findNavigationController() else { return }
        guard let gesture = nav.interactivePopGestureRecognizer else { return }
        gesture.isEnabled = false
        gesture.delegate = self
    }

    /// Always block the pop gesture from starting.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    /// Walk the responder chain to find the nearest UINavigationController.
    private func findNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let nav = next as? UINavigationController {
                return nav
            }
            responder = next
        }
        return nil
    }
}
