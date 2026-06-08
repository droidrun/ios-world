import Foundation

enum AppTab: String, Codable, CaseIterable {
    case home
    case account
    case cart
    case menu
    case search
    case orders
}

enum CatalogSourceType: String, Codable, CaseIterable {
    case seeded
    case snapshot

    var label: String {
        switch self {
        case .seeded:
            return "Standard Data"
        case .snapshot:
            return "Snapshot Catalog Data"
        }
    }
}

enum AuthEntryMode: String, Codable, Hashable {
    case signIn
    case createAccount

    var title: String {
        switch self {
        case .signIn:
            return "Sign In"
        case .createAccount:
            return "Create Account"
        }
    }
}

enum SearchSortOption: String, Codable, CaseIterable, Identifiable {
    case mostRelevant
    case lowestPrice
    case highestPrice
    case highestRated
    case newestArrivals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mostRelevant:
            return "Most Relevant"
        case .lowestPrice:
            return "Price: Low to High"
        case .highestPrice:
            return "Price: High to Low"
        case .highestRated:
            return "Highest Rated"
        case .newestArrivals:
            return "Newest Arrivals"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .mostRelevant:
            return "sort_most_relevant"
        case .lowestPrice:
            return "sort_price_low_to_high"
        case .highestPrice:
            return "sort_price_high_to_low"
        case .highestRated:
            return "sort_highest_rated"
        case .newestArrivals:
            return "sort_newest_arrivals"
        }
    }
}

enum OrderStatus: String, Codable, CaseIterable, Identifiable {
    case ordered
    case preparingForShipment
    case shipped
    case outForDelivery
    case delivered
    case canceled
    case returned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ordered:
            return "Ordered"
        case .preparingForShipment:
            return "Preparing for shipment"
        case .shipped:
            return "Shipped"
        case .outForDelivery:
            return "Out for delivery"
        case .delivered:
            return "Delivered"
        case .canceled:
            return "Canceled"
        case .returned:
            return "Returned"
        }
    }

    var isActive: Bool {
        switch self {
        case .ordered, .preparingForShipment, .shipped, .outForDelivery:
            return true
        case .delivered, .canceled, .returned:
            return false
        }
    }

    var sortRank: Int {
        switch self {
        case .ordered:
            return 0
        case .preparingForShipment:
            return 1
        case .shipped:
            return 2
        case .outForDelivery:
            return 3
        case .delivered:
            return 4
        case .canceled:
            return 5
        case .returned:
            return 6
        }
    }
}

struct Department: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let systemImage: String
}

struct ProductCategory: Identifiable, Codable, Hashable {
    let id: String
    let departmentID: String
    let name: String
    let systemImage: String
}

struct ProductVariant: Identifiable, Codable, Hashable {
    let id: String
    let variantName: String
    let variantValue: String
    let isAvailable: Bool
    let priceAdjustment: Double
}

struct ProductSpecification: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let value: String
}

struct Promotion: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let badgeText: String
}

struct Product: Identifiable, Codable, Hashable {
    let id: String
    let productName: String
    let brand: String
    let departmentID: String
    let categoryID: String
    let price: Double
    let originalPrice: Double?
    let currency: String
    let rating: Double
    let reviewCount: Int
    let primeEligible: Bool
    let deliveryEstimate: String
    let variantSummary: String?
    let inStock: Bool
    let sellerName: String
    let condition: String
    let imageSystemName: String
    let imageURL: String?
    let aboutItems: [String]
    let specifications: [ProductSpecification]
    let variants: [ProductVariant]
    let promotions: [Promotion]
    let popularityRank: Int
    let isNewestArrival: Bool
    let searchKeywords: [String]
    let releaseLabel: String?

    var discountPercent: Int? {
        guard let originalPrice, originalPrice > price else { return nil }
        return Int(((originalPrice - price) / originalPrice * 100).rounded())
    }

    var variantGroups: [String] {
        Array(Set(variants.map(\.variantName))).sorted()
    }
}

struct SearchSuggestion: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let subtitle: String
}

