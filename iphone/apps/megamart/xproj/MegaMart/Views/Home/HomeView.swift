import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MegaMartStore

    private var firstName: String {
        store.state.userProfile.name.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var featuredProducts: [Product] {
        prioritizedProducts(
            ids: [
                "airpods_pro_108",
                "instant_pot_090",
                "stanley_tumbler_119",
                "face_moisturizer_033",
                "crocs_classic_116",
                "paper_towels_046"
            ]
        )
    }

    private var buyAgainProducts: [Product] {
        let recent = Array(store.buyAgainProducts.prefix(6))
        if !recent.isEmpty {
            return recent
        }

        return prioritizedProducts(
            ids: [
                "paper_towels_046",
                "sunscreen_lotion_036",
                "face_moisturizer_033",
                "dog_treats_065",
                "water_bottle_074",
                "led_desk_lamp_049"
            ]
        )
    }

    private var beautyProducts: [Product] {
        prioritizedProducts(
            ids: [
                "face_moisturizer_033",
                "vitamin_c_serum_034",
                "sunscreen_lotion_036",
                "lip_balm_pack_037",
                "cleansing_balm_038",
                "face_mask_097"
            ]
        )
    }

    private var petProducts: [Product] {
        prioritizedProducts(
            ids: [
                "dog_treats_065",
                "dental_chews_072",
                "dog_food_105",
                "cat_litter_066",
                "cat_tree_121",
                "cat_toy_104"
            ]
        )
    }

    private var fitnessOutdoorProducts: [Product] {
        prioritizedProducts(
            ids: [
                "running_shoes_025",
                "adidas_ultraboost_114",
                "stanley_tumbler_119",
                "yoga_mat_073",
                "water_bottle_074",
                "dumbbell_set_078"
            ]
        )
    }

    private var gamingProducts: [Product] {
        prioritizedProducts(
            ids: [
                "ps5_digital_bundle_081",
                "ps5_charging_station_083",
                "ps5_controller_084",
                "ps5_headset_085",
                "ps5_external_storage_086",
                "ps5_cooling_stand_087"
            ]
        )
    }

    private var dealOfTheDayProducts: [Product] {
        prioritizedProducts(ids: SeedData.dealOfTheDayProductIDs)
    }

    private var recommendedProducts: [Product] {
        prioritizedProducts(
            ids: [
                "kindle_paperwhite_109",
                "espresso_machine_012",
                "smart_thermostat_091",
                "wireless_earbuds_088",
                "ring_doorbell_113",
                "webcam_100"
            ]
        )
    }

    private var primeHeroProduct: Product? {
        store.product(for: "ps5_digital_bundle_081")
    }

    private var spotlightProduct: Product? {
        store.product(for: "running_shoes_025")
    }

    private var primaryAddressText: String {
        store.selectedAddress?.formattedLines.joined(separator: ", ") ?? store.state.userProfile.defaultDeliveryLocation
    }

    private var activeOrderCount: Int {
        store.activeOrders.count
    }

    private var savedItemCount: Int {
        store.state.savedItems.count
    }

    private func prioritizedProducts(ids: [String]) -> [Product] {
        ids.compactMap(store.product(for:))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                deliveryAddressStrip
                topShortcutRow
                signInPanel
                productShelf(
                    title: "Popular with fast delivery",
                    subtitle: "Top picks across kitchen, household, beauty, and more.",
                    products: featuredProducts
                )
                heroRail
                dealOfTheDaySection
                productShelf(
                    title: "Buy again",
                    subtitle: "Items from recent orders and essentials you reorder often.",
                    products: buyAgainProducts
                )
                productShelf(
                    title: "Recommended for you",
                    subtitle: "Based on your browsing history and past purchases.",
                    products: recommendedProducts
                )
                productShelf(
                    title: "Skincare & beauty picks",
                    subtitle: "Serums, sunscreen, and daily essentials for your routine.",
                    products: beautyProducts
                )
                sponsoredBanner
                productShelf(
                    title: "Pet favorites",
                    subtitle: "Treats, food, and supplies your pets will love.",
                    products: petProducts
                )
                productShelf(
                    title: "Fitness & outdoor",
                    subtitle: "Gear up for your next run, workout, or weekend hike.",
                    products: fitnessOutdoorProducts
                )
                productShelf(
                    title: "Gaming finds",
                    subtitle: "Console bundles, accessories, and add-ons ready to ship.",
                    products: gamingProducts
                )

                if !store.recentlyViewedProducts.isEmpty {
                    productShelf(
                        title: "Keep shopping for",
                        subtitle: "Your recent searches and viewed items stay here for quick access.",
                        products: Array(store.recentlyViewedProducts.prefix(6))
                    )
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
    }

    private var deliveryAddressStrip: some View {
        NavigationLink {
            ManageAddressesView()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14, weight: .semibold))
                Text("Deliver to \(firstName) - \(store.selectedAddress?.city ?? "San Francisco") \(store.selectedAddress?.postalCode ?? "94107")")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.black.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 181 / 255, green: 219 / 255, blue: 213 / 255))
        }
        .buttonStyle(.plain)
    }

    private var topShortcutRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                shortcutPill(title: "Essentials", query: "essentials")
                shortcutPill(title: "Deals", query: "deals")
                shortcutPill(title: "Beauty", query: "beauty")
                shortcutPill(title: "Groceries", query: "groceries")
                shortcutPill(title: "Prime", query: "prime")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(MegaMartTheme.headerAccent)
    }

    private func shortcutPill(title: String, query: String) -> some View {
        Button {
            store.navigateToSearch(query: query)
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.7))
                        .overlay(
                            Capsule()
                                .stroke(.black.opacity(0.15), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var heroRail: some View {
        Group {
            if let primeHeroProduct, let spotlightProduct {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        primeHeroCard(product: primeHeroProduct)
                        spotlightCard(product: spotlightProduct)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func primeHeroCard(product: Product) -> some View {
        NavigationLink {
            ProductDetailView(productID: product.id)
        } label: {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 18 / 255, green: 99 / 255, blue: 240 / 255), Color(red: 0 / 255, green: 74 / 255, blue: 173 / 255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 286, height: 280)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prime picks for game night")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)

                        Text("Fast delivery on consoles, storage, and must-have accessories.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 10) {
                            Text("See deal")
                                .font(.system(size: 15, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(MegaMartTheme.amazonYellow)
                                )
                                .foregroundStyle(.black)

                            Text(Formatters.currency(product.price))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        MegaMartProductArtwork(product: product)
                            .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 180)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                    }
                    .padding(20)
                }
        }
        .buttonStyle(.plain)
    }

    private func spotlightCard(product: Product) -> some View {
        NavigationLink {
            ProductDetailView(productID: product.id)
        } label: {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 96 / 255, green: 82 / 255, blue: 58 / 255), Color(red: 144 / 255, green: 112 / 255, blue: 74 / 255)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 172, height: 280)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New from \(product.brand)")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        Text("Training ready")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text(Formatters.currency(product.price))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        MegaMartProductArtwork(product: product)
                            .frame(maxWidth: .infinity, minHeight: 144, maxHeight: 156)
                            .padding(.horizontal, 10)

                        Text("Shop shoes")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.16))
                            )
                            .foregroundStyle(.white)
                    }
                    .padding(18)
                }
        }
        .buttonStyle(.plain)
    }

    private var sponsoredBanner: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                sponsoredBannerWide
                    .frame(minWidth: 360)

                sponsoredBannerCompact
            }

            Label("Sponsored", systemImage: "info.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 18)
    }

    private var sponsoredBannerWide: some View {
        HStack(spacing: 14) {
            sponsoredCopyBlock
                .frame(maxWidth: .infinity, alignment: .leading)

            sponsoredBrandCard(compact: false)

            sponsoredCTAButton(compact: false)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(sponsoredBannerBackground)
    }

    private var sponsoredBannerCompact: some View {
        VStack(alignment: .leading, spacing: 12) {
            sponsoredCopyBlock

            HStack(alignment: .center, spacing: 12) {
                sponsoredBrandCard(compact: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                sponsoredCTAButton(compact: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(sponsoredBannerBackground)
    }

    private var sponsoredCopyBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Up to 100% blowout &\nleak protection")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 206 / 255, green: 79 / 255, blue: 68 / 255))
                .fixedSize(horizontal: false, vertical: true)
            Text("KCWW x Disney")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 206 / 255, green: 79 / 255, blue: 68 / 255))
        }
    }

    private func sponsoredBrandCard(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 8) {
            Text("HUGGIES")
                .font(.system(size: compact ? 22 : 24, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text("little snugglers")
                .font(.system(size: compact ? 13 : 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: compact ? 156 : 164, height: compact ? 80 : 88)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.92))
        )
    }

    private func sponsoredCTAButton(compact: Bool) -> some View {
        Button("SHOP NOW") {
            store.navigateToSearch(query: "deals")
        }
        .font(.system(size: compact ? 16 : 17, weight: .bold))
        .frame(maxWidth: compact ? 132 : nil)
        .padding(.horizontal, compact ? 16 : 22)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red)
        )
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var sponsoredBannerBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 253 / 255, green: 235 / 255, blue: 232 / 255))
    }

    private var dealOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Deals")
                        .font(.system(size: 21, weight: .bold))
                    Text("Top deals updated daily. Quantities are limited.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                DealCountdownView()
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dealOfTheDayProducts.prefix(6)) { product in
                        NavigationLink {
                            ProductDetailView(productID: product.id)
                        } label: {
                            DealProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var signInPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(store.isAuthenticated ? "Welcome back, \(firstName)" : "Sign in for the best experience")
                .font(.system(size: 24, weight: .bold))

            Text(primaryAddressText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if store.isAuthenticated {
                HStack(spacing: 8) {
                    statChip(title: "\(activeOrderCount)", subtitle: "Active")
                    statChip(title: "\(savedItemCount)", subtitle: "Saved")
                    statChip(title: "\(store.cartItemCount)", subtitle: "Cart")
                }

                HStack(spacing: 10) {
                    Button("Your orders") {
                        store.navigateToAccount(.orders)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(MegaMartTheme.amazonYellow)
                    )
                    .foregroundStyle(.black)

                    Button("Your account") {
                        store.setSelectedTab(.account)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(MegaMartTheme.cardBorder, lineWidth: 1.5)
                            )
                    )
                    .foregroundStyle(.primary)
                }
            } else {
                Button("Sign in") {
                    store.navigateToAccount(.auth(.signIn))
                }
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(MegaMartTheme.amazonYellow)
                )
                .foregroundStyle(.black)

                Button("Create account") {
                    store.navigateToAccount(.auth(.createAccount))
                }
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(MegaMartTheme.cardBorder, lineWidth: 1.5)
                        )
                )
                .foregroundStyle(.primary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
        )
        .padding(.horizontal, 18)
    }

    private func productShelf(title: String, subtitle: String, products: [Product]) -> some View {
        Group {
            if !products.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 21, weight: .bold))
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 18)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(products.prefix(6)) { product in
                                CompactProductCard(product: product) {
                                    store.addToCart(product: product, quantity: 1, selectedVariantValues: [:])
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
            }
        }
    }

    private func statChip(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }
}

