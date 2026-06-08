import Foundation

struct CartLineItem: Identifiable {
    let product: Product
    let cartItem: CartItem

    var id: String { product.id }
    var lineTotal: Double { product.price * Double(cartItem.quantity) }
}

@MainActor
final class HomeViewModel: StoreBackedViewModel {
    var selectedStore: Store? { store.selectedStore }
    var stores: [Store] { store.stores }
    var selectedAddress: Address? { store.selectedAddress }
    var deliveryMode: DeliveryMode { store.state.deliveryMode }
    var categories: [ProductCategory] { Array(store.categories.prefix(8)) }
    var recommendedProducts: [Product] { store.productsForSelectedStore.filter(\.isRecommended).prefix(8).map { $0 } }
    var buyAgainProducts: [Product] { store.productsForSelectedStore.filter(\.isBuyAgain).prefix(8).map { $0 } }
    var promotions: [Promotion] { store.state.promotions }
    var membershipStatus: MembershipStatus { store.state.membershipStatus }
    var pastOrders: [Order] { Array(store.pastOrders.prefix(4)) }

    func selectStore(_ storeID: String) { store.selectStore(storeID) }
    func setMode(_ mode: DeliveryMode) { store.setDeliveryMode(mode) }
    func searchGroceries() { store.switchTab(.search) }
    func viewCart() { store.switchTab(.cart) }
    func viewOrders() { store.switchTab(.orders) }
    func scheduleDelivery() { store.switchTab(.cart) }

    func reorderMostRecent() {
        guard let order = store.pastOrders.first else { return }
        store.reorder(order.id)
    }
}

@MainActor
final class BrowseViewModel: StoreBackedViewModel {
    var categories: [ProductCategory] { store.categories }
    var selectedStore: Store? { store.selectedStore }

    func products(for categoryID: String?) -> [Product] {
        store.products(categoryID: categoryID)
    }

    func addToCart(productID: String) {
        store.addToCart(productID: productID)
    }

    func setMode(_ mode: DeliveryMode) {
        store.setDeliveryMode(mode)
    }

    func selectStore(_ storeID: String) {
        let cartWillClear = store.state.cartItems.contains { item in
            store.product(with: item.productID)?.storeID != storeID
        }
        store.selectStore(storeID)
        if let selectedStore = store.store(with: storeID) {
            if cartWillClear {
                store.postInlineStatusMessage("Switched to \(selectedStore.storeName). Cart was cleared for a single-store checkout.")
            } else {
                store.postInlineStatusMessage("Switched to \(selectedStore.storeName).")
            }
        }
    }
}

@MainActor
final class SearchViewModel: StoreBackedViewModel {
    struct StoreSearchMatch: Identifiable {
        let store: Store
        let totalCount: Int
        let results: [Product]

        var id: String { store.id }
        var resultCount: Int { totalCount }
        var previewProduct: Product? { results.first }
    }

    @Published var query: String = ""
    @Published var selectedCategoryID: String?
    @Published var selectedBrand: String?
    @Published var selectedDietaryTag: String?
    @Published var organicOnly: Bool = false
    @Published var onSaleOnly: Bool = false
    @Published var inStockOnly: Bool = true
    @Published var availabilityFilter: AvailabilityFilter = .all
    @Published var sortOption: SearchSortOption = .relevance

    var recentSearches: [String] { store.state.recentSearches }
    var popularSearches: [String] { SeededCatalogRepository.popularSearches }
    var categories: [ProductCategory] { store.categories }
    var brands: [String] { store.availableBrands }
    var dietaryTags: [String] { store.availableDietaryTags }
    var selectedStore: Store? { store.selectedStore }
    var results: [Product] {
        store.searchProducts(
            query: query,
            categoryID: selectedCategoryID,
            brand: selectedBrand,
            dietaryTag: selectedDietaryTag,
            organicOnly: organicOnly,
            onSaleOnly: onSaleOnly,
            inStockOnly: inStockOnly,
            availability: availabilityFilter,
            sort: sortOption
        )
    }
    var suggestedCategories: [ProductCategory] {
        let storeCategoryIDs = Set(store.productsForSelectedStore.map(\.categoryID))
        return store.categories.filter { storeCategoryIDs.contains($0.id) }.prefix(6).map { $0 }
    }
    var otherStoreMatches: [StoreSearchMatch] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else { return [] }

