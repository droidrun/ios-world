import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    @ObservedObject var moreViewModel: MoreViewModel

    @State private var showHelp = false
    @State private var showLists = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                accountHeader
                accountBody
            }
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showHelp) {
            HelpCenterView()
        }
        .navigationDestination(isPresented: $showLists) {
            ShoppingListsView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var accountHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text(initials)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.userProfile.firstName) \(viewModel.userProfile.lastName)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(viewModel.membershipStatus.tierName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                NavigationLink {
                    MoreSettingsView(viewModel: moreViewModel)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color.instacartGreenDark)
    }

    // MARK: - Body

    private var accountBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            membershipCard
            quickActionsRow
            addressesCard
            paymentMethodsCard
            savedStoresCard

            if viewModel.savedProducts.isEmpty == false {
                savedItemsCard
            }

            if viewModel.buyAgainProducts.isEmpty == false {
                buyAgainCard
            }

            preferencesCard
            settingsCard
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Membership Card

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.instacartGreen)
                    Text(viewModel.membershipStatus.tierName)
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                NavigationLink {
                    MembershipBenefitsView(membershipStatus: viewModel.membershipStatus)
                } label: {
                    Text("View benefits")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.instacartGreen)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.instacartGreen)
                Text("Saved \(AppFormatters.currencyString(viewModel.membershipStatus.savingsToDate)) this year")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            quickActionTile(icon: "bag", title: "Orders") {
                viewModel.store.switchTab(.orders)
            }
            quickActionTile(icon: "bookmark", title: "Lists") {
                showLists = true
            }
            .accessibilityIdentifier("account_lists_button")
            quickActionTile(icon: "gift", title: "Gift cards") {
                viewModel.store.postInlineStatusMessage("Visit instacart.com to manage gift cards.")
            }
            quickActionTile(icon: "questionmark.circle", title: "Help") {
                showHelp = true
            }
        }
    }

    private func quickActionTile(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.instacartGreenDark)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.instacartGreen.opacity(0.08))
                    )
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Addresses

    private var addressesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Addresses")
                    .font(.system(size: 18, weight: .heavy))
                Spacer()
            }

            ForEach(viewModel.userProfile.addresses) { address in
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.instacartGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(address.label)
                            .font(.system(size: 15, weight: .semibold))
                        Text(address.streetLine1)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if address.id != viewModel.userProfile.addresses.last?.id {
                    Divider()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Payment Methods

    private var paymentMethodsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Payment methods")
                .font(.system(size: 18, weight: .heavy))

            ForEach(viewModel.userProfile.paymentMethods) { paymentMethod in
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text(paymentMethod.label)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Text(paymentMethod.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                if paymentMethod.id != viewModel.userProfile.paymentMethods.last?.id {
                    Divider()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Saved Stores

    private var savedStoresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your stores")
                .font(.system(size: 18, weight: .heavy))

            ForEach(viewModel.savedStores) { store in
                Button {
                    viewModel.selectStore(store.id)
                } label: {
                    HStack(spacing: 12) {
                        StoreLogoBadge(store: store)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.storeName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(store.dynamicETA)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.id == viewModel.activeStoreID {
                            Text("Active")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.instacartGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.instacartGreen.opacity(0.12)))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.storeCard(store.id))

                if store.id != viewModel.savedStores.last?.id {
                    Divider()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Saved Items

    private var savedItemsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Saved items")
                .font(.system(size: 18, weight: .heavy))

            ForEach(viewModel.savedProducts) { product in
                HStack(spacing: 12) {
                    ProductArtView(product: product, cornerRadius: 10)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        Text(product.brand)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button {
                        viewModel.store.addToCart(productID: product.id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.instacartGreen))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
                }

                if product.id != viewModel.savedProducts.last?.id {
                    Divider()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Buy Again

    private var buyAgainCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Buy it again")
                    .font(.system(size: 18, weight: .heavy))
                Spacer()
                Button("See all") {
                    viewModel.store.switchTab(.home)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.instacartGreen)
                .buttonStyle(.plain)
            }

            ForEach(viewModel.buyAgainProducts.prefix(4)) { product in
                Button {
                    viewModel.store.addToCart(productID: product.id)
                } label: {
                    HStack(spacing: 12) {
                        ProductArtView(product: product, cornerRadius: 10)
                            .frame(width: 40, height: 40)
                        Text(product.productName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        Text(AppFormatters.currencyString(product.price))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.instacartGreen)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.addToCart(product.id))

                if product.id != viewModel.buyAgainProducts.prefix(4).last?.id {
                    Divider()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preferences")
                .font(.system(size: 18, weight: .heavy))

            Toggle(isOn: Binding(
                get: { viewModel.userProfile.notificationsEnabled },
                set: { viewModel.toggleNotifications($0) }
            )) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text("Notifications")
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .tint(Color.instacartGreen)

            Divider()

            NavigationLink {
                HelpCenterView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text("Help Center")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 18, weight: .heavy))

            NavigationLink {
                MoreSettingsView(viewModel: moreViewModel)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text("App settings")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("account_settings_link")

            Divider()

            NavigationLink {
                DebugImportView(viewModel: moreViewModel)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "ladybug")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.instacartGreenDark)
                    Text("Debug / import")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("account_debug_import_link")

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(viewModel.userProfile.emailAddress)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Image(systemName: "doc")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                Text(viewModel.sourceLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }

    // MARK: - Helpers

    private var initials: String {
        let first = viewModel.userProfile.firstName.prefix(1)
        let last = viewModel.userProfile.lastName.prefix(1)
        return "\(first)\(last)"
    }
}

private struct HelpCenterView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                helpRow(icon: "clock", title: "How delivery and pickup windows work")
                helpRow(icon: "arrow.2.squarepath", title: "Changing substitutions during shopping")
                helpRow(icon: "star.fill", title: "How FreshCart+ savings apply")
                helpRow(icon: "person.2.fill", title: "Inviting family members to help build a cart")

                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Need more help?")
                        .font(.system(size: 18, weight: .heavy))
                    Text("Response time: usually within a few minutes")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func helpRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.instacartGreen)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.instacartGreen.opacity(0.1)))
            Text(title)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private struct MembershipBenefitsView: View {
    let membershipStatus: MembershipStatus

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(membershipStatus.tierName)
                        .font(.system(size: 24, weight: .heavy))
                    Text("Next billing: \(AppFormatters.shortDate.string(from: membershipStatus.nextBillingDate))")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Included benefits")
                        .font(.system(size: 18, weight: .heavy))

                    ForEach(membershipStatus.benefits, id: \.self) { benefit in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.instacartGreen)
                            Text(benefit)
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white)
                )
            }
            .padding(20)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationTitle("Membership")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ShoppingListsView: View {
    @ObservedObject var viewModel: AccountViewModel

    // Seed list names modelled on Instacart shopping lists
    private let listNames = ["Weekly groceries", "Party supplies", "Household essentials"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.savedProducts.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Color.instacartGreen.opacity(0.5))
                        Text("No saved items yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Bookmark products while shopping to add them here.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    Text("Saved items")
                        .font(.system(size: 20, weight: .heavy))

                    ForEach(viewModel.savedProducts) { product in
                        HStack(spacing: 14) {
                            ProductArtView(product: product, cornerRadius: 12)
                                .frame(width: 60, height: 60)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.productName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(2)
                                Text(product.brand)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Text(AppFormatters.currencyString(product.price))
                                    .font(.system(size: 14, weight: .bold))
                            }

                            Spacer()

                            Button {
                                viewModel.store.addToCart(productID: product.id)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Circle().fill(Color.instacartGreen))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                        )
                    }
                }

                Divider()

                Text("Your lists")
                    .font(.system(size: 20, weight: .heavy))

                ForEach(listNames, id: \.self) { name in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.instacartGreen.opacity(0.10))
                                .frame(width: 44, height: 44)
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.instacartGreenDark)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 15, weight: .semibold))
                            Text("0 items")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                    )
                    .accessibilityIdentifier("shopping_list_row_\(AccessibilityID.slug(name))")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationTitle("Lists")
        .navigationBarTitleDisplayMode(.inline)
    }
}
