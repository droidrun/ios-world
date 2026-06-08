import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel

    @State private var selectedProduct: Product?
    @FocusState private var isSearchFocused: Bool

    private let popularGrid = [GridItem(.adaptive(minimum: 96, maximum: 120), spacing: 12, alignment: .top)]
    private let resultGrid = [GridItem(.flexible(), spacing: 16, alignment: .top), GridItem(.flexible(), spacing: 16, alignment: .top)]

    var body: some View {
        VStack(spacing: 0) {
            topSearchBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if shouldShowDiscovery {
                        if viewModel.recentSearches.isEmpty == false {
                            recentSearchesSection
                        }
                        suggestionChips
                        categoryBrowseSection
                        popularSearchesSection
                    } else {
                        filterRow
                        resultsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, cartCount > 0 ? 140 : 24)
            }
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if cartCount > 0 {
                FloatingCartBar(subtotal: subtotal, cartCount: cartCount) {
                    viewModel.store.switchTab(.cart)
                }
            }
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailView(product: product, store: viewModel.store)
        }
        .onAppear {
            if shouldShowDiscovery {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isSearchFocused = true
                }
            }
        }
    }

    private var topSearchBar: some View {
        HStack(spacing: 10) {
            Button {
                if !shouldShowDiscovery {
                    viewModel.query = ""
                    viewModel.clearFilters()
                    isSearchFocused = true
                } else {
                    viewModel.store.switchTab(.home)
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Search products and stores", text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.setQueryText($0) }
                ))
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)
                .onSubmit {
                    viewModel.commitCurrentQuery()
                    isSearchFocused = false
                }
                .accessibilityIdentifier("search_products_field")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending")
                .font(.system(size: 18, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularSearches.prefix(4), id: \.self) { suggestion in
                        SearchSuggestionChip(title: suggestion) {
                            viewModel.setQueryText(suggestion)
                            viewModel.commitCurrentQuery()
                            isSearchFocused = false
                        }
                    }
                }
            }
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent searches")
                .font(.system(size: 18, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentSearches.prefix(6), id: \.self) { query in
                        SearchSuggestionChip(title: query) {
                            viewModel.setQueryText(query)
                            viewModel.commitCurrentQuery()
                            isSearchFocused = false
                        }
                    }
                }
            }
        }
    }

    private var categoryBrowseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse \(selectedStoreName)")
                .font(.system(size: 18, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.suggestedCategories) { category in
                        Button {
                            viewModel.browseCategory(category.id)
                            isSearchFocused = false
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.systemImage)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(category.name)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white))
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityID.categoryTile(category.id))
                    }
                }
            }
        }
    }

    private var popularSearchesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Popular at \(selectedStoreName)")
                .font(.system(size: 20, weight: .heavy))

            LazyVGrid(columns: popularGrid, spacing: 18) {
                ForEach(popularProducts) { product in
                    PopularSearchTile(product: product) {
                        viewModel.setQueryText(searchTerm(for: product))
                        viewModel.commitCurrentQuery()
                        isSearchFocused = false
                    }
                }
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(SearchSortOption.allCases, id: \.self) { option in
                        Button(option.label) {
                            viewModel.sortOption = option
                        }
                        .accessibilityIdentifier(sortAccessibilityIdentifier(option))
                    }
                } label: {
                    filterLabel(title: "Sort", systemImage: "arrow.up.arrow.down")
                }

                Menu {
                    Button("All") {
                        viewModel.selectedDietaryTag = nil
                        viewModel.organicOnly = false
                    }
                    Button("Organic only") {
                        viewModel.organicOnly = true
                    }
                    ForEach(viewModel.dietaryTags, id: \.self) { tag in
                        Button(tag) {
                            viewModel.toggleDietaryTag(tag)
                            viewModel.organicOnly = false
                        }
                    }
                } label: {
                    filterLabel(title: ingredientLabel, systemImage: nil)
                }

                Menu {
                    Button("All") {
                        viewModel.selectedCategoryID = nil
                    }
                    ForEach(viewModel.categories) { category in
                        Button(category.name) {
                            viewModel.selectedCategoryID = category.id
                        }
                    }
                } label: {
                    filterLabel(title: typeLabel, systemImage: nil)
                }

                Button {
                    viewModel.onSaleOnly.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("On Sale")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(viewModel.onSaleOnly ? Color.instacartGreen.opacity(0.15) : Color.instacartChip))
                    .overlay(Capsule().stroke(viewModel.onSaleOnly ? Color.instacartGreen : Color.clear, lineWidth: 2))
                }
                .buttonStyle(.plain)

                if viewModel.brands.isEmpty == false {
                    Menu {
                        Button("All brands") {
                            viewModel.selectedBrand = nil
                        }
                        ForEach(viewModel.brands, id: \.self) { brand in
                            Button(brand) {
                                viewModel.selectedBrand = brand
                            }
                        }
                    } label: {
                        filterLabel(title: brandLabel, systemImage: nil)
                    }
                }
            }
        }
    }

    private var brandLabel: String {
        viewModel.selectedBrand ?? "Brand"
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(resultsTitle)
                .font(.system(size: 20, weight: .heavy))

            if viewModel.results.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    EmptyStateCard(
                        title: "No search results",
                        subtitle: "Try a shorter query, another category, or switch stores below.",
                        accessibilityIdentifier: "search_empty_state"
                    )

                    if viewModel.otherStoreMatches.isEmpty == false {
                        otherStoreMatchesSection
                    }
                }
            } else {
                LazyVGrid(columns: resultGrid, spacing: 18) {
                    ForEach(viewModel.results) { product in
                        SearchResultCard(product: product) {
                            selectedProduct = product
                        } onAdd: {
                            viewModel.addToCart(productID: product.id)
                        }
                    }
                }
            }
        }
    }

    private func filterLabel(title: String, systemImage: String?) -> some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.instacartChip))
    }

    private func searchTerm(for product: Product) -> String {
        let lowered = product.productName.lowercased()
        if lowered.contains("paper towel") {
            return "paper towels"
        }
        if lowered.contains("toilet") {
            return "toilet paper"
        }
        if lowered.contains("dog") {
            return "dog food"
        }
        if lowered.contains("laundry") {
            return "laundry detergent"
        }
        return product.productName.lowercased()
    }

    private var popularProducts: [Product] {
        let preferred = popularKeywords
        let matched = preferred.compactMap { keyword in
            viewModel.store.productsForSelectedStore.first { $0.productName.lowercased().contains(keyword) }
        }
        if matched.isEmpty {
            let featured = viewModel.store.productsForSelectedStore.filter { $0.isRecommended || $0.isBuyAgain || $0.isOnSale }
            return Array((featured.isEmpty ? viewModel.store.productsForSelectedStore : featured).prefix(8))
        }
        return matched
    }

    private var popularKeywords: [String] {
        switch viewModel.selectedStore?.id {
        case "costco":
            return ["salmon", "paper towels", "toilet paper", "croissants", "grapes", "eggs", "water", "laundry"]
        case "aldi":
            return ["bananas", "eggs", "spinach", "marinara", "sourdough", "yogurt", "sparkling", "avocados"]
        case "target":
            return ["storage", "cleaner", "paper towels", "laundry", "soap", "snack", "candle", "blanket"]
        case "petco":
            return ["dog food", "cat litter", "treat", "toy", "cat", "salmon"]
        case "giant_eagle":
            return ["oranges", "rotisserie", "milk", "eggs", "salad", "pasta"]
        case "market_district":
            return ["sushi", "salad", "bread", "cold brew", "olive oil"]
        case "panera":
            return ["soup", "salad", "sandwich", "croissant", "tea"]
        case "chipotle":
            return ["bowl", "burrito", "queso", "chips", "coca-cola"]
        case "cvs":
            return ["vitamin", "pain", "cough", "toothpaste", "bandages", "tissues"]
        case "lowes":
            return ["bulb", "drill", "paint", "planter", "gloves", "tote"]
        case "dollar_tree":
            return ["paper plates", "laundry", "cookies", "cola", "cleaner", "trash"]
        case "michaels":
            return ["paint", "sketchbook", "glue", "yarn", "frame", "wreath"]
        case "family_dollar":
            return ["cereal", "juice", "paper towels", "toothpaste", "trash", "detergent"]
        default:
            return ["produce", "eggs", "water", "paper"]
        }
    }

    private var resultsTitle: String {
        if let selectedCategoryID,
           viewModel.query.isEmpty,
           let category = viewModel.categories.first(where: { $0.id == selectedCategoryID }) {
            return "Browse \(category.name)"
        }
        return "Results for \"\(viewModel.query)\""
    }

    private var otherStoreMatchesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Found in other stores")
                .font(.system(size: 20, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.otherStoreMatches) { match in
                        SearchStoreMatchCard(match: match) {
                            viewModel.activateStoreMatch(match.store.id)
                        }
                    }
                }
            }
        }
    }

    private var ingredientLabel: String {
        if viewModel.organicOnly {
            return "Organic"
        }
        return viewModel.selectedDietaryTag ?? "Ingredient Preferences"
    }

    private var typeLabel: String {
        guard let selectedCategoryID,
              let category = viewModel.categories.first(where: { $0.id == selectedCategoryID }) else {
            return "Type"
        }
        return category.name
    }

    private var selectedCategoryID: String? {
        viewModel.selectedCategoryID
    }

    private var selectedStoreName: String {
        viewModel.selectedStore?.storeName ?? "this store"
    }

    private var shouldShowDiscovery: Bool {
        viewModel.query.isEmpty && viewModel.selectedCategoryID == nil
    }

    private var subtotal: Double {
        viewModel.store.cartSummary().itemSubtotal
    }

    private var cartCount: Int {
        viewModel.store.state.cartItems.reduce(0) { $0 + $1.quantity }
    }

    private func sortAccessibilityIdentifier(_ option: SearchSortOption) -> String {
        switch option {
        case .relevance:
            return "sort_relevance"
        case .priceLowToHigh:
            return "sort_price_low_to_high"
        case .priceHighToLow:
            return "sort_price_high_to_low"
        case .unitPrice:
            return "sort_unit_price"
        }
    }
}

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var store: FreshCartStore

    @Environment(\.dismiss) private var dismiss

    @State private var quantity = 1
    @State private var selectedRelatedProduct: Product?
    @State private var showDetails = true
    @State private var showNutrition = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                topButtons

                ProductArtView(product: product, cornerRadius: 24)
                    .frame(height: 280)
                    .overlay(alignment: .bottomTrailing) {
                        Text(product.inStock ? "Many in stock" : "Out of stock")
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.9)))
                            .padding(.trailing, 18)
                            .padding(.bottom, 18)
                    }

                HStack(spacing: 10) {
                    Circle().fill(Color.primary).frame(width: 14, height: 14)
                    Circle().fill(Color.black.opacity(0.12)).frame(width: 14, height: 14)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.productName)
                        .font(.system(size: 22, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            let filled = Double(star) <= product.averageRating
                            let halfFilled = Double(star) - 0.5 <= product.averageRating && !filled
                            Image(systemName: filled ? "star.fill" : (halfFilled ? "star.leadinghalf.filled" : "star"))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.instacartGreen)
                        }
                        Text(String(format: "%.1f", product.averageRating))
                            .font(.system(size: 14, weight: .semibold))
                        Text("(\(product.reviewCount))")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Text(AppFormatters.currencyString(product.price))
                        .font(.system(size: 24, weight: .heavy))
                        .accessibilityIdentifier(AccessibilityID.priceLabel("detail_\(product.id)"))
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Product information")
                        .font(.system(size: 20, weight: .heavy))
                    Button {
                        showDetails.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Details")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.instacartChip))
                    }
                    .buttonStyle(.plain)

                    if showDetails {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(product.description)
                                .font(.system(size: 17))
                                .foregroundStyle(.secondary)
                            Text("Package size: \(product.packageSize)")
                                .font(.system(size: 17, weight: .medium))
                            Text("Unit price: \(product.unitPrice)")
                                .font(.system(size: 17, weight: .medium))
                            if product.dietaryTags.isEmpty == false {
                                Text("Highlights: \(product.dietaryTags.joined(separator: ", "))")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        showNutrition.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Nutrition facts")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: showNutrition ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.instacartChip))
                    }
                    .buttonStyle(.plain)

                    if showNutrition {
                        nutritionFactsPanel
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Frequently bought together")
                        .font(.system(size: 20, weight: .heavy))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(relatedProducts) { relatedProduct in
                                RelatedProductCard(product: relatedProduct) {
                                    selectedRelatedProduct = relatedProduct
                                } onAdd: {
                                    store.addToCart(productID: relatedProduct.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(Color.instacartBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationDestination(item: $selectedRelatedProduct) { relatedProduct in
            ProductDetailView(product: relatedProduct, store: store)
        }
    }

    private var topButtons: some View {
        HStack {
            InsetIconButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            InsetIconButton(systemImage: store.isSavedProduct(product.id) ? "bookmark.fill" : "bookmark") {
                store.toggleSavedProduct(product.id)
            }

            ShareLink(item: shareMessage) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.94)))
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 20) {
                Button {
                    quantity = max(1, quantity - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("product_detail_quantity_decrement_\(AccessibilityID.slug(product.id))")

                Text("\(quantity)")
                    .font(.system(size: 18, weight: .bold))

                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("product_detail_quantity_increment_\(AccessibilityID.slug(product.id))")
            }
            .frame(width: 130, height: 54)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))

            Button(product.inStock ? "Add to cart" : "Out of stock") {
                store.addToCart(productID: product.id, quantity: quantity)
                dismiss()
            }
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(product.inStock ? Color.instacartGreen : Color.gray))
            .disabled(product.inStock == false)
            .accessibilityIdentifier(AccessibilityID.addToCart(product.id))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.instacartBackground)
    }

    private var relatedProducts: [Product] {
        let categoryMatches = store.products(categoryID: product.categoryID, storeID: product.storeID)
            .filter { $0.id != product.id }
        return Array(categoryMatches.prefix(3))
    }

    private var shareMessage: String {
        "\(product.productName) on FreshCart for \(AppFormatters.currencyString(product.price))."
    }

    private var nutritionFactsPanel: some View {
        let seed = product.id.hashValue
        let calories = 80 + abs(seed % 350)
        let fat = 1 + abs(seed % 25)
        let saturatedFat = max(0, fat / 3)
        let sodium = 20 + abs(seed % 600)
        let carbs = 5 + abs(seed % 45)
        let fiber = abs(seed % 8)
        let sugars = abs(seed % 20)
        let protein = 1 + abs(seed % 25)

        return VStack(alignment: .leading, spacing: 0) {
            Text("Nutrition Facts")
                .font(.system(size: 22, weight: .black))
            Rectangle().fill(Color.primary).frame(height: 8).padding(.vertical, 2)
            nutritionRow("Serving size", "\(product.packageSize)", bold: true)
            Rectangle().fill(Color.primary).frame(height: 4).padding(.vertical, 2)
            nutritionRow("Calories", "\(calories)", bold: true)
            Rectangle().fill(Color.primary).frame(height: 1).padding(.vertical, 1)
            nutritionRow("Total Fat", "\(fat)g", bold: true)
            nutritionSubRow("Saturated Fat", "\(saturatedFat)g")
            nutritionSubRow("Trans Fat", "0g")
            Rectangle().fill(Color.primary).frame(height: 1).padding(.vertical, 1)
            nutritionRow("Sodium", "\(sodium)mg", bold: true)
            Rectangle().fill(Color.primary).frame(height: 1).padding(.vertical, 1)
            nutritionRow("Total Carbohydrate", "\(carbs)g", bold: true)
            nutritionSubRow("Dietary Fiber", "\(fiber)g")
            nutritionSubRow("Total Sugars", "\(sugars)g")
            Rectangle().fill(Color.primary).frame(height: 1).padding(.vertical, 1)
            nutritionRow("Protein", "\(protein)g", bold: true)
            Rectangle().fill(Color.primary).frame(height: 4).padding(.vertical, 2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.1)))
    }

    private func nutritionRow(_ label: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: bold ? .bold : .regular))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: bold ? .bold : .regular))
        }
        .padding(.vertical, 2)
    }

    private func nutritionSubRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .padding(.leading, 20)
            Spacer()
            Text(value)
                .font(.system(size: 14))
        }
        .padding(.vertical, 1)
    }
}
