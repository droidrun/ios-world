import Foundation

enum CheckoutPaymentAccountType: String, Codable {
    case checking
    case savings
    case credit
}

struct CheckoutPaymentAccount: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: CheckoutPaymentAccountType
    let balance: Double
    let availableBalance: Double
    let currency: String
    let lastUpdated: Date
    let creditLimit: Double?

    var maskedNumber: String {
        switch type {
        case .checking:
            return "**** **** **** 6645"
        case .savings:
            return "**** **** **** 7814"
        case .credit:
            return "**** **** **** 2095"
        }
    }

    var network: String {
        switch type {
        case .credit:
            return "MASTERCARD"
        case .checking:
            return "VISA DEBIT"
        case .savings:
            return "MASTERCARD DEBIT"
        }
    }

    var displayName: String {
        "\(network) \(maskedNumber)"
    }
}

final class MyBankCheckoutAccountsService {
    private let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private let fileName = "mybank_accounts.json"

    private var accountsURL: URL {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    func loadAccounts() -> [CheckoutPaymentAccount] {
        guard let data = try? Data(contentsOf: accountsURL) else {
            return defaultAccounts()
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([CheckoutPaymentAccount].self, from: data), !decoded.isEmpty {
            return decoded
        }

        return defaultAccounts()
    }

    private func defaultAccounts() -> [CheckoutPaymentAccount] {
        let now = Date()
        return [
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Total Checking (...6645)",
                type: .checking,
                balance: 2150.32,
                availableBalance: 2150.32,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Savings (...1032)",
                type: .savings,
                balance: 9400.00,
                availableBalance: 9400.00,
                currency: "USD",
                lastUpdated: now,
                creditLimit: nil
            ),
            CheckoutPaymentAccount(
                id: UUID(),
                name: "Freedom Unlimited (...2095)",
                type: .credit,
                balance: -642.13,
                availableBalance: 5357.87,
                currency: "USD",
                lastUpdated: now,
                creditLimit: 6000.0
            )
        ]
    }
}

final class MegaMartStore: ObservableObject {
    @Published private(set) var state: MegaMartSimState
    @Published private(set) var seededCatalog: CatalogData
    @Published private(set) var snapshotCatalog: CatalogData?
    @Published private(set) var snapshotLocationLabel: String
    @Published var searchNavigationRequest: SearchNavigationRequest?
    @Published var accountNavigationRequest: AccountNavigationRequest?
    @Published var inlineStatusMessage: String?

    private(set) var paymentAccounts: [CheckoutPaymentAccount] = []
    var selectedPaymentAccountID: UUID?

    private let persistence: AppPersistence
    private let seededRepository: SeededCatalogRepository
    private let snapshotRepository: SnapshotCatalogRepository
    private let myBankAccountsService = MyBankCheckoutAccountsService()

    init(
        persistence: AppPersistence = AppPersistence(),
        seededRepository: SeededCatalogRepository = SeededCatalogRepository()
    ) {
        self.persistence = persistence
        self.seededRepository = seededRepository
        self.snapshotRepository = SnapshotCatalogRepository(persistence: persistence)

        let seededCatalog = seededRepository.loadCatalog() ?? CatalogData(metadata: nil, departments: [], categories: [], products: [])
        let snapshotCatalog = self.snapshotRepository.loadCatalog()
        let snapshotLocationLabel = self.snapshotRepository.currentLocation?.label ?? "Unavailable"

        var initialState = persistence.loadState() ?? SeedData.initialState(snapshotMetadata: snapshotCatalog?.metadata)
        if initialState.snapshotMetadata == nil {
            initialState.snapshotMetadata = snapshotCatalog?.metadata
        }

        if initialState.selectedTab == .search {
            initialState.selectedTab = .home
        } else if initialState.selectedTab == .orders {
            initialState.selectedTab = .account
        }

        if initialState.catalogSource == .snapshot, snapshotCatalog == nil {
            initialState.catalogSource = .seeded
            self.inlineStatusMessage = "snapshot data unavailable"
        }

        self.seededCatalog = seededCatalog
        self.snapshotCatalog = snapshotCatalog
        self.snapshotLocationLabel = snapshotLocationLabel
        self.state = initialState
        persistence.saveState(initialState)

        paymentAccounts = myBankAccountsService.loadAccounts()
        selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
    }

