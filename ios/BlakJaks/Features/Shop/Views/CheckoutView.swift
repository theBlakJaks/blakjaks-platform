import SwiftUI

// MARK: - CheckoutView
// 4-step checkout stepper:
//   1. Shipping Address
//   2. Age Verification (AgeChecker.net WebView stub)
//   3. Payment (Braintree nonce stub)
//   4. Review & Place Order

struct CheckoutView: View {
    @ObservedObject var cartVM: CartViewModel
    @State private var showOrderConfirmation = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                stepperHeader
                    .padding(.top, UIScreen.main.bounds.height * 0.20)

                stepContent
            }
            NicotineWarningBanner()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Checkout")
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $showOrderConfirmation) {
            if let order = cartVM.completedOrder {
                OrderConfirmationView(order: order)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { cartVM.error != nil },
            set: { _ in cartVM.clearError() }
        )) {
            Button("OK", role: .cancel) { cartVM.clearError() }
        } message: {
            Text(cartVM.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Stepper header

    private var stepperHeader: some View {
        HStack(spacing: 0) {
            ForEach(CheckoutStep.allCases, id: \.rawValue) { step in
                let isActive = step == cartVM.checkoutStep
                let isDone = step.rawValue < cartVM.checkoutStep.rawValue

                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(isDone ? Color.gold : (isActive ? Color.gold.opacity(0.2) : Color.backgroundTertiary))
                            .frame(width: 28, height: 28)
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.black)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(isActive ? .gold : .secondary)
                        }
                    }
                    Text(step.title)
                        .font(isActive ? .caption2.weight(.bold) : .caption2)
                        .foregroundColor(isActive ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if step != CheckoutStep.allCases.last {
                    Rectangle()
                        .fill(isDone ? Color.gold : Color.backgroundTertiary)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Spacing.base)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.backgroundSecondary)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch cartVM.checkoutStep {
        case .shipping:
            ShippingStep(cartVM: cartVM)
        case .ageVerification:
            AgeVerificationStep(cartVM: cartVM)
        case .payment:
            PaymentStep(cartVM: cartVM)
        case .review:
            ReviewStep(cartVM: cartVM, showOrderConfirmation: $showOrderConfirmation)
        }
    }
}

// MARK: - Step 1: Shipping Address

private struct ShippingStep: View {
    @ObservedObject var cartVM: CartViewModel
    @FocusState private var focusedField: ShippingField?

    enum ShippingField: Hashable {
        case firstName, lastName, line1, line2, city, state, zip
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Shipping Address")
                    .font(.system(.headline, design: .serif))

                // Name row
                HStack(spacing: Spacing.sm) {
                    fieldInput("First Name", text: $cartVM.firstName, focus: .firstName)
                    fieldInput("Last Name", text: $cartVM.lastName, focus: .lastName)
                }

                fieldInput("Street Address", text: $cartVM.line1, focus: .line1)
                fieldInput("Apt, Suite, Unit (optional)", text: $cartVM.line2, focus: .line2)

                HStack(spacing: Spacing.sm) {
                    fieldInput("City", text: $cartVM.city, focus: .city)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    fieldInput("State", text: $cartVM.state, focus: .state)
                        .frame(width: 64)
                    fieldInput("ZIP", text: $cartVM.zip, focus: .zip)
                        .frame(width: 90)
                        .keyboardType(.numberPad)
                }

                GoldButton(
                    cartVM.isLoading ? "Calculating Tax..." : "Continue",
                    isLoading: cartVM.isLoading,
                    isDisabled: !cartVM.isShippingValid
                ) {
                    await cartVM.proceedFromShipping()
                }
            }
            .padding(Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.backgroundPrimary)
    }

    private func fieldInput(_ placeholder: String, text: Binding<String>, focus: ShippingField) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(placeholder)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .font(.body)
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.backgroundSecondary)
                .cornerRadius(Spacing.md)
                .focused($focusedField, equals: focus)
        }
    }
}

// MARK: - Step 2: Age Verification (AgeChecker.net stub)

