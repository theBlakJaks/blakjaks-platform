import SwiftUI
import WebKit

@main
struct BlakJaksMockupApp: App {
    var body: some Scene {
        WindowGroup {
            MockupWebView()
                .ignoresSafeArea()
        }
    }
}

struct MockupWebView: UIViewRepresentable {

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Ensure viewport-fit=cover is set for env(safe-area-inset-*) CSS vars.
        // The HTML already contains this in its viewport meta — this script is a
        // safety net in case anything overwrites it.
        let viewportScript = WKUserScript(
            source: """
            (function() {
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                    meta = document.createElement('meta');
                    meta.name = 'viewport';
                    document.head.appendChild(meta);
                }
                meta.content = 'width=device-width, initial-scale=1.0, viewport-fit=cover';
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(viewportScript)

        // CSS overrides injected after Babel/React renders.
        //
        // .iphone-frame  → fills full screen (100vw × 100dvh), no mock device
        //                   chrome (border-radius, box-shadow, border removed)
        //
        // .warning-banner → padding-top clears the Dynamic Island / notch.
        //                   max() keeps ≥18px on older devices without a notch.
        //
        // .bot-nav        → padding-bottom pushes nav icons above the home
        //                   indicator (≈34pt on Face ID iPhones).
        //
        // MutationObserver + setTimeout fallbacks ensure injection fires AFTER
        // Babel async-transpiles and React renders into the DOM.
        let layoutScript = WKUserScript(
            source: """
            (function() {
                var css = `
                    html, body {
                        margin: 0 !important;
                        padding: 0 !important;
                        display: block !important;
                        width: 100vw !important;
                        height: 100dvh !important;
                        overflow: hidden !important;
                        background: #0A0A0A !important;
                    }

                    .iphone-frame {
                        width: 100vw !important;
                        height: 100dvh !important;
                        position: fixed !important;
                        top: 0 !important;
                        left: 0 !important;
                        margin: 0 !important;
                        padding: 0 !important;
                        border-radius: 0 !important;
                        box-shadow: none !important;
                        border: none !important;
                        overflow: hidden !important;
                        background: #0A0A0A !important;
                    }

                    .warning-banner {
                        padding-top: max(env(safe-area-inset-top), 18px) !important;
                    }

                    .bot-nav {
                        padding-bottom: env(safe-area-inset-bottom) !important;
                    }
                `;

                function inject() {
                    if (!document.head) return false;
                    var existing = document.getElementById('bj-native-fix');
                    if (existing) existing.remove();
                    var style = document.createElement('style');
                    style.id = 'bj-native-fix';
                    style.textContent = css;
                    document.head.appendChild(style);
                    return true;
                }

                if (!inject()) {
                    var obs = new MutationObserver(function() {
                        if (inject()) obs.disconnect();
                    });
                    obs.observe(document.documentElement, { childList: true, subtree: true });
                }

                setTimeout(inject, 100);
                setTimeout(inject, 500);
                setTimeout(inject, 1500);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(layoutScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.backgroundColor = .black
        webView.isOpaque = true

        if let url = Bundle.main.url(forResource: "app-mockup", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
