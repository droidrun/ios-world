import SwiftUI

struct CartView: View {
    @EnvironmentObject private var store: MegaMartStore
    @StateObject private var viewModel = CartViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.state.cartItems.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cart items")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal, 18)

                        ForEach(store.state.cartItems) { item in
                            CartItemRow(item: item)
                        }
                    }

                    summaryCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saved for later")
                            .font(.system(size: 24, weight: .bold))
                            .padding(.horizontal, 18)

                        if store.state.savedItems.isEmpty {
                            Text("No saved items yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 18)
                                .accessibilityIdentifier("saved_items_empty_state")
                        } else {
                            ForEach(store.state.savedItems) { item in
                                SavedItemRow(item: item)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 80)
        }
        .background(MegaMartTheme.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            MegaMartScreenHeader(
                destination: SearchView(initialRequest: SearchNavigationRequest(query: "", departmentID: nil, categoryID: nil)),
                text: "Search MegaMart"
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isCheckoutPresented) {
            CheckoutFlowView(mode: .cart, store: store)
                .environmentObject(store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                Image(systemName: "cart")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(Color(red: 116 / 255, green: 130 / 255, blue: 145 / 255))
                    .padding(.top, 14)

                Text("Your MegaMart Cart is empty")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)

                Button("Shop today's deals") {
                    store.navigateToSearch(query: "deals")
                }
                .buttonStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(MegaMartTheme.linkBlue)
            }
            .frame(maxWidth: .infinity)

            if store.isAuthenticated {
                Button("View your orders") {
                    store.navigateToAccount(.orders)
                }
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(MegaMartTheme.amazonYellow)
                )
                .foregroundStyle(.black)
            } else {
                Button("Sign in to your account") {
                    store.navigateToAccount(.auth(.signIn))
                }
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(MegaMartTheme.amazonYellow)
                )
                .foregroundStyle(.black)

                Button("Sign up now") {
                    store.navigateToAccount(.auth(.createAccount))
                }
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                        .overlay(
                            Capsule()
                                .stroke(Color(.systemGray3), lineWidth: 1.5)
                        )
                )
                .foregroundStyle(.black)
            }

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 110, height: 66)
                    .overlay {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("amazon")
                                .font(.system(size: 18, weight: .bold))
                            Text("VISA")
                                .font(.system(size: 16, weight: .black))
                        }
                        .foregroundStyle(.black.opacity(0.7))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pay for this order. Get $50 off instantly")
                        .font(.system(size: 16, weight: .bold))
                    Text("upon approval for MegaMart Visa")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )

            Button("Continue shopping") {
                store.setSelectedTab(.home)
            }
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(MegaMartTheme.amazonYellow)
            )
            .foregroundStyle(.black)
            .accessibilityIdentifier("empty_cart_continue_shopping")
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .accessibilityIdentifier("empty_cart_state")
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order summary")
                .font(.system(size: 24, weight: .bold))

            summaryRow("Items subtotal", value: Formatters.currency(store.cartSubtotal))
            summaryRow("Estimated shipping", value: "Free")
            summaryRow("Estimated tax", value: Formatters.currency(store.cartTaxEstimate))
            summaryRow("Discounts", value: "-\(Formatters.currency(store.cartDiscountEstimate))")
            Divider()
            summaryRow("Estimated total", value: Formatters.currency(store.cartEstimatedTotal), bold: true)
                .accessibilityIdentifier("cart_estimated_total_label")

            Button("Proceed to Checkout") {
                viewModel.isCheckoutPresented = true
            }
            .font(.system(size: 20, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(MegaMartTheme.amazonYellow)
            )
            .foregroundStyle(.black)
            .accessibilityIdentifier("proceed_to_checkout_button")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
        )
        .padding(.horizontal, 18)
    }

    private func summaryRow(_ title: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(bold ? .subheadline.weight(.bold) : .subheadline)
            Spacer()
            Text(value)
                .font(bold ? .headline.weight(.bold) : .subheadline)
        }
    }
}

