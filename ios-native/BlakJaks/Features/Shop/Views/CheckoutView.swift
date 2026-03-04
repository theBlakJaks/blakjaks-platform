import SwiftUI

// MARK: - CheckoutView
// Shipping address form with order summary and place order action.

struct CheckoutView: View {
    @ObservedObject var cartVM: CartViewModel
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedField: CheckoutField?
    @State private var showConfirmation = false

    // Local binding mirrors to work around struct-based ShippingAddress
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var line1: String = ""
    @State private var line2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""

    private let usStates = [
        "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
        "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
        "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
        "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
        "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
    ]

    enum CheckoutField: Hashable {
        case firstName, lastName, line1, line2, city, state, zip
    }

    var canPlaceOrder: Bool {
        !firstName.isEmpty && !lastName.isEmpty &&
        !line1.isEmpty && !city.isEmpty &&
        !state.isEmpty && !zip.isEmpty
    }

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {

                    // Age verification notice
                    ageVerificationBanner

                    // Shipping address form
                    shippingAddressSection

                    // Order summary
                    orderSummarySection

                    // Error message
                    if let error = cartVM.errorMessage {
                        Text(error)
                            .font(BJFont.caption)
                            .foregroundColor(Color.error)
                            .padding(.horizontal, Spacing.xl)
                            .multilineTextAlignment(.center)
                    }

                    // Place Order
                    GoldButton(
                        title: "Place Order",
                        action: placeOrder,
                        isLoading: cartVM.isCheckingOut,
                        isDisabled: !canPlaceOrder
                    )
                    .padding(.horizontal, Spacing.xl)

                    Spacer(minLength: Spacing.xxxl)
                }
                .padding(.top, Spacing.xl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CHECKOUT")
                    .font(BJFont.playfair(18, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.textPrimary)
            }
        }
        .navigationDestination(isPresented: $showConfirmation) {
            if let order = cartVM.lastOrder {
                OrderConfirmationView(order: order, cartVM: cartVM)
            }
        }
        .onTapGesture { hideKeyboard() }
        .onChange(of: cartVM.lastOrder?.id) { newId in
            if newId != nil {
                showConfirmation = true
            }
        }
    }

    // MARK: - Age Verification Banner

    private var ageVerificationBanner: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.gold.opacity(0.15))
                    .frame(width: 38, height: 38)
                Text("21+")
                    .font(BJFont.outfit(13, weight: .heavy))
                    .foregroundColor(Color.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AGE VERIFICATION REQUIRED")
                    .font(BJFont.eyebrow)
                    .tracking(2)
                    .foregroundColor(Color.gold)
                Text("You must be 21 or older to purchase. Age verification will be required at checkout.")
                    .font(BJFont.sora(11, weight: .regular))
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(Color.gold.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.gold.opacity(0.25), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Shipping Address Section

    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.goldMid)
                Text("SHIPPING ADDRESS")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
            }
            .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.sm) {
                // First / Last name row
                HStack(spacing: Spacing.sm) {
                    BJTextField(placeholder: "First Name", text: $firstName)
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .lastName }

                    BJTextField(placeholder: "Last Name", text: $lastName)
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .line1 }
                }

                // Address line 1
                BJTextField(placeholder: "Address Line 1", text: $line1)
                    .focused($focusedField, equals: .line1)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .line2 }

                // Address line 2
                BJTextField(placeholder: "Apt, Suite, Unit (optional)", text: $line2)
                    .focused($focusedField, equals: .line2)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .city }

                // City
                BJTextField(placeholder: "City", text: $city)
                    .focused($focusedField, equals: .city)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .zip }

                // State + ZIP row
                HStack(spacing: Spacing.sm) {
                    // State picker
                    Menu {
                        ForEach(usStates, id: \.self) { abbrev in
                            Button(abbrev) { state = abbrev }
                        }
                    } label: {
                        HStack {
                            Text(state.isEmpty ? "State" : state)
                                .font(BJFont.sora(14))
                                .foregroundColor(state.isEmpty ? Color.textTertiary : Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.textTertiary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 52)
                        .background(Color.bgInput)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.borderGold, lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .frame(maxWidth: .infinity)

                    // ZIP
                    BJTextField(placeholder: "ZIP Code", text: $zip)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .zip)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Order Summary Section

    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.goldMid)
                Text("ORDER SUMMARY")
                    .font(BJFont.eyebrow)
                    .tracking(3)
                    .foregroundColor(Color.goldMid)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.sm)

            VStack(spacing: 0) {
                // Items
                if let items = cartVM.cart?.items {
                    ForEach(items) { item in
                        CheckoutItemRow(item: item)
                        if item.id != items.last?.id {
                            Rectangle()
                                .fill(Color.borderSubtle)
                                .frame(height: 0.5)
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }

                Rectangle()
                    .fill(Color.borderSubtle)
                    .frame(height: 0.5)
                    .padding(.top, Spacing.xs)

                VStack(spacing: Spacing.sm) {
                    // Subtotal
                    CheckoutSummaryRow(
                        label: "Subtotal",
                        value: cartVM.subtotal.formatted(.currency(code: "USD"))
                    )

                    // Tax
                    if let tax = cartVM.taxEstimate {
                        CheckoutSummaryRow(
                            label: "Tax (\(String(format: "%.1f", tax.taxRate * 100))%)",
                            value: tax.taxAmount.formatted(.currency(code: "USD"))
                        )
                    } else if !zip.isEmpty {
                        HStack {
                            Text("Tax")
                                .font(BJFont.sora(13, weight: .regular))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            HStack(spacing: Spacing.xxs) {
                                ProgressView().tint(Color.gold).scaleEffect(0.7)
                                Text("Calculating...")
                                    .font(BJFont.sora(11, weight: .regular))
                                    .foregroundColor(Color.textTertiary)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    } else {
                        CheckoutSummaryRow(label: "Tax", value: "—")
                    }

                    // Total
                    HStack {
                        Text("TOTAL")
                            .font(BJFont.sora(14, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        let total = cartVM.taxEstimate?.total ?? cartVM.subtotal
                        Text(total.formatted(.currency(code: "USD")))
                            .font(BJFont.outfit(22, weight: .heavy))
                            .foregroundColor(Color.gold)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xxs)
                }
                .padding(.vertical, Spacing.md)
            }
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.borderGold, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Actions

    private func placeOrder() {
        // Sync local state into cartVM's shipping address before checkout
        cartVM.shippingAddress = ShippingAddress(
            firstName: firstName,
            lastName: lastName,
            line1: line1,
            line2: line2.isEmpty ? nil : line2,
            city: city,
            state: state,
            zip: zip,
            country: "US"
        )
        Task { await cartVM.checkout(paymentToken: "manual") }
    }
}

// MARK: - CheckoutItemRow

private struct CheckoutItemRow: View {
    let item: CartItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("×\(item.quantity)")
                .font(BJFont.outfit(12, weight: .bold))
                .foregroundColor(Color.textTertiary)
                .frame(width: 28)

            Text(item.productName)
                .font(BJFont.sora(13, weight: .regular))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)

            Spacer()

            Text(item.lineTotal.formatted(.currency(code: "USD")))
                .font(BJFont.outfit(13, weight: .semibold))
                .foregroundColor(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - CheckoutSummaryRow

private struct CheckoutSummaryRow: View {
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
        .padding(.horizontal, Spacing.md)
    }
}

#Preview {
    NavigationStack {
        CheckoutView(cartVM: CartViewModel())
    }
}
