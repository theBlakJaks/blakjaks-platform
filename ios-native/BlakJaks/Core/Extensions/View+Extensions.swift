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
