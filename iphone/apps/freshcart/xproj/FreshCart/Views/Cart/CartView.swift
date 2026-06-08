import SwiftUI

struct CartView: View {
    @ObservedObject var viewModel: CartViewModel

    @State private var showCheckout = false
    @State private var showSlotSelector = false
    @State private var selectedProduct: Product?
    @State private var expandedNoteIDs: Set<String> = []

    private let unlockTarget = 10.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar

                if viewModel.cartLineItems.isEmpty {
                    emptyCartContent
                        .padding(.bottom, 190)
                } else {
                    filledCartContent
                        .padding(.bottom, 130)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if viewModel.cartLineItems.isEmpty {
                emptyCartFooter
            } else {
                checkoutFooter
            }
        }
        .sheet(isPresented: $showSlotSelector) {
            NavigationStack {
                SlotSelectorView(
                    mode: viewModel.deliveryMode,
                    slots: viewModel.availableSlots,
                    selectedSlotID: viewModel.selectedSlot?.id
                ) { slot in
                    viewModel.setSlot(slot.id)
                    showSlotSelector = false
                }
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(viewModel: viewModel)
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product, store: viewModel.store)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.store.switchTab(.home)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Your cart")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: 210)
                .frame(height: 54)
                .background(Capsule().fill(Color.black.opacity(0.08)))

            Spacer()

            if viewModel.cartLineItems.isEmpty {
                ShareLink(item: familyInviteMessage) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.94)))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    viewModel.store.switchTab(.search)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.94)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyCartContent: some View {
        VStack(spacing: 28) {
            inviteBanner

            VStack(spacing: 18) {
                CartIllustrationView()
                    .scaleEffect(0.8)
                    .frame(height: 200)

                Text("Your personal cart is empty")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.secondary)

                Button("Shop now") {
                    viewModel.store.switchTab(.home)
                }
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .underline()
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
    }

    private var inviteBanner: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(red: 0.00, green: 0.44, blue: 0.02))
            .frame(height: 176)
            .overlay(
                VStack(alignment: .leading, spacing: 16) {
                    Text("Invite a family member to help\nyou fill your cart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    ShareLink(item: familyInviteMessage) {
                        Text("Get started")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.instacartGreenDark)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Color(red: 0.95, green: 0.91, blue: 0.84)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack {
                        Spacer()
                        Text("Family")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                .padding(20)
            )
    }

    private var filledCartContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            selectedStoreCard

            Text("Items")
                .font(.system(size: 20, weight: .heavy))

            ForEach(viewModel.cartLineItems) { lineItem in
                cartItemCard(lineItem)
            }

            pricingCard
        }
    }

    private var selectedStoreCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedStore?.storeName ?? "Store")
                .font(.system(size: 22, weight: .heavy))

            HStack {
                Text(viewModel.deliveryMode.label)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.instacartGreenDark)

                Spacer()

                Button {
                    showSlotSelector = true
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.selectedSlot?.displayLabel ?? "Select a slot")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("selected_delivery_slot_button")
            }

            Text(viewModel.selectedAddress?.streetLine1 ?? "Choose an address")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
    }

    private func cartItemCard(_ lineItem: CartLineItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Button {
                    selectedProduct = lineItem.product
                } label: {
                    ProductArtView(product: lineItem.product, cornerRadius: 16)
                        .frame(width: 110, height: 110)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.productRow(lineItem.product.id))

                VStack(alignment: .leading, spacing: 4) {
                    Text(lineItem.product.productName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(lineItem.product.unitPrice)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    // Feature 6: Replacement selector
                    Menu {
                        ForEach(SubstitutionPreferenceType.allCases, id: \.self) { prefType in
                            Button {
                                viewModel.updateSubstitution(
                                    productID: lineItem.product.id,
                                    preference: SubstitutionPreference(type: prefType, replacementProductID: nil)
                                )
                            } label: {
                                HStack {
                                    Text(prefType.label)
                                    if lineItem.cartItem.substitutionPreference.type == prefType {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 10, weight: .bold))
                            Text(lineItem.cartItem.substitutionPreference.summary)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.instacartGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.instacartGreen.opacity(0.12)))
                    }
                }

                Spacer()

                Text(AppFormatters.currencyString(lineItem.lineTotal))
                    .font(.system(size: 18, weight: .bold))
                    .accessibilityIdentifier(AccessibilityID.priceLabel("cart_\(lineItem.product.id)"))
            }

            HStack {
                HStack(spacing: 0) {
                    Button {
                        if lineItem.cartItem.quantity <= 1 {
                            viewModel.remove(productID: lineItem.product.id)
                        } else {
                            viewModel.decrement(productID: lineItem.product.id)
                        }
                    } label: {
                        Image(systemName: lineItem.cartItem.quantity <= 1 ? "trash" : "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(lineItem.cartItem.quantity <= 1 ? .red : .secondary)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.cartDecrement(lineItem.product.id))

                    Text("\(lineItem.cartItem.quantity)")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 30)

                    Button {
                        viewModel.increment(productID: lineItem.product.id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.instacartGreen)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.cartIncrement(lineItem.product.id))
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.instacartChip)
                )

                Spacer()

                // Feature 7: Item note toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedNoteIDs.contains(lineItem.product.id) {
                            expandedNoteIDs.remove(lineItem.product.id)
                        } else {
                            expandedNoteIDs.insert(lineItem.product.id)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: lineItem.cartItem.note.isEmpty ? "note.text.badge.plus" : "note.text")
                            .font(.system(size: 13, weight: .semibold))
                        Text(lineItem.cartItem.note.isEmpty ? "Add note" : "Note")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(lineItem.cartItem.note.isEmpty ? .secondary : Color.instacartGreen)
                }
                .buttonStyle(.plain)
            }

            // Feature 7: Collapsible note field
            if expandedNoteIDs.contains(lineItem.product.id) {
                TextField("e.g. Pick ripe ones", text: Binding(
                    get: { lineItem.cartItem.note },
                    set: { viewModel.updateItemNote(productID: lineItem.product.id, note: $0) }
                ))
                .font(.system(size: 14))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.instacartChip))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
    }

    private var pricingCard: some View {
        let summary = viewModel.pricingSummary
        return VStack(alignment: .leading, spacing: 14) {
            Text("Summary")
                .font(.system(size: 18, weight: .heavy))

            priceRow("Item subtotal", value: summary.itemSubtotal, id: AccessibilityID.priceLabel("item_subtotal"))
            priceRow("Delivery fee", value: summary.deliveryFee, id: AccessibilityID.priceLabel("delivery_fee"))
            if summary.priorityFee > 0 {
                priceRow("Priority fee", value: summary.priorityFee, id: AccessibilityID.priceLabel("priority_fee"))
            }
            priceRow("Service fee", value: summary.serviceFee, id: AccessibilityID.priceLabel("service_fee"))
            priceRow("Tax estimate", value: summary.taxEstimate, id: AccessibilityID.priceLabel("tax_estimate"))
            priceRow("Tip", value: summary.tip, id: AccessibilityID.priceLabel("tip"))
            if summary.promoDiscount > 0 {
                priceRow("Promo discount", value: -summary.promoDiscount, id: AccessibilityID.priceLabel("promo_discount"))
            }

            Divider()

            priceRow("Estimated total", value: summary.estimatedTotal, id: AccessibilityID.priceLabel("cart_total"), emphasized: true)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
    }

    private var emptyCartFooter: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                highlightedProgressText
                Spacer()
                Text("0/1 earned")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 16) {
                Text("\(compactCurrency(max(0, unlockTarget - subtotal))) Min. to checkout")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.black.opacity(0.18))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer()
                Text(AppFormatters.currencyString(subtotal))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.black.opacity(0.06)))
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 82)
            .background(Capsule().fill(Color.black.opacity(0.05)))
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var checkoutFooter: some View {
        VStack(spacing: 14) {
            if subtotal < unlockTarget {
                FloatingCartBar(subtotal: subtotal, cartCount: cartCount) { }
                    .allowsHitTesting(false)
            }

            // Feature 4: Instacart+ savings banner
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.instacartGreen)
                Text("FreshCart+ member")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.instacartGreenDark)
                Spacer()
                Text("Saved \(AppFormatters.currencyString(viewModel.membershipStatus.savingsToDate))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.instacartGreen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.instacartGreen.opacity(0.08))
            )
            .padding(.horizontal, 18)

            Button {
                showCheckout = true
            } label: {
                HStack {
                    Text("Go to checkout")
                        .font(.system(size: 18, weight: .heavy))
                    Spacer()
                    Text(AppFormatters.currencyString(viewModel.pricingSummary.estimatedTotal))
                        .font(.system(size: 18, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.instacartGreen))
            }
            .accessibilityIdentifier("checkout_place_order_button")
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .background(Color.instacartBackground)
    }

    private var highlightedProgressText: some View {
        HStack(spacing: 0) {
            Text("Add \(compactCurrency(max(0, unlockTarget - subtotal))) to get ")
                .font(.system(size: 16, weight: .semibold))
            Text("$0 delivery fee")
                .font(.system(size: 16, weight: .heavy))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.instacartYellow)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private var subtotal: Double {
        viewModel.pricingSummary.itemSubtotal
    }

    private var cartCount: Int {
        viewModel.cartLineItems.reduce(0) { $0 + $1.cartItem.quantity }
    }

    private func compactCurrency(_ value: Double) -> String {
        let rounded = round(value)
        if abs(rounded - value) < 0.01 {
            return "$\(Int(rounded))"
        }
        return AppFormatters.currencyString(value)
    }

    private var familyInviteMessage: String {
        "Join my FreshCart family cart and help me shop this order."
    }

    private func priceRow(_ title: String, value: Double, id: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .system(size: 16, weight: .heavy) : .system(size: 15, weight: .medium))
            Spacer()
            Text(AppFormatters.currencyString(value))
                .font(emphasized ? .system(size: 16, weight: .heavy) : .system(size: 15, weight: .medium))
                .accessibilityIdentifier(id)
        }
    }
}

