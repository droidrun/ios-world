import CoreLocation
import Foundation

final class HomeViewModel: ObservableObject {
    @Published var highlightedCategoryID: String?
}

enum SearchPriceFilterOption: String, CaseIterable, Identifiable {
    case any
    case under25
    case between25And50
    case between50And100
    case over100

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Any Price"
        case .under25:
            return "Under $25"
        case .between25And50:
            return "$25 to $50"
        case .between50And100:
            return "$50 to $100"
        case .over100:
            return "$100+"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .any:
            return "filter_price_any"
        case .under25:
            return "filter_price_under_25"
        case .between25And50:
            return "filter_price_25_to_50"
        case .between50And100:
            return "filter_price_50_to_100"
        case .over100:
            return "filter_price_over_100"
        }
    }

    func matches(_ value: Double) -> Bool {
        switch self {
        case .any:
            return true
        case .under25:
            return value < 25
        case .between25And50:
            return value >= 25 && value <= 50
        case .between50And100:
            return value > 50 && value <= 100
        case .over100:
            return value > 100
        }
    }
}

enum SearchRatingFilterOption: String, CaseIterable, Identifiable {
    case any
    case fourPlus
    case fourPointFivePlus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Any Rating"
        case .fourPlus:
            return "4.0+"
        case .fourPointFivePlus:
            return "4.5+"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .any:
            return "filter_rating_any"
        case .fourPlus:
            return "filter_rating_4_plus"
        case .fourPointFivePlus:
            return "filter_rating_4_5_plus"
        }
    }

    func matches(_ rating: Double) -> Bool {
        switch self {
        case .any:
            return true
        case .fourPlus:
            return rating >= 4.0
        case .fourPointFivePlus:
            return rating >= 4.5
        }
    }
}

