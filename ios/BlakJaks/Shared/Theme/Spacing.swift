import SwiftUI

// MARK: - BlakJaks Spacing Scale
// Screen edge margin: lg (20pt) | Section gap: xxl (32pt) | Card padding: base (16pt)

enum Spacing {
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let base: CGFloat = 16
    static let lg: CGFloat   = 20   // Standard screen margin
    static let xl: CGFloat   = 24
    static let xxl: CGFloat  = 32   // Section separation
    static let xxxl: CGFloat = 40   // Major section separation
}

// MARK: - Standard Layout Constants

enum Layout {
    static let screenMargin: CGFloat = 20       // Premium feel horizontal margin
    static let cardPadding: CGFloat = 20        // Card internal padding
    static let cardCornerRadius: CGFloat = 16   // Standard card radius
    static let buttonHeight: CGFloat = 50       // Primary CTA button height
    static let buttonCornerRadius: CGFloat = 16 // Button corner radius
    static let listRowVerticalPadding: CGFloat = 12
    static let gridGutter: CGFloat = 16
    static let sectionSpacing: CGFloat = 32
    static let tabBarCenterBubbleSize: CGFloat = 60  // Center Scan & Wallet tab bubble
}
