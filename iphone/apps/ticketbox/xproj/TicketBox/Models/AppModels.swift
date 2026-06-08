import Foundation

enum EventCategory: String, CaseIterable, Codable, Identifiable {
    case sports = "Sports"
    case concerts = "Concerts"
    case theater = "Broadway"
    case comedy = "Comedy"

    var id: String { rawValue }
}

enum DeliveryType: String, CaseIterable, Codable, Identifiable {
    case instant = "Instant"
    case mobile = "Mobile"
    case transfer = "Transfer"

    var id: String { rawValue }
}

enum DateRangeFilter: String, CaseIterable, Codable, Identifiable {
    case any = "Any time"
    case weekend = "This weekend"
    case next7 = "Next 7 days"
    case next30 = "Next 30 days"

    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Codable, Identifiable {
    case recommended = "Recommended"
    case lowestPrice = "Lowest price"
    case bestValue = "Best value"
    case soonestDate = "Soonest date"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .recommended:
            return "Recommended"
        case .lowestPrice:
            return "Price"
        case .bestValue:
            return "Best value"
        case .soonestDate:
            return "Date"
        }
    }
}

enum CheckoutDeliveryMethod: String, CaseIterable, Codable, Identifiable {
    case mobileTransfer = "Mobile transfer"
    case instant = "Instant"

    var id: String { rawValue }
}

enum ContactMethod: String, CaseIterable, Codable, Identifiable {
    case email = "Email"
    case phone = "Phone"

    var id: String { rawValue }
}

enum TicketBoxTab: String, CaseIterable, Codable, Identifiable {
    case browse
    case search
    case tickets
    case tracking
    case me

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browse:
            return "Browse"
        case .search:
            return "Search"
        case .tickets:
            return "Tickets"
        case .tracking:
            return "Favorites"
        case .me:
            return "More"
        }
    }

    var iconName: String {
        switch self {
        case .browse:
            return "house"
        case .search:
            return "magnifyingglass"
        case .tickets:
            return "ticket"
        case .tracking:
            return "heart"
        case .me:
            return "ellipsis"
        }
    }

    var selectedIconName: String {
        switch self {
        case .browse:
            return "house.fill"
        case .search:
            return "magnifyingglass"
        case .tickets:
            return "ticket.fill"
        case .tracking:
            return "heart.fill"
        case .me:
            return "ellipsis"
        }
    }
}

enum TrackingMode: String, CaseIterable, Codable, Identifiable {
    case events = "Events"
    case performers = "Performers"
    case venues = "Venues"

    var id: String { rawValue }
}

enum MusicServiceKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case appleMusic
    case spotify

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleMusic:
            return "Apple Music Library"
        case .spotify:
            return "Spotify"
        }
    }

    var trackingName: String {
        switch self {
        case .appleMusic:
            return "Music"
        case .spotify:
            return "Spotify"
        }
    }
}

enum SearchRecordKind: String, Codable, Hashable {
    case event
    case performer
    case venue
    case suggestion
}

enum SearchSuggestionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case popularEvents
    case favoritePerformers
    case justAnnounced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .popularEvents:
            return "Popular Events"
        case .favoritePerformers:
            return "Favorite Performers"
        case .justAnnounced:
            return "Just Announced"
        }
    }

    var systemImage: String {
        switch self {
        case .popularEvents:
            return "star.fill"
        case .favoritePerformers:
            return "heart.fill"
        case .justAnnounced:
            return "megaphone.fill"
        }
    }
}

enum ListingImageStyle: String, CaseIterable, Codable, Identifiable, Hashable {
    case centerCourt
    case cornerView
    case clubLevel
    case behindGoal
    case behindPlate
    case dugout
    case floor
    case sideStage
    case orchestra
    case balcony
    case lawn
    case generalAdmission

    var id: String { rawValue }
}

struct Performer: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: EventCategory
    let imageName: String
    let eventCount: Int
}

struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let city: String
    let address: String
    let capacity: Int
    let imageName: String
}

