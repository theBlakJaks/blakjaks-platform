import SwiftUI

// MARK: - LogoAnimationView
// Native SwiftUI replica of the logo_animation.html orbit effect.
// Uses the exact orbitTransform() math from the original JavaScript:
//
//   s1 = t * 0.001521
//   s2 = s1 * 0.37
//   ry = sin(s1)*15 + sin(s2+1.3)*5          → Y-axis rotation (degrees)
//   rx = sin(s1*0.7+0.9)*14 + sin(s2*1.1+0.8)*6  → X-axis rotation
//   rz = cos(s1)*3 + cos(s2*0.9)*1.5         → Z-axis rotation
//   y  = sin(t*0.0004)*6 + sin(t*0.00017+2.1)*3  → vertical float (pts)
//
// where t = milliseconds elapsed since the view first appeared.
//
// Replaces the previous WKWebView implementation. WKWebView blocked the main
// thread for ~9 s on first install (WebKit content process spawn + IPC setup).
// TimelineView drives 60 fps with zero initialisation delay.

struct LogoAnimationView: View {
    var width: CGFloat = 280

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let t  = context.date.timeIntervalSince(startDate) * 1000  // ms
            let s1 = t * 0.001521
            let s2 = s1 * 0.37
            let ry = sin(s1) * 15        + sin(s2 + 1.3) * 5
            let rx = sin(s1 * 0.7 + 0.9) * 14 + sin(s2 * 1.1 + 0.8) * 6
            let rz = cos(s1) * 3         + cos(s2 * 0.9) * 1.5
            let ty = sin(t * 0.0004) * 6 + sin(t * 0.00017 + 2.1) * 3

            Image("blakjaks-logo")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                // Apply rotations in the same order as the CSS transform string:
                // rotateY → rotateX → rotateZ, then translateY.
                // perspective: 0.35 ≈ CSS perspective:900px on a 280pt element.
                .rotation3DEffect(.degrees(ry),
                                  axis: (x: 0, y: 1, z: 0),
                                  perspective: 0.35)
                .rotation3DEffect(.degrees(rx),
                                  axis: (x: 1, y: 0, z: 0),
                                  perspective: 0)
                .rotation3DEffect(.degrees(rz),
                                  axis: (x: 0, y: 0, z: 1),
                                  perspective: 0)
                .offset(y: ty)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LogoAnimationView(width: 280)
            .frame(width: 320, height: 180)
    }
}