final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedDepartmentID: String?
    @Published var selectedCategoryID: String?
    @Published var selectedBrand: String?
    @Published var selectedPriceFilter: SearchPriceFilterOption = .any
    @Published var selectedRatingFilter: SearchRatingFilterOption = .any
    @Published var primeOnly = false
    @Published var inStockOnly = false
    @Published var sortOption: SearchSortOption = .mostRelevant

    var hasActiveFilters: Bool {
        selectedDepartmentID != nil ||
            selectedCategoryID != nil ||
            selectedBrand != nil ||
            selectedPriceFilter != .any ||
            selectedRatingFilter != .any ||
            primeOnly ||
            inStockOnly
    }

    func apply(request: SearchNavigationRequest) {
        query = request.query
        selectedDepartmentID = request.departmentID
        selectedCategoryID = request.categoryID
        if request.departmentID != nil || request.categoryID != nil {
            selectedBrand = nil
        }
    }

    func clearAllFilters() {
        selectedDepartmentID = nil
        selectedCategoryID = nil
        selectedBrand = nil
        selectedPriceFilter = .any
        selectedRatingFilter = .any
        primeOnly = false
        inStockOnly = false
        sortOption = .mostRelevant
    }

    func brandOptions(in catalog: CatalogData) -> [String] {
        let filteredProducts = catalog.products.filter { product in
            (selectedDepartmentID == nil || product.departmentID == selectedDepartmentID) &&
                (selectedCategoryID == nil || product.categoryID == selectedCategoryID)
        }
        let brands = Set(filteredProducts.map(\.brand))
        return Array(brands).sorted().prefix(10).map { $0 }
    }

    func filteredProducts(in catalog: CatalogData) -> [Product] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = catalog.products.filter { product in
            let queryMatches: Bool
            if trimmed.isEmpty {
                queryMatches = true
            } else {
                let departmentName = catalog.departments.first(where: { $0.id == product.departmentID })?.name ?? ""
                let categoryName = catalog.categories.first(where: { $0.id == product.categoryID })?.name ?? ""
                var components = [product.productName, product.brand, departmentName, categoryName]
                components.append(contentsOf: product.searchKeywords)
                if product.primeEligible { components.append("prime") }
                if let originalPrice = product.originalPrice, originalPrice > product.price { components.append("deals deal sale") }
                let haystack = components.joined(separator: " ").lowercased()
                let tokens = trimmed.split(separator: " ").map { String($0) }
                queryMatches = tokens.allSatisfy { token in haystack.contains(token) }
            }

            return queryMatches &&
                (selectedDepartmentID == nil || product.departmentID == selectedDepartmentID) &&
                (selectedCategoryID == nil || product.categoryID == selectedCategoryID) &&
                (selectedBrand == nil || product.brand == selectedBrand) &&
                selectedPriceFilter.matches(product.price) &&
                selectedRatingFilter.matches(product.rating) &&
                (!primeOnly || product.primeEligible) &&
                (!inStockOnly || product.inStock)
        }

        switch sortOption {
        case .mostRelevant:
            return base.sorted { lhs, rhs in
                relevanceScore(for: lhs, query: trimmed) > relevanceScore(for: rhs, query: trimmed)
            }
        case .lowestPrice:
            return base.sorted { $0.price < $1.price }
        case .highestPrice:
            return base.sorted { $0.price > $1.price }
        case .highestRated:
            return base.sorted {
                if $0.rating == $1.rating {
                    return $0.reviewCount > $1.reviewCount
                }
                return $0.rating > $1.rating
            }
        case .newestArrivals:
            return base.sorted {
                if $0.isNewestArrival == $1.isNewestArrival {
                    return $0.popularityRank < $1.popularityRank
                }
                return $0.isNewestArrival && !$1.isNewestArrival
            }
        }
    }

    func autocompleteSuggestions(in catalog: CatalogData, recentSearches: [String]) -> [SearchSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        var seen = Set<String>()
        var suggestions: [SearchSuggestion] = []

        for recent in recentSearches where recent.lowercased().contains(trimmed) {
            if seen.insert(recent.lowercased()).inserted {
                suggestions.append(SearchSuggestion(id: "recent_\(AccessibilityID.slug(recent))", text: recent, subtitle: "Recent search"))
            }
        }

        for product in catalog.products where product.productName.lowercased().contains(trimmed) {
            if seen.insert(product.productName.lowercased()).inserted {
                suggestions.append(SearchSuggestion(id: "product_\(product.id)", text: product.productName, subtitle: product.brand))
            }
        }

        for brand in Set(catalog.products.map(\.brand)).sorted() where brand.lowercased().contains(trimmed) {
            if seen.insert(brand.lowercased()).inserted {
                suggestions.append(SearchSuggestion(id: "brand_\(AccessibilityID.slug(brand))", text: brand, subtitle: "Brand"))
            }
        }

        return Array(suggestions.prefix(8))
    }

    private func relevanceScore(for product: Product, query: String) -> Int {
        guard !query.isEmpty else { return 10_000 - product.popularityRank }
        let name = product.productName.lowercased()
        let brand = product.brand.lowercased()
        let keywords = product.searchKeywords.joined(separator: " ").lowercased()

        var score = 0
        if name == query { score += 400 }
        if name.hasPrefix(query) { score += 250 }
        if name.contains(query) { score += 150 }
        if brand.contains(query) { score += 100 }
        if keywords.contains(query) { score += 50 }
        score += max(0, 100 - product.popularityRank)
        return score
    }
}

final class ProductDetailViewModel: ObservableObject {
    let productID: String
    @Published var quantity = 1
    @Published var selectedVariantValues: [String: String] = [:]

    init(productID: String) {
        self.productID = productID
    }

    func configureDefaults(for product: Product) {
        guard selectedVariantValues.isEmpty else { return }
        for group in product.variantGroups {
            if let firstAvailable = product.variants.first(where: { $0.variantName == group && $0.isAvailable }) {
                selectedVariantValues[group] = firstAvailable.variantValue
            }
        }
    }

    func options(for product: Product, group: String) -> [ProductVariant] {
        product.variants.filter { $0.variantName == group }
    }

    func select(_ variant: ProductVariant) {
        selectedVariantValues[variant.variantName] = variant.variantValue
    }

    func isSelected(_ variant: ProductVariant) -> Bool {
        selectedVariantValues[variant.variantName] == variant.variantValue
    }

    func canPurchase(product: Product, using store: MegaMartStore) -> Bool {
        store.canPurchase(product: product, selection: selectedVariantValues)
    }
}

final class CartViewModel: ObservableObject {
    @Published var isCheckoutPresented = false
}

