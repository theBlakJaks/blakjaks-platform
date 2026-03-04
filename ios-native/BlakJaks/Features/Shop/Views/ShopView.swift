import SwiftUI

// MARK: - ShopView
// Single-product customization flow matching the #s-shop mockup:
// flavor grid (4x2) → strength buttons → qty stepper + price → Add to Cart
// Cart as .sheet, 4-step Checkout as fullScreenCover.

struct ShopView: View {

    // MARK: Selection state
    @State private var selectedFlavor: String? = nil
    @State private var selectedStrength: Int? = nil
    @State private var quantity: Int = 1

    // MARK: Sheet / overlay presentation
    @State private var showCart       = false
    @State private var showCheckout   = false
    @State private var showConfirm    = false

    // MARK: Local cart state (self-contained, no API dependency for this screen)
    @State private var cartItems: [LocalCartItem] = []

    // MARK: Checkout step (1-4)
    @State private var checkoutStep = 1

    // MARK: Order confirmation
    @State private var confirmedOrderNumber: String = ""

    private let unitPrice: Double = 4.99

    private var canAddToCart: Bool {
        selectedFlavor != nil && selectedStrength != nil
    }

    private var cartCount: Int { cartItems.reduce(0) { $0 + $1.quantity } }

    private var subtotal: Double {
        cartItems.reduce(0) { $0 + (Double($1.quantity) * unitPrice) }
    }

    private let shippingCost: Double = 2.99
    private let taxRate: Double = 0.08

