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
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
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

@MainActor
final class FreshCartStore: ObservableObject {
    @Published private(set) var state: FreshCartState
    @Published private(set) var seededCatalog: CatalogData
    @Published private(set) var snapshotCatalog: CatalogData?
    @Published var inlineStatusMessage: String?
    @Published private(set) var paymentAccounts: [CheckoutPaymentAccount] = []
    var selectedPaymentAccountID: UUID?

    private let persistence: AppPersistence
    private let seededRepository: CatalogRepository
    private let snapshotRepository: SnapshotCatalogRepository
    private let myBankAccountsService = MyBankCheckoutAccountsService()

    init(
        persistence: AppPersistence = AppPersistence(),
        seededRepository: CatalogRepository = SeededCatalogRepository(),
        snapshotRepository: SnapshotCatalogRepository? = nil
    ) {
        self.persistence = persistence
        self.seededRepository = seededRepository
        self.snapshotRepository = snapshotRepository ?? SnapshotCatalogRepository(persistence: persistence)
        self.seededCatalog = (try? seededRepository.loadCatalog()) ?? CatalogData(metadata: CatalogSnapshotMetadata(providerLabel: "Fallback", sourceType: .seeded, snapshotTimestamp: Date(timeIntervalSince1970: 0), lastUpdated: Date(timeIntervalSince1970: 0)), stores: [], categories: [], products: [])
        self.snapshotCatalog = try? self.snapshotRepository.loadCatalog()
        let loadedState = persistence.loadState()
        self.state = loadedState ?? SeededCatalogRepository.initialState()

        if requiresSeedReset(for: state) {
            self.state = SeededCatalogRepository.initialState()
            persistence.saveState(self.state)
        }

        if state.catalogSource == .snapshot, snapshotCatalog == nil {
            state.catalogSource = .seeded
            inlineStatusMessage = "snapshot data unavailable"
            persistence.saveState(state)
        }

        paymentAccounts = myBankAccountsService.loadAccounts()
        selectedPaymentAccountID = paymentAccounts.first(where: { $0.type == .credit })?.id ?? paymentAccounts.first?.id
    }

    var activeCatalog: CatalogData {
        if state.catalogSource == .snapshot, let snapshotCatalog {
            return snapshotCatalog
        }
        return seededCatalog
    }

    var currentSourceLabel: String {
        if state.catalogSource == .snapshot, let snapshotCatalog {
            return "\(snapshotCatalog.metadata.sourceType.label) • \(snapshotCatalog.metadata.providerLabel)"
        }
        return "\(seededCatalog.metadata.sourceType.label) • \(seededCatalog.metadata.providerLabel)"
    }

    var currentSnapshotMetadata: CatalogSnapshotMetadata? {
        snapshotCatalog?.metadata
    }

    var stores: [Store] {
        activeCatalog.stores
    }

    var categories: [ProductCategory] {
        activeCatalog.categories.sorted(by: { $0.displayOrder < $1.displayOrder })
    }

    var selectedStore: Store? {
        store(with: state.selectedStoreID) ?? stores.first
    }

    var selectedAddress: Address? {
        state.userProfile.addresses.first(where: { $0.id == state.selectedAddressID }) ?? state.userProfile.addresses.first
    }