private struct CheckoutView: View {
    @ObservedObject var viewModel: CartViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showSlotSelector = false
    @State private var confirmationOrder: Order?
    @State private var showCustomTip = false
    @State private var customTipText = ""
    @State private var selectedDeliveryChip: String?
    @State private var customDeliveryInstruction = ""
    @State private var showPromoField = false

    private let deliveryChipOptions = ["Leave at door", "Meet at door", "Leave with doorman"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Delivery / Pickup card
                checkoutCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery or pickup")
                            .font(.system(size: 18, weight: .heavy))

                        Picker("Mode", selection: Binding(
                            get: { viewModel.deliveryMode },
                            set: { viewModel.setMode($0) }
                        )) {
                            Text("Delivery").tag(DeliveryMode.delivery)
                            Text("Pickup").tag(DeliveryMode.pickup)
                        }
                        .pickerStyle(.segmented)

                        Button {
                            showSlotSelector = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.instacartGreen)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Time slot")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(viewModel.selectedSlot?.displayLabel ?? "Select a slot")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkout_time_slot_button")
                    }
                }

                // Feature 3: Priority delivery upsell
                if viewModel.deliveryMode == .delivery {
                    checkoutCard {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.instacartGreen)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Priority delivery")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Get your order faster")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("$2.00")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Toggle("", isOn: Binding(
                                get: { viewModel.priorityDelivery },
                                set: { viewModel.setPriorityDelivery($0) }
                            ))
                            .labelsHidden()
                            .tint(Color.instacartGreen)
                            .accessibilityIdentifier("checkout_priority_delivery_toggle")
                        }
                    }
                }

                // Address card
                checkoutCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Delivery address")
                            .font(.system(size: 18, weight: .heavy))

                        Menu {
                            ForEach(viewModel.addresses) { address in
                                Button(address.label) {
                                    viewModel.setAddress(address.id)
                                }
                                .accessibilityIdentifier("address_option_\(AccessibilityID.slug(address.id))")
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.instacartGreen)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(viewModel.selectedAddress?.label ?? "Address")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(viewModel.selectedAddress?.streetLine1 ?? "Select address")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("checkout_address_menu")
                    }
                }

                // Payment card
                checkoutCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Payment")
                            .font(.system(size: 18, weight: .heavy))

                        HStack(spacing: 12) {
                            Image(systemName: "hand.wave")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.instacartGreenDark)
                            Toggle("Contactless handoff", isOn: Binding(
                                get: { viewModel.contactlessHandoff },
                                set: { viewModel.setContactless($0) }
                            ))
                            .tint(Color.instacartGreen)
                            .accessibilityIdentifier("checkout_contactless_toggle")
                        }

                        Divider()

                        Menu {
                            ForEach(viewModel.paymentAccounts) { account in
                                Button {
                                    viewModel.setPaymentAccount(account.id)
                                } label: {
                                    VStack {
                                        Text(account.name)
                                        Text(account.displayName)
                                    }
                                }
                                .accessibilityIdentifier("payment_account_option_\(account.id.uuidString)")
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.instacartGreenDark)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(viewModel.selectedPaymentAccount?.name ?? "Payment method")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(viewModel.selectedPaymentAccount?.displayName ?? "Select payment method")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("checkout_payment_menu")
                    }
                }

                // Feature 1: Tip selector
                checkoutCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Shopper tip")
                            .font(.system(size: 18, weight: .heavy))

                        Text("100% of your tip goes to the shopper.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach([15, 18, 20, 25], id: \.self) { pct in
                                let tipValue = round(viewModel.pricingSummary.itemSubtotal * Double(pct) / 100.0 * 100) / 100
                                let isSelected = abs(viewModel.tipAmount - tipValue) < 0.01
                                Button {
                                    viewModel.setTip(tipValue)
                                    showCustomTip = false
                                } label: {
                                    VStack(spacing: 2) {
                                        Text("\(pct)%")
                                            .font(.system(size: 15, weight: .bold))
                                        Text(AppFormatters.currencyString(tipValue))
                                            .font(.system(size: 11))
                                    }
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(isSelected ? Color.instacartGreen : Color.instacartChip)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? Color.instacartGreen : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCustomTip.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Custom amount")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Color.instacartGreen)
                        }
                        .buttonStyle(.plain)

                        if showCustomTip {
                            HStack(spacing: 10) {
                                Text("$")
                                    .font(.system(size: 16, weight: .semibold))
                                TextField("0.00", text: $customTipText)
                                    .font(.system(size: 16))
                                    .keyboardType(.decimalPad)
                                    .accessibilityIdentifier("checkout_custom_tip_field")
                                Button("Set") {
                                    if let value = Double(customTipText) {
                                        viewModel.setTip(max(0, value))
                                    }
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.instacartGreen)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.instacartChip))
                        }
                    }
                }

                // Feature 2: Delivery instruction chips + Notes card
                checkoutCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Instructions")
                            .font(.system(size: 18, weight: .heavy))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order notes")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            TextField("Add a note for your shopper", text: Binding(
                                get: { viewModel.orderNotes },
                                set: { viewModel.setOrderNotes($0) }
                            ))
                            .font(.system(size: 15))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.instacartChip))
                            .accessibilityIdentifier("checkout_order_notes_field")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Delivery instructions")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(deliveryChipOptions, id: \.self) { option in
                                    let isSelected = selectedDeliveryChip == option
                                    Button {
                                        selectedDeliveryChip = option
                                        viewModel.setSpecialInstructions(option)
                                    } label: {
                                        Text(option)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule().fill(isSelected ? Color.instacartGreen : Color.instacartChip)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    selectedDeliveryChip = "other"
                                    viewModel.setSpecialInstructions(customDeliveryInstruction)
                                } label: {
                                    Text("Other")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(selectedDeliveryChip == "other" ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(selectedDeliveryChip == "other" ? Color.instacartGreen : Color.instacartChip)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            if selectedDeliveryChip == "other" {
                                TextField("Custom instructions", text: $customDeliveryInstruction)
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.instacartChip))
                                    .onChange(of: customDeliveryInstruction) { _, newValue in
                                        viewModel.setSpecialInstructions(newValue)
                                    }
                                    .accessibilityIdentifier("checkout_delivery_instructions_field")
                            }
                        }
                    }
                }

                // Substitution preferences
                if viewModel.activeSubstitutionSummary.isEmpty == false {
                    checkoutCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Replacement preferences")
                                .font(.system(size: 18, weight: .heavy))

                            ForEach(viewModel.activeSubstitutionSummary, id: \.self) { summary in
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.2.squarepath")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.instacartGreen)
                                    Text(summary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                        }
                    }
                }

                // Feature 5: Promo code
                checkoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPromoField.toggle()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.instacartGreen)
                                Text("Add promo or gift card")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: showPromoField ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkout_promo_toggle")

                        if showPromoField {
                            if viewModel.promoApplied {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.instacartGreen)
                                    Text("Promo code applied!")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.instacartGreen)
                                }
                            } else {
                                HStack(spacing: 10) {
                                    TextField("Enter code", text: Binding(
                                        get: { viewModel.promoCode },
                                        set: { viewModel.setPromoCode($0) }
                                    ))
                                    .font(.system(size: 15))
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.instacartChip))
                                    .accessibilityIdentifier("checkout_promo_code_field")

                                    Button("Apply") {
                                        viewModel.applyPromoCode()
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.instacartGreen))
                                    .accessibilityIdentifier("checkout_promo_apply_button")
                                }
                            }
                        }
                    }
                }

                // Summary card
                checkoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order summary")
                            .font(.system(size: 18, weight: .heavy))

                        priceRow("Item subtotal", value: viewModel.pricingSummary.itemSubtotal, id: AccessibilityID.priceLabel("checkout_item_subtotal"))
                        priceRow("Delivery fee", value: viewModel.pricingSummary.deliveryFee, id: AccessibilityID.priceLabel("checkout_delivery_fee"))
                        if viewModel.pricingSummary.priorityFee > 0 {
                            priceRow("Priority fee", value: viewModel.pricingSummary.priorityFee, id: AccessibilityID.priceLabel("checkout_priority_fee"))
                        }
                        priceRow("Service fee", value: viewModel.pricingSummary.serviceFee, id: AccessibilityID.priceLabel("checkout_service_fee"))
                        priceRow("Tax estimate", value: viewModel.pricingSummary.taxEstimate, id: AccessibilityID.priceLabel("checkout_tax_estimate"))
                        priceRow("Tip", value: viewModel.pricingSummary.tip, id: AccessibilityID.priceLabel("checkout_tip"))
                        if viewModel.pricingSummary.promoDiscount > 0 {
                            priceRow("Promo discount", value: -viewModel.pricingSummary.promoDiscount, id: AccessibilityID.priceLabel("checkout_promo_discount"))
                        }

                        Divider()

                        priceRow("Estimated total", value: viewModel.pricingSummary.estimatedTotal, id: AccessibilityID.priceLabel("checkout_total"), emphasized: true)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                confirmationOrder = viewModel.placeOrder()
            } label: {
                HStack {
                    Text("Place order")
                        .font(.system(size: 18, weight: .heavy))
                    Spacer()
                    Text(AppFormatters.currencyString(viewModel.pricingSummary.estimatedTotal))
                        .font(.system(size: 18, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.instacartGreen))
            }
            .accessibilityIdentifier("checkout_place_order_button")
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color.instacartBackground)
        }
        .sheet(isPresented: $showSlotSelector) {
            NavigationStack {
                SlotSelectorView(
                    mode: viewModel.deliveryMode,
                    slots: viewModel.availableSlots,
                    selectedSlotID: viewModel.selectedSlot?.id
                ) { slot in
                    viewModel.setSlot(slot.id)
                    showSlotSelector = false
                }
            }
        }
        .sheet(item: $confirmationOrder) { order in
            CheckoutConfirmationView(order: order, storeName: viewModel.selectedStore?.storeName ?? "Store", paymentAccount: viewModel.selectedPaymentAccount) {
                confirmationOrder = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.store.switchTab(.orders)
                    dismiss()
                }
            }
        }
    }

    private func checkoutCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
            )
    }

    private func priceRow(_ title: String, value: Double, id: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .system(size: 16, weight: .heavy) : .system(size: 15, weight: .medium))
            Spacer()
            Text(AppFormatters.currencyString(value))
                .font(emphasized ? .system(size: 16, weight: .heavy) : .system(size: 15, weight: .medium))
                .accessibilityIdentifier(id)
        }
    }
}