    var selectedTab: AppTab {
        state.selectedTab
    }

    var isAuthenticated: Bool {
        state.isAuthenticated
    }

    var catalog: CatalogData {
        switch state.catalogSource {
        case .seeded:
            return seededCatalog
        case .snapshot:
            return snapshotCatalog ?? seededCatalog
        }
    }

    var catalogSourceLabel: String {
        switch state.catalogSource {
        case .seeded:
            return "Standard Catalog"
        case .snapshot:
            let provider = state.snapshotMetadata?.providerLabel ?? "Imported Catalog"
            return "Imported Catalog • \(provider)"
        }
    }

    var deliveryOptions: [DeliveryOption] {
        SeedData.deliveryOptions
    }

    var selectedAddress: Address? {
        state.addresses.first(where: { $0.id == state.selectedAddressID })
    }

    var selectedPaymentMethod: PaymentMethod? {
        state.paymentMethods.first(where: { $0.id == state.selectedPaymentMethodID })
    }

    var selectedPaymentAccount: CheckoutPaymentAccount? {
        guard let selectedPaymentAccountID else { return nil }
        return paymentAccounts.first(where: { $0.id == selectedPaymentAccountID })
    }

    func refreshPaymentAccounts() {
        paymentAccounts = myBankAccountsService.loadAccounts()
        if selectedPaymentAccountID == nil || !paymentAccounts.contains(where: { $0.id == selectedPaymentAccountID }) {
            selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
        }
    }

    var activeOrders: [Order] {
        state.orders
            .filter { $0.status.isActive }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var deliveredOrders: [Order] {
        state.orders
            .filter { $0.status == .delivered || $0.status == .returned }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var canceledOrders: [Order] {
        state.orders
            .filter { $0.status == .canceled }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var recentlyViewedProducts: [Product] {
        state.recentlyViewedProductIDs.compactMap(product(for:))
    }

    var recommendedProducts: [Product] {
        catalog.products
            .filter(\.inStock)
            .sorted { lhs, rhs in
                if lhs.popularityRank == rhs.popularityRank {
                    return lhs.rating > rhs.rating
                }
                return lhs.popularityRank < rhs.popularityRank
            }
            .prefix(10)
            .map { $0 }
    }

    var dealProducts: [Product] {
        catalog.products
            .filter { ($0.originalPrice ?? $0.price) > $0.price }
            .sorted {
                ($0.discountPercent ?? 0) > ($1.discountPercent ?? 0)
            }
            .prefix(8)
            .map { $0 }
    }

    var homeCategories: [ProductCategory] {
        catalog.categories.prefix(8).map { $0 }
    }

    var buyAgainProducts: [Product] {
        var seen = Set<String>()
        return deliveredOrders
            .flatMap(\.items)
            .compactMap { item in
                guard !seen.contains(item.productID), let product = product(for: item.productID) else {
                    return nil
                }
                seen.insert(item.productID)
                return product
            }
            .prefix(8)
            .map { $0 }
    }

    var cartSubtotal: Double {
        state.cartItems.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) }
    }

    var cartDiscountEstimate: Double {
        state.cartItems.reduce(0) { partial, item in
            let baseline = (item.originalUnitPrice ?? item.unitPrice) * Double(item.quantity)
            return partial + max(0, baseline - (item.unitPrice * Double(item.quantity)))
        }
    }

    var cartShippingEstimate: Double {
        state.cartItems.isEmpty ? 0 : 0
    }

    var cartTaxEstimate: Double {
        roundCurrency(cartSubtotal * 0.0825)
    }

    var cartEstimatedTotal: Double {
        roundCurrency(cartSubtotal + cartShippingEstimate + cartTaxEstimate)
    }

    var cartItemCount: Int {
        state.cartItems.reduce(0) { $0 + $1.quantity }
    }

    func reviews(for productID: String) -> [UserReview] {
        state.userReviews.filter { $0.productID == productID && $0.authorName == state.userProfile.name }
            .sorted { $0.reviewDate > $1.reviewDate }
    }

    func communityReviews(for productID: String) -> [UserReview] {
        state.userReviews.filter { $0.productID == productID && $0.authorName != state.userProfile.name }
            .sorted { $0.reviewDate > $1.reviewDate }
    }

    func departments(in departmentIDs: Set<String>? = nil) -> [Department] {
        guard let departmentIDs, !departmentIDs.isEmpty else {
            return catalog.departments
        }
        return catalog.departments.filter { departmentIDs.contains($0.id) }
    }

    func categories(for departmentID: String? = nil) -> [ProductCategory] {
        guard let departmentID else { return catalog.categories }
        return catalog.categories.filter { $0.departmentID == departmentID }
    }

    func products(for categoryID: String? = nil, departmentID: String? = nil) -> [Product] {
        catalog.products.filter { product in
            let departmentMatch = departmentID == nil || product.departmentID == departmentID
            let categoryMatch = categoryID == nil || product.categoryID == categoryID
            return departmentMatch && categoryMatch
        }
    }

    func product(for productID: String) -> Product? {
        if let current = catalog.products.first(where: { $0.id == productID }) {
            return current
        }
        if let seeded = seededCatalog.products.first(where: { $0.id == productID }) {
            return seeded
        }
        return snapshotCatalog?.products.first(where: { $0.id == productID })
    }

    func category(for categoryID: String) -> ProductCategory? {
        catalog.categories.first(where: { $0.id == categoryID })
            ?? seededCatalog.categories.first(where: { $0.id == categoryID })
            ?? snapshotCatalog?.categories.first(where: { $0.id == categoryID })
    }

    func department(for departmentID: String) -> Department? {
        catalog.departments.first(where: { $0.id == departmentID })
            ?? seededCatalog.departments.first(where: { $0.id == departmentID })
            ?? snapshotCatalog?.departments.first(where: { $0.id == departmentID })
    }

    func setSelectedTab(_ tab: AppTab) {
        mutateState { state in
            state.selectedTab = tab
        }
    }

    func dismissInlineMessage() {
        inlineStatusMessage = nil
    }

    func navigateToSearch(query: String = "", departmentID: String? = nil, categoryID: String? = nil) {
        setSelectedTab(.home)
        searchNavigationRequest = SearchNavigationRequest(query: query, departmentID: departmentID, categoryID: categoryID)
    }

    func navigateToAccount(_ target: AccountNavigationTarget) {
        setSelectedTab(.account)
        accountNavigationRequest = AccountNavigationRequest(target: target)
    }

    func recordSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mutateState { state in
            var updated = state.recentSearches.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
            updated.insert(trimmed, at: 0)
            state.recentSearches = Array(updated.prefix(12))
        }
    }