private struct DealCountdownView: View {
    @State private var timeRemaining: TimeInterval = {
        let calendar = Calendar.current
        let now = Date()
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else { return 0 }
        return max(0, endOfDay.timeIntervalSince(now))
    }()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hoursLeft: Int { Int(timeRemaining) / 3600 }
    private var minutesLeft: Int { (Int(timeRemaining) % 3600) / 60 }
    private var secondsLeft: Int { Int(timeRemaining) % 60 }

    var body: some View {
        HStack(spacing: 4) {
            Text("Ends in")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            timerBlock(String(format: "%02d", hoursLeft))
            Text(":")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
            timerBlock(String(format: "%02d", minutesLeft))
            Text(":")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
            timerBlock(String(format: "%02d", secondsLeft))
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }

    private func timerBlock(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.red)
            )
    }
}

private struct DealProductCard: View {
    let product: Product

    private var claimedPercent: Int {
        min(92, max(45, product.popularityRank * 7 + 38))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 116)
                    .overlay {
                        MegaMartProductArtwork(product: product)
                            .padding(10)
                    }

                Text("Deal of the Day")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.red)
                    )
                    .padding(8)
            }

            if let discountPercent = product.discountPercent {
                Text("\(discountPercent)% off")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.red)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(Formatters.currency(product.price))
                    .font(.system(size: 18, weight: .medium))
                if let originalPrice = product.originalPrice, originalPrice > product.price {
                    Text(Formatters.currency(originalPrice))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }

            Text(product.productName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
                .foregroundStyle(.primary)

            // Claimed bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                        Capsule()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: proxy.size.width * Double(claimedPercent) / 100.0)
                    }
                }
                .frame(height: 8)

                Text("\(claimedPercent)% claimed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 176)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
        )
    }
}

private struct PrimeBenefitsView: View {
    @EnvironmentObject private var store: MegaMartStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 18 / 255, green: 99 / 255, blue: 240 / 255))
                    .frame(height: 220)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Prime")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Fast shipping, streaming, and member-only deals.")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(22)
                    }

                benefitRow(title: "Fast free delivery", detail: "Most eligible items arrive within one or two days.")
                benefitRow(title: "Member deals", detail: "Search and home surfaces highlight member pricing and delivery perks.")
                benefitRow(title: "Shopping perks", detail: "Your home feed highlights reorder picks, gaming deals, and everyday essentials.")

                Button(store.isAuthenticated ? "View your account" : "Sign in to continue") {
                    if store.isAuthenticated {
                        store.setSelectedTab(.account)
                    } else {
                        store.navigateToAccount(.auth(.signIn))
                    }
                }
                .font(.system(size: 20, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(MegaMartTheme.amazonYellow)
                )
                .foregroundStyle(.black)
            }
            .padding(18)
        }
        .background(MegaMartTheme.background)
        .navigationTitle("Prime")
    }

    private func benefitRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
            Text(detail)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
    }
}
