import SwiftUI

// MARK: - BlakJaks Typography System
// SF Pro (default):   All UI text, navigation, buttons, body content
// New York (serif):   Brand headlines, premium display, tier names
// SF Mono:            Wallet addresses, transaction hashes, USDT amounts

extension Font {

    // MARK: - Brand / Display (New York serif)
    static let brandLargeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let brandTitle = Font.system(.title, design: .serif).weight(.semibold)
    static let brandTitle2 = Font.system(.title2, design: .serif).weight(.semibold)

    // MARK: - Crypto / Monospaced (SF Mono)
    static let monoBody = Font.system(.body, design: .monospaced)
    static let monoCallout = Font.system(.callout, design: .monospaced)
    static let monoFootnote = Font.system(.footnote, design: .monospaced)
    static let monoTitle = Font.system(.title, design: .monospaced).weight(.semibold)
    static let monoTitle2 = Font.system(.title2, design: .monospaced).weight(.semibold)

    // MARK: - USDT / Balance amounts (large monospaced)
    static let walletBalance = Font.system(size: 44, weight: .semibold, design: .monospaced)
    static let walletBalanceSmall = Font.system(size: 28, weight: .medium, design: .monospaced)
}

// MARK: - View modifier for consistent text styles

struct WalletAmountStyle: ViewModifier {
    let isCredit: Bool?

    func body(content: Content) -> some View {
        content
            .font(.monoTitle2)
            .foregroundColor(isCredit == nil ? .primary :
                            isCredit == true ? .creditAmount : .debitAmount)
    }
}

extension View {
    func walletAmountStyle(isCredit: Bool? = nil) -> some View {
        modifier(WalletAmountStyle(isCredit: isCredit))
    }

    func brandHeadlineStyle() -> some View {
        self.font(.brandTitle2).foregroundColor(.primary)
    }

    func cryptoAddressStyle() -> some View {
        self.font(.monoFootnote).foregroundColor(.secondary)
    }
}
