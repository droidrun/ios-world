import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var searchFocused: Bool
    @State private var appliedInitialRequest = false

    private let initialRequest: SearchNavigationRequest?

    init(initialRequest: SearchNavigationRequest? = nil) {
        self.initialRequest = initialRequest
    }

    private var suggestions: [SearchSuggestion] {
        viewModel.autocompleteSuggestions(in: store.catalog, recentSearches: store.state.recentSearches)
    }

    private var results: [Product] {
        viewModel.filteredProducts(in: store.catalog)
    }

    private var dynamicShortcutItems: [(title: String, subtitle: String, symbol: String, query: String)] {
        let normalized = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("ps5") || normalized.contains("playstation") {
            return [
                ("Controllers", "DualSense and more", "gamecontroller.fill", "ps5 controller"),
                ("Charging\nstation", "Dock and display", "battery.100.bolt", "ps5 charging station"),
                ("Gaming\nheadset", "Chat + surround", "headphones", "ps5 gaming headset"),
                ("External\nstorage", "Expand memory", "externaldrive.fill", "ps5 external storage"),
                ("Cooling\nstand", "Keep airflow up", "wind", "ps5 cooling stand")
            ]
        }

        return store.catalog.departments.map { department in
            (department.name, "Browse \(department.name.lowercased())", department.systemImage, department.name)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                locationBanner
                filterRow
                shortcutRail

                if searchFocused && !suggestions.isEmpty {
                    suggestionSection
                } else if shouldShowDiscovery {
                    discoverySection
                } else {
                    if viewModel.query.lowercased().contains("ps5"), !results.isEmpty {
                        insightsBanner
                    }
                    resultsSection
                }
            }
            .padding(.bottom, 80)
        }
        .background(MegaMartTheme.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            searchHeader
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            applyInitialRequestIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if viewModel.query.isEmpty {
                    searchFocused = true
                }
            }
        }
    }

    private var shouldShowDiscovery: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.hasActiveFilters
    }

    private var locationBannerText: String {
        let city = store.selectedAddress?.city ?? "San Francisco"
        let postalCode = store.selectedAddress?.postalCode ?? "94107"
        return "Delivering to \(city) \(postalCode) - Update location"
    }

    private var searchHeader: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 390

            VStack(spacing: 0) {
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

                    HStack(spacing: compact ? 6 : 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: compact ? 14 : 15, weight: .medium))
                            .foregroundStyle(MegaMartTheme.mutedText)

                        TextField("Search MegaMart", text: $viewModel.query)
                            .font(.system(size: compact ? 14 : 15, weight: .regular))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .submitLabel(.search)
                            .focused($searchFocused)
                            .onSubmit {
                                commitSearch(viewModel.query)
                            }
                            .accessibilityIdentifier("search_products_field")

                        if !viewModel.query.isEmpty {
                            Button {
                                viewModel.query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: compact ? 14 : 15))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("search_clear_button")
                        }

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
                .padding(.horizontal, compact ? 10 : 14)
                .padding(.vertical, compact ? 6 : 8)
            }
            .background(MegaMartTheme.header)
        }
        .frame(height: 62)
    }

    private var locationBanner: some View {
        NavigationLink {
            ManageAddressesView()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "location.circle")
                    .font(.system(size: 14, weight: .bold))
                Text(locationBannerText)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(MegaMartTheme.header.opacity(0.92))
        }
        .buttonStyle(.plain)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(title: "Filter", symbol: "slider.horizontal.3", isSelected: false) {
                    if viewModel.hasActiveFilters {
                        viewModel.clearAllFilters()
                    } else {
                        viewModel.inStockOnly = true
                    }
                }
                filterChip(title: "Prime", symbol: "checkmark", isSelected: viewModel.primeOnly) {
                    viewModel.primeOnly.toggle()
                }
                filterChip(title: "4 Stars & Up", symbol: nil, isSelected: viewModel.selectedRatingFilter != .any) {
                    viewModel.selectedRatingFilter = viewModel.selectedRatingFilter == .any ? .fourPlus : .any
                }
                filterChip(title: sortChipTitle, symbol: nil, isSelected: true) {
                    cycleSortOption()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.white)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var sortChipTitle: String {
        switch viewModel.sortOption {
        case .mostRelevant:
            return "Most Relevant"
        case .lowestPrice:
            return "Low to High"
        case .highestPrice:
            return "High to Low"
        case .highestRated:
            return "Top Rated"
        case .newestArrivals:
            return "New Arrivals"
        }
    }

    private var shortcutRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(dynamicShortcutItems.enumerated()), id: \.offset) { entry in
                    let item = entry.element
                    Button {
                        viewModel.query = item.query
                        commitSearch(item.query)
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                                .frame(width: 72, height: 60)
                                .overlay {
                                    MegaMartCategoryArtwork(query: item.query, fallbackSystemImage: item.symbol)
                                        .padding(8)
                                }

                            Text(item.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .frame(width: 72)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.white)
    }

    private var insightsBanner: some View {
        Text("Press & hold for product insights")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MegaMartTheme.linkBlue)
            )
            .overlay(alignment: .bottom) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MegaMartTheme.linkBlue)
                    .rotationEffect(.degrees(180))
                    .offset(y: 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.horizontal, 24)
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions")
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 14)

            ForEach(suggestions) { suggestion in
                Button {
                    viewModel.query = suggestion.text
                    commitSearch(suggestion.text)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.text)
                                .font(.system(size: 14, weight: .medium))
                            Text(suggestion.subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.searchSuggestionRow(suggestion.text))
            }
        }
    }

    private var discoverySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent searches")
                    .font(.system(size: 17, weight: .bold))
                    .padding(.horizontal, 14)

                if store.state.recentSearches.isEmpty {
                    Text("No recent searches yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.state.recentSearches, id: \.self) { recent in
                                Button(recent) {
                                    viewModel.query = recent
                                    commitSearch(recent)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
            }

            departmentBrowsingSection

            VStack(alignment: .leading, spacing: 10) {
                Text("Popular on MegaMart")
                    .font(.system(size: 17, weight: .bold))
                    .padding(.horizontal, 14)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(store.catalog.categories.prefix(8)) { category in
                        Button {
                            viewModel.query = category.name
                            commitSearch(category.name)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 68)
                                    .overlay {
                                        MegaMartCategoryArtwork(query: category.name, fallbackSystemImage: category.systemImage)
                                            .padding(10)
                                    }
                                Text(category.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.white)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private var departmentBrowsingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shop by Department")
                .font(.system(size: 17, weight: .bold))
                .padding(.horizontal, 14)

            ForEach(store.catalog.departments) { department in
                let categories = store.categories(for: department.id)
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        searchFocused = false
                        viewModel.selectedDepartmentID = department.id
                        viewModel.query = department.name
                        commitSearch(department.name)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: department.systemImage)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(MegaMartTheme.linkBlue)
                                .frame(width: 32, height: 32)
                            Text(department.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if !categories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories) { category in
                                    Button {
                                        searchFocused = false
                                        viewModel.selectedDepartmentID = department.id
                                        viewModel.selectedCategoryID = category.id
                                        viewModel.query = category.name
                                        commitSearch(category.name)
                                    } label: {
                                        Text(category.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(Color(.systemGray6))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                )
                .padding(.horizontal, 14)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(results.isEmpty ? "No results found" : "Check each product page for additional seller and shipping details")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)

            if results.isEmpty {
                Text("Try a different search or clear your filters.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
            } else {
                ForEach(results) { product in
                    MegaMartSearchResultCard(product: product) {
                        store.addToCart(product: product, quantity: 1, selectedVariantValues: [:])
                    } onSave: {
                        store.addToSaved(product: product, selectedVariantValues: [:])
                    }
                }
            }
        }
    }

    private func filterChip(title: String, symbol: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                }
                if title == "4 Stars & Up" {
                    Text("★★★★")
                        .foregroundStyle(.orange)
                    Text("& Up")
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(red: 247 / 255, green: 240 / 255, blue: 200 / 255) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MegaMartTheme.searchBorder, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func applyInitialRequestIfNeeded() {
        guard !appliedInitialRequest else { return }
        appliedInitialRequest = true

        guard let initialRequest else { return }
        viewModel.apply(request: initialRequest)
        if !initialRequest.query.isEmpty {
            store.recordSearch(initialRequest.query)
        }
    }

    private func commitSearch(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.recordSearch(trimmed)
        searchFocused = false
    }

    private func cycleSortOption() {
        let options = SearchSortOption.allCases
        guard let index = options.firstIndex(of: viewModel.sortOption) else {
            viewModel.sortOption = .mostRelevant
            return
        }
        viewModel.sortOption = options[(index + 1) % options.count]
    }
}

private struct MegaMartSearchResultCard: View {
    @EnvironmentObject private var store: MegaMartStore
    let product: Product
    let onAddToCart: () -> Void
    let onSave: () -> Void

    private var purchaseSummary: String {
        if product.popularityRank <= 2 {
            return "6K+ bought in past month"
        }
        if product.popularityRank <= 8 {
            return "2K+ bought in past month"
        }
        return "Popular pick in \(product.brand)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                ProductDetailView(productID: product.id)
            } label: {
                HStack(alignment: .top, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(width: 120, height: 170)

                        VStack(alignment: .leading, spacing: 4) {
                            if product.popularityRank <= 3 {
                                Text("Best Seller")
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 232 / 255, green: 113 / 255, blue: 0))
                                    )
                                    .foregroundStyle(.white)
                            }
                            if SeedData.amazonsChoiceProductIDs.contains(product.id) {
                                AmazonsChoiceBadge()
                            }
                        }
                        .padding(.top, 6)
                        .padding(.leading, 6)

                        VStack {
                            Spacer()
                            MegaMartProductArtwork(product: product)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(product.productName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)

                        Text("by \(product.brand)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        if let releaseLabel = product.releaseLabel {
                            Text(releaseLabel)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 2) {
                            Text(Formatters.rating(product.rating))
                                .font(.system(size: 12, weight: .medium))
                            MegaMartStarsView(rating: product.rating)
                            Text("(\(Formatters.reviewCount(product.reviewCount)))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Text(purchaseSummary)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(product.brand)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)

                        MegaMartPriceText(price: product.price, originalPrice: product.originalPrice, discount: product.discountPercent)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(product.deliveryEstimate)
                                .font(.system(size: 11))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if product.primeEligible {
                                Text("Or fastest delivery Sun, Mar 8")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                        }

                        if SeedData.subscribeAndSaveProductIDs.contains(product.id) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 9, weight: .semibold))
                                Text("Subscribe & Save 15%")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(.teal)
                        }

                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button {
                    onSave()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: store.isSaved(productID: product.id) ? "bookmark.fill" : "bookmark")
                        Text("Save")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
                    .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Button("Add to cart", action: onAddToCart)
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(MegaMartTheme.amazonYellow)
                    )
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
        .padding(.horizontal, 12)
    }
}

private struct MegaMartStarsView: View {
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

private struct MegaMartPriceText: View {
    let price: Double
    let originalPrice: Double?
    let discount: Int?

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            if let discount {
                Text("-\(discount)%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }

            Text(Formatters.currency(price))
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let originalPrice, originalPrice > price {
                Text(Formatters.currency(originalPrice))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .strikethrough()
                    .lineLimit(1)
            }
        }
    }
}