    var selectedPaymentMethod: PaymentMethod? {
        state.userProfile.paymentMethods.first(where: { $0.id == state.selectedPaymentMethodID }) ?? state.userProfile.paymentMethods.first
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

    var selectedSlot: DeliverySlot? {
        selectedSlot(for: state.deliveryMode)
    }

    var activeOrders: [Order] {
        state.orders
            .filter { $0.isActive }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    var scheduledOrders: [Order] {
        state.orders
            .filter { $0.orderStatus.isScheduled }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    var pastOrders: [Order] {
        state.orders
            .filter { $0.orderStatus.isPast }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    var cartProducts: [Product] {
        state.cartItems.compactMap { product(with: $0.productID) }
    }

    var savedProducts: [Product] {
        state.savedProductIDs.compactMap { product(with: $0) }
    }

    var availableBrands: [String] {
        Array(Set(productsForSelectedStore.map(\.brand))).sorted()
    }

    var availableDietaryTags: [String] {
        Array(Set(productsForSelectedStore.flatMap(\.dietaryTags))).sorted()
    }

    var productsForSelectedStore: [Product] {
        activeCatalog.products
            .filter { $0.storeID == state.selectedStoreID }
            .sorted(by: { $0.productName < $1.productName })
    }

    func switchTab(_ tab: AppTab) {
        mutateState { draftState, _ in
            draftState.selectedTab = tab
        }
    }

    func store(with id: String) -> Store? {
        activeCatalog.stores.first(where: { $0.id == id })
            ?? seededCatalog.stores.first(where: { $0.id == id })
            ?? snapshotCatalog?.stores.first(where: { $0.id == id })
    }

    func category(with id: String) -> ProductCategory? {
        activeCatalog.categories.first(where: { $0.id == id })
            ?? seededCatalog.categories.first(where: { $0.id == id })
            ?? snapshotCatalog?.categories.first(where: { $0.id == id })
    }

    func product(with id: String) -> Product? {
        activeCatalog.products.first(where: { $0.id == id })
            ?? seededCatalog.products.first(where: { $0.id == id })
            ?? snapshotCatalog?.products.first(where: { $0.id == id })
    }

    func products(categoryID: String? = nil, storeID: String? = nil) -> [Product] {
        let resolvedStoreID = storeID ?? state.selectedStoreID
        return activeCatalog.products
            .filter { product in
                product.storeID == resolvedStoreID && (categoryID == nil || product.categoryID == categoryID)
            }
            .sorted(by: { $0.productName < $1.productName })
    }

    func searchProducts(
        query: String,
        categoryID: String?,
        brand: String?,
        dietaryTag: String?,
        organicOnly: Bool,
        onSaleOnly: Bool,
        inStockOnly: Bool,
        availability: AvailabilityFilter,
        sort: SearchSortOption,
        storeID: String? = nil
    ) -> [Product] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let resolvedStore = storeID.flatMap(store(with:)) ?? selectedStore

        let filtered = products(categoryID: categoryID, storeID: resolvedStore?.id).filter { product in
            if trimmedQuery.isEmpty == false {
                let categoryName = category(with: product.categoryID)?.name ?? ""
                let haystack = "\(product.productName) \(product.brand) \(categoryName)".lowercased()
                let exactMatch = haystack.contains(trimmedQuery)
                if !exactMatch {
                    // Fuzzy matching: check each query word against haystack words
                    let queryWords = trimmedQuery.split(separator: " ").map(String.init)
                    let haystackWords = haystack.split(separator: " ").map(String.init)
                    let fuzzyMatch = queryWords.allSatisfy { qWord in
                        haystackWords.contains { hWord in
                            hWord.contains(qWord) || qWord.contains(hWord) || Self.editDistance(qWord, hWord) <= max(1, qWord.count / 4)
                        }
                    }
                    guard fuzzyMatch else { return false }
                }
            }
            if let brand, product.brand != brand { return false }
            if let dietaryTag, product.dietaryTags.contains(dietaryTag) == false { return false }
            if organicOnly, product.isOrganic == false { return false }
            if onSaleOnly, product.isOnSale == false { return false }
            if inStockOnly, product.inStock == false { return false }
            switch availability {
            case .all:
                break
            case .delivery:
                if resolvedStore?.supportsDelivery == false { return false }
            case .pickup:
                if resolvedStore?.supportsPickup == false { return false }
            }
            return true
        }

        switch sort {
        case .relevance:
            return filtered.sorted { lhs, rhs in
                relevanceScore(for: lhs, query: trimmedQuery) > relevanceScore(for: rhs, query: trimmedQuery)
            }
        case .priceLowToHigh:
            return filtered.sorted { $0.price < $1.price }
        case .priceHighToLow:
            return filtered.sorted { $0.price > $1.price }
        case .unitPrice:
            return filtered.sorted { unitPriceValue($0.unitPrice) < unitPriceValue($1.unitPrice) }
        }
    }

    func selectedSlot(for mode: DeliveryMode) -> DeliverySlot? {
        let slotID = mode == .delivery ? state.selectedDeliverySlotID : state.selectedPickupSlotID
        let availableSlots = mode == .delivery ? SeededCatalogRepository.deliverySlots : SeededCatalogRepository.pickupSlots
        return availableSlots.first(where: { $0.id == slotID }) ?? availableSlots.first(where: \.isAvailable) ?? availableSlots.first
    }

    func availableSlots(for mode: DeliveryMode) -> [DeliverySlot] {
        mode == .delivery ? SeededCatalogRepository.deliverySlots : SeededCatalogRepository.pickupSlots
    }

    func setCatalogSource(_ source: CatalogSourceType) {
        guard source != state.catalogSource else {
            return
        }

        if source == .snapshot {
            guard let snapshotCatalog = try? snapshotRepository.loadCatalog() else {
                inlineStatusMessage = "snapshot data unavailable"
                return
            }
            self.snapshotCatalog = snapshotCatalog
        }

        mutateState { draftState, _ in
            draftState.catalogSource = source
        }
    }

    func reloadBundledSnapshotData() {
        do {
            snapshotCatalog = try snapshotRepository.loadCatalog()
            inlineStatusMessage = "Snapshot catalog reloaded."
        } catch {
            inlineStatusMessage = "snapshot data unavailable"
        }
    }

    func resetAppState() {
        persistence.clearState()
        snapshotCatalog = try? snapshotRepository.loadCatalog()
        state = SeededCatalogRepository.initialState()
        persistence.saveState(state)
        inlineStatusMessage = "App state reset to defaults."
    }

    func selectStore(_ storeID: String) {
        guard let store = store(with: storeID) else { return }

        mutateState { draftState, _ in
            if draftState.selectedStoreID != storeID {
                swapCartForStoreChange(to: storeID, draftState: &draftState)
            }
            draftState.selectedStoreID = storeID
            if store.supports(mode: draftState.deliveryMode) == false {
                draftState.deliveryMode = store.supportsDelivery ? .delivery : .pickup
            }
        }
    }

    func setDeliveryMode(_ mode: DeliveryMode) {
        guard let selectedStore else { return }
        guard selectedStore.supports(mode: mode) else {
            inlineStatusMessage = mode == .delivery ? "delivery unavailable" : "pickup unavailable"
            return
        }

        mutateState { draftState, _ in
            draftState.deliveryMode = mode
        }
    }

    func setSelectedAddress(_ addressID: String) {
        guard state.userProfile.addresses.contains(where: { $0.id == addressID }) else { return }
        mutateState { draftState, _ in
            draftState.selectedAddressID = addressID
        }
    }

    func setSelectedPaymentMethod(_ paymentMethodID: String) {
        guard state.userProfile.paymentMethods.contains(where: { $0.id == paymentMethodID }) else { return }
        mutateState { draftState, _ in
            draftState.selectedPaymentMethodID = paymentMethodID
        }
    }

    func setSelectedSlot(_ slotID: String) {
        guard let slot = availableSlots(for: state.deliveryMode).first(where: { $0.id == slotID }) else { return }
        guard slot.isAvailable else {
            inlineStatusMessage = state.deliveryMode == .delivery ? "delivery unavailable" : "pickup unavailable"
            return
        }

        mutateState { draftState, _ in
            if draftState.deliveryMode == .delivery {
                draftState.selectedDeliverySlotID = slotID
            } else {
                draftState.selectedPickupSlotID = slotID
            }
        }
    }

    func setTipAmount(_ amount: Double) {
        mutateState { draftState, _ in
            draftState.tipAmount = amount
        }
    }

    func setContactlessHandoff(_ enabled: Bool) {
        mutateState { draftState, _ in
            draftState.contactlessHandoff = enabled
        }
    }

    func setOrderNotes(_ notes: String) {
        mutateState { draftState, _ in
            draftState.orderNotes = notes
        }
    }

    func setSpecialInstructions(_ instructions: String) {
        mutateState { draftState, _ in
            draftState.specialInstructions = instructions
        }
    }

    func setPriorityDelivery(_ enabled: Bool) {
        mutateState { draftState, _ in
            draftState.priorityDelivery = enabled
        }
    }

    func setPromoCode(_ code: String) {
        mutateState { draftState, _ in
            draftState.promoCode = code
            draftState.promoApplied = false
        }
    }

    func applyPromoCode() {
        let trimmed = state.promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty == false {
            mutateState { draftState, _ in
                draftState.promoApplied = true
            }
            postInlineStatusMessage("Promo code applied!")
        } else {
            postInlineStatusMessage("Enter a valid promo code.")
        }
    }

    func updateCartItemNote(for productID: String, note: String) {
        mutateState { draftState, _ in
            guard let index = draftState.cartItems.firstIndex(where: { $0.productID == productID }) else { return }
            draftState.cartItems[index].note = note
        }
    }

    func rateOrder(_ orderID: String, rating: ShopperRating) {
        mutateState { draftState, _ in
            guard let index = draftState.orders.firstIndex(where: { $0.id == orderID }) else { return }
            draftState.orders[index].shopperRating = rating
        }
        postInlineStatusMessage("Thanks for your feedback!")
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        mutateState { draftState, _ in
            draftState.userProfile.notificationsEnabled = enabled
        }
    }

    func isSavedProduct(_ productID: String) -> Bool {
        state.savedProductIDs.contains(productID)
    }

    func toggleSavedProduct(_ productID: String) {
        guard product(with: productID) != nil else { return }

        var isSaved = false
        mutateState { draftState, _ in
            if let index = draftState.savedProductIDs.firstIndex(of: productID) {
                draftState.savedProductIDs.remove(at: index)
                isSaved = false
            } else {
                draftState.savedProductIDs.insert(productID, at: 0)
                draftState.savedProductIDs = draftState.savedProductIDs.reduce(into: []) { partialResult, productID in
                    if partialResult.contains(productID) == false {
                        partialResult.append(productID)
                    }
                }
                isSaved = true
            }
        }

        inlineStatusMessage = isSaved ? "Saved item added." : "Saved item removed."
    }

    func clearInlineStatusMessage() {
        inlineStatusMessage = nil
    }

    func postInlineStatusMessage(_ message: String) {
        inlineStatusMessage = message
    }

    func addToCart(
        productID: String,
        quantity: Int = 1,
        substitutionPreference: SubstitutionPreference = SubstitutionPreference(type: .bestMatch, replacementProductID: nil),
        note: String = ""
    ) {
        guard let product = product(with: productID) else { return }
        guard quantity > 0 else { return }
        guard product.inStock else {
            inlineStatusMessage = "out of stock"
            return
        }

        mutateState { draftState, timestamp in
            if draftState.selectedStoreID != product.storeID {
                swapCartForStoreChange(to: product.storeID, draftState: &draftState)
                draftState.selectedStoreID = product.storeID
            }

            if let index = draftState.cartItems.firstIndex(where: { $0.productID == productID }) {
                draftState.cartItems[index].quantity += quantity
                if note.isEmpty == false {
                    draftState.cartItems[index].note = note
                }
                draftState.cartItems[index].substitutionPreference = substitutionPreference
                draftState.cartItems[index].addedAt = timestamp
            } else {
                draftState.cartItems.append(
                    CartItem(
                        productID: productID,
                        quantity: quantity,
                        substitutionPreference: substitutionPreference,
                        note: note,
                        addedAt: timestamp
                    )
                )
            }
        }
    }

    func incrementCartItem(_ productID: String) {
        mutateState { draftState, _ in
            guard let index = draftState.cartItems.firstIndex(where: { $0.productID == productID }) else { return }
            guard draftState.cartItems[index].quantity < 99 else { return }
            draftState.cartItems[index].quantity += 1
        }
    }

    func decrementCartItem(_ productID: String) {
        mutateState { draftState, _ in
            guard let index = draftState.cartItems.firstIndex(where: { $0.productID == productID }) else { return }
            draftState.cartItems[index].quantity -= 1
            if draftState.cartItems[index].quantity <= 0 {
                draftState.cartItems.remove(at: index)
            }
        }
    }

    func removeCartItem(_ productID: String) {
        mutateState { draftState, _ in
            draftState.cartItems.removeAll(where: { $0.productID == productID })
        }
    }

    func updateSubstitutionPreference(for productID: String, preference: SubstitutionPreference) {
        mutateState { draftState, _ in
            guard let index = draftState.cartItems.firstIndex(where: { $0.productID == productID }) else { return }
            draftState.cartItems[index].substitutionPreference = preference
        }
    }

    func upsertRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        mutateState { draftState, _ in
            draftState.recentSearches.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
            draftState.recentSearches.insert(trimmed, at: 0)
            draftState.recentSearches = Array(draftState.recentSearches.prefix(8))
        }
    }

    func cartSummary() -> PricingSummary {
        let subtotal = state.cartItems.reduce(0) { partialResult, cartItem in
            partialResult + ((product(with: cartItem.productID)?.price ?? 0) * Double(cartItem.quantity))
        }
        let slotFee = state.deliveryMode == .delivery ? (selectedSlot?.fee ?? selectedStore?.deliveryFee ?? 0) : 0
        let priorityFee: Double = state.priorityDelivery && state.deliveryMode == .delivery ? 2.00 : 0
        let serviceFee = round(subtotal * 0.06 * 100) / 100
        let tax = round(subtotal * 0.0825 * 100) / 100
        let tip = state.deliveryMode == .delivery ? state.tipAmount : 0
        let promoDiscount: Double = state.promoApplied ? min(5.00, subtotal * 0.1) : 0
        let total = subtotal + slotFee + priorityFee + serviceFee + tax + tip - promoDiscount

        return PricingSummary(
            itemSubtotal: subtotal,
            deliveryFee: slotFee,
            priorityFee: priorityFee,
            serviceFee: serviceFee,
            taxEstimate: tax,
            tip: tip,
            promoDiscount: promoDiscount,
            estimatedTotal: total
        )
    }

    func placeOrder() -> Order? {
        guard state.cartItems.isEmpty == false else {
            inlineStatusMessage = "checkout unavailable"
            return nil
        }

        guard let selectedStore, let address = selectedAddress, let paymentMethod = selectedPaymentMethod, let slot = selectedSlot, slot.isAvailable else {
            inlineStatusMessage = "checkout unavailable"
            return nil
        }

        let items = state.cartItems.compactMap { cartItem -> OrderItem? in
            guard let product = product(with: cartItem.productID) else { return nil }
            return OrderItem(
                id: "\(cartItem.productID)_\(state.orderSequence)",
                productID: product.id,
                productName: product.productName,
                brand: product.brand,
                packageSize: product.packageSize,
                unitPrice: product.unitPrice,
                quantity: cartItem.quantity,
                price: product.price,
                substitutionPreference: cartItem.substitutionPreference
            )
        }

        guard items.isEmpty == false else {
            inlineStatusMessage = "checkout unavailable"
            return nil
        }

        let summary = cartSummary()
        let initialStatus: OrderStatus = slot.dayLabel == "Tomorrow" ? .scheduled : .placed
        var createdOrder: Order?

        mutateState { draftState, timestamp in
            let orderID = "order_\(draftState.orderSequence)"
            let orderNumber = "\(storePrefix(for: selectedStore))-\(draftState.orderSequence)"
            let firstEvent = OrderStatusEvent(
                id: "\(orderID)_\(initialStatus.rawValue)",
                status: initialStatus,
                timestamp: timestamp,
                message: initialStatus == .scheduled ? "Your order was scheduled." : "Your order was placed."
            )

            let order = Order(
                id: orderID,
                orderNumber: orderNumber,
                storeID: selectedStore.id,
                items: items,
                deliveryMode: draftState.deliveryMode,
                deliverySlot: slot,
                address: address,
                paymentMethod: paymentMethod,
                orderStatus: initialStatus,
                statusEvents: [firstEvent],
                pricingSummary: summary,
                orderNotes: draftState.orderNotes,
                deliveryInstructions: draftState.specialInstructions,
                createdAt: timestamp,
                updatedAt: timestamp
            )

            draftState.orders.insert(order, at: 0)
            draftState.cartItems = []
            draftState.storeCarts.removeValue(forKey: selectedStore.id)
            draftState.orderNotes = ""
            draftState.specialInstructions = ""
            draftState.priorityDelivery = false
            draftState.promoCode = ""
            draftState.promoApplied = false
            draftState.orderSequence += 1
            createdOrder = order
        }

        if let order = createdOrder {
            FreshCartMailOutboxWriter.recordOrderEmail(order, storeName: selectedStore.storeName)
            if let accountId = selectedPaymentAccountID {
                FreshCartMyBankLedgerWriter.recordOrder(order, total: order.pricingSummary.estimatedTotal, paymentAccountId: accountId, storeName: selectedStore.storeName)
            }
        }

        return createdOrder
    }

    func advanceOrderState(_ orderID: String) {
        mutateState { draftState, timestamp in
            guard let index = draftState.orders.firstIndex(where: { $0.id == orderID }) else { return }
            let currentStatus = draftState.orders[index].orderStatus
            guard let nextStatus = nextStatus(after: currentStatus, mode: draftState.orders[index].deliveryMode) else { return }

            draftState.orders[index].orderStatus = nextStatus
            draftState.orders[index].updatedAt = timestamp
            draftState.orders[index].statusEvents.append(
                OrderStatusEvent(
                    id: "\(orderID)_\(nextStatus.rawValue)_\(draftState.orders[index].statusEvents.count + 1)",
                    status: nextStatus,
                    timestamp: timestamp,
                    message: statusMessage(for: nextStatus)
                )
            )
        }
    }

    func cancelOrder(_ orderID: String) {
        mutateState { draftState, timestamp in
            guard let index = draftState.orders.firstIndex(where: { $0.id == orderID }) else { return }
            guard draftState.orders[index].orderStatus.isCancellable else { return }
            draftState.orders[index].orderStatus = .canceled
            draftState.orders[index].updatedAt = timestamp
            draftState.orders[index].statusEvents.append(
                OrderStatusEvent(
                    id: "\(orderID)_canceled_\(draftState.orders[index].statusEvents.count + 1)",
                    status: .canceled,
                    timestamp: timestamp,
                    message: "Your order was canceled."
                )
            )
        }
    }

    func reorder(_ orderID: String) {
        guard let order = state.orders.first(where: { $0.id == orderID }) else { return }

        mutateState { draftState, timestamp in
            swapCartForStoreChange(to: order.storeID, draftState: &draftState)
            draftState.selectedStoreID = order.storeID
            draftState.deliveryMode = order.deliveryMode
            if order.deliveryMode == .delivery {
                draftState.selectedDeliverySlotID = order.deliverySlot.id
            } else {
                draftState.selectedPickupSlotID = order.deliverySlot.id
            }
            draftState.cartItems = order.items.map { item in
                CartItem(
                    productID: item.productID,
                    quantity: item.quantity,
                    substitutionPreference: item.substitutionPreference,
                    note: "",
                    addedAt: timestamp
                )
            }
            draftState.selectedTab = .cart
        }
    }

    private func mutateState(_ mutation: (inout FreshCartState, Date) -> Void) {
        var draftState = state
        let timestamp = draftState.lastUpdated.addingTimeInterval(60)
        mutation(&draftState, timestamp)
        draftState.lastUpdated = timestamp
        state = draftState
        persistence.saveState(draftState)
    }

    private func swapCartForStoreChange(to newStoreID: String, draftState: inout FreshCartState) {
        let currentStoreID = draftState.selectedStoreID
        guard currentStoreID != newStoreID else { return }

        // Save current cart for the old store (or clear stale entry if empty)
        if draftState.cartItems.isEmpty {
            draftState.storeCarts.removeValue(forKey: currentStoreID)
        } else {
            draftState.storeCarts[currentStoreID] = draftState.cartItems
        }

        // Restore saved cart for the new store (or empty)
        draftState.cartItems = draftState.storeCarts[newStoreID] ?? []
    }

    private static let currentSeedVersion = 3

    private func requiresSeedReset(for state: FreshCartState) -> Bool {
        if state.seedVersion != Self.currentSeedVersion {
            return true
        }

        let referenceCatalog: CatalogData
        switch state.catalogSource {
        case .seeded:
            referenceCatalog = seededCatalog
        case .snapshot:
            guard let snapshotCatalog else {
                return true
            }
            referenceCatalog = snapshotCatalog
        }

        if referenceCatalog.stores.contains(where: { $0.id == state.selectedStoreID }) == false {
            return true
        }

        if referenceCatalog.products.contains(where: { $0.id == state.cartItems.first?.productID ?? "" }) == false,
           state.cartItems.isEmpty == false {
            return true
        }

        if state.savedProductIDs.contains(where: { savedProductID in
            referenceCatalog.products.contains(where: { $0.id == savedProductID }) == false
        }) {
            return true
        }

        return false
    }

    private func relevanceScore(for product: Product, query: String) -> Int {
        guard query.isEmpty == false else {
            return (product.isRecommended ? 2 : 0) + (product.isOnSale ? 1 : 0)
        }
        let name = product.productName.lowercased()
        let brand = product.brand.lowercased()
        var score = 0
        if name.hasPrefix(query) { score += 8 }
        if name.contains(query) { score += 4 }
        if brand.contains(query) { score += 3 }
        if product.isRecommended { score += 2 }
        if product.isOnSale { score += 1 }
        return score
    }

    private static func editDistance(_ a: String, _ b: String) -> Int {
        let m = a.count, n = b.count
        if m == 0 { return n }
        if n == 0 { return m }
        let aArr = Array(a), bArr = Array(b)
        var prev = Array(0...n)
        var curr = [Int](repeating: 0, count: n + 1)
        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = aArr[i - 1] == bArr[j - 1] ? 0 : 1
                curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
            }
            prev = curr
        }
        return prev[n]
    }