struct CartItem: Identifiable, Codable {
    let id: String
    let productID: String
    let productName: String
    let brand: String
    let unitPrice: Double
    let originalUnitPrice: Double?
    let currency: String
    var quantity: Int
    let primeEligible: Bool
    let deliveryEstimate: String
    let selectedVariantValues: [String: String]
    let sellerName: String
    let imageSystemName: String
    let inStock: Bool
}

struct SavedItem: Identifiable, Codable {
    let id: String
    let productID: String
    let productName: String
    let brand: String
    let unitPrice: Double
    let originalUnitPrice: Double?
    let currency: String
    let primeEligible: Bool
    let deliveryEstimate: String
    let selectedVariantValues: [String: String]
    let sellerName: String
    let imageSystemName: String
    let inStock: Bool
    let savedAt: Date
}

struct OrderItem: Identifiable, Codable {
    let id: String
    let productID: String
    let productName: String
    let brand: String
    let unitPrice: Double
    let originalUnitPrice: Double?
    let currency: String
    let quantity: Int
    let selectedVariantValues: [String: String]
    let imageSystemName: String
}

struct Address: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let recipientName: String
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String

    var shortLine: String {
        "\(city), \(state)"
    }

    var formattedLines: [String] {
        var values = [recipientName, line1]
        if let line2, !line2.isEmpty {
            values.append(line2)
        }
        values.append("\(city), \(state) \(postalCode)")
        return values
    }
}

struct PaymentMethod: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let details: String
    let isDefault: Bool
}

struct DeliveryOption: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let estimatedArrival: String
    let additionalCost: Double
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String
    let membershipLabel: String
    let defaultDeliveryLocation: String
    let profileNote: String
}

struct CatalogSnapshotMetadata: Codable, Hashable {
    let providerLabel: String
    let sourceType: CatalogSourceType
    let lastUpdated: Date
    let snapshotVersion: String
    let fileLabel: String
}

struct OrderStatusEvent: Identifiable, Codable {
    let id: String
    let status: OrderStatus
    let timestamp: Date
    let summary: String
}

struct Order: Identifiable, Codable {
    let id: String
    let orderNumber: String
    let status: OrderStatus
    let createdAt: Date
    let updatedAt: Date
    let items: [OrderItem]
    let shippingAddress: Address
    let paymentMethod: PaymentMethod
    let deliveryOption: DeliveryOption
    let itemSubtotal: Double
    let shippingCost: Double
    let tax: Double
    let discount: Double
    let estimatedTotal: Double
    let sourceType: CatalogSourceType
    let statusEvents: [OrderStatusEvent]

    var canCancel: Bool {
        status == .ordered || status == .preparingForShipment
    }
}

struct CatalogData: Codable {
    let metadata: CatalogSnapshotMetadata?
    let departments: [Department]
    let categories: [ProductCategory]
    let products: [Product]
}

struct MegaMartSimState: Codable {
    var selectedTab: AppTab
    var catalogSource: CatalogSourceType
    var snapshotMetadata: CatalogSnapshotMetadata?
    var isAuthenticated: Bool
    var cartItems: [CartItem]
    var savedItems: [SavedItem]
    var orders: [Order]
    var recentSearches: [String]
    var recentlyViewedProductIDs: [String]
    var userProfile: UserProfile
    var addresses: [Address]
    var paymentMethods: [PaymentMethod]
    var selectedAddressID: String
    var selectedPaymentMethodID: String
    var simulationDate: Date
    var userReviews: [UserReview]
}

struct UserReview: Identifiable, Codable, Hashable {
    let id: String
    let productID: String
    let authorName: String
    let rating: Int
    let title: String
    let body: String
    let reviewDate: Date
    let isVerifiedPurchase: Bool
}

struct SearchNavigationRequest: Hashable {
    let id = UUID()
    let query: String
    let departmentID: String?
    let categoryID: String?
}

enum AccountNavigationTarget: Hashable {
    case auth(AuthEntryMode)
    case orders
    case savedItems
    case settings
}

struct AccountNavigationRequest: Hashable {
    let id = UUID()
    let target: AccountNavigationTarget
}