private struct CartItemRow: View {
    @EnvironmentObject private var store: MegaMartStore
    let item: CartItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let product = store.product(for: item.productID) {
                NavigationLink {
                    ProductDetailView(productID: product.id)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 80, height: 80)
                            .overlay {
                                if let product = store.product(for: item.productID) {
                                    MegaMartProductArtwork(product: product)
                                        .padding(8)
                                } else {
                                    Image(systemName: item.imageSystemName)
                                        .foregroundStyle(.orange)
                                }
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.productName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Text(item.brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !item.selectedVariantValues.isEmpty {
                                Text(Formatters.variantSummary(item.selectedVariantValues))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(Formatters.currency(item.unitPrice))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.primary)
                                .accessibilityIdentifier("cart_price_\(item.productID)")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button {
                    store.updateCartQuantity(cartItemID: item.id, delta: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .accessibilityIdentifier("cart_quantity_decrement_\(item.productID)")

                Text("\(item.quantity)")
                    .font(.headline)

                Button {
                    store.updateCartQuantity(cartItemID: item.id, delta: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityIdentifier("cart_quantity_increment_\(item.productID)")

                Spacer()

                Button("Move to saved") {
                    store.moveCartItemToSaved(cartItemID: item.id)
                }
                .buttonStyle(.bordered)
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("cart_move_to_saved_\(item.productID)")

                Button("Remove") {
                    store.removeCartItem(cartItemID: item.id)
                }
                .buttonStyle(.bordered)
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("cart_remove_\(item.productID)")
            }
            .foregroundStyle(.orange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
        .padding(.horizontal, 18)
    }
}

private struct SavedItemRow: View {
    @EnvironmentObject private var store: MegaMartStore
    let item: SavedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.12))
                .frame(width: 76, height: 76)
                .overlay {
                    if let product = store.product(for: item.productID) {
                        MegaMartProductArtwork(product: product)
                            .padding(8)
                    } else {
                        Image(systemName: item.imageSystemName)
                            .foregroundStyle(.orange)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline.weight(.semibold))
                Text(Formatters.currency(item.unitPrice))
                    .font(.headline)
                    .accessibilityIdentifier("saved_item_price_\(item.productID)")
                Text(item.deliveryEstimate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 8) {
                Button("Move to Cart") {
                    store.moveSavedItemToCart(savedItemID: item.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("saved_move_to_cart_\(item.productID)")

                Button("Remove") {
                    store.removeSavedItem(savedItemID: item.id)
                }
                .buttonStyle(.bordered)
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("saved_remove_\(item.productID)")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
        .padding(.horizontal, 18)
    }
}

struct CheckoutFlowView: View {
    @EnvironmentObject private var store: MegaMartStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CheckoutViewModel

    init(mode: CheckoutMode, store: MegaMartStore) {
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(mode: mode, store: store))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    stepHeader

                    if viewModel.step == .confirmation {
                        confirmationStep
                    } else if viewModel.items(in: store).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Checkout unavailable")
                                .font(.headline)
                            Text("Add at least one item before checking out.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .accessibilityIdentifier("checkout_unavailable_state")
                    } else {
                        switch viewModel.step {
                        case .address:
                            addressStep
                        case .delivery:
                            deliveryStep
                        case .payment:
                            paymentStep
                        case .review:
                            reviewStep
                        case .confirmation:
                            confirmationStep
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.step != .address && viewModel.step != .confirmation {
                        Button("Back") {
                            viewModel.back()
                        }
                        .accessibilityIdentifier("checkout_back_button")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("checkout_modal_close_button")
                }
            }
        }
    }

    private var stepHeader: some View {
        HStack(spacing: 10) {
            ForEach(CheckoutStep.allCases) { step in
                VStack(spacing: 6) {
                    Circle()
                        .fill(step == viewModel.step ? Color.orange : Color.gray.opacity(0.2))
                        .frame(width: 10, height: 10)
                    Text(step.title)
                        .font(.caption2.weight(step == viewModel.step ? .bold : .regular))
                        .foregroundStyle(step == viewModel.step ? .primary : .secondary)
                }
                if step != CheckoutStep.allCases.last {
                    Divider()
                }
            }
        }
    }

    private var addressStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select a shipping address")
                .font(.headline)

            ForEach(store.state.addresses) { address in
                Button {
                    viewModel.selectedAddressID = address.id
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(address.label)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if viewModel.selectedAddressID == address.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        ForEach(address.formattedLines, id: \.self) { line in
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shipping_address_\(address.id)")
            }

            Button("Continue") {
                viewModel.advance()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("checkout_continue_address_button")
        }
    }

    private var deliveryStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose delivery speed")
                .font(.headline)

            ForEach(store.deliveryOptions) { option in
                Button {
                    viewModel.selectedDeliveryOptionID = option.id
                } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.subheadline.weight(.semibold))
                            Text(option.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(option.estimatedArrival)
                                .font(.caption.weight(.semibold))
                        }
                        Spacer()
                        Text(option.additionalCost == 0 ? "Free" : Formatters.currency(option.additionalCost))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(viewModel.selectedDeliveryOptionID == option.id ? Color.orange : Color.clear, lineWidth: 1.5)
                )
                .accessibilityIdentifier("delivery_option_\(AccessibilityID.slug(option.id))")
            }

            Button("Continue") {
                viewModel.advance()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("checkout_continue_delivery_button")
        }
    }

    private var paymentStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment and options")
                .font(.headline)

            if !store.paymentAccounts.isEmpty {
                Text("Bank Cards")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(store.paymentAccounts) { account in
                    Button {
                        viewModel.selectedPaymentAccountID = account.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(account.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Available: \(Formatters.currency(account.availableBalance))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedPaymentAccountID == account.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("payment_account_\(account.id.uuidString)")
                }
            }

            Text("Other Payment Methods")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ForEach(store.state.paymentMethods) { method in
                Button {
                    viewModel.selectedPaymentMethodID = method.id
                    viewModel.selectedPaymentAccountID = nil
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(method.label)
                                .font(.subheadline.weight(.semibold))
                            Text(method.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedPaymentAccountID == nil && viewModel.selectedPaymentMethodID == method.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("payment_method_\(method.id)")
            }

            Toggle("This order contains a gift", isOn: $viewModel.isGift)
                .accessibilityIdentifier("gift_option_toggle")

            if viewModel.isGift {
                TextField("Gift message", text: $viewModel.giftMessage)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("gift_message_field")
            }

            TextField("Promo code", text: $viewModel.promoCode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .accessibilityIdentifier("promo_code_field")

            Button("Continue") {
                viewModel.advance()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("checkout_continue_payment_button")
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review order")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(viewModel.items(in: store)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.productName)
                                .font(.subheadline.weight(.semibold))
                            if !item.selectedVariantValues.isEmpty {
                                Text(Formatters.variantSummary(item.selectedVariantValues))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Qty \(item.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Formatters.currency(item.unitPrice * Double(item.quantity)))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )

            VStack(spacing: 10) {
                reviewSummaryRow("Items", value: Formatters.currency(viewModel.subtotal(in: store)))
                reviewSummaryRow("Shipping", value: viewModel.deliveryCost(in: store) == 0 ? "Free" : Formatters.currency(viewModel.deliveryCost(in: store)))
                reviewSummaryRow("Tax", value: Formatters.currency(viewModel.tax(in: store)))
                reviewSummaryRow("Promo", value: "-\(Formatters.currency(viewModel.estimatedDiscount(in: store)))")
                reviewSummaryRow("Estimated total", value: Formatters.currency(viewModel.total(in: store)), bold: true)
                    .accessibilityIdentifier("checkout_total_label")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )

            Button("Place Order") {
                store.selectedPaymentAccountID = viewModel.selectedPaymentAccountID
                let order = store.placeOrder(
                    items: viewModel.items(in: store),
                    selectedAddressID: viewModel.selectedAddressID,
                    selectedPaymentMethodID: viewModel.selectedPaymentMethodID,
                    deliveryOptionID: viewModel.selectedDeliveryOptionID,
                    promoCode: viewModel.promoCode,
                    isGift: viewModel.isGift,
                    clearCart: {
                        if case .cart = viewModel.mode { return true }
                        return false
                    }()
                )
                if let order {
                    viewModel.placedOrder = order
                    viewModel.step = .confirmation
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("checkout_place_order_button")
        }
    }

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                Text("Order confirmed")
                    .font(.title3.weight(.bold))
            }

            if let order = viewModel.placedOrder {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order #\(order.orderNumber)")
                        .font(.subheadline.weight(.semibold))

                    Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(spacing: 8) {
                    confirmationRow("Items subtotal", value: Formatters.currency(order.itemSubtotal))
                    confirmationRow("Shipping", value: order.shippingCost == 0 ? "Free" : Formatters.currency(order.shippingCost))
                    confirmationRow("Tax", value: Formatters.currency(order.tax))
                    if order.discount > 0 {
                        confirmationRow("Promo discount", value: "-\(Formatters.currency(order.discount))")
                    }
                    Divider()
                    confirmationRow("Order total", value: Formatters.currency(order.estimatedTotal), bold: true)
                        .accessibilityIdentifier("confirmation_total_label")
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    if let account = viewModel.selectedPaymentAccountID.flatMap({ id in store.paymentAccounts.first(where: { $0.id == id }) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("Charged to \(account.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(.orange)
                            Text(order.paymentMethod.label)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated delivery")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(order.deliveryOption.estimatedArrival)
                        .font(.subheadline)
                }

                Text("You can track this order from Your Orders.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("View Orders") {
                store.navigateToAccount(.orders)
                dismiss()
            }
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(MegaMartTheme.amazonYellow)
            )
            .foregroundStyle(.black)
            .accessibilityIdentifier("checkout_view_orders_button")

            Button("Done") {
                dismiss()
            }
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
            )
            .foregroundStyle(.primary)
            .accessibilityIdentifier("checkout_confirmation_button")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func confirmationRow(_ title: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(bold ? .subheadline.weight(.bold) : .subheadline)
            Spacer()
            Text(value)
                .font(bold ? .headline.weight(.bold) : .subheadline)
        }
    }

    private func reviewSummaryRow(_ title: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(bold ? .subheadline.weight(.bold) : .subheadline)
            Spacer()
            Text(value)
                .font(bold ? .headline.weight(.bold) : .subheadline)
        }
    }
}