enum OrdersSegment: String, CaseIterable, Identifiable {
    case active
    case delivered
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .delivered:
            return "Past Orders"
        case .canceled:
            return "Canceled"
        }
    }
}

final class OrdersViewModel: ObservableObject {
    @Published var selectedSegment: OrdersSegment = .active
}

final class AccountViewModel: ObservableObject {
    @Published var isShowingHelp = false
}

enum CheckoutStep: String, CaseIterable, Identifiable {
    case address
    case delivery
    case payment
    case review
    case confirmation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .address:
            return "Address"
        case .delivery:
            return "Delivery"
        case .payment:
            return "Payment"
        case .review:
            return "Review"
        case .confirmation:
            return "Confirmation"
        }
    }
}

enum CheckoutMode {
    case cart
    case buyNow(CartItem)
}

final class CheckoutViewModel: ObservableObject {
    let mode: CheckoutMode
    @Published var step: CheckoutStep = .address
    @Published var selectedAddressID: String
    @Published var selectedDeliveryOptionID: String
    @Published var selectedPaymentMethodID: String
    @Published var selectedPaymentAccountID: UUID?
    @Published var isGift = false
    @Published var promoCode = ""
    @Published var giftMessage = ""
    @Published var placedOrder: Order?

    init(mode: CheckoutMode, store: MegaMartStore) {
        self.mode = mode
        self.selectedAddressID = store.selectedAddress?.id ?? store.state.addresses.first?.id ?? ""
        self.selectedDeliveryOptionID = store.deliveryOptions.first?.id ?? ""
        self.selectedPaymentMethodID = store.selectedPaymentMethod?.id ?? store.state.paymentMethods.first?.id ?? ""
        self.selectedPaymentAccountID = store.selectedPaymentAccountID
    }

    func items(in store: MegaMartStore) -> [CartItem] {
        switch mode {
        case .cart:
            return store.state.cartItems
        case .buyNow(let item):
            return [item]
        }
    }

    func subtotal(in store: MegaMartStore) -> Double {
        items(in: store).reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) }
    }

    func estimatedDiscount(in store: MegaMartStore) -> Double {
        let code = promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch code {
        case "SAVE10", "WELCOME10":
            return min(10, subtotal(in: store))
        case "SPRING15":
            return min(15, subtotal(in: store))
        default:
            return 0
        }
    }

    func deliveryCost(in store: MegaMartStore) -> Double {
        store.deliveryOptions.first(where: { $0.id == selectedDeliveryOptionID })?.additionalCost ?? 0
    }

    func tax(in store: MegaMartStore) -> Double {
        let taxable = max(0, subtotal(in: store) + deliveryCost(in: store) - estimatedDiscount(in: store))
        return (taxable * 100 * 0.0825).rounded() / 100
    }

    func total(in store: MegaMartStore) -> Double {
        let total = subtotal(in: store) + deliveryCost(in: store) + tax(in: store) - estimatedDiscount(in: store)
        return (total * 100).rounded() / 100
    }

    func advance() {
        switch step {
        case .address:
            step = .delivery
        case .delivery:
            step = .payment
        case .payment:
            step = .review
        case .review, .confirmation:
            break
        }
    }

    func back() {
        switch step {
        case .address:
            break
        case .delivery:
            step = .address
        case .payment:
            step = .delivery
        case .review:
            step = .payment
        case .confirmation:
            step = .review
        }
    }
}

final class MoreViewModel: ObservableObject {
    @Published var showResetConfirmation = false
}

@MainActor
final class DeviceLocationManager: NSObject, ObservableObject {
    @Published private(set) var latestResolvedAddress: Address?
    @Published private(set) var resolutionToken = UUID()
    @Published private(set) var statusMessage: String?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isRequestInFlight = false

    private let geocoder = CLGeocoder()
    private var manager: CLLocationManager?
    private var pendingRecipientName = "MegaMart Customer"