    private var tax: Double { subtotal * taxRate }
    private var estimatedTotal: Double { subtotal + shippingCost + tax }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Nicotine warning banner pinned above scroll
                NicotineWarningBanner()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header row
                        headerRow
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.xs)
                            .padding(.bottom, Spacing.md)

                        // Flavor section
                        shopSectionLabel("Select Your Flavor")
                            .padding(.horizontal, Spacing.md)

                        flavorGrid
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xs)

                        // Strength section
                        shopSectionLabel("Select Strength")
                            .padding(.horizontal, Spacing.md)

                        strengthRow
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.md)

                        // Qty + Price row
                        qtyPriceRow
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.sm)

                        // Add to Cart button
                        addToCartButton
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.md)

                        // Feature tiles
                        shopFeatures
                            .padding(.horizontal, Spacing.md)

                        // Bottom padding for tab bar
                        Spacer(minLength: Spacing.xxxl)
                    }
                }
            }
        }
        // Cart sheet
        .sheet(isPresented: $showCart) {
            CartSheet(
                items: $cartItems,
                unitPrice: unitPrice,
                shippingCost: shippingCost,
                taxRate: taxRate,
                onCheckout: {
                    showCart = false
                    checkoutStep = 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCheckout = true
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        // Checkout full-screen cover
        .fullScreenCover(isPresented: $showCheckout) {
            CheckoutFlowView(
                step: $checkoutStep,
                items: cartItems,
                unitPrice: unitPrice,
                shippingCost: shippingCost,
                taxRate: taxRate,
                onConfirm: { orderNumber in
                    confirmedOrderNumber = orderNumber
                    showCheckout = false
                    cartItems = []
                    selectedFlavor = nil
                    selectedStrength = nil
                    quantity = 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showConfirm = true
                    }
                },
                onDismiss: {
                    showCheckout = false
                }
            )
        }
        // Order confirmation full-screen cover
        .fullScreenCover(isPresented: $showConfirm) {
            OrderConfirmedView(orderNumber: confirmedOrderNumber) {
                showConfirm = false
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                // Eyebrow: "BlakJaks" in Playfair, 9px, gold, letter-spacing 5, opacity 0.6
                Text("BlakJaks")
                    .font(BJFont.playfair(9))
                    .tracking(5)
                    .foregroundColor(Color.gold.opacity(0.6))

                // Title
                Text("Shop")
                    .font(BJFont.sora(20, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
            }

            Spacer()

            // Cart button
            Button {
                showCart = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Text("🛒")
                            .font(.system(size: 16))
                        if cartCount > 0 {
                            Text("\(cartCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.067)) // #111
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(white: 0.133), lineWidth: 1) // #222
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Badge
                    if cartCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.gold)
                                .frame(width: 16, height: 16)
                            Text("\(min(cartCount, 99))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
        }
    }

    // MARK: - Section Label

    private func shopSectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(BJFont.sora(11, weight: .regular))
            .tracking(2)
            .foregroundColor(Color(white: 0.533)) // #888
            .padding(.top, Spacing.md)
            .padding(.bottom, 10)
    }

    // MARK: - Flavor Grid (4 columns x 2 rows)

    private let flavors: [FlavorItem] = [
        FlavorItem(key: "spearmint",   emoji: "🌿", name: "Spearmint",   desc: "Cool & crisp"),
        FlavorItem(key: "wintergreen", emoji: "❄️", name: "Wintergreen", desc: "Bold & icy"),
        FlavorItem(key: "bubblegum",   emoji: "🫧", name: "Bubblegum",   desc: "Sweet & smooth"),
        FlavorItem(key: "bluerazz",    emoji: "💎", name: "Blue Razz",   desc: "Berry frost"),
        FlavorItem(key: "mintice",     emoji: "🧊", name: "Mint Ice",    desc: "Arctic chill"),
        FlavorItem(key: "citrus",      emoji: "🍊", name: "Citrus",      desc: "Bright & tangy"),
        FlavorItem(key: "cinnamon",    emoji: "🔥", name: "Cinnamon",    desc: "Warm & spicy"),
        FlavorItem(key: "coffee",      emoji: "☕", name: "Coffee",      desc: "Rich & bold"),
    ]

    private let flavorColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    private var flavorGrid: some View {
        LazyVGrid(columns: flavorColumns, spacing: 8) {
            ForEach(flavors) { flavor in
                FlavorCard(
                    flavor: flavor,
                    isSelected: selectedFlavor == flavor.key
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFlavor = flavor.key
                    }
                }
            }
        }
    }

    // MARK: - Strength Buttons

    private let strengths = [3, 6, 9, 12]

    private var strengthRow: some View {
        HStack(spacing: 8) {
            ForEach(strengths, id: \.self) { mg in
                StrengthButton(
                    label: "\(mg)mg",
                    isSelected: selectedStrength == mg
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedStrength = mg
                    }
                }
            }
        }
    }

    // MARK: - Qty + Price Row

    private var qtyPriceRow: some View {
        HStack(alignment: .center) {
            // Qty stepper
            HStack(spacing: 0) {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Text("−")
                        .font(.system(size: 18))
                        .foregroundColor(Color(white: 0.533)) // #888
                        .frame(width: 38, height: 38)
                }

                Text("\(quantity)")
                    .font(BJFont.sora(15, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .frame(minWidth: 32)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                Button {
                    quantity += 1
                } label: {
                    Text("+")
                        .font(.system(size: 18))
                        .foregroundColor(Color(white: 0.533))
                        .frame(width: 38, height: 38)
                }
            }
            .background(Color(white: 0.059)) // #0f0f0f
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.102), lineWidth: 1) // #1a1a1a
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Price — Playfair Display, 26px, bold, gold
            Text(String(format: "$%.2f", unitPrice * Double(quantity)))
                .font(BJFont.playfair(26, weight: .bold))
                .foregroundColor(Color.gold)
        }
        .padding(.bottom, 14)
    }

    // MARK: - Add to Cart Button

    private var addToCartButton: some View {
        Button {
            guard canAddToCart else { return }
            addItemToCart()
        } label: {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 212/255, green: 175/255, blue: 55/255),
                        Color(red: 201/255, green: 160/255, blue: 40/255)
                    ]),
                    startPoint: UnitPoint(x: 0.13, y: 0.13),
                    endPoint: UnitPoint(x: 1.0, y: 1.0)
                )

                Text("ADD TO CART")
                    .font(BJFont.sora(14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color(red: 10/255, green: 10/255, blue: 10/255))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .disabled(!canAddToCart)
        .opacity(canAddToCart ? 1.0 : 0.35)
        .animation(.easeInOut(duration: 0.15), value: canAddToCart)
    }

    // MARK: - Shop Features Grid (2 columns)

    private var shopFeatures: some View {
        let features: [(icon: String, label: String)] = [
            ("♠", "QR code inside"),
            ("🚚", "Free shipping $50+"),
            ("₮", "Earn USDC comps"),
            ("📦", "$2.99 flat rate"),
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                HStack(spacing: 8) {
                    Text(feature.icon)
                        .font(.system(size: 13))
                    Text(feature.label)
                        .font(BJFont.sora(11, weight: .regular))
                        .foregroundColor(Color(white: 0.4)) // #666
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(white: 0.059)) // #0f0f0f
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.067), lineWidth: 1) // #111
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Add Item Action

    private func addItemToCart() {
        guard let flavor = selectedFlavor, let strength = selectedStrength else { return }
        let flavorInfo = flavors.first(where: { $0.key == flavor })
        let itemName = "\(flavorInfo?.name ?? flavor) \(strength)mg"

        if let idx = cartItems.firstIndex(where: { $0.flavor == flavor && $0.strength == strength }) {
            cartItems[idx].quantity += quantity
        } else {
            cartItems.append(LocalCartItem(
                id: UUID(),
                flavor: flavor,
                flavorName: flavorInfo?.name ?? flavor,
                flavorEmoji: flavorInfo?.emoji ?? "🌿",
                strength: strength,
                name: itemName,
                quantity: quantity
            ))
        }

        // Reset quantity after adding
        quantity = 1
        showCart = true
    }
}

