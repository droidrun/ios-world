import SwiftUI

struct BrowseView: View {
    @ObservedObject var viewModel: BrowseViewModel
    let initialCategoryID: String?

    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var showPricingSheet = false
    @State private var showAllPrimaryProducts = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                bodySection
            }
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if cartCount > 0 {
                FloatingCartBar(subtotal: subtotal, cartCount: cartCount) {
                    viewModel.store.switchTab(.cart)
                }
            }
        }
        .sheet(isPresented: $showPricingSheet) {
            StorePricingSheet(store: selectedStore, slot: viewModel.store.selectedSlot)
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product, store: viewModel.store)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.18)))
                }
                .buttonStyle(.plain)

                StoreLogoBadge(store: selectedStore)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedStore.storeName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Button {
                        viewModel.store.switchTab(.account)
                    } label: {
                        Text(membershipButtonTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                ShareLink(item: familyInviteMessage) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }

            Button {
                viewModel.store.switchTab(.search)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(searchPrompt)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 42)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(headerColor)
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()
                Button {
                    showPricingSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Pricing & fees")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.vertical, 8)

            fulfillmentSection

            if allProducts.isEmpty {
                EmptyStateCard(
                    title: "No products loaded for this store",
                    subtitle: "Pick another store below or go back Home to continue shopping.",
                    accessibilityIdentifier: "browse_empty_state"
                )
            } else {
                shortcutsRow
                primarySection
                if secondaryProducts.isEmpty == false {
                    secondarySection
                }
                if nearbyStores.isEmpty == false {
                    nearbyStoresSection
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 28)
        .background(Color.instacartBackground)
    }

    private var shortcutsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(shortcutSpecs) { shortcut in
                    let product = product(withID: shortcut.productID)
                    StorefrontShortcutTile(
                        title: shortcut.title,
                        subtitle: shortcut.subtitle,
                        product: product,
                        systemImage: shortcut.systemImage
                    ) {
                        handleShortcutTap(shortcut, product: product)
                    }
                }
            }
        }
    }

    private var primarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(primarySectionTitle)
                    .font(.system(size: 20, weight: .heavy))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer()
                if primaryProducts.count > 3 {
                    Button(showAllPrimaryProducts ? "Show less" : "Show all") {
                        showAllPrimaryProducts.toggle()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .underline()
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(displayedPrimaryProducts) { product in
                        StorefrontProductCard(
                            product: product,
                            badgeText: primaryBadge(for: product)
                        ) {
                            selectedProduct = product
                        } onAdd: {
                            viewModel.addToCart(productID: product.id)
                        }
                    }
                }
            }
        }
    }

    private var secondarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(secondarySectionTitle)
                .font(.system(size: 20, weight: .heavy))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(secondaryProducts) { product in
                        RelatedProductCard(product: product) {
                            selectedProduct = product
                        } onAdd: {
                            viewModel.addToCart(productID: product.id)
                        }
                    }
                }
            }
        }
    }

    private var nearbyStoresSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Switch stores")
                .font(.system(size: 20, weight: .heavy))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(nearbyStores) { store in
                        BrowseStoreSwitchCard(store: store) {
                            selectedProduct = nil
                            showAllPrimaryProducts = false
                            viewModel.selectStore(store.id)
                        }
                    }
                }
            }
        }
    }

    private var fulfillmentSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 14) {
                modeButtonsRow
                Spacer(minLength: 0)
                fulfillmentSummary
            }
            VStack(alignment: .leading, spacing: 14) {
                modeButtonsRow
                fulfillmentSummary
            }
        }
    }

    private var modeButtonsRow: some View {
        HStack(spacing: 8) {
            modeButton(
                mode: .delivery,
                title: "Delivery",
                systemImage: "bag",
                isAvailable: selectedStore.supportsDelivery
            )
            modeButton(
                mode: .pickup,
                title: "Pickup",
                systemImage: "storefront",
                isAvailable: selectedStore.supportsPickup
            )
        }
    }

    private var fulfillmentSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: fulfillmentSystemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.instacartGreen)
            Text(fulfillmentEtaText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.instacartGreenDark)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func modeButton(
        mode: DeliveryMode,
        title: String,
        systemImage: String,
        isAvailable: Bool
    ) -> some View {
        let isSelected = viewModel.store.state.deliveryMode == mode
        return Button {
            viewModel.setMode(mode)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isAvailable ? .primary : .secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                Capsule().fill(isSelected ? Color.white : Color.white.opacity(0.72))
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.instacartGreen : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isAvailable ? 1 : 0.72)
        }
        .buttonStyle(.plain)
    }

    private func handleShortcutTap(_ shortcut: StorefrontShortcutSpec, product: Product?) {
        if shortcut.opensDeals {
            showAllPrimaryProducts = true
            return
        }

        if let product {
            selectedProduct = product
        } else {
            viewModel.store.postInlineStatusMessage("Browse featured products below.")
        }
    }

    private func product(withID productID: String?) -> Product? {
        guard let productID else { return nil }
        return viewModel.store.product(with: productID)
    }

    private func productMatching(_ keywords: [String]) -> Product? {
        allProducts.first { product in
            let haystack = "\(product.productName) \(product.brand)".lowercased()
            return keywords.contains { haystack.contains($0) }
        }
    }

    private func firstProduct(in categoryID: String) -> Product? {
        allProducts.first(where: { $0.categoryID == categoryID })
    }

    private func prioritizedProducts(
        matching keywords: [String],
        fallbackProducts: [Product]? = nil,
        limit: Int = 6
    ) -> [Product] {
        let source = fallbackProducts ?? allProducts
        var matches: [Product] = []

        for keyword in keywords {
            if let product = source.first(where: {
                let haystack = "\($0.productName) \($0.brand)".lowercased()
                return haystack.contains(keyword)
            }), matches.contains(where: { $0.id == product.id }) == false {
                matches.append(product)
            }
        }

        for product in source where matches.contains(where: { $0.id == product.id }) == false {
            matches.append(product)
            if matches.count >= limit {
                break
            }
        }

        return Array(matches.prefix(limit))
    }

    private func remainingProducts(excluding productIDs: Set<String>, limit: Int = 4) -> [Product] {
        Array(allProducts.filter { productIDs.contains($0.id) == false }.prefix(limit))
    }

    private var selectedStore: Store {
        viewModel.selectedStore ?? viewModel.store.stores.first ?? Store(
            id: "fallback",
            storeName: "Store",
            tagline: "",
            addressLine: "",
            etaText: "",
            distanceMiles: 0,
            supportsDelivery: true,
            supportsPickup: false,
            deliveryFee: 0,
            pickupFee: 0,
            accentColorHex: "#000000"
        )
    }

    private var allProducts: [Product] {
        viewModel.products(for: initialCategoryID)
    }

    private var availableCategories: [ProductCategory] {
        viewModel.categories.filter { category in
            allProducts.contains(where: { $0.categoryID == category.id })
        }
    }

    private var shortcutSpecs: [StorefrontShortcutSpec] {
        switch selectedStore.id {
        case "costco":
            return [
                StorefrontShortcutSpec(id: "deals", title: "Flyers", subtitle: nil, productID: nil, systemImage: "doc.text.fill", opensDeals: true),
                StorefrontShortcutSpec(id: "signature", title: "Kirkland Signature", subtitle: nil, productID: productMatching(["kirkland"])?.id, systemImage: "seal.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "produce", title: "Produce", subtitle: nil, productID: productMatching(["grapes", "strawberr"])?.id, systemImage: "leaf.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "frozen", title: "Frozen", subtitle: nil, productID: productMatching(["nuggets", "salmon, 6 oz"])?.id, systemImage: "snowflake", opensDeals: false),
                StorefrontShortcutSpec(id: "warehouse", title: "Warehouse Finds", subtitle: nil, productID: productMatching(["protein", "paper towel", "cold brew"])?.id, systemImage: "magnifyingglass", opensDeals: false)
            ]
        case "aldi":
            return [
                StorefrontShortcutSpec(id: "deals", title: "Weekly finds", subtitle: nil, productID: nil, systemImage: "tag.fill", opensDeals: true),
                StorefrontShortcutSpec(id: "produce", title: "Organic produce", subtitle: nil, productID: productMatching(["banana", "spinach", "avocado"])?.id, systemImage: "leaf.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "dairy", title: "Dairy & eggs", subtitle: nil, productID: productMatching(["egg", "yogurt"])?.id, systemImage: "takeoutbag.and.cup.and.straw.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "pantry", title: "Pantry value", subtitle: nil, productID: productMatching(["marinara", "penne"])?.id, systemImage: "cabinet.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "bakery", title: "Bakery", subtitle: nil, productID: productMatching(["sourdough"])?.id, systemImage: "birthday.cake.fill", opensDeals: false)
            ]
        case "target":
            return [
                StorefrontShortcutSpec(id: "deals", title: "Top deals", subtitle: nil, productID: nil, systemImage: "star.fill", opensDeals: true),
                StorefrontShortcutSpec(id: "cleaning", title: "Cleaning", subtitle: nil, productID: productMatching(["cleaner", "laundry", "soap"])?.id, systemImage: "sparkles", opensDeals: false),
                StorefrontShortcutSpec(id: "storage", title: "Storage", subtitle: nil, productID: productMatching(["storage"])?.id, systemImage: "shippingbox.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "snacks", title: "Snacks", subtitle: nil, productID: productMatching(["snack"])?.id, systemImage: "takeoutbag.and.cup.and.straw.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "home", title: "Home refresh", subtitle: nil, productID: productMatching(["candle", "blanket"])?.id, systemImage: "lamp.table.fill", opensDeals: false)
            ]
        case "panera":
            return [
                StorefrontShortcutSpec(id: "featured", title: "Lunch picks", subtitle: nil, productID: nil, systemImage: "star.fill", opensDeals: true),
                StorefrontShortcutSpec(id: "soup", title: "Soups", subtitle: nil, productID: productMatching(["soup"])?.id, systemImage: "takeoutbag.and.cup.and.straw.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "salad", title: "Salads", subtitle: nil, productID: productMatching(["salad"])?.id, systemImage: "leaf.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "sandwich", title: "Sandwiches", subtitle: nil, productID: productMatching(["sandwich"])?.id, systemImage: "fork.knife", opensDeals: false),
                StorefrontShortcutSpec(id: "bakery", title: "Bakery", subtitle: nil, productID: productMatching(["croissant"])?.id, systemImage: "birthday.cake.fill", opensDeals: false)
            ]
        case "chipotle":
            return [
                StorefrontShortcutSpec(id: "featured", title: "Popular meals", subtitle: nil, productID: nil, systemImage: "star.fill", opensDeals: true),
                StorefrontShortcutSpec(id: "bowls", title: "Bowls", subtitle: nil, productID: productMatching(["bowl"])?.id, systemImage: "takeoutbag.and.cup.and.straw.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "burritos", title: "Burritos", subtitle: nil, productID: productMatching(["burrito"])?.id, systemImage: "fork.knife", opensDeals: false),
                StorefrontShortcutSpec(id: "sides", title: "Sides", subtitle: nil, productID: productMatching(["chips", "queso"])?.id, systemImage: "cabinet.fill", opensDeals: false),
                StorefrontShortcutSpec(id: "drinks", title: "Drinks", subtitle: nil, productID: productMatching(["coca-cola"])?.id, systemImage: "waterbottle.fill", opensDeals: false)
            ]
        default:
            var specs = [StorefrontShortcutSpec(id: "deals", title: "Featured", subtitle: nil, productID: nil, systemImage: "star.fill", opensDeals: true)]
            specs.append(contentsOf: availableCategories.prefix(4).map { category in
                StorefrontShortcutSpec(
                    id: category.id,
                    title: category.name,
                    subtitle: nil,
                    productID: firstProduct(in: category.id)?.id,
                    systemImage: category.systemImage,
                    opensDeals: false
                )
            })
            return specs
        }
    }

    private var primaryProducts: [Product] {
        switch selectedStore.id {
        case "costco":
            return prioritizedProducts(matching: ["madegood", "cinnamon", "nuggets", "protein", "water", "paper towel"])
        case "aldi":
            return prioritizedProducts(matching: ["banana", "egg", "spinach", "sourdough", "marinara", "yogurt"])
        case "target":
            return prioritizedProducts(matching: ["paper towels", "laundry", "storage", "soap", "snack", "candle"])
        case "petco":
            return prioritizedProducts(matching: ["dog food", "cat litter", "treat", "toy"], limit: 4)
        case "panera":
            return prioritizedProducts(matching: ["soup", "salad", "sandwich", "croissant", "tea"], limit: 5)
        case "chipotle":
            return prioritizedProducts(matching: ["bowl", "burrito", "chips", "queso", "coca-cola"], limit: 5)
        default:
            let featured = allProducts.filter { $0.isRecommended || $0.isOnSale || $0.isBuyAgain }
            return Array((featured.isEmpty ? allProducts : featured).prefix(6))
        }
    }

    private var displayedPrimaryProducts: [Product] {
        showAllPrimaryProducts ? primaryProducts : Array(primaryProducts.prefix(3))
    }

    private var secondaryProducts: [Product] {
        let excluded = Set(primaryProducts.map(\.id))
        switch selectedStore.id {
        case "costco":
            let source = allProducts.filter { excluded.contains($0.id) == false }
            return prioritizedProducts(matching: ["grapes", "strawberr", "blueberr", "raspberr"], fallbackProducts: source, limit: 4)
        case "aldi":
            let source = allProducts.filter { excluded.contains($0.id) == false }
            return prioritizedProducts(matching: ["salad", "sparkling", "chicken", "avocado"], fallbackProducts: source, limit: 4)
        case "target":
            let source = allProducts.filter { excluded.contains($0.id) == false }
            return prioritizedProducts(matching: ["cleaner", "soap", "blanket", "storage"], fallbackProducts: source, limit: 4)
        case "panera":
            let source = allProducts.filter { excluded.contains($0.id) == false }
            return prioritizedProducts(matching: ["tea", "croissant", "salad"], fallbackProducts: source, limit: 4)
        case "chipotle":
            let source = allProducts.filter { excluded.contains($0.id) == false }
            return prioritizedProducts(matching: ["chips", "queso", "coca-cola"], fallbackProducts: source, limit: 4)
        default:
            return remainingProducts(excluding: excluded)
        }
    }

    private var nearbyStores: [Store] {
        let preferredIDs = ["aldi", "target", "petco", "panera", "chipotle", "giant_eagle", "cvs", "market_district", "family_dollar"]
        var stores: [Store] = []

        for storeID in preferredIDs where storeID != selectedStore.id {
            if let store = viewModel.store.store(with: storeID),
               stores.contains(where: { $0.id == store.id }) == false {
                stores.append(store)
            }
        }

        for store in viewModel.store.stores where store.id != selectedStore.id {
            if stores.contains(where: { $0.id == store.id }) == false {
                stores.append(store)
            }
        }

        return Array(stores.prefix(5))
    }

    private var primarySectionTitle: String {
        switch selectedStore.id {
        case "costco":
            let cal = Calendar.current
            let now = Date()
            let startDay = cal.component(.day, from: now) <= 15 ? 1 : 16
            var startComps = cal.dateComponents([.year, .month], from: now)
            startComps.day = startDay
            let endDay = startDay == 1 ? 15 : cal.range(of: .day, in: .month, for: now)?.upperBound.advanced(by: -1) ?? 30
            let monthStr = now.formatted(.dateTime.month(.abbreviated))
            return "Flyer deals \(monthStr) \(startDay)-\(endDay)"
        case "aldi":
            return "ALDI weekly picks"
        case "target":
            return "Everyday home essentials"
        case "petco":
            return "Pet favorites"
        case "panera":
            return "Panera lunch favorites"
        case "chipotle":
            return "Chipotle best sellers"
        default:
            return "\(selectedStore.storeName) highlights"
        }
    }

    private var secondarySectionTitle: String {
        switch selectedStore.id {
        case "costco":
            return "Fresh fruit"
        case "aldi":
            return "Produce and dairy"
        case "target":
            return "Quick home restocks"
        case "petco":
            return "More pet care"
        case "panera":
            return "Bakery and drinks"
        case "chipotle":
            return "Sides and drinks"
        default:
            return "Shop more from \(selectedStore.storeName)"
        }
    }

    private func primaryBadge(for product: Product) -> String? {
        if product.isOrganic {
            return "Organic"
        }
        if let firstTag = product.dietaryTags.first {
            return firstTag
        }
        if selectedStore.id == "costco", product.brand.lowercased().contains("kirkland") {
            return "Store choice"
        }
        if selectedStore.id == "target", product.brand.lowercased().contains("brightroom") {
            return "Popular"
        }
        return nil
    }

    private var headerColor: Color {
        Color(storeHex: selectedStore.accentColorHex)
    }

    private var membershipButtonTitle: String {
        switch selectedStore.id {
        case "costco":
            return "+ Add membership"
        case "aldi":
            return "Save with FreshCart+"
        case "target":
            return "See store perks"
        case "panera", "chipotle":
            return "Offers & rewards"
        default:
            return "Store perks"
        }
    }

    private var searchPrompt: String {
        switch selectedStore.id {
        case "costco":
            return "Try \"best veggies to roast\""
        case "aldi":
            return "Search low-price staples"
        case "target":
            return "Search home, snacks, and more"
        case "petco":
            return "Search food, litter, and toys"
        case "panera":
            return "Search soups, salads, and sandwiches"
        case "chipotle":
            return "Search bowls, burritos, and sides"
        default:
            return "Search \(selectedStore.storeName)"
        }
    }

    private var subtotal: Double {
        viewModel.store.cartSummary().itemSubtotal
    }

    private var cartCount: Int {
        viewModel.store.state.cartItems.reduce(0) { $0 + $1.quantity }
    }

    private var fulfillmentSystemImage: String {
        viewModel.store.state.deliveryMode == .delivery ? "bolt.fill" : "storefront"
    }

    private var fulfillmentEtaText: String {
        if viewModel.store.state.deliveryMode == .pickup {
            return "Pickup \(selectedStore.dynamicETA)"
        }
        return "Delivery \(selectedStore.dynamicETA)"
    }

    private var familyInviteMessage: String {
        "Help me shop my FreshCart cart from \(selectedStore.storeName)."
    }
}

private struct StorefrontShortcutSpec: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let productID: String?
    let systemImage: String
    let opensDeals: Bool
}

private struct BrowseStoreSwitchCard: View {
    let store: Store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                StoreLogoBadge(store: store)
                    .frame(width: 80, height: 80)
                Text(store.storeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(store.dynamicETA)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct StorePricingSheet: View {
    let store: Store
    let slot: DeliverySlot?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Pricing & fees") {
                    priceRow("Delivery fee", value: slot?.fee ?? store.deliveryFee)
                    priceRow("Pickup fee", value: store.pickupFee)
                    priceRow("Estimated service fee", value: 2.99)
                }

                Section("Store details") {
                    Text(store.storeName)
                    Text(store.addressLine)
                    Text(store.tagline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pricing & fees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func priceRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(AppFormatters.currencyString(value))
                .foregroundStyle(.secondary)
        }
    }
}

private extension Color {
    init(storeHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