    func requestCurrentLocation(recipientName: String) {
        pendingRecipientName = recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "MegaMart Customer" : recipientName
        statusMessage = nil

        guard CLLocationManager.locationServicesEnabled() else {
            applyFallback(message: "Location services are off. Using the San Francisco default address.")
            return
        }

        if manager == nil {
            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.manager = manager
        }

        guard let manager else { return }
        authorizationStatus = manager.authorizationStatus
        isRequestInFlight = true

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusMessage = "Finding your current iPhone location..."
            manager.requestLocation()
        case .notDetermined:
            statusMessage = "Requesting access to your current iPhone location..."
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            applyFallback(message: "Location unavailable. Using the San Francisco default address.")
        @unknown default:
            applyFallback(message: "Location unavailable. Using the San Francisco default address.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusMessage = "Finding your current iPhone location..."
            manager.requestLocation()
        case .denied, .restricted:
            applyFallback(message: "Location access denied. Using the San Francisco default address.")
        case .notDetermined:
            break
        @unknown default:
            applyFallback(message: "Location unavailable. Using the San Francisco default address.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            applyFallback(message: "Location unavailable. Using the San Francisco default address.")
            return
        }

        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let address = self.buildResolvedAddress(from: placemarks?.first, location: location)
                self.latestResolvedAddress = address
                self.resolutionToken = UUID()
                self.statusMessage = placemarks?.first == nil
                    ? "Approximate device location applied."
                    : "Using your current iPhone location."
                self.isRequestInFlight = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        applyFallback(message: "Location lookup failed. Using the San Francisco default address.")
    }

    private func applyFallback(message: String) {
        latestResolvedAddress = SeedData.benchmarkCurrentLocationAddress(recipientName: pendingRecipientName)
        resolutionToken = UUID()
        statusMessage = message
        isRequestInFlight = false
    }

    private func buildResolvedAddress(from placemark: CLPlacemark?, location: CLLocation?) -> Address {
        let seed = ApproximateLocationSeed.seed(for: location?.coordinate)
        let line1 = joinedStreetLine(
            placemark?.subThoroughfare,
            placemark?.thoroughfare,
            fallback: seed.line1
        )
        let line2 = placemark?.subLocality ?? seed.line2
        let city = placemark?.locality ?? placemark?.subAdministrativeArea ?? seed.city
        let state = placemark?.administrativeArea ?? seed.state
        let postalCode = placemark?.postalCode ?? seed.postalCode

        return Address(
            id: "address_current_location",
            label: "Current Location",
            recipientName: pendingRecipientName,
            line1: line1,
            line2: line2,
            city: city,
            state: state,
            postalCode: postalCode
        )
    }

    private func joinedStreetLine(_ streetNumber: String?, _ streetName: String?, fallback: String) -> String {
        let values = [streetNumber, streetName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return values.isEmpty ? fallback : values.joined(separator: " ")
    }
}

extension DeviceLocationManager: @preconcurrency CLLocationManagerDelegate {}

private struct ApproximateLocationSeed {
    let city: String
    let state: String
    let postalCode: String
    let line1: String
    let line2: String?

    static func seed(for coordinate: CLLocationCoordinate2D?) -> ApproximateLocationSeed {
        guard let coordinate else { return sanFrancisco }

        switch (coordinate.latitude, coordinate.longitude) {
        case (37.70...37.83, -122.53 ... -122.35):
            return sanFrancisco
        case (37.76...37.90, -122.36 ... -122.18):
            return oakland
        case (37.20...37.42, -122.05 ... -121.75):
            return sanJose
        case (47.52...47.74, -122.45 ... -122.20):
            return seattle
        default:
            return sanFrancisco
        }
    }

    static let sanFrancisco = ApproximateLocationSeed(
        city: "San Francisco",
        state: "CA",
        postalCode: "94107",
        line1: "410 Brannan Street",
        line2: "Suite 320"
    )

    static let oakland = ApproximateLocationSeed(
        city: "Oakland",
        state: "CA",
        postalCode: "94607",
        line1: "1900 Broadway",
        line2: "Floor 6"
    )

    static let sanJose = ApproximateLocationSeed(
        city: "San Jose",
        state: "CA",
        postalCode: "95113",
        line1: "111 Market Street",
        line2: "Suite 300"
    )

    static let seattle = ApproximateLocationSeed(
        city: "Seattle",
        state: "WA",
        postalCode: "98109",
        line1: "535 Terry Avenue",
        line2: "Suite 220"
    )
}
