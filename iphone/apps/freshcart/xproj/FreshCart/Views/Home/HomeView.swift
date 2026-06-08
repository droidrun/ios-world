import SwiftUI

struct HomeView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var browseViewModel: BrowseViewModel
    @ObservedObject var searchViewModel: SearchViewModel

    @State private var selectedStore: Store?
    @State private var showPromoSheet = true
    @State private var selectedServiceMode: ServiceMode? = .grocery
    @State private var selectedMarketplaceFilter: MarketplaceFilter = .none

    private let storeGrid = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                darkGreenHeader

                heroBanner
                    .padding(.bottom, 6)

                serviceCategoryRow
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 14)

                if !buyAgainProducts.isEmpty {
                    buyAgainSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                if homeViewModel.categories.isEmpty == false {
                    categoryQuickLinks
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                if homeViewModel.recommendedProducts.isEmpty == false {
                    recommendedSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                marketplaceChips
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                sectionHeader("Popular near you")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                storesGrid
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: showPromoSheet ? 12 : 0) {
            if showPromoSheet {
                promoSheet
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showPromoSheet)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedStore) { _ in
            BrowseView(viewModel: browseViewModel, initialCategoryID: nil)
        }
    }

    // MARK: - Dark Green Header

    private var darkGreenHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    homeViewModel.store.switchTab(.account)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.instacartGreen)
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(deliveryAddressTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            Text(deliveryTimeText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                InsetIconButton(systemImage: "bell", filled: true) {
                    homeViewModel.store.switchTab(.account)
                }
                InsetIconButton(systemImage: "cart", filled: true) {
                    homeViewModel.viewCart()
                }
                .overlay(alignment: .topTrailing) {
                    if cartItemCount > 0 {
                        Text("\(cartItemCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.instacartGreen))
                            .offset(x: 4, y: -4)
                    }
                }
            }

            // Search bar
            Button {
                homeViewModel.searchGroceries()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Search products and stores")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(Color.instacartGreenDark)
    }

    // MARK: - Hero Banner (Full-Width)

    private var heroBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Primary hero — full-width
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.50, blue: 0.03),
                                    Color(red: 0.0, green: 0.35, blue: 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)

                    // Decorative circles
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .offset(x: 220, y: 60)

                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 120, height: 120)
                        .offset(x: -30, y: -30)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("FreshCart+")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.2)))

                        Text("$0 delivery fee\non all orders")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text("You've saved \(AppFormatters.currencyString(homeViewModel.store.state.membershipStatus.savingsToDate)) with FreshCart+")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(16)
                }
                .frame(width: UIScreen.main.bounds.width)
                .clipShape(Rectangle())

                // Secondary banner
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.instacartCream)
                        .frame(height: 140)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.instacartGreen)
                            Text("$9.99/mo")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.primary.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.06)))

                        Text("Save with\nFreshCart+")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text("$0 delivery fee on every order")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                }
                .frame(width: UIScreen.main.bounds.width - 60)
                .clipShape(Rectangle())
            }
        }
    }

    // MARK: - Service Category Row (Green tiles)

    private var serviceCategoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ServiceMode.allCases, id: \.self) { mode in
                    Button {
                        handleServiceSelection(mode)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selectedServiceMode == mode ? Color.instacartGreenDark : Color.white)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(selectedServiceMode == mode ? .clear : Color.black.opacity(0.06), lineWidth: 1)
                                    )
                                VStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(selectedServiceMode == mode ? .white : Color.instacartGreenDark)
                                    Text("\(storeCount(for: mode))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(selectedServiceMode == mode ? .white.opacity(0.7) : .secondary)
                                }
                            }
                            Text(mode.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Buy It Again Section

    private var buyAgainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Buy it again")
                    .font(.system(size: 20, weight: .heavy))
                Spacer()
                Button("See all") {
                        homeViewModel.store.switchTab(.search)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.instacartGreen)
                    .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(buyAgainProducts.prefix(6)) { product in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                ProductArtView(product: product, cornerRadius: 14)
                                    .frame(width: 136, height: 136)

                                Button {
                                    homeViewModel.store.addToCart(productID: product.id)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Circle().fill(Color.instacartGreen))
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                            }

                            Text(AppFormatters.currencyString(product.price))
                                .font(.system(size: 15, weight: .bold))

                            Text(product.productName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .frame(width: 136, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Quick Links

    private var categoryQuickLinks: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(homeViewModel.categories) { category in
                    Button {
                        searchViewModel.browseCategory(category.id)
                        homeViewModel.store.switchTab(.search)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color.instacartGreen.opacity(0.08))
                                    .frame(width: 56, height: 56)
                                Image(systemName: category.systemImage)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.instacartGreenDark)
                            }
                            Text(category.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: 70)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recommended For You

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended for you")
                    .font(.system(size: 20, weight: .heavy))
                Spacer()
                Button("See all") {
                    homeViewModel.store.switchTab(.search)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.instacartGreen)
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(homeViewModel.recommendedProducts.prefix(6)) { product in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                ProductArtView(product: product, cornerRadius: 14)
                                    .frame(width: 136, height: 136)

                                Button {
                                    homeViewModel.store.addToCart(productID: product.id)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Circle().fill(Color.instacartGreen))
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                            }

                            Text(AppFormatters.currencyString(product.price))
                                .font(.system(size: 15, weight: .bold))

                            Text(product.productName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .frame(width: 136, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var marketplaceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(.offers, title: "Offers", systemImage: "tag.fill")
                filterChip(.pickup, title: "Pickup", systemImage: "storefront")
                filterChip(.ebt, title: "EBT", systemImage: "creditcard.fill")
                filterChip(.noMarkups, title: "No markups", systemImage: "dollarsign")
            }
        }
    }

    private func filterChip(_ filter: MarketplaceFilter, title: String, systemImage: String) -> some View {
        let isActive = selectedMarketplaceFilter == filter
        return Button {
            selectedMarketplaceFilter = isActive ? .none : filter
        } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? Color.instacartGreenDark : Color.white)
            )
            .foregroundStyle(isActive ? .white : .primary)
            .overlay(
                Capsule().stroke(isActive ? .clear : Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .heavy))
    }

    // MARK: - Stores Grid

    private var storesGrid: some View {
        LazyVGrid(columns: storeGrid, spacing: 14) {
            ForEach(filteredStores) { store in
                MarketplaceStoreTile(store: store) {
                    homeViewModel.selectStore(store.id)
                    selectedStore = store
                }
            }

            Button {
                selectedServiceMode = nil
                selectedMarketplaceFilter = .none
                homeViewModel.store.postInlineStatusMessage("Showing all stores.")
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.instacartGreenDark)
                            .frame(width: 56, height: 56)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Show all")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("\(homeViewModel.stores.count) stores")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Color.clear.frame(height: 14)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Promo Sheet (Bottom)

    private var promoSheet: some View {
        let promo = homeViewModel.promotions.first
        return ZStack(alignment: .topLeading) {
            Circle()
                .fill(Color.white.opacity(0.26))
                .frame(width: 180, height: 180)
                .offset(x: -70, y: -90)

            Circle()
                .fill(Color(red: 1.0, green: 0.94, blue: 0.34))
                .frame(width: 140, height: 140)
                .offset(x: 200, y: 100)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(promo?.badgeText ?? "Limited time")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.08)))

                    Spacer()

                    Button {
                        dismissPromo()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.black.opacity(0.74)))
                    }
                    .buttonStyle(.plain)
                }

                Text(promo?.title ?? "$0 delivery fees on your next 3 orders")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(promo?.subtitle ?? "Svc fees apply. 3 orders in 14 days. Excl restaurants. Terms apply.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .bottom) {
                    Button("Got It!") {
                        dismissPromo()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 110, height: 40)
                    .background(Capsule().fill(Color.instacartGreenDark))
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.instacartGreenDark)
                        Text("3 eligible orders")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.6))
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 195)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.instacartYellow))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)
    }

    // MARK: - Data

    private var filteredStores: [Store] {
        homeViewModel.stores.filter { store in
            serviceMatches(store) && marketplaceFilterMatches(store)
        }
    }

    private func serviceMatches(_ store: Store) -> Bool {
        switch selectedServiceMode {
        case nil:
            return true
        case .grocery:
            return ["costco", "aldi", "giant_eagle", "market_district", "walmart", "whole_foods", "trader_joes", "jewel_osco", "sprouts", "sams_club"].contains(store.id)
        case .express:
            return ["costco", "petco", "giant_eagle", "whole_foods", "sams_club", "walmart"].contains(store.id)
        case .retail:
            return ["target", "cvs", "lowes", "dollar_tree", "michaels", "family_dollar", "petco", "walgreens", "walmart"].contains(store.id)
        case .restaurants:
            return ["panera", "chipotle"].contains(store.id)
        }
    }

    private func marketplaceFilterMatches(_ store: Store) -> Bool {
        switch selectedMarketplaceFilter {
        case .none:
            return true
        case .offers:
            return ["petco", "cvs", "lowes", "dollar_tree", "michaels", "walgreens", "walmart"].contains(store.id)
        case .pickup:
            return store.supportsPickup
        case .ebt:
            return ["aldi", "giant_eagle", "family_dollar", "walmart", "jewel_osco"].contains(store.id)
        case .noMarkups:
            return ["cvs", "lowes", "dollar_tree", "michaels", "walgreens"].contains(store.id)
        }
    }

    private func handleServiceSelection(_ mode: ServiceMode) {
        selectedServiceMode = selectedServiceMode == mode ? nil : mode
    }

    private func storeCount(for mode: ServiceMode) -> Int {
        homeViewModel.stores.filter { store in
            switch mode {
            case .grocery:
                return ["costco", "aldi", "giant_eagle", "market_district", "walmart", "whole_foods", "trader_joes", "jewel_osco", "sprouts", "sams_club"].contains(store.id)
            case .express:
                return ["costco", "petco", "giant_eagle", "whole_foods", "sams_club", "walmart"].contains(store.id)
            case .retail:
                return ["target", "cvs", "lowes", "dollar_tree", "michaels", "family_dollar", "petco", "walgreens", "walmart"].contains(store.id)
            case .restaurants:
                return ["panera", "chipotle"].contains(store.id)
            }
        }.count
    }

    private var buyAgainProducts: [Product] {
        homeViewModel.store.productsForSelectedStore.filter { $0.isBuyAgain }
    }

    private var deliveryAddressTitle: String {
        if let address = homeViewModel.selectedAddress {
            let street = address.streetLine1
            if let commaRange = street.range(of: ",") {
                return String(street[street.startIndex..<commaRange.lowerBound])
            }
            return street
        }
        return "Set delivery address"
    }

    private var deliveryTimeText: String {
        if let store = homeViewModel.selectedStore {
            return "Delivery \(store.dynamicETA)"
        }
        return "Delivery in 45 min"
    }

    private var cartItemCount: Int {
        homeViewModel.store.state.cartItems.reduce(0) { $0 + $1.quantity }
    }

    private func dismissPromo() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showPromoSheet = false
        }
    }
}

private enum ServiceMode: CaseIterable {
    case grocery
    case restaurants
    case express
    case retail

    var title: String {
        switch self {
        case .grocery:
            return "Grocery"
        case .restaurants:
            return "Restaurants"
        case .express:
            return "Express"
        case .retail:
            return "Retail"
        }
    }

    var icon: String {
        switch self {
        case .grocery:
            return "leaf.fill"
        case .restaurants:
            return "fork.knife"
        case .express:
            return "bolt.fill"
        case .retail:
            return "bag.fill"
        }
    }
}

private enum MarketplaceFilter {
    case none
    case offers
    case pickup
    case ebt
    case noMarkups
}