    func markRecentlyViewed(productID: String) {
        guard product(for: productID) != nil else { return }
        mutateState { state in
            var updated = state.recentlyViewedProductIDs.filter { $0 != productID }
            updated.insert(productID, at: 0)
            state.recentlyViewedProductIDs = Array(updated.prefix(12))
        }
    }

    func previewCartItem(product: Product, quantity: Int, selectedVariantValues: [String: String]) -> CartItem {
        let adjustment = priceAdjustment(for: product, selection: selectedVariantValues)
        return CartItem(
            id: "preview_\(product.id)_\(AccessibilityID.slug(Formatters.variantSummary(selectedVariantValues)))",
            productID: product.id,
            productName: product.productName,
            brand: product.brand,
            unitPrice: roundCurrency(product.price + adjustment),
            originalUnitPrice: product.originalPrice.map { roundCurrency($0 + adjustment) },
            currency: product.currency,
            quantity: max(1, quantity),
            primeEligible: product.primeEligible,
            deliveryEstimate: product.deliveryEstimate,
            selectedVariantValues: selectedVariantValues,
            sellerName: product.sellerName,
            imageSystemName: product.imageSystemName,
            inStock: product.inStock
        )
    }

    func addToCart(product: Product, quantity: Int, selectedVariantValues: [String: String]) {
        guard canPurchase(product: product, selection: selectedVariantValues) else {
            inlineStatusMessage = product.inStock ? "variant unavailable" : "out of stock"
            return
        }

        let snapshot = previewCartItem(product: product, quantity: quantity, selectedVariantValues: selectedVariantValues)
        mutateState { state in
            if let index = state.cartItems.firstIndex(where: { $0.productID == snapshot.productID && $0.selectedVariantValues == snapshot.selectedVariantValues }) {
                state.cartItems[index].quantity += snapshot.quantity
            } else {
                state.cartItems.append(snapshot)
            }
        }
        inlineStatusMessage = "Added to cart"
    }

