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

/// Invisible UIViewControllerRepresentable that walks up the responder chain
/// to find the hosting UINavigationController and disables its pop gesture.
/// Re-checks on every viewDidAppear so SwiftUI can't re-enable it.
private struct SwipeBackDisablerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeBackDisablerVC {
        SwipeBackDisablerVC()
    }
    func updateUIViewController(_ uiViewController: SwipeBackDisablerVC, context: Context) {}
}

private class SwipeBackDisablerVC: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disablePopGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        disablePopGesture()
    }

    private func disablePopGesture() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}