// MARK: - FlavorItem Model

private struct FlavorItem: Identifiable {
    let id = UUID()
    let key: String
    let emoji: String
    let name: String
    let desc: String
}

// MARK: - LocalCartItem Model

struct LocalCartItem: Identifiable {
    let id: UUID
    let flavor: String
    let flavorName: String
    let flavorEmoji: String
    let strength: Int
    let name: String
    var quantity: Int
}

// MARK: - FlavorCard

private struct FlavorCard: View {
    let flavor: FlavorItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    // Emoji
                    Text(flavor.emoji)
                        .font(.system(size: 22))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                        .padding(.top, 10)

                    // Name
                    Text(flavor.name)
                        .font(BJFont.sora(10, weight: .semibold))
                        .foregroundColor(Color(white: 0.8)) // #ccc
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 2)

                    // Description
                    Text(flavor.desc)
                        .font(BJFont.sora(9, weight: .regular))
                        .foregroundColor(Color(white: 0.333)) // #555
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? Color.gold.opacity(0.06)
                        : Color(white: 0.059) // #0f0f0f
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.gold.opacity(0.5) : Color(white: 0.102),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Check badge (top-right)
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.gold : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.gold : Color(white: 0.2), lineWidth: 1)
                        )
                        .frame(width: 14, height: 14)

                    if isSelected {
                        Text("✓")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(6)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - StrengthButton

private struct StrengthButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(BJFont.sora(12, weight: .semibold))
                .tracking(1)
                .foregroundColor(isSelected ? Color.gold : Color(white: 0.533)) // #888
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    isSelected
                        ? Color.gold.opacity(0.1)
                        : Color(white: 0.059) // #0f0f0f
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.gold.opacity(0.4) : Color(white: 0.133),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - CartSheet

private struct CartSheet: View {
    @Binding var items: [LocalCartItem]
    let unitPrice: Double
    let shippingCost: Double
    let taxRate: Double
    let onCheckout: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var subtotal: Double { items.reduce(0) { $0 + Double($1.quantity) * unitPrice } }
    private var tax: Double { subtotal * taxRate }
    private var total: Double { subtotal + shippingCost + tax }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                if items.isEmpty {
                    emptyCartView
                } else {
                    filledCartView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Cart")
                        .font(BJFont.playfair(18, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color(white: 0.12))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private var filledCartView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    // Items
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            CartItemRow(
                                item: item,
                                unitPrice: unitPrice,
                                onDecrement: {
                                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                        if items[idx].quantity > 1 {
                                            items[idx].quantity -= 1
                                        } else {
                                            items.remove(at: idx)
                                        }
                                    }
                                },
                                onIncrement: {
                                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                        items[idx].quantity += 1
                                    }
                                },
                                onRemove: {
                                    items.removeAll { $0.id == item.id }
                                }
                            )

                            if index < items.count - 1 {
                                Rectangle()
                                    .fill(Color.borderSubtle)
                                    .frame(height: 0.5)
                                    .padding(.horizontal, Spacing.md)
                            }
                        }
                    }
                    .background(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.borderGold, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    // Summary card
                    cartSummaryCard
                        .padding(.horizontal, Spacing.md)

                    Spacer(minLength: 100)
                }
            }

            // Checkout sticky bar
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.borderSubtle)
                    .frame(height: 0.5)

                Button(action: onCheckout) {
                    Text("CHECKOUT")
                        .font(BJFont.sora(14, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.goldShimmer)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.bgPrimary)
            }
        }
    }

    private var cartSummaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ORDER SUMMARY")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Rectangle().fill(Color.borderSubtle).frame(height: 0.5)
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                CartSummaryRow(label: "Subtotal", value: String(format: "$%.2f", subtotal))
                CartSummaryRow(label: "Shipping", value: String(format: "$%.2f", shippingCost))
                CartSummaryRow(label: "Tax (est.)", value: String(format: "$%.2f", tax))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Rectangle().fill(Color.borderSubtle).frame(height: 0.5)
                .padding(.horizontal, Spacing.md)

            HStack {
                Text("ESTIMATED TOTAL")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text(String(format: "$%.2f", total))
                    .font(BJFont.outfit(22, weight: .heavy))
                    .foregroundColor(Color.gold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderGold, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var emptyCartView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Text("🛒")
                .font(.system(size: 48))
            Text("Your cart is empty")
                .font(BJFont.playfair(20, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            Text("Select a flavor and strength to get started.")
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Button { dismiss() } label: {
                Text("BROWSE PRODUCTS")
                    .font(BJFont.sora(13, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color.goldMid)
                    .frame(maxWidth: 220)
                    .frame(height: 50)
                    .overlay(Capsule().stroke(Color.borderGold, lineWidth: 1))
            }
            Spacer()
        }
    }
}

// MARK: - CartItemRow (inside CartSheet)

private struct CartItemRow: View {
    let item: LocalCartItem
    let unitPrice: Double
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onRemove: () -> Void

    var lineTotal: Double { Double(item.quantity) * unitPrice }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Emoji thumb
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .stroke(Color.borderSubtle, lineWidth: 0.5)
                    )
                Text(item.flavorEmoji)
                    .font(.system(size: 24))
            }
            .frame(width: 60, height: 60)

            // Name + price
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.name)
                    .font(BJFont.playfair(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)

                Text(String(format: "$%.2f each", unitPrice))
                    .font(BJFont.sora(10, weight: .regular))
                    .foregroundColor(Color.textTertiary)

                Text(String(format: "$%.2f", lineTotal))
                    .font(BJFont.outfit(15, weight: .bold))
                    .foregroundColor(Color.gold)
            }

            Spacer()

            // Qty stepper + remove
            VStack(spacing: Spacing.xs) {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.textTertiary)
                        .frame(width: 22, height: 22)
                        .background(Color.bgInput)
                        .clipShape(Circle())
                }

                HStack(spacing: 0) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.goldMid)
                            .frame(width: 28, height: 28)
                    }
                    Text("\(item.quantity)")
                        .font(BJFont.outfit(13, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                        .frame(width: 28, height: 28)
                        .multilineTextAlignment(.center)
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.goldMid)
                            .frame(width: 28, height: 28)
                    }
                }
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .padding(Spacing.md)
    }
}