    func addToSaved(product: Product, selectedVariantValues: [String: String]) {
        let snapshot = previewCartItem(product: product, quantity: 1, selectedVariantValues: selectedVariantValues)
        guard !isSaved(productID: snapshot.productID, selectedVariantValues: selectedVariantValues) else {
            inlineStatusMessage = "Already saved"
            return
        }

        mutateState { state in
            state.savedItems.insert(
                SavedItem(
                    id: "saved_\(snapshot.productID)_\(AccessibilityID.slug(Formatters.variantSummary(selectedVariantValues)))",
                    productID: snapshot.productID,
                    productName: snapshot.productName,
                    brand: snapshot.brand,
                    unitPrice: snapshot.unitPrice,
                    originalUnitPrice: snapshot.originalUnitPrice,
                    currency: snapshot.currency,
                    primeEligible: snapshot.primeEligible,
                    deliveryEstimate: snapshot.deliveryEstimate,
                    selectedVariantValues: selectedVariantValues,
                    sellerName: snapshot.sellerName,
                    imageSystemName: snapshot.imageSystemName,
                    inStock: snapshot.inStock,
                    savedAt: state.simulationDate
                ),
                at: 0
            )
        }
        inlineStatusMessage = "Saved for later"
    }

    func isSaved(productID: String) -> Bool {
        state.savedItems.contains(where: { $0.productID == productID })
    }

    func isSaved(productID: String, selectedVariantValues: [String: String]) -> Bool {
        state.savedItems.contains {
            $0.productID == productID && $0.selectedVariantValues == selectedVariantValues
        }
    }

    func updateCartQuantity(cartItemID: String, delta: Int) {
        mutateState { state in
            guard let index = state.cartItems.firstIndex(where: { $0.id == cartItemID }) else { return }
            state.cartItems[index].quantity += delta
            if state.cartItems[index].quantity <= 0 {
                state.cartItems.remove(at: index)
            }
        }
    }

    func removeCartItem(cartItemID: String) {
        mutateState { state in
            state.cartItems.removeAll { $0.id == cartItemID }
        }
        inlineStatusMessage = "Removed from cart"
    }

    func moveCartItemToSaved(cartItemID: String) {
        guard let cartItem = state.cartItems.first(where: { $0.id == cartItemID }) else { return }
        if let product = product(for: cartItem.productID) {
            addToSaved(product: product, selectedVariantValues: cartItem.selectedVariantValues)
        }
        removeCartItem(cartItemID: cartItemID)
    }

    func moveSavedItemToCart(savedItemID: String) {
        guard let savedItem = state.savedItems.first(where: { $0.id == savedItemID }),
              let product = product(for: savedItem.productID) else {
            return
        }
        addToCart(product: product, quantity: 1, selectedVariantValues: savedItem.selectedVariantValues)
        removeSavedItem(savedItemID: savedItemID)
    }

    func removeSavedItem(savedItemID: String) {
        mutateState { state in
            state.savedItems.removeAll { $0.id == savedItemID }
        }
        inlineStatusMessage = "Removed from list"
    }

    func placeOrder(
        items: [CartItem],
        selectedAddressID: String,
        selectedPaymentMethodID: String,
        deliveryOptionID: String,
        promoCode: String,
        isGift: Bool,
        clearCart: Bool
    ) -> Order? {
        guard !items.isEmpty else {
            inlineStatusMessage = "checkout unavailable"
            return nil
        }

        guard let address = state.addresses.first(where: { $0.id == selectedAddressID }),
              let paymentMethod = state.paymentMethods.first(where: { $0.id == selectedPaymentMethodID }),
              let deliveryOption = deliveryOptions.first(where: { $0.id == deliveryOptionID }) else {
            inlineStatusMessage = "checkout unavailable"
            return nil
        }

        let orderNumber = nextOrderNumber()
        let createdAt = state.simulationDate
        let normalizedPromo = promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let itemSubtotal = roundCurrency(items.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) })
        let discount: Double

