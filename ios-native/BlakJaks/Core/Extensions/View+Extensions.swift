import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Disables the interactive pop (swipe-back) gesture on the nearest
    /// UINavigationController. Apply to any view pushed inside a NavigationStack.
    func disableSwipeBack() -> some View {
        background(SwipeBackDisabler())
    }
}

// MARK: - Disable Swipe-Back Navigation

private struct SwipeBackDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> DisableSwipeBackView {
        DisableSwipeBackView()
    }
    func updateUIView(_ uiView: DisableSwipeBackView, context: Context) {}
}

private class DisableSwipeBackView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.disableInteractivePopGesture()
        }
    }

    private func disableInteractivePopGesture() {
        guard let vc = findViewController() else { return }
        var current: UIViewController? = vc
        while let candidate = current {
            if let nav = candidate as? UINavigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = false
                return
            }
            if let nav = candidate.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = false
                return
            }
            current = candidate.parent
        }
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}