private struct AgeVerificationStep: View {
    @ObservedObject var cartVM: CartViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.gold.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(.largeTitle, design: .default))
                        .foregroundColor(.gold)
                }

                Text("Age Verification Required")
                    .font(.system(.title3, design: .serif))
                    .fontWeight(.bold)

                Text("Federal law requires age verification before purchasing nicotine products. You must be 21 or older.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                // AgeChecker.net WebView — wired in production polish pass
                // Stub: tap to confirm you are 21+
                BlakJaksCard {
                    VStack(spacing: Spacing.sm) {
                        Text("AgeChecker.net")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("Age verification service will appear here in production.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Toggle(isOn: $cartVM.ageVerified) {
                            Text("I confirm I am 21 years of age or older")
                                .font(.footnote)
                        }
                        .toggleStyle(.switch)
                        .tint(.gold)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            Spacer()

            GoldButton("Continue", isDisabled: !cartVM.ageVerified) {
                cartVM.proceedFromAgeVerification()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Step 3: Payment (Braintree stub)

private struct PaymentStep: View {
    @ObservedObject var cartVM: CartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Payment")
                    .font(.system(.headline, design: .serif))

                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.gold)
                            Text("Secure Payment")
                                .font(.footnote.weight(.semibold))
                            Spacer()
                            Text("Braintree")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Divider()
                        // Braintree Drop-in UI wired in production polish pass.
                        // Stub: enter a test token.
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Payment Token (stub)")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                            TextField("Enter payment token...", text: $cartVM.paymentToken)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, Spacing.md)
                                .frame(height: 50)
                                .background(Color.backgroundTertiary)
                                .cornerRadius(Spacing.md)
                        }
                        Text("Braintree Drop-in UI replaces this field in production.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Order summary
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Order Summary")
                        .font(.system(.headline, design: .serif))
                    orderSummaryRow("Subtotal", cartVM.subtotal)
                    orderSummaryRow(cartVM.isFreeShipping ? "Shipping (FREE)" : "Shipping", cartVM.shippingCost, isFree: cartVM.isFreeShipping)
                    if let tax = cartVM.taxEstimate {
                        orderSummaryRow("Tax (\(tax.jurisdiction))", tax.taxAmount)
                    }
                    Divider()
                    orderSummaryRow("Total", cartVM.orderTotal, isBold: true)
                }

                GoldButton(
                    "Review Order",
                    isDisabled: cartVM.paymentToken.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    cartVM.proceedFromPayment()
                }
            }
            .padding(Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.backgroundPrimary)
    }

    private func orderSummaryRow(_ label: String, _ value: Double, isBold: Bool = false, isFree: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .footnote.weight(.bold) : .footnote)
                .foregroundColor(isBold ? .primary : .secondary)
            Spacer()
            if isFree {
                Text("FREE")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(.success)
            } else {
                Text("$\(value.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.footnote, design: .monospaced).weight(isBold ? .bold : .regular))
                    .foregroundColor(isBold ? .gold : .primary)
            }
        }
    }
}

// MARK: - Step 4: Review & Place Order

private struct ReviewStep: View {
    @ObservedObject var cartVM: CartViewModel
    @Binding var showOrderConfirmation: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Review Your Order")
                    .font(.system(.headline, design: .serif))

                // Shipping address summary
                BlakJaksCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        sectionHeader("Shipping Address", icon: "shippingbox")
                        Text("\(cartVM.firstName) \(cartVM.lastName)")
                            .font(.footnote.weight(.medium))
                        Text(cartVM.line1)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if !cartVM.line2.isEmpty {
                            Text(cartVM.line2)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Text("\(cartVM.city), \(cartVM.state) \(cartVM.zip)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                // Age verification
                BlakJaksCard {
                    HStack {
                        sectionHeader("Age Verified", icon: "checkmark.shield.fill")
                        Spacer()
                        Text("21+")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.success)
                    }
                }

                // Payment
                BlakJaksCard {
                    HStack {
                        sectionHeader("Payment", icon: "creditcard")
                        Spacer()
                        Text("•••• " + String(cartVM.paymentToken.suffix(4)))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                // Order items
                if let cart = cartVM.cart, !cart.items.isEmpty {
                    BlakJaksCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            sectionHeader("Items (\(cart.itemCount))", icon: "bag")
                            ForEach(cart.items) { item in
                                HStack {
                                    Text(item.productName)
                                        .font(.footnote)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("×\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(item.lineTotal.formatted(.number.precision(.fractionLength(2))))")
                                        .font(.system(.footnote, design: .monospaced))
                                }
                            }
                        }
                    }
                }

                // Totals
                GoldAccentCard {
                    VStack(spacing: Spacing.sm) {
                        totalRow("Subtotal", cartVM.subtotal)
                        totalRow(cartVM.isFreeShipping ? "Shipping (FREE)" : "Shipping",
                                 cartVM.shippingCost, isFree: cartVM.isFreeShipping)
                        if let tax = cartVM.taxEstimate {
                            totalRow("Tax (\(tax.jurisdiction))", tax.taxAmount)
                        }
                        Divider()
                        totalRow("ORDER TOTAL", cartVM.orderTotal, isBold: true)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Place order button
                GoldButton("Place Order", isLoading: cartVM.isPlacingOrder) {
                    let success = await cartVM.placeOrder()
                    if success { showOrderConfirmation = true }
                }
                .padding(.bottom, Spacing.xxl)
            }
            .padding(Spacing.lg)
        }
        .background(Color.backgroundPrimary)
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.gold)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private func totalRow(_ label: String, _ value: Double, isBold: Bool = false, isFree: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isBold ? .footnote.weight(.bold) : .footnote)
                .foregroundColor(isBold ? .primary : .secondary)
            Spacer()
            if isFree {
                Text("FREE")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundColor(.success)
            } else {
                Text("$\(value.formatted(.number.precision(.fractionLength(2))))")
                    .font(.system(.footnote, design: .monospaced).weight(isBold ? .bold : .regular))
                    .foregroundColor(isBold ? .gold : .primary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CheckoutView(cartVM: CartViewModel())
    }
}