    private func unitPriceValue(_ unitPrice: String) -> Double {
        let digits = unitPrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(digits) ?? .greatestFiniteMagnitude
    }

    private func nextStatus(after status: OrderStatus, mode: DeliveryMode) -> OrderStatus? {
        switch status {
        case .scheduled:
            return .placed
        case .placed:
            return .shopperAssigned
        case .shopperAssigned:
            return .shopping
        case .shopping:
            return mode == .delivery ? .outForDelivery : .readyForPickup
        case .outForDelivery:
            return .delivered
        case .readyForPickup:
            return .pickedUp
        case .delivered, .pickedUp, .canceled:
            return nil
        }
    }

    private func statusMessage(for status: OrderStatus) -> String {
        switch status {
        case .scheduled:
            return "Your order was scheduled."
        case .placed:
            return "Your order was placed."
        case .shopperAssigned:
            return "A shopper was assigned to your order."
        case .shopping:
            return "Your order is being shopped."
        case .outForDelivery:
            return "Your order is out for delivery."
        case .readyForPickup:
            return "Your order is ready for pickup."
        case .delivered:
            return "Your order was delivered."
        case .pickedUp:
            return "Your order was picked up."
        case .canceled:
            return "Your order was canceled."
        }
    }

    private func storePrefix(for store: Store) -> String {
        store.storeName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

struct FreshCartMailOutboxWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mail_inbox.json"
    private static let ioQueue = DispatchQueue(label: "freshcart.instacart_outbox.io", qos: .utility)

    private struct MailRecord: Codable {
        let id: UUID
        let from: String
        let subject: String
        let body: String
        let category: Int
        let date: Date
    }

    static func recordOrderEmail(_ order: Order, storeName: String) {
        guard let url = inboxURL() else {
            print("[Mail] App Group unavailable; Instacart email write skipped.")
            return
        }

        let totalText = String(format: "$%.2f", order.pricingSummary.estimatedTotal)
        let subject = "Your FreshCart order is confirmed"
        let itemSummary = order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: "\n        ")
        let slotInfo = "\(order.deliverySlot.dayLabel) \(order.deliverySlot.timeLabel)"
        let body = """
        Hi,

        Your FreshCart order is confirmed.

        Order number: \(order.orderNumber)
        Store: \(storeName)
        Items:
        \(itemSummary)
        Delivery slot: \(slotInfo)
        Estimated total: \(totalText)

        Thanks,
        FreshCart
        """

        let record = MailRecord(
            id: UUID(),
            from: "FreshCart",
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
            print("[Mail] Failed to write Instacart email: \(error)")
        }
    }
}

struct FreshCartMyBankLedgerWriter {
    private static let appGroupID = "group.com.iosworld.benchmark.personalsuite"
    private static let fileName = "mybank_ledger.json"
    private static let ioQueue = DispatchQueue(label: "freshcart.instacart_ledger.io", qos: .utility)

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

    static func recordOrder(_ order: Order, total: Double, paymentAccountId: UUID, storeName: String) {
        guard let url = ledgerURL() else {
            print("[MyBank] App Group unavailable; Instacart ledger write skipped.")
            return
        }

        let vendor = "\(storeName) via FreshCart"
        let note = order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: ", ")

        let record = LedgerTransaction(
            id: UUID(),
            externalId: order.id,
            accountId: paymentAccountId,
            vendor: vendor,
            amount: -abs(total),
            currency: "USD",
            category: "Groceries",
            note: note.isEmpty ? nil : note,
            timestamp: Date(),
            status: "pending",
            sourceApp: "FreshCart",
            rawSource: "freshcart_checkout"
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
            print("[MyBank] Failed to write Instacart ledger: \(error)")
        }
    }
}
