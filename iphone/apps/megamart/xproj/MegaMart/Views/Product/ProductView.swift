import SwiftUI

struct StatusChipView: View {
    let status: OrderStatus

    private var backgroundColor: Color {
        switch status {
        case .ordered, .preparingForShipment:
            return .orange
        case .shipped, .outForDelivery:
            return .blue
        case .delivered:
            return .green
        case .canceled:
            return .red
        case .returned:
            return .gray
        }
    }

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(backgroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(backgroundColor.opacity(0.12))
            )
            .accessibilityIdentifier("order_status_chip_\(AccessibilityID.slug(status.title))")
    }
}

struct CompactProductCard: View {
    let product: Product
    var onAddToCart: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink {
                ProductDetailView(productID: product.id)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                        .frame(height: 116)
                        .overlay {
                            MegaMartProductArtwork(product: product)
                                .padding(10)
                        }

                    Text(product.productName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(Formatters.currency(product.price))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("compact_price_\(product.id)")

                    Text(product.deliveryEstimate)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.productRow(product.id))

            if let onAddToCart {
                Button("Add to cart", action: onAddToCart)
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(MegaMartTheme.amazonYellow)
                )
                    .foregroundStyle(.black)
                    .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
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

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    @StateObject private var viewModel: ProductDetailViewModel
    @State private var isCheckoutPresented = false
    @State private var presentedSheet: ProductWorkflowSheet?
    @State private var selectedDetailTab: ProductDetailTab = .top
    @State private var selectedProtectionPlanTitle: String?

    private var isCurrentSelectionSaved: Bool {
        store.isSaved(productID: viewModel.productID, selectedVariantValues: viewModel.selectedVariantValues)
    }

    init(productID: String) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productID: productID))
    }

    var body: some View {
        Group {
            if let product = store.product(for: viewModel.productID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        heroBlock(for: product)
                        titleBlock(for: product)
                        purchaseBox(for: product)
                        detailTabs
                        productSections(for: product)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 60)
                }
                .background(MegaMartTheme.background)
                .safeAreaInset(edge: .top, spacing: 0) {
                    detailHeader
                }
                .toolbar(.hidden, for: .navigationBar)
                .onAppear {
                    viewModel.configureDefaults(for: product)
                    store.markRecentlyViewed(productID: product.id)
                }
                .sheet(isPresented: $isCheckoutPresented) {
                    CheckoutFlowView(
                        mode: .buyNow(
                            store.previewCartItem(
                                product: product,
                                quantity: viewModel.quantity,
                                selectedVariantValues: viewModel.selectedVariantValues
                            )
                        ),
                        store: store
                    )
                    .environmentObject(store)
                }
                .sheet(item: $presentedSheet) { sheet in
                    switch sheet {
                    case .protectionPlan:
                        ProtectionPlanSelectionView(
                            product: product,
                            selectedPlanTitle: $selectedProtectionPlanTitle
                        )
                        .environmentObject(store)
                    case .sellerOptions:
                        SellerOffersView(
                            product: product,
                            quantity: viewModel.quantity,
                            selectedVariantValues: viewModel.selectedVariantValues
                        )
                        .environmentObject(store)
                    case .tradeIn:
                        TradeInOfferView(product: product)
                            .environmentObject(store)
                    case .reportIssue:
                        ProductIssueReportView(product: product)
                            .environmentObject(store)
                    }
                }
            } else {
                Text("This product is not available in the current catalog.")
                    .padding()
                    .background(MegaMartTheme.background)
            }
        }
    }

    private var detailHeader: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 390

            HStack(spacing: compact ? 6 : 8) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: compact ? 16 : 17, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SearchView(initialRequest: SearchNavigationRequest(query: "", departmentID: nil, categoryID: nil))
                } label: {
                    HStack(spacing: compact ? 6 : 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: compact ? 14 : 15, weight: .medium))
                            .foregroundStyle(MegaMartTheme.mutedText)
                        Text("Search MegaMart")
                            .font(.system(size: compact ? 14 : 15, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 4)
                        Image(systemName: "mic.fill")
                            .font(.system(size: compact ? 14 : 15, weight: .medium))
                            .foregroundStyle(MegaMartTheme.mutedText)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: compact ? 16 : 17, weight: .medium))
                            .foregroundStyle(MegaMartTheme.mutedText)
                    }
                    .padding(.horizontal, compact ? 10 : 12)
                    .padding(.vertical, compact ? 8 : 9)
                    .background(
                        RoundedRectangle(cornerRadius: compact ? 8 : 10)
                            .fill(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: compact ? 8 : 10)
                                    .stroke(MegaMartTheme.cardBorder, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 6 : 8)
        }
        .background(MegaMartTheme.header)
        .frame(height: 62)
    }

    private func heroBlock(for product: Product) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .frame(height: 220)
            .overlay {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 175)
                        .overlay {
                            MegaMartProductArtwork(product: product)
                                .padding(14)
                        }
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index == 0 ? .black : Color(.systemGray4))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding(14)
            }
    }

    private func titleBlock(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if SeedData.amazonsChoiceProductIDs.contains(product.id) {
                AmazonsChoiceBadge()
            }

            Text(product.productName)
                .font(.system(size: 17, weight: .medium))

            Button(product.brand) {
                store.navigateToSearch(query: product.brand)
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(MegaMartTheme.linkBlue)

            HStack(spacing: 4) {
                Text(Formatters.rating(product.rating))
                    .font(.system(size: 14, weight: .medium))
                ProductStarsView(rating: product.rating)
                Text("\(Formatters.reviewCount(product.reviewCount))")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            if product.reviewCount >= 10_000 {
                Text("\(Formatters.reviewCount(product.reviewCount / 100 * 100))+ bought in past month")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                if let discountPercent = product.discountPercent {
                    Text("-\(discountPercent)%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                }
                Text(Formatters.currency(product.price))
                    .font(.system(size: 22, weight: .regular))
                    .accessibilityIdentifier("product_detail_price_\(product.id)")
                if let originalPrice = product.originalPrice, originalPrice > product.price {
                    Text(Formatters.currency(originalPrice))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }

            if SeedData.subscribeAndSaveProductIDs.contains(product.id) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.teal)
                    Text("Subscribe & Save: \(Formatters.currency(product.price * 0.85))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.teal)
                    Text("(15% off)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Text(product.inStock ? product.deliveryEstimate : "Currently unavailable")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(product.inStock ? Color.primary : Color.red)
        }
    }

    private func purchaseBox(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sold by \(product.sellerName)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            if let selectedProtectionPlanTitle {
                Label(selectedProtectionPlanTitle, systemImage: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.green)
            }

            if !product.variantGroups.isEmpty {
                variantSelectors(for: product)
            }

            quantitySelector(for: product)

            VStack(spacing: 8) {
                Button("Add to Cart") {
                    store.addToCart(product: product, quantity: viewModel.quantity, selectedVariantValues: viewModel.selectedVariantValues)
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(MegaMartTheme.amazonYellow)
                )
                .foregroundStyle(.black)
                .disabled(!viewModel.canPurchase(product: product, using: store))
                .accessibilityIdentifier(AccessibilityID.addToCart(product.id))

                Button("Buy Now") {
                    isCheckoutPresented = true
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(Color(red: 255 / 255, green: 164 / 255, blue: 28 / 255))
                )
                .foregroundStyle(.black)
                .disabled(!viewModel.canPurchase(product: product, using: store))
                .accessibilityIdentifier(AccessibilityID.buyNow(product.id))

                Button(isCurrentSelectionSaved ? "Saved to List" : "Add to List") {
                    store.addToSaved(product: product, selectedVariantValues: viewModel.selectedVariantValues)
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(.white)
                        .overlay(
                            Capsule()
                                .stroke(Color(.systemGray3), lineWidth: 1.5)
                        )
                )
                .foregroundStyle(.black)
                .accessibilityIdentifier(AccessibilityID.saveItem(product.id))
            }

            if !viewModel.canPurchase(product: product, using: store) {
                Text(product.inStock ? "The selected variant is unavailable. Choose another option." : "This item is currently unavailable right now.")
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
    }

    private var detailTabs: some View {
        HStack(spacing: 0) {
            ForEach(ProductDetailTab.allCases) { tab in
                detailTab(tab)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
    }

    private func detailTab(_ tab: ProductDetailTab) -> some View {
        Button {
            selectedDetailTab = tab
        } label: {
            VStack(spacing: 6) {
                if tab == .top {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(tab.title)
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selectedDetailTab == tab ? Color(.systemGray6) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func productSections(for product: Product) -> some View {
        switch selectedDetailTab {
        case .top:
            topSection(for: product)
        case .details:
            detailsSection(for: product)
        case .explore:
            exploreSection(for: product)
        case .reviews:
            reviewsSection(for: product)
        }
    }

    private func frequentlyBoughtTogetherSection(for product: Product) -> some View {
        Group {
            if let companionIDs = SeedData.frequentlyBoughtTogether[product.id] {
                let companions = companionIDs.compactMap { store.product(for: $0) }
                if !companions.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Frequently bought together")
                            .font(.system(size: 17, weight: .bold))

                        HStack(spacing: 8) {
                            fbtProductTile(product)
                            ForEach(companions.prefix(2)) { companion in
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.secondary)
                                fbtProductTile(companion)
                            }
                        }

                        let totalPrice = product.price + companions.prefix(2).reduce(0) { $0 + $1.price }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total price: \(Formatters.currency(totalPrice))")
                                .font(.system(size: 15, weight: .semibold))
                            Button("Add all \(min(companions.count, 2) + 1) to Cart") {
                                store.addToCart(product: product, quantity: 1, selectedVariantValues: viewModel.selectedVariantValues)
                                for companion in companions.prefix(2) {
                                    store.addToCart(product: companion, quantity: 1, selectedVariantValues: [:])
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(MegaMartTheme.amazonYellow)
                            )
                            .foregroundStyle(.black)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.white)
                    )
                }
            }
        }
    }

    private func fbtProductTile(_ product: Product) -> some View {
        NavigationLink {
            ProductDetailView(productID: product.id)
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .overlay {
                        MegaMartProductArtwork(product: product)
                            .padding(8)
                    }
                Text(Formatters.currency(product.price))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func customerQASection(for product: Product) -> some View {
        Group {
            if let qaItems = SeedData.customerQandA[product.id], !qaItems.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Customer questions & answers")
                        .font(.system(size: 17, weight: .bold))

                    ForEach(Array(qaItems.enumerated()), id: \.offset) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("Q:")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)
                                Text(entry.element.question)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("A:")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(MegaMartTheme.linkBlue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.element.answer)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)
                                    Text("By \(entry.element.answerer)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if entry.offset < qaItems.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white)
                )
            }
        }
    }

    private func topSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            frequentlyBoughtTogetherSection(for: product)

            VStack(alignment: .leading, spacing: 0) {
                Button {
                    presentedSheet = .protectionPlan
                } label: {
                    accessoryRow(
                        title: selectedProtectionPlanTitle ?? "2-Year Protection Plan for",
                        price: protectionPrice(for: product),
                        trailing: "chevron.right",
                        isSelected: selectedProtectionPlanTitle != nil
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.horizontal, 16)
                Text("Gift-wrap available.")
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                Divider().padding(.horizontal, 16)
                Button {
                    presentedSheet = .tradeIn
                } label: {
                    HStack {
                        Text("Trade-In and save")
                            .font(.system(size: 22, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.green, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Button(isCurrentSelectionSaved ? "Saved to List" : "Add to List") {
                    store.addToSaved(product: product, selectedVariantValues: viewModel.selectedVariantValues)
                }
                .buttonStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(MegaMartTheme.linkBlue)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white)
            )

            Button {
                presentedSheet = .sellerOptions
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other sellers on MegaMart")
                        .font(.system(size: 17, weight: .bold))
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Compare New & Used (\(otherSellerCount(for: product))) from")
                                .font(.system(size: 14))
                            Text(Formatters.currency(product.originalPrice ?? product.price))
                                .font(.system(size: 18, weight: .medium))
                            Text("FREE Shipping")
                                .font(.system(size: 14))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.top, 12)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white)
                )
            }
            .buttonStyle(.plain)

            Button {
                presentedSheet = .reportIssue
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "message.badge")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                    Text("Report an issue with this product or seller")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MegaMartTheme.linkBlue)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white)
                )
            }
            .buttonStyle(.plain)

            if let related = relatedProducts(for: product).first {
                NavigationLink {
                    ProductDetailView(productID: related.id)
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Customers also viewed")
                            .font(.system(size: 17, weight: .bold))

                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(width: 128, height: 128)
                                .overlay {
                                    MegaMartProductArtwork(product: related)
                                        .padding(12)
                                }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(related.productName)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(3)
                                HStack(spacing: 4) {
                                    Text(Formatters.rating(related.rating))
                                        .font(.system(size: 13, weight: .medium))
                                    ProductStarsView(rating: related.rating)
                                    Text(Formatters.reviewCount(related.reviewCount))
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                HStack(alignment: .lastTextBaseline, spacing: 6) {
                                    if let discountPercent = related.discountPercent {
                                        Text("-\(discountPercent)%")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.red)
                                    }
                                    Text(Formatters.currency(related.price))
                                        .font(.system(size: 18, weight: .regular))
                                    if let originalPrice = related.originalPrice, originalPrice > related.price {
                                        Text(Formatters.currency(originalPrice))
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                            .strikethrough()
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.white)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func detailsSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if !product.promotions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Offers")
                        .font(.system(size: 17, weight: .bold))

                    ForEach(product.promotions) { promotion in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(promotion.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text(promotion.detail)
                                .font(.system(size: 15))
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
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("About this item")
                    .font(.system(size: 17, weight: .bold))

                ForEach(Array(product.aboutItems.enumerated()), id: \.offset) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(entry.element)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white)
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Product details")
                    .font(.system(size: 17, weight: .bold))

                ForEach(product.specifications) { spec in
                    HStack(alignment: .top) {
                        Text(spec.title)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(spec.value)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if spec.id != product.specifications.last?.id {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white)
            )
        }
    }

    private func exploreSection(for product: Product) -> some View {
        let related = relatedProducts(for: product)

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Explore similar products")
                    .font(.system(size: 17, weight: .bold))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(related.prefix(4)) { relatedProduct in
                            CompactProductCard(product: relatedProduct) {
                                store.addToCart(product: relatedProduct, quantity: 1, selectedVariantValues: [:])
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Recently viewed")
                    .font(.system(size: 17, weight: .bold))

                ForEach(store.recentlyViewedProducts.filter { $0.id != product.id }.prefix(3)) { viewedProduct in
                    NavigationLink {
                        ProductDetailView(productID: viewedProduct.id)
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(width: 82, height: 82)
                                .overlay {
                                    MegaMartProductArtwork(product: viewedProduct)
                                        .padding(10)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewedProduct.productName)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                Text(viewedProduct.brand)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                Text(Formatters.currency(viewedProduct.price))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reviewsSection(for product: Product) -> some View {
        let userReviews = store.reviews(for: product.id)
        let communityReviews = store.communityReviews(for: product.id)

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Customer reviews")
                    .font(.system(size: 17, weight: .bold))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Formatters.rating(product.rating))
                        .font(.system(size: 28, weight: .bold))
                    ProductStarsView(rating: product.rating)
                    Text("\(Formatters.reviewCount(product.reviewCount)) global ratings")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                ForEach(reviewBreakdown(for: product), id: \.label) { row in
                    HStack(spacing: 10) {
                        Text(row.label)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 52, alignment: .leading)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                Capsule()
                                    .fill(MegaMartTheme.amazonYellow)
                                    .frame(width: proxy.size.width * row.fraction)
                            }
                        }
                        .frame(height: 10)
                        Text("\(Int(row.fraction * 100))%")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white)
            )

            if !userReviews.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your reviews")
                        .font(.system(size: 17, weight: .bold))

                    ForEach(userReviews) { review in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.secondary)
                                Text(review.authorName)
                                    .font(.system(size: 16, weight: .medium))
                            }

                            HStack(spacing: 8) {
                                ProductStarsView(rating: Double(review.rating))
                                Text(review.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .lineLimit(2)
                            }

                            Text("Reviewed on \(Formatters.shortDate(review.reviewDate))")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            if review.isVerifiedPurchase {
                                Text("Verified Purchase")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }

                            Text(review.body)
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white)
                        )
                        .accessibilityIdentifier("user_review_\(review.id)")
                    }
                }
            }

            if !communityReviews.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top reviews from the community")
                        .font(.system(size: 17, weight: .bold))

                    ForEach(communityReviews.prefix(3)) { review in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.secondary)
                                Text(review.authorName)
                                    .font(.system(size: 16, weight: .medium))
                            }

                            HStack(spacing: 8) {
                                ProductStarsView(rating: Double(review.rating))
                                Text(review.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(2)
                            }

                            Text("Reviewed on \(Formatters.shortDate(review.reviewDate))")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            if review.isVerifiedPurchase {
                                Text("Verified Purchase")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }

                            Text(review.body)
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 16) {
                                Button {
                                    store.inlineStatusMessage = "Thanks for your feedback!"
                                } label: {
                                    Label("Helpful", systemImage: "hand.thumbsup")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("review_helpful_\(review.id)")

                                Button {
                                    store.inlineStatusMessage = "Review reported. Thank you."
                                } label: {
                                    Label("Report", systemImage: "flag")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("review_report_\(review.id)")
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white)
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Top review highlights")
                    .font(.system(size: 17, weight: .bold))

                ForEach(reviewHighlights(for: product), id: \.title) { highlight in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(highlight.title)
                            .font(.system(size: 14, weight: .semibold))
                        ProductStarsView(rating: highlight.rating)
                        Text(highlight.body)
                            .font(.system(size: 13))
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

            customerQASection(for: product)
        }
    }

    private func accessoryRow(title: String, price: Double, trailing: String, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color(.systemGray3), lineWidth: 2)
                    .frame(width: 34, height: 34)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.green)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                Text(Formatters.currency(price))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.red)
            }
            Spacer()
            Image(systemName: trailing)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private func variantSelectors(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(product.variantGroups, id: \.self) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group)
                        .font(.system(size: 16, weight: .semibold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.options(for: product, group: group)) { option in
                                Button {
                                    viewModel.select(option)
                                } label: {
                                    Text(option.variantValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(viewModel.isSelected(option) ? Color(red: 247 / 255, green: 240 / 255, blue: 200 / 255) : Color(.systemGray6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(viewModel.isSelected(option) ? MegaMartTheme.searchBorder : Color(.systemGray4), lineWidth: 1.5)
                                        )
                                        .foregroundStyle(option.isAvailable ? .primary : .secondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(!option.isAvailable)
                            }
                        }
                    }
                }
            }
        }
    }

    private func quantitySelector(for product: Product) -> some View {
        HStack {
            Text("Quantity")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            HStack(spacing: 16) {
                Button {
                    viewModel.quantity = max(1, viewModel.quantity - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("product_quantity_decrement_\(product.id)")

                Text("\(viewModel.quantity)")
                    .font(.system(size: 20, weight: .semibold))

                Button {
                    viewModel.quantity = min(10, viewModel.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("product_quantity_increment_\(product.id)")
            }
            .foregroundStyle(MegaMartTheme.linkBlue)
        }
    }

    private func relatedProducts(for product: Product) -> [Product] {
        store.catalog.products
            .filter { $0.categoryID == product.categoryID && $0.id != product.id }
            .sorted { $0.popularityRank < $1.popularityRank }
            .prefix(6)
            .map { $0 }
    }

    private func protectionPrice(for product: Product) -> Double {
        let value = max(19.99, min(79.99, product.price * 0.0925))
        return (value * 100).rounded() / 100
    }

    private func otherSellerCount(for product: Product) -> Int {
        max(relatedProducts(for: product).count * 4, product.productName.localizedCaseInsensitiveContains("PlayStation") ? 20 : 8)
    }

    private func reviewBreakdown(for product: Product) -> [(label: String, fraction: Double)] {
        let emphasis = min(max((product.rating - 3.5) / 1.5, 0.2), 1.0)
        let fiveStar = min(0.58 + (emphasis * 0.20), 0.84)
        let fourStar = max(0.16, 0.24 - (emphasis * 0.06))
        let threeStar = 0.10
        let twoStar = 0.05
        let oneStar = max(0.01, 1 - fiveStar - fourStar - threeStar - twoStar)
        return [
            ("5 star", fiveStar),
            ("4 star", fourStar),
            ("3 star", threeStar),
            ("2 star", twoStar),
            ("1 star", oneStar)
        ]
    }

    private func reviewHighlights(for product: Product) -> [(title: String, rating: Double, body: String)] {
        let categoryDescription = product.categoryID.replacingOccurrences(of: "_", with: " ")
        return [
            (
                title: "Worth it for everyday use",
                rating: min(5.0, max(4.0, product.rating)),
                body: "Buyers consistently call out \(product.brand) for dependable performance, clear setup, and solid value at this price."
            ),
            (
                title: "Good fit and delivery experience",
                rating: min(5.0, max(4.0, product.rating - 0.1)),
                body: "Recent reviews mention the item arrived on time, matched the listing details, and worked well for common \(categoryDescription) needs."
            ),
            (
                title: "Best if you want the current offer",
                rating: min(5.0, max(4.0, product.rating - 0.2)),
                body: "Shoppers like the current price, but they still recommend checking variant availability and add-on coverage before you place the order."
            )
        ]
    }
}

private enum ProductWorkflowSheet: String, Identifiable {
    case protectionPlan
    case sellerOptions
    case tradeIn
    case reportIssue

    var id: String { rawValue }
}

private enum ProductDetailTab: String, CaseIterable, Identifiable {
    case top
    case details
    case explore
    case reviews

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top:
            return "Top"
        case .details:
            return "Details"
        case .explore:
            return "Explore"
        case .reviews:
            return "Reviews"
        }
    }
}

struct AmazonsChoiceBadge: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("MegaMart's ")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            + Text("Choice")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 255 / 255, green: 170 / 255, blue: 51 / 255))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.13, green: 0.16, blue: 0.19))
        )
    }
}