// MARK: - CartSummaryRow

private struct CartSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(BJFont.outfit(14, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
    }
}

// MARK: - CheckoutFlowView (4-step overlay)

private struct CheckoutFlowView: View {
    @Binding var step: Int
    let items: [LocalCartItem]
    let unitPrice: Double
    let shippingCost: Double
    let taxRate: Double
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    // Shipping fields
    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var address   = ""
    @State private var city      = ""
    @State private var state     = ""
    @State private var zip       = ""
    @State private var phone     = ""
    @State private var saveAddress = false

    // Payment
    @State private var useUSDC = false
    @State private var cardNumber = ""
    @State private var cardExpiry = ""
    @State private var cardCVV    = ""

    @FocusState private var focused: CheckoutField?

    enum CheckoutField: Hashable {
        case firstName, lastName, address, city, state, zip, phone
        case cardNumber, cardExpiry, cardCVV
    }

    private var subtotal: Double { items.reduce(0) { $0 + Double($1.quantity) * unitPrice } }
    private var tax: Double { subtotal * taxRate }
    private var total: Double { subtotal + shippingCost + tax }

    private var canContinue: Bool {
        switch step {
        case 1:
            return !firstName.isEmpty && !lastName.isEmpty &&
                   !address.isEmpty  && !city.isEmpty     &&
                   !state.isEmpty    && !zip.isEmpty
        case 2:
            return true // Age verification placeholder — always allow continue
        case 3:
            return useUSDC || (!cardNumber.isEmpty && !cardExpiry.isEmpty && !cardCVV.isEmpty)
        case 4:
            return true
        default:
            return true
        }
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                checkoutNavBar

                // Step dots
                stepDots
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.md)

