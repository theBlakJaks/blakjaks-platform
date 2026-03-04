import SwiftUI

// MARK: - Typography
// Font stack matching app-mockup.html:
//   Playfair Display — serif display / headlines
//   Sora             — body text, labels, UI
//   Outfit           — numbers, prices, bold callouts
//   Pulpo            — BlakJaks wordmark only (commercial — add Pulpo.otf to Fonts/ folder)

enum BJFont {

    // MARK: - Playfair Display (display / headers)
    static func playfair(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("PlayfairDisplay-Regular", size: size).weight(weight)
    }

    // MARK: - Sora (body / UI)
    static func sora(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Sora-Regular", size: size).weight(weight)
    }

    // MARK: - Outfit (numbers / prices / bold callouts)
    static func outfit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Outfit-Regular", size: size).weight(weight)
    }

    // MARK: - Pulpo (BlakJaks logo wordmark — requires Pulpo.otf in bundle)
    static func pulpo(_ size: CGFloat) -> Font {
        .custom("Pulpo", size: size)
    }

    // MARK: - Semantic type scale

    /// Large serif display headline  ~32pt
    static let display     = playfair(32, weight: .bold)
    /// Section heading               ~22pt
    static let heading     = playfair(22, weight: .bold)
    /// Card / modal heading          ~18pt
    static let subheading  = playfair(18, weight: .semibold)

    /// Eyebrow label (Sora caps)     ~9pt 700
    static let eyebrow     = sora(9,  weight: .bold)
    /// Primary body                  ~14pt
    static let body        = sora(14, weight: .regular)
    /// Secondary / caption           ~11pt
    static let caption     = sora(11, weight: .regular)
    /// Small label                   ~9.5pt
    static let micro       = sora(9.5, weight: .semibold)

    /// Price / balance (Outfit)      ~24pt 800
    static let price       = outfit(24, weight: .heavy)
    /// Medium number callout         ~18pt 700
    static let stat        = outfit(18, weight: .bold)
    /// Small number label            ~14pt 600
    static let label       = outfit(14, weight: .semibold)

    /// CTA button text               ~13pt 700 Sora
    static let button      = sora(13, weight: .bold)
    /// Navigation tab label          ~10pt 600 Sora
    static let tab         = sora(10, weight: .semibold)
}

// MARK: - View modifier convenience

struct BJTextStyle: ViewModifier {
    let font: Font
    let color: Color
    let tracking: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .tracking(tracking)
    }
}

extension View {
    func bjStyle(_ font: Font, color: Color = .textPrimary, tracking: CGFloat = 0) -> some View {
        modifier(BJTextStyle(font: font, color: color, tracking: tracking))
    }
}