        return store.stores.compactMap { candidateStore in
            guard candidateStore.id != store.state.selectedStoreID else { return nil }
            let matches = store.searchProducts(
                query: query,
                categoryID: selectedCategoryID,
                brand: selectedBrand,
                dietaryTag: selectedDietaryTag,
                organicOnly: organicOnly,
                onSaleOnly: onSaleOnly,
                inStockOnly: inStockOnly,
                availability: availabilityFilter,
                sort: sortOption,
                storeID: candidateStore.id
            )
            guard matches.isEmpty == false else { return nil }
            return StoreSearchMatch(store: candidateStore, totalCount: matches.count, results: Array(matches.prefix(3)))
        }
        .sorted { lhs, rhs in
            if lhs.resultCount == rhs.resultCount {
                return lhs.store.distanceMiles < rhs.store.distanceMiles
            }
            return lhs.resultCount > rhs.resultCount
        }
        .prefix(4)
        .map { $0 }
    }

    func setQueryText(_ value: String) {
        query = value
    }

    func commitCurrentQuery() {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            store.upsertRecentSearch(query)
        }
    }

    func browseCategory(_ categoryID: String) {
        selectedCategoryID = categoryID
        query = ""
        selectedBrand = nil
        selectedDietaryTag = nil
        organicOnly = false
        onSaleOnly = false
        availabilityFilter = .all
    }

    func activateStoreMatch(_ storeID: String) {
        store.selectStore(storeID)
        store.switchTab(.search)
    }

    func toggleCategory(_ categoryID: String) {
        selectedCategoryID = selectedCategoryID == categoryID ? nil : categoryID
    }

    func toggleDietaryTag(_ dietaryTag: String) {
        selectedDietaryTag = selectedDietaryTag == dietaryTag ? nil : dietaryTag
    }

    func selectBrand(_ brand: String?) {
        selectedBrand = brand
    }

    func clearFilters() {
        selectedCategoryID = nil
        selectedBrand = nil
        selectedDietaryTag = nil
        organicOnly = false
        onSaleOnly = false
        inStockOnly = true
        availabilityFilter = .all
        sortOption = .relevance
    }

    func addToCart(productID: String) {
        store.addToCart(productID: productID)
    }
}

@MainActor
final class CartViewModel: StoreBackedViewModel {
    var selectedStore: Store? { store.selectedStore }
    var addresses: [Address] { store.state.userProfile.addresses }
    var paymentMethods: [PaymentMethod] { store.state.userProfile.paymentMethods }
    var paymentAccounts: [CheckoutPaymentAccount] { store.paymentAccounts }
    var selectedPaymentAccountID: UUID? {
        get { store.selectedPaymentAccountID }
        set { store.selectedPaymentAccountID = newValue }
    }
    var cartLineItems: [CartLineItem] {
        store.state.cartItems.compactMap { cartItem in
            guard let product = store.product(with: cartItem.productID) else { return nil }
            return CartLineItem(product: product, cartItem: cartItem)
        }
    }
    var deliveryMode: DeliveryMode { store.state.deliveryMode }
    var selectedAddress: Address? { store.selectedAddress }
    var selectedPaymentMethod: PaymentMethod? { store.selectedPaymentMethod }
    var selectedSlot: DeliverySlot? { store.selectedSlot }
    var availableSlots: [DeliverySlot] { store.availableSlots(for: store.state.deliveryMode) }
    var pricingSummary: PricingSummary { store.cartSummary() }
    var tipAmount: Double { store.state.tipAmount }
    var contactlessHandoff: Bool { store.state.contactlessHandoff }
    var orderNotes: String { store.state.orderNotes }
    var specialInstructions: String { store.state.specialInstructions }
    var checkoutAvailable: Bool { cartLineItems.isEmpty == false }
    var activeSubstitutionSummary: [String] {
        cartLineItems.map { "\($0.product.productName): \($0.cartItem.substitutionPreference.summary)" }
    }

