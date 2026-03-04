import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Disable Swipe-Back Navigation Globally

/// Swizzles UINavigationController.viewDidAppear to disable the interactive
/// pop gesture every time a navigation controller's view appears.
/// viewDidAppear is used instead of viewDidLoad because SwiftUI's
/// NavigationStack re-enables the gesture recognizer after viewDidLoad.
/// Called once from AppDelegate.didFinishLaunchingWithOptions.
enum SwipeBackDisabler {
    static func install() {
        let original = #selector(UINavigationController.viewDidAppear(_:))
        let swizzled = #selector(UINavigationController.bj_viewDidAppear(_:))
        guard let originalMethod = class_getInstanceMethod(UINavigationController.self, original),
              let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UINavigationController {
    @objc func bj_viewDidAppear(_ animated: Bool) {
        bj_viewDidAppear(animated) // calls original (implementations are swapped)
        interactivePopGestureRecognizer?.isEnabled = false
    }
}

// MARK: - Disable Swipe-Back Navigation Globally

/// Disables the interactive pop (swipe-back) gesture on every UINavigationController.
/// Uses a notification observer to catch each new nav controller as UIKit creates it.
/// No method swizzling — safe to call from AppDelegate.didFinishLaunching.
final class SwipeBackDisabler: NSObject, UIGestureRecognizerDelegate {
    static let shared = SwipeBackDisabler()

    private var observer: NSObjectProtocol?

    func activate() {
        // Observe every window scene to find navigation controllers
        observer = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.disableAllPopGestures()
        }

        // Also run immediately + on a short delay to catch the initial controllers
        DispatchQueue.main.async { [weak self] in
            self?.disableAllPopGestures()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.disableAllPopGestures()
        }

        // Periodic light check for any new nav controllers (e.g. pushed modals)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.disableAllPopGestures()
        }
    }

    private func disableAllPopGestures() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                disablePopGesture(in: window.rootViewController)
            }
        }
    }

    private func disablePopGesture(in vc: UIViewController?) {
        guard let vc else { return }
        if let nav = vc as? UINavigationController {
            nav.interactivePopGestureRecognizer?.isEnabled = false
            nav.interactivePopGestureRecognizer?.delegate = self
        }
        for child in vc.children {
            disablePopGesture(in: child)
        }
        if let presented = vc.presentedViewController {
            disablePopGesture(in: presented)
        }
    }

    // UIGestureRecognizerDelegate — always deny the gesture
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