        switch normalizedPromo {
        case "SAVE10", "WELCOME10":
            discount = min(10, itemSubtotal)
        case "SPRING15":
            discount = min(15, itemSubtotal)
        default:
            discount = 0
        }

        let shippingCost = deliveryOption.additionalCost
        let tax = roundCurrency(max(0, itemSubtotal + shippingCost - discount) * 0.0825)
        let total = roundCurrency(itemSubtotal + shippingCost + tax - discount)
        let orderItems = items.map {
            OrderItem(
                id: "placed_\($0.id)",
                productID: $0.productID,
                productName: $0.productName,
                brand: $0.brand,
                unitPrice: $0.unitPrice,
                originalUnitPrice: $0.originalUnitPrice,
                currency: $0.currency,
                quantity: $0.quantity,
                selectedVariantValues: $0.selectedVariantValues,
                imageSystemName: $0.imageSystemName
            )
        }
        var events = SeedData.statusEvents(for: .ordered, orderNumber: orderNumber, createdAt: createdAt)
        if isGift {
            events.append(
                OrderStatusEvent(
                    id: "\(orderNumber)_gift",
                    status: .ordered,
                    timestamp: createdAt.addingTimeInterval(20 * 60),
                    summary: "Gift option selected"
                )
            )
            events.sort { $0.timestamp < $1.timestamp }
        }

        let order = Order(
            id: "order_\(orderNumber.lowercased())",
            orderNumber: orderNumber,
            status: .ordered,
            createdAt: createdAt,
            updatedAt: events.last?.timestamp ?? createdAt,
            items: orderItems,
            shippingAddress: address,
            paymentMethod: paymentMethod,
            deliveryOption: deliveryOption,
            itemSubtotal: itemSubtotal,
            shippingCost: shippingCost,
            tax: tax,
            discount: discount,
            estimatedTotal: total,
            sourceType: state.catalogSource,
            statusEvents: events
        )

        mutateState { state in
            state.orders.insert(order, at: 0)
            if clearCart {
                state.cartItems.removeAll()
            }
            state.selectedAddressID = selectedAddressID
            state.selectedPaymentMethodID = selectedPaymentMethodID
            state.simulationDate = createdAt.addingTimeInterval(10 * 60)
        }