    func setMode(_ mode: DeliveryMode) { store.setDeliveryMode(mode) }
    func increment(productID: String) { store.incrementCartItem(productID) }
    func decrement(productID: String) { store.decrementCartItem(productID) }
    func remove(productID: String) { store.removeCartItem(productID) }
    func updateSubstitution(productID: String, preference: SubstitutionPreference) { store.updateSubstitutionPreference(for: productID, preference: preference) }
    func setAddress(_ addressID: String) { store.setSelectedAddress(addressID) }
    func setPaymentMethod(_ paymentMethodID: String) { store.setSelectedPaymentMethod(paymentMethodID) }
    func setPaymentAccount(_ id: UUID) { store.selectedPaymentAccountID = id }
    var selectedPaymentAccount: CheckoutPaymentAccount? { store.selectedPaymentAccount }
    func setSlot(_ slotID: String) { store.setSelectedSlot(slotID) }
    func setTip(_ amount: Double) { store.setTipAmount(amount) }
    func setContactless(_ enabled: Bool) { store.setContactlessHandoff(enabled) }
    func setOrderNotes(_ notes: String) { store.setOrderNotes(notes) }
    func setSpecialInstructions(_ instructions: String) { store.setSpecialInstructions(instructions) }
    var priorityDelivery: Bool { store.state.priorityDelivery }
    func setPriorityDelivery(_ enabled: Bool) { store.setPriorityDelivery(enabled) }
    var membershipStatus: MembershipStatus { store.state.membershipStatus }
    var promoCode: String { store.state.promoCode }
    var promoApplied: Bool { store.state.promoApplied }
    func setPromoCode(_ code: String) { store.setPromoCode(code) }
    func applyPromoCode() { store.applyPromoCode() }
    func updateItemNote(productID: String, note: String) { store.updateCartItemNote(for: productID, note: note) }
    func placeOrder() -> Order? { store.placeOrder() }
}

@MainActor
final class OrdersViewModel: StoreBackedViewModel {
    var activeOrders: [Order] { store.activeOrders }
    var scheduledOrders: [Order] { store.scheduledOrders }
    var pastOrders: [Order] { store.pastOrders }

    func storeName(for order: Order) -> String {
        store.store(with: order.storeID)?.storeName ?? "Store"
    }

    func advanceOrder(_ orderID: String) {
        store.advanceOrderState(orderID)
    }

    func cancelOrder(_ orderID: String) {
        store.cancelOrder(orderID)
    }

    func reorder(_ orderID: String) {
        store.reorder(orderID)
    }

    func rateOrder(_ orderID: String, rating: ShopperRating) {
        store.rateOrder(orderID, rating: rating)
    }
}

@MainActor
final class AccountViewModel: StoreBackedViewModel {
    var userProfile: UserProfile { store.state.userProfile }
    var membershipStatus: MembershipStatus { store.state.membershipStatus }
    var savedStores: [Store] { store.state.userProfile.savedStoreIDs.compactMap { store.store(with: $0) } }
    var savedProducts: [Product] { store.savedProducts }
    var promotions: [Promotion] { store.state.promotions }
    var buyAgainProducts: [Product] { store.productsForSelectedStore.filter(\.isBuyAgain).prefix(5).map { $0 } }
    var sourceLabel: String { store.currentSourceLabel }
    var activeStoreID: String { store.state.selectedStoreID }

    func toggleNotifications(_ enabled: Bool) { store.setNotificationsEnabled(enabled) }
    func toggleSavedProduct(_ productID: String) { store.toggleSavedProduct(productID) }

    func selectStore(_ storeID: String) {
        store.selectStore(storeID)
        if let selectedStore = store.store(with: storeID) {
            store.postInlineStatusMessage("\(selectedStore.storeName) is now your active store.")
        }
    }
}

@MainActor
final class MoreViewModel: StoreBackedViewModel {
    var sourceType: CatalogSourceType { store.state.catalogSource }
    var metadata: CatalogSnapshotMetadata? { store.currentSnapshotMetadata }
    var currentSourceLabel: String { store.currentSourceLabel }
    var activeOrder: Order? { store.activeOrders.first ?? store.scheduledOrders.first }
    var persistencePathLabel: String { "Documents/catalog_snapshot.json" }

    func switchSource(_ source: CatalogSourceType) { store.setCatalogSource(source) }
    func reloadSnapshot() { store.reloadBundledSnapshotData() }
    func resetAppState() { store.resetAppState() }

    func advanceActiveOrder() {
        guard let order = activeOrder else { return }
        store.advanceOrderState(order.id)
    }
}
