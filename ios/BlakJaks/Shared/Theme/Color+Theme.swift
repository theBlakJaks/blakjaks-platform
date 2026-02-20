import SwiftUI

// MARK: - BlakJaks Color System
// Use 5–10% of screen real estate maximum for gold — rarity creates luxury.
// All system colors adapt automatically to dark/light mode.

extension Color {

    // MARK: - Brand Colors
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255)      // #D4AF37 — primary brand gold
    static let goldDark = Color(red: 201/255, green: 169/255, blue: 97/255)  // #C9A961 — desaturated for dark mode

    // MARK: - Tier Colors
    static let tierStandard = Color(UIColor.systemGray)
    static let tierVIP = Color(UIColor.systemBlue)
    static let tierHighRoller = Color.purple
    static let tierWhale = gold

    // MARK: - Backgrounds (system — auto dark/light)
    static let backgroundPrimary = Color(UIColor.systemBackground)            // #000000 dark / #FFFFFF light
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground) // #1C1C1E dark
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)   // #2C2C2E dark

    // MARK: - Semantic
    static let success = Color(UIColor.systemGreen)   // #32D74B dark
    static let failure = Color(UIColor.systemRed)     // #FF453A dark
    static let warning = Color(UIColor.systemOrange)  // #FF9F0A dark
    static let info = Color(UIColor.systemBlue)       // #0A84FF dark

    // MARK: - Transaction
    static let creditAmount = Color(UIColor.systemGreen)
    static let debitAmount = Color(UIColor.systemRed)
    static let pendingAmount = Color(UIColor.systemOrange)
}

// MARK: - Shorthand convenience (use in views as `BrandGold`)
extension Color {
    static let brandGold = Color.gold
}