                // Step content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        stepContent
                        Spacer(minLength: Spacing.xxxl)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
                }

                // Continue / Place Order button
                continueBar
            }
        }
        .onTapGesture { focused = nil }
    }

    // MARK: Nav bar

    private var checkoutNavBar: some View {
        HStack {
            Button(action: {
                if step > 1 { step -= 1 } else { onDismiss() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(step > 1 ? "Back" : "Cancel")
                        .font(BJFont.sora(14, weight: .medium))
                }
                .foregroundColor(Color.goldMid)
            }

            Spacer()

            Text("CHECKOUT")
                .font(BJFont.playfair(18, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Spacer()

            // Invisible balance button
            Text("Cancel")
                .font(BJFont.sora(14, weight: .medium))
                .foregroundColor(Color.clear)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    // MARK: Step dots

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { s in
                Circle()
                    .fill(s <= step ? Color.gold : Color(white: 0.2))
                    .frame(width: s == step ? 10 : 6, height: s == step ? 10 : 6)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
    }

    // MARK: Step content routing

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: shippingStep
        case 2: ageVerificationStep
        case 3: paymentStep
        case 4: reviewStep
        default: EmptyView()
        }
    }

    // MARK: Step 1: Shipping

    private var shippingStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            checkoutSectionHeader(icon: "location", title: "SHIPPING ADDRESS")

            HStack(spacing: Spacing.sm) {
                checkoutField("First Name", text: $firstName, field: .firstName)
                checkoutField("Last Name",  text: $lastName,  field: .lastName)
            }

            checkoutField("Address", text: $address, field: .address)

            HStack(spacing: Spacing.sm) {
                checkoutField("City",  text: $city,  field: .city)
                checkoutField("State", text: $state, field: .state)
            }

            HStack(spacing: Spacing.sm) {
                checkoutField("ZIP Code", text: $zip,   field: .zip)
                    .keyboardType(.numberPad)
                checkoutField("Phone",    text: $phone, field: .phone)
                    .keyboardType(.phonePad)
            }

            // Save address toggle
            HStack(spacing: Spacing.sm) {
                Button {
                    saveAddress.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(saveAddress ? Color.gold : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(saveAddress ? Color.gold : Color(white: 0.3), lineWidth: 1)
                            )
                            .frame(width: 18, height: 18)
                        if saveAddress {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                Text("Save this address for future orders")
                    .font(BJFont.sora(12, weight: .regular))
                    .foregroundColor(Color.textSecondary)
            }
        }
    }

    // MARK: Step 2: Age Verification

    private var ageVerificationStep: some View {
        VStack(spacing: Spacing.xl) {
            checkoutSectionHeader(icon: "person.badge.shield.checkmark", title: "AGE VERIFICATION")

            // Info card
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.gold.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Text("21+")
                        .font(BJFont.outfit(24, weight: .heavy))
                        .foregroundColor(Color.gold)
                }

                Text("Age Verification Required")
                    .font(BJFont.playfair(20, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("You must be 21 or older to purchase nicotine products. We use AgeChecker to verify your age instantly.")
                    .font(BJFont.sora(13, weight: .regular))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // AgeChecker placeholder card
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 20))
                            .foregroundColor(Color.goldMid)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AgeChecker Integration")
                                .font(BJFont.sora(13, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            Text("Secure, instant age verification powered by AgeChecker.Net")
                                .font(BJFont.sora(11, weight: .regular))
                                .foregroundColor(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.gold.opacity(0.25), lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                // "Verify Age" button (placeholder — tapping advances step in demo)
                Button {
                    // In production: launch AgeChecker SDK
                    // For demo, just advance
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield")
                        Text("VERIFY AGE")
                            .font(BJFont.sora(13, weight: .bold))
                            .tracking(2)
                    }
                    .foregroundColor(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LinearGradient.goldShimmer)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: Step 3: Payment

    private var paymentStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            checkoutSectionHeader(icon: "creditcard", title: "PAYMENT")

            // Credit Card radio
            paymentOption(
                label: "Credit / Debit Card",
                icon: "💳",
                isSelected: !useUSDC
            ) {
                useUSDC = false
            }

            // USDC radio
            paymentOption(
                label: "USDC Wallet",
                icon: "₮",
                isSelected: useUSDC
            ) {
                useUSDC = true
            }

            if !useUSDC {
                // Card fields
                VStack(spacing: Spacing.sm) {
                    checkoutField("Card Number", text: $cardNumber, field: .cardNumber)
                        .keyboardType(.numberPad)
                    HStack(spacing: Spacing.sm) {
                        checkoutField("MM/YY", text: $cardExpiry, field: .cardExpiry)
                            .keyboardType(.numberPad)
                        checkoutField("CVV", text: $cardCVV, field: .cardCVV)
                            .keyboardType(.numberPad)
                    }
                }
                .padding(Spacing.md)
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            } else {
                // USDC placeholder
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "wallet.pass")
                        .foregroundColor(Color.goldMid)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected Wallet")
                            .font(BJFont.sora(13, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        Text("0x1A2B...3C4D")
                            .font(BJFont.outfit(12, weight: .regular))
                            .foregroundColor(Color.textTertiary)
                    }
                    Spacer()
                    Text("USDC")
                        .font(BJFont.sora(11, weight: .semibold))
                        .foregroundColor(Color.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gold.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(Spacing.md)
                .background(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.borderGold, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    // MARK: Step 4: Order Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            checkoutSectionHeader(icon: "list.bullet.rectangle", title: "ORDER REVIEW")

            // Items
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Spacing.sm) {
                        Text(item.flavorEmoji)
                            .font(.system(size: 18))
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(BJFont.sora(13, weight: .regular))
                                .foregroundColor(Color.textSecondary)
                            Text("×\(item.quantity)")
                                .font(BJFont.outfit(12, weight: .bold))
                                .foregroundColor(Color.textTertiary)
                        }
                        Spacer()
                        Text(String(format: "$%.2f", Double(item.quantity) * unitPrice))
                            .font(BJFont.outfit(13, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                    if index < items.count - 1 {
                        Rectangle().fill(Color.borderSubtle).frame(height: 0.5)
                            .padding(.horizontal, Spacing.md)
                    }
                }

                Rectangle().fill(Color.borderSubtle).frame(height: 0.5)
                    .padding(.top, Spacing.xs)

                VStack(spacing: Spacing.sm) {
                    reviewSummaryRow("Subtotal",   String(format: "$%.2f", subtotal))
                    reviewSummaryRow("Shipping",   String(format: "$%.2f", shippingCost))
                    reviewSummaryRow("Tax (est.)", String(format: "$%.2f", tax))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                Rectangle().fill(Color.borderSubtle).frame(height: 0.5)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)

                HStack {
                    Text("TOTAL")
                        .font(BJFont.sora(14, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    Text(String(format: "$%.2f", total))
                        .font(BJFont.outfit(22, weight: .heavy))
                        .foregroundColor(Color.gold)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.borderGold, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

            // Shipping address summary
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(Color.goldMid)
                    Text("SHIPPING TO")
                        .font(BJFont.eyebrow)
                        .tracking(3)
                        .foregroundColor(Color.goldMid)
                }
                Text("\(firstName) \(lastName)")
                    .font(BJFont.sora(13, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("\(address), \(city), \(state) \(zip)")
                    .font(BJFont.sora(12, weight: .regular))
                    .foregroundColor(Color.textSecondary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    private func reviewSummaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(BJFont.outfit(14, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
    }

    // MARK: Continue bar

    private var continueBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.borderSubtle).frame(height: 0.5)

            Button {
                if step < 4 {
                    withAnimation { step += 1 }
                } else {
                    // Generate mock order number and confirm
                    let orderNum = "BJ-\(Int.random(in: 10000...99999))-X"
                    onConfirm(orderNum)
                }
            } label: {
                Text(step == 4 ? "PLACE ORDER" : "CONTINUE")
                    .font(BJFont.sora(14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(canContinue ? Color.bgPrimary : Color.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        canContinue
                            ? LinearGradient.goldShimmer
                            : LinearGradient(colors: [Color(white: 0.18)], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canContinue)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(Color.bgPrimary)
        }
    }

    // MARK: Helpers

    private func checkoutSectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.goldMid)
            Text(title)
                .font(BJFont.eyebrow)
                .tracking(3)
                .foregroundColor(Color.goldMid)
        }
    }

    private func checkoutField(
        _ placeholder: String,
        text: Binding<String>,
        field: CheckoutField
    ) -> some View {
        TextField(placeholder, text: text)
            .font(BJFont.sora(14))
            .foregroundColor(Color.textPrimary)
            .tint(Color.gold)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .focused($focused, equals: field)
            .padding(.horizontal, Spacing.md)
            .frame(height: 52)
            .background(Color.bgInput)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.borderGold, lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private func paymentOption(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.gold : Color.clear)
                        .overlay(
                            Circle().stroke(isSelected ? Color.gold : Color(white: 0.3), lineWidth: 1.5)
                        )
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle().fill(Color.bgPrimary).frame(width: 8, height: 8)
                    }
                }

                Text(icon)
                    .font(.system(size: 18))

                Text(label)
                    .font(BJFont.sora(14, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                Spacer()
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.gold.opacity(0.06) : Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(isSelected ? Color.gold.opacity(0.4) : Color.borderGold, lineWidth: isSelected ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - OrderConfirmedView

private struct OrderConfirmedView: View {
    let orderNumber: String
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: Spacing.xxxl)

                    // Animated checkmark
                    ZStack {
                        Circle()
                            .fill(Color.gold.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(appeared ? 1.0 : 0.5)
                            .opacity(appeared ? 1.0 : 0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.15), value: appeared)

                        Circle()
                            .fill(LinearGradient.goldShimmer)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.gold.opacity(0.4), radius: 20, y: 6)
                            .scaleEffect(appeared ? 1.0 : 0.3)
                            .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.05), value: appeared)

                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color.bgPrimary)
                            .scaleEffect(appeared ? 1.0 : 0.1)
                            .opacity(appeared ? 1.0 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3), value: appeared)
                    }
                    .padding(.bottom, Spacing.xl)

                    // Heading
                    VStack(spacing: Spacing.xs) {
                        Text("Order Placed!")
                            .font(BJFont.playfair(28, weight: .bold))
                            .foregroundColor(Color.textPrimary)

                        Text("Your order has been confirmed and is being prepared.")
                            .font(BJFont.sora(13, weight: .regular))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.bottom, Spacing.xl)

                    // Order details card
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ORDER NUMBER")
                                    .font(BJFont.eyebrow)
                                    .tracking(2.5)
                                    .foregroundColor(Color.textTertiary)
                                Text(orderNumber)
                                    .font(BJFont.outfit(20, weight: .heavy))
                                    .foregroundColor(Color.gold)
                            }
                            Spacer()
                        }
                        .padding(Spacing.md)

                        Rectangle().fill(Color.borderSubtle).frame(height: 0.5)

                        VStack(spacing: Spacing.sm) {
                            confirmRow("Items",    "Nicotine Pouches")
                            confirmRow("Delivery", "5–7 business days")
                            confirmRow("Tracking", "Assigned after shipment")
                        }
                        .padding(Spacing.md)
                    }
                    .background(Color.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.borderGold, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)

                    // Done / Continue Shopping
                    Button(action: onDone) {
                        Text("CONTINUE SHOPPING")
                            .font(BJFont.sora(13, weight: .bold))
                            .tracking(2.5)
                            .foregroundColor(Color.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.goldShimmer)
                            .clipShape(Capsule())
                            .shadow(color: Color.gold.opacity(0.25), radius: 12, y: 4)
                    }
                    .padding(.horizontal, Spacing.xl)

                    Spacer(minLength: Spacing.xxxl)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }

    private func confirmRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(BJFont.outfit(13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    ShopView()
}