        MegaMartMailOutboxWriter.recordOrderEmail(order)
        if let accountId = selectedPaymentAccountID {
            MegaMartMyBankLedgerWriter.recordOrder(order, total: order.estimatedTotal, paymentAccountId: accountId)
        }
        inlineStatusMessage = "Order \(orderNumber) placed"
        return order
    }

    func advanceFirstActiveOrder() {
        guard let order = activeOrders.first else {
            inlineStatusMessage = "no active orders"
            return
        }
        advanceOrder(orderID: order.id)
    }

    func advanceAllActiveOrders() {
        let activeIDs = activeOrders.map(\.id)
        guard !activeIDs.isEmpty else {
            inlineStatusMessage = "no active orders"
            return
        }
        activeIDs.forEach(advanceOrder(orderID:))
        inlineStatusMessage = "Advanced active order states"
    }

    func advanceOrder(orderID: String) {
        guard let order = state.orders.first(where: { $0.id == orderID }),
              let nextStatus = nextStatus(after: order.status) else {
            return
        }

        let advancedDate = state.simulationDate.addingTimeInterval(6 * 60 * 60)
        let summary = nextStatus.title
        let event = OrderStatusEvent(
            id: "\(order.orderNumber)_\(nextStatus.rawValue)_\(Int(advancedDate.timeIntervalSince1970))",
            status: nextStatus,
            timestamp: advancedDate,
            summary: summary
        )

        mutateState { state in
            guard let index = state.orders.firstIndex(where: { $0.id == orderID }) else { return }
            let current = state.orders[index]
            state.orders[index] = Order(
                id: current.id,
                orderNumber: current.orderNumber,
                status: nextStatus,
                createdAt: current.createdAt,
                updatedAt: advancedDate,
                items: current.items,
                shippingAddress: current.shippingAddress,
                paymentMethod: current.paymentMethod,
                deliveryOption: current.deliveryOption,
                itemSubtotal: current.itemSubtotal,
                shippingCost: current.shippingCost,
                tax: current.tax,
                discount: current.discount,
                estimatedTotal: current.estimatedTotal,
                sourceType: current.sourceType,
                statusEvents: (current.statusEvents + [event]).sorted { $0.timestamp < $1.timestamp }
            )
            state.simulationDate = advancedDate
        }
    }

    func cancelOrder(orderID: String) {
        guard let order = state.orders.first(where: { $0.id == orderID }), order.canCancel else {
            return
        }

        let canceledAt = state.simulationDate.addingTimeInterval(30 * 60)
        let event = OrderStatusEvent(
            id: "\(order.orderNumber)_canceled_manual",
            status: .canceled,
            timestamp: canceledAt,
            summary: "Order canceled"
        )

        mutateState { state in
            guard let index = state.orders.firstIndex(where: { $0.id == orderID }) else { return }
            let current = state.orders[index]
            state.orders[index] = Order(
                id: current.id,
                orderNumber: current.orderNumber,
                status: .canceled,
                createdAt: current.createdAt,
                updatedAt: canceledAt,
                items: current.items,
                shippingAddress: current.shippingAddress,
                paymentMethod: current.paymentMethod,
                deliveryOption: current.deliveryOption,
                itemSubtotal: current.itemSubtotal,
                shippingCost: current.shippingCost,
                tax: current.tax,
                discount: current.discount,
                estimatedTotal: current.estimatedTotal,
                sourceType: current.sourceType,
                statusEvents: (current.statusEvents + [event]).sorted { $0.timestamp < $1.timestamp }
            )
            state.simulationDate = canceledAt
        }
        inlineStatusMessage = "Order canceled"
    }

    func reorder(orderID: String) {
        guard let order = state.orders.first(where: { $0.id == orderID }) else { return }
        for item in order.items {
            if let product = product(for: item.productID) {
                addToCart(product: product, quantity: item.quantity, selectedVariantValues: item.selectedVariantValues)
            }
        }
        setSelectedTab(.cart)
        inlineStatusMessage = "Added order items back to cart"
    }

    func selectAddress(_ addressID: String) {
        guard let address = state.addresses.first(where: { $0.id == addressID }) else { return }
        mutateState { state in
            state.selectedAddressID = addressID
            state.userProfile = updatedProfile(state.userProfile, deliveryLocation: deliveryLocationLabel(for: address))
        }
        inlineStatusMessage = "Delivering to \(address.city) \(address.postalCode)"
    }

    func upsertCurrentLocationAddress(_ address: Address) {
        mutateState { state in
            if let index = state.addresses.firstIndex(where: { $0.id == address.id }) {
                state.addresses[index] = address
                let updatedAddress = state.addresses.remove(at: index)
                state.addresses.insert(updatedAddress, at: 0)
            } else {
                state.addresses.insert(address, at: 0)
            }
            state.selectedAddressID = address.id
            state.userProfile = updatedProfile(state.userProfile, deliveryLocation: deliveryLocationLabel(for: address))
        }
        inlineStatusMessage = "Delivering to \(address.city) \(address.postalCode)"
    }

    func selectPaymentMethod(_ paymentMethodID: String) {
        guard state.paymentMethods.contains(where: { $0.id == paymentMethodID }) else { return }
        mutateState { state in
            state.selectedPaymentMethodID = paymentMethodID
        }
        inlineStatusMessage = "Payment method updated"
    }

    func signIn(email: String) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { return }

        mutateState { state in
            state.isAuthenticated = true
            if normalizedEmail != state.userProfile.email.lowercased() {
                let existing = state.userProfile
                state.userProfile = UserProfile(
                    id: existing.id,
                    name: existing.name,
                    email: normalizedEmail,
                    membershipLabel: existing.membershipLabel,
                    defaultDeliveryLocation: existing.defaultDeliveryLocation,
                    profileNote: existing.profileNote
                )
            }
        }
        inlineStatusMessage = "Signed in successfully"
    }

    func createAccount(name: String, email: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedName.isEmpty, !normalizedEmail.isEmpty else { return }

        mutateState { state in
            let current = state.userProfile
            state.userProfile = UserProfile(
                id: current.id,
                name: trimmedName,
                email: normalizedEmail,
                membershipLabel: "MegaMart customer",
                defaultDeliveryLocation: current.defaultDeliveryLocation,
                profileNote: "Local account ready for shopping, checkout, and order tracking."
            )
            state.isAuthenticated = true
        }
        inlineStatusMessage = "Account created"
    }

    func signOut() {
        mutateState { state in
            state.isAuthenticated = false
        }
        inlineStatusMessage = "Signed out"
    }

    func requestReturn(orderID: String, reason: String) {
        guard let order = state.orders.first(where: { $0.id == orderID }),
              order.status == .delivered else {
            return
        }

        let returnedAt = state.simulationDate.addingTimeInterval(45 * 60)
        let summary = reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Return requested" : "Return requested: \(reason)"
        let event = OrderStatusEvent(
            id: "\(order.orderNumber)_returned_request",
            status: .returned,
            timestamp: returnedAt,
            summary: summary
        )

        mutateState { state in
            guard let index = state.orders.firstIndex(where: { $0.id == orderID }) else { return }
            let current = state.orders[index]
            state.orders[index] = Order(
                id: current.id,
                orderNumber: current.orderNumber,
                status: .returned,
                createdAt: current.createdAt,
                updatedAt: returnedAt,
                items: current.items,
                shippingAddress: current.shippingAddress,
                paymentMethod: current.paymentMethod,
                deliveryOption: current.deliveryOption,
                itemSubtotal: current.itemSubtotal,
                shippingCost: current.shippingCost,
                tax: current.tax,
                discount: current.discount,
                estimatedTotal: current.estimatedTotal,
                sourceType: current.sourceType,
                statusEvents: (current.statusEvents + [event]).sorted { $0.timestamp < $1.timestamp }
            )
            state.simulationDate = returnedAt
        }
        inlineStatusMessage = "Return started for \(order.orderNumber)"
    }

    func reorderMostRecentDeliveredOrder() {
        guard let order = deliveredOrders.first else {
            inlineStatusMessage = "no past orders"
            return
        }
        reorder(orderID: order.id)
    }

    func setCatalogSource(_ source: CatalogSourceType) {
        guard source != state.catalogSource else { return }

        if source == .snapshot, snapshotCatalog == nil {
            inlineStatusMessage = "snapshot data unavailable"
            return
        }

        mutateState { state in
            state.catalogSource = source
            if source == .snapshot {
                state.snapshotMetadata = snapshotCatalog?.metadata
            }
        }
    }

    func reloadBundledSnapshotData() {
        guard let catalog = snapshotRepository.reloadBundledSnapshotData() else {
            inlineStatusMessage = "snapshot data unavailable"
            return
        }

        snapshotCatalog = catalog
        snapshotLocationLabel = snapshotRepository.currentLocation?.label ?? "Unavailable"
        mutateState { state in
            state.snapshotMetadata = catalog.metadata
        }
        inlineStatusMessage = "Reloaded bundled snapshot data"
    }

    func resetAppState() {
        persistence.clearState()
        persistence.removeSandboxSnapshotData()
        seededCatalog = seededRepository.loadCatalog() ?? seededCatalog
        snapshotCatalog = snapshotRepository.loadCatalog()
        snapshotLocationLabel = snapshotRepository.currentLocation?.label ?? "Unavailable"
        state = SeedData.initialState(snapshotMetadata: snapshotCatalog?.metadata)
        persistence.saveState(state)
        inlineStatusMessage = "App state reset"
    }

    func canPurchase(product: Product, selection: [String: String]) -> Bool {
        guard product.inStock else { return false }
        for group in product.variantGroups {
            guard let selectedValue = selection[group] else { continue }
            if let variant = product.variants.first(where: { $0.variantName == group && $0.variantValue == selectedValue }),
               !variant.isAvailable {
                return false
            }
        }
        return true
    }

    private func mutateState(_ update: (inout MegaMartSimState) -> Void) {
        var draft = state
        update(&draft)
        state = draft
        persistence.saveState(draft)
    }

    private func nextOrderNumber() -> String {
        let highest = state.orders.compactMap { order -> Int? in
            Int(order.orderNumber.replacingOccurrences(of: "AMZ", with: ""))
        }.max() ?? 100246
        return "AMZ\(highest + 1)"
    }

    private func nextStatus(after status: OrderStatus) -> OrderStatus? {
        switch status {
        case .ordered:
            return .preparingForShipment
        case .preparingForShipment:
            return .shipped
        case .shipped:
            return .outForDelivery
        case .outForDelivery:
            return .delivered
        case .delivered, .canceled, .returned:
            return nil
        }
    }

    private func priceAdjustment(for product: Product, selection: [String: String]) -> Double {
        selection.reduce(0) { partial, item in
            let variant = product.variants.first(where: { $0.variantName == item.key && $0.variantValue == item.value })
            return partial + (variant?.priceAdjustment ?? 0)
        }
    }

    private func deliveryLocationLabel(for address: Address) -> String {
        "Deliver to \(address.city) \(address.postalCode)"
    }

    private func updatedProfile(_ profile: UserProfile, deliveryLocation: String) -> UserProfile {
        UserProfile(
            id: profile.id,
            name: profile.name,
            email: profile.email,
            membershipLabel: profile.membershipLabel,
            defaultDeliveryLocation: deliveryLocation,
            profileNote: profile.profileNote
        )
    }

    private func roundCurrency(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

struct MegaMartMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "megamart.amazon_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordOrderEmail(_ order: Order) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; MegaMart email write skipped.")
            return
        }

        let totalText = String(format: "$%.2f", order.estimatedTotal)
        let subject = "Your MegaMart order is confirmed"
        let itemSummary = order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: "\n        ")
        let addressLabel = order.shippingAddress.label
        let body = """
        Hi \(order.shippingAddress.recipientName),

        Your MegaMart order is confirmed.

        Order number: \(order.orderNumber)
        Items:
        \(itemSummary)
        Total: \(totalText)
        Delivery address: \(addressLabel)

        Thanks,
        MegaMart
        """

        let record = MailRecord(
            id: UUID(),
            from: "MegaMart",
            subject: subject,
            body: body,
            category: 1,
            date: Date()
        )

        ioQueue.async {
            var records = loadRecords(from: url)
            records.append(record)
            saveRecords(records, to: url)
        }
    }

    private static func inboxURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadRecords(from url: URL) -> [MailRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([MailRecord].self, from: data)) ?? []
    }

    private static func saveRecords(_ records: [MailRecord], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[Mail] Failed to write MegaMart email: \(error)")
        }
    }
}

