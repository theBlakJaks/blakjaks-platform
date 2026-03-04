import SwiftUI

// MARK: - BlakJaks Color System
// Design tokens matching the app-mockup.html CSS variables.
// #D4AF37 / #C9A84C is the gold used throughout. Background is near-black #0A0A0A.

extension Color {

    // MARK: - Brand
    static let gold      = Color(red: 212/255, green: 175/255, blue: 55/255)   // #D4AF37
    static let goldMid   = Color(red: 201/255, green: 168/255, blue: 76/255)   // #C9A84C
    static let goldDim   = Color(red: 201/255, green: 168/255, blue: 76/255).opacity(0.65)
    static let goldAmber = Color(red: 204/255, green: 143/255, blue: 23/255)   // #CC8F17 — logo amber gold

    // MARK: - Backgrounds (always dark)
    static let bgPrimary   = Color(red: 10/255, green: 10/255, blue: 10/255)     // #0A0A0A
    static let bgSecondary = Color(red: 16/255, green: 14/255, blue: 10/255)     // #100E0A
    static let bgCard      = Color(white: 1, opacity: 0.04)
    static let bgInput     = Color(white: 1, opacity: 0.04)

    // MARK: - Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(white: 1, opacity: 0.65)
    static let textTertiary  = Color(white: 1, opacity: 0.38)
    static let textGold      = Color.goldMid

    // MARK: - Borders
    static let borderGold   = Color.goldMid.opacity(0.22)
    static let borderSubtle = Color(white: 1, opacity: 0.09)

    // MARK: - Semantic
    static let success = Color(UIColor.systemGreen)
    static let error   = Color(UIColor.systemRed)
    static let warning = Color(UIColor.systemOrange)
    static let info    = Color(UIColor.systemBlue)

    // MARK: - Tier
    static let tierStandard   = Color(UIColor.systemGray)
    static let tierVIP        = Color(UIColor.systemBlue)
    static let tierHighRoller = Color.purple
    static let tierWhale      = Color.gold

    // MARK: - Transaction
    static let creditAmount  = Color(UIColor.systemGreen)
    static let debitAmount   = Color(UIColor.systemRed)
    static let pendingAmount = Color(UIColor.systemOrange)
}

// MARK: - Gradient helpers

extension LinearGradient {
    static let goldShimmer = LinearGradient(
        colors: [Color.goldMid, Color.gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let darkBackground = LinearGradient(
        colors: [Color.bgPrimary, Color.bgSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
}