private struct SlotSelectorView: View {
    let mode: DeliveryMode
    let slots: [DeliverySlot]
    let selectedSlotID: String?
    let onSelect: (DeliverySlot) -> Void

    var body: some View {
        List {
            ForEach(slots, id: \.id) { slot in
                Button {
                    onSelect(slot)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.displayLabel)
                                .font(.headline)
                            Text(slot.isAvailable ? (mode == .delivery ? "Delivery available" : "Pickup available") : (mode == .delivery ? "delivery unavailable" : "pickup unavailable"))
                                .font(.caption)
                                .foregroundStyle(slot.isAvailable ? Color.secondary : Color.orange)
                        }
                        Spacer()
                        if slot.fee > 0 {
                            Text(AppFormatters.currencyString(slot.fee))
                                .font(.subheadline.weight(.semibold))
                        }
                        if selectedSlotID == slot.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.instacartGreen)
                        }
                    }
                }
                .disabled(slot.isAvailable == false)
                .accessibilityIdentifier(AccessibilityID.deliverySlotRow(slot.id))
            }
        }
        .navigationTitle(mode == .delivery ? "Delivery slots" : "Pickup slots")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CheckoutConfirmationView: View {
    let order: Order
    let storeName: String
    let paymentAccount: CheckoutPaymentAccount?
    let onViewOrders: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Success header
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.instacartGreen.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.instacartGreen)
                    }

                    Text("Order confirmed!")
                        .font(.system(size: 24, weight: .heavy))

                    Text("\(storeName) · \(order.orderNumber)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    OrderStatusChipView(status: order.orderStatus)
                }
                .padding(.top, 12)

                // Order summary card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Order summary")
                            .font(.system(size: 18, weight: .heavy))
                        Spacer()
                        Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    receiptRow("Subtotal", value: order.pricingSummary.itemSubtotal)
                    receiptRow("Delivery fee", value: order.pricingSummary.deliveryFee)
                    if order.pricingSummary.priorityFee > 0 {
                        receiptRow("Priority fee", value: order.pricingSummary.priorityFee)
                    }
                    receiptRow("Service fee", value: order.pricingSummary.serviceFee)
                    receiptRow("Taxes", value: order.pricingSummary.taxEstimate)
                    receiptRow("Tip", value: order.pricingSummary.tip)
                    if order.pricingSummary.promoDiscount > 0 {
                        receiptRow("Promo discount", value: -order.pricingSummary.promoDiscount)
                    }

                    Divider()

                    HStack {
                        Text("Total")
                            .font(.system(size: 16, weight: .heavy))
                        Spacer()
                        Text(AppFormatters.currencyString(order.pricingSummary.estimatedTotal))
                            .font(.system(size: 16, weight: .heavy))
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))

                // Payment & delivery card
                VStack(alignment: .leading, spacing: 14) {
                    if let account = paymentAccount {
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.instacartGreenDark)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(account.network) \(account.maskedNumber)")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Charged to \(account.name)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.instacartGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.deliverySlot.displayLabel)
                                .font(.system(size: 15, weight: .semibold))
                            Text(order.address.streetLine1)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onViewOrders()
                    } label: {
                        Text("Track order")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.instacartGreen))
                    }
                    .accessibilityIdentifier("checkout_confirmation_button")

                    Button("Done") {
                        onViewOrders()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("checkout_confirmation_done_button")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
    }

    private func receiptRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(AppFormatters.currencyString(value))
                .font(.system(size: 15, weight: .medium))
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