private struct ProductStarsView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                let threshold = Double(index) + 1
                let icon = if rating >= threshold {
                    "star.fill"
                } else if rating >= threshold - 0.5 {
                    "star.leadinghalf.filled"
                } else {
                    "star"
                }

                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct TradeInOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    let product: Product

    private var estimatedCredit: Double {
        max(20, (product.price * 0.18).rounded())
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Estimated credit") {
                    Text("Get up to \(Formatters.currency(estimatedCredit)) toward a new purchase when you trade in a qualifying console or accessory.")
                    Text("Trade-in quotes are evaluated using product price tiers and condition assumptions.")
                        .foregroundStyle(.secondary)
                }

                Section("How it works") {
                    Label("Answer a few questions about your current device", systemImage: "checkmark.circle")
                    Label("Receive a prepaid shipping label after confirmation", systemImage: "shippingbox")
                    Label("MegaMart applies the credit after inspection", systemImage: "creditcard")
                }

                Section {
                    Button("Start trade-in") {
                        store.inlineStatusMessage = "Trade-in estimate saved for \(product.brand)"
                        dismiss()
                    }
                }
            }
            .navigationTitle("Trade-In")
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
}

private struct ProtectionPlanSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore

    let product: Product
    @Binding var selectedPlanTitle: String?

    private var options: [(title: String, detail: String, price: Double)] {
        let basePrice = max(19.99, min(79.99, product.price * 0.0925))
        return [
            ("2-Year Protection Plan", "Covers drops, spills, and electrical failures after the return window.", (basePrice * 100).rounded() / 100),
            ("3-Year Protection Plan", "Extends coverage longer for high-use electronics and accessories.", ((basePrice + 12) * 100).rounded() / 100)
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Coverage options") {
                    ForEach(options, id: \.title) { option in
                        Button {
                            selectedPlanTitle = "\(option.title) selected"
                            store.inlineStatusMessage = "\(option.title) added"
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(option.title)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(Formatters.currency(option.price))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.red)
                                }
                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Protection Plan")
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
}

private struct SellerOffersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore

    let product: Product
    let quantity: Int
    let selectedVariantValues: [String: String]

    private var offers: [(seller: String, condition: String, price: Double, eta: String)] {
        [
            (product.sellerName, product.condition, product.price, product.deliveryEstimate),
            ("Warehouse Deals", "Used - Like New", max(0, product.price - 24), "FREE delivery in 2 days"),
            ("Top Rated Seller", "New", max(0, product.price - 8), "FREE delivery by Friday")
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Available offers") {
                    ForEach(offers, id: \.seller) { offer in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(offer.seller)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(Formatters.currency(offer.price))
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text(offer.condition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(offer.eta)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button("Add best offer to Cart") {
                        store.addToCart(
                            product: product,
                            quantity: quantity,
                            selectedVariantValues: selectedVariantValues
                        )
                        dismiss()
                    }
                }
            }
            .navigationTitle("Other Sellers")
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
}

private struct ProductIssueReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    let product: Product

    @State private var issueType = "Incorrect details"
    @State private var details = ""
    @State private var submitted = false

    private let issueTypes = [
        "Incorrect details",
        "Misleading price",
        "Inaccurate images",
        "Seller concern"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    Text(product.productName)
                    Text(product.brand)
                        .foregroundStyle(.secondary)
                }

                if submitted {
                    Section("Thanks") {
                        Text("Your report was submitted and stored locally for review.")
                        Button("Done") {
                            dismiss()
                        }
                    }
                } else {
                    Section("Issue type") {
                        Picker("Issue", selection: $issueType) {
                            ForEach(issueTypes, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        TextField("Additional details", text: $details, axis: .vertical)
                            .lineLimit(3...5)
                    }

                    Section {
                        Button("Submit report") {
                            store.inlineStatusMessage = "Issue report sent for \(product.brand)"
                            submitted = true
                        }
                    }
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
