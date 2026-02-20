import SwiftUI

// MARK: - BlakJaks 8-Point Spacing Grid
// All spacing is a multiple of 8pt (with 4pt for fine adjustments).
// This creates visual rhythm and consistency across all screens.

enum Spacing {
    static let xs: CGFloat = 4      // Fine adjustment — icon padding, badge offset
    static let sm: CGFloat = 8      // Minimum spacing — between related elements
    static let md: CGFloat = 16     // Standard spacing — between components, horizontal margins
    static let lg: CGFloat = 24     // Generous spacing — between card sections
    static let xl: CGFloat = 32     // Section separation
    static let xxl: CGFloat = 48    // Major section separation
    static let tight: CGFloat = 12  // Tight spacing — label to value, row vertical padding
    static let comfortable: CGFloat = 20  // Comfortable spacing — premium feel, section padding
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