struct TicketListing: Identifiable, Codable, Hashable {
    let id: UUID
    let eventID: UUID
    let section: String
    let row: String
    let seatRange: String
    let quantityAvailable: Int
    let price: Double
    let fees: Double
    let deliveryType: DeliveryType
    let dealScore: Int
    let imageStyle: ListingImageStyle
    let viewDescription: String

    var isInstant: Bool { deliveryType == .instant }
}

struct Event: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let venueID: UUID
    let city: String
    let category: EventCategory
    let performers: [Performer]
    let imageName: String
    let description: String
    let listings: [TicketListing]
}

struct SearchRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let imageName: String
    let kind: SearchRecordKind
    let referenceID: UUID?
}

struct SearchSuggestion: Identifiable, Hashable {
    let id: SearchSuggestionKind
    let title: String
    let systemImage: String
    let kind: SearchSuggestionKind
}

enum TicketArchiveStyle: String, CaseIterable, Codable, Identifiable {
    case padresAtBraves
    case giantsAtDodgers
    case warriorsVsSuns
    case giantsVsDodgers
    case concertChaseCenter
    case warriorsVsNuggets
    case giantsVsPadres
    case comedyMasonic
    case theaterOrpheum
    case warriorsVsClippers
    case concertFillmore
    case giantsVsRockies

    var id: String { rawValue }
}

struct TicketArchiveItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let style: TicketArchiveStyle
    let pricePaid: Double
    let venueName: String
    let section: String
    let row: String
    let seatRange: String
}

struct CartItem: Identifiable, Codable, Hashable {
    let id: UUID
    let listingID: UUID
    let eventID: UUID
    let eventTitle: String
    let venueName: String
    let city: String
    let eventDate: Date
    let section: String
    let row: String
    let seatRange: String
    let quantityAvailable: Int
    let pricePerTicket: Double
    let feesPerTicket: Double
    let deliveryType: DeliveryType
    var quantity: Int
}

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    let orderNumber: String
    let items: [CartItem]
    let createdAt: Date
    let estimatedDelivery: Date
    let deliveryMethod: CheckoutDeliveryMethod
    let contactMethod: ContactMethod
    let appliedPromoCode: String?
    let discountAmount: Double?
    let totalPaid: Double?
}

struct SaleListing: Codable, Hashable, Identifiable {
    let orderID: UUID
    var askingPrice: Double
    var lastUpdated: Date

    var id: UUID { orderID }
}

enum OrderStatus: String, CaseIterable, Codable, Identifiable {
    case processing = "Processing"
    case confirmed = "Confirmed"
    case delivered = "Tickets delivered"

    var id: String { rawValue }
}

struct PromoCode: Identifiable, Codable, Hashable {
    let id: UUID
    let code: String
    let title: String
    let detail: String
    let discountAmount: Double
    let minimumSpend: Double
    let expiresAt: Date
    var isRedeemed: Bool
    var isConsumed: Bool
}

struct FilterState: Codable, Hashable {
    var dateRange: DateRangeFilter
    var category: EventCategory?
    var city: String?
    var minPrice: Double
    var maxPrice: Double
    var instantOnly: Bool
    var sortOption: SortOption

    static let `default` = FilterState(
        dateRange: .any,
        category: nil,
        city: nil,
        minPrice: 0,
        maxPrice: 400,
        instantOnly: false,
        sortOption: .recommended
    )
}

struct SettingsState: Codable, Hashable {
    var use24HourTime: Bool
    var showFeesUpfront: Bool
    var selectedCity: String
    var hasManualLocationOverride: Bool
    var preferredSort: SortOption
    var deliveryAddress: String
    var profileName: String
    var profileEmail: String
    var profilePhone: String?
    var connectedMusicServices: Set<MusicServiceKind>
    var hasMLBAccountLinked: Bool

    static let `default` = SettingsState(
        use24HourTime: false,
        showFeesUpfront: true,
        selectedCity: "San Francisco, CA",
        hasManualLocationOverride: false,
        preferredSort: .lowestPrice,
        deliveryAddress: "jordan.avery@email.com",
        profileName: "Jordan Avery",
        profileEmail: "jordan.avery@email.com",
        profilePhone: "(206) 555-0147",
        connectedMusicServices: [.spotify],
        hasMLBAccountLinked: true
    )
}