struct MegaMartMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "megamart.amazon_ledger.io", qos: .utility)

    private struct LedgerTransaction: Codable {
        let id: UUID
        let externalId: String
        let accountId: UUID
        let vendor: String
        let amount: Double
        let currency: String
        let category: String
        let note: String?
        let timestamp: Date
        let status: String
        let sourceApp: String
        let rawSource: String

        enum CodingKeys: String, CodingKey {
            case id
            case externalId = "external_id"
            case accountId = "account_id"
            case vendor
            case amount
            case currency
            case category
            case note
            case timestamp
            case status
            case sourceApp = "source_app"
            case rawSource = "raw_source"
        }
    }

    static func recordOrder(_ order: Order, total: Double, paymentAccountId: UUID) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; MegaMart ledger write skipped.")
            return
        }

        let note = order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: ", ")

        let record = LedgerTransaction(
            id: UUID(),
            externalId: order.id,
            accountId: paymentAccountId,
            vendor: "MegaMart",
            amount: -abs(total),
            currency: "USD",
            category: "Shopping",
            note: note.isEmpty ? nil : note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "MegaMart",
            rawSource: "megamart_checkout"
        )

        ioQueue.async {
            var records = loadLedger(from: url)
            if records.contains(where: { $0.externalId == record.externalId }) {
                return
            }
            records.append(record)
            saveLedger(records, to: url)
        }
    }

    private static func ledgerURL() -> URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    private static func loadLedger(from url: URL) -> [LedgerTransaction] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([LedgerTransaction].self, from: data)) ?? []
    }

    private static func saveLedger(_ records: [LedgerTransaction], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[MyBank] Failed to write MegaMart ledger: \(error)")
        }
    }
}
