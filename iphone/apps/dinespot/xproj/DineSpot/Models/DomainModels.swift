import Foundation

enum AvailabilityMode: String, Codable, CaseIterable, Identifiable {
    case seeded
    case snapshot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seeded:
            return "Standard Data"
        case .snapshot:
            return "Snapshot Availability Data"
        }
    }
}

enum AvailabilitySourceType: String, Codable {
    case seeded
    case snapshot
}

struct City: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let stateCode: String
}

struct Neighborhood: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let cityID: String
}

enum RestaurantTag: String, Codable, CaseIterable, Hashable {
    case popular = "Popular"
    case newlyAdded = "New"
    case outdoorSeating = "Outdoor Seating"
    case chefCounter = "Chef's Counter"
    case barSeating = "Bar Seating"
    case tastingMenu = "Tasting Menu"
    case wheelchairAccessible = "Wheelchair Accessible"
    case vegetarianFriendly = "Vegetarian Friendly"
    case bookableOnline = "Bookable Online"

    var shortBadge: String { rawValue }
}

struct RestaurantPolicy: Codable, Hashable {
    let cancellationPolicy: String
    let lateArrivalPolicy: String
    let seatingNotes: String
    let creditCardHold: String
}

struct RestaurantPhotoSeed: Identifiable, Hashable {
    let id: String
    let assetName: String
    let title: String
    let subtitle: String
    let paletteHex: [String]
}

enum AvailabilityPattern: String, Codable {
    case standard
    case sparse
    case waitlistOnly
}

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let cuisine: String
    let neighborhoodID: String
    let cityID: String
    let address: String
    let hours: [String]
    let priceTier: Int
    let rating: Double
    let foodRating: Double
    let serviceRating: Double
    let ambianceRating: Double
    let valueRating: Double
    let distanceMiles: Double
    let shortDescription: String
    let tags: [RestaurantTag]
    let supportsWaitlist: Bool
    let supportsNotify: Bool
    let policy: RestaurantPolicy
    let menuHighlights: [String]
    let photoCount: Int
    let availabilityPattern: AvailabilityPattern
}

struct ReservationSlot: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    let date: Date
    let partySize: Int
    let sourceType: AvailabilitySourceType
    let isBookable: Bool
}

struct RestaurantAvailability: Identifiable, Codable, Hashable {
    var id: String { restaurantID }
    let restaurantID: String
    let sourceType: AvailabilitySourceType
    let lastUpdated: Date
    let supportsWaitlist: Bool
    let availableSlots: [ReservationSlot]
}

enum ReservationStatus: String, Codable, CaseIterable {
    case upcoming
    case past
    case canceled
}

struct Reservation: Identifiable, Codable, Hashable {
    let id: String
    let reservationCode: String
    let restaurantID: String
    var date: Date
    var partySize: Int
    var status: ReservationStatus
    var diningPreference: String
    let sourceType: AvailabilitySourceType
    let policySummary: String
    var notes: String
    let createdAt: Date
    var updatedAt: Date
}

struct DiningPreference: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var value: String
}

struct SavedRestaurant: Identifiable, Codable, Hashable {
    var id: String { restaurantID }
    let restaurantID: String
    let savedAt: Date
}

enum WaitlistRequestType: String, Codable, CaseIterable, Identifiable {
    case waitlist
    case notify

    var id: String { rawValue }
}

struct WaitlistEntry: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    let requestType: WaitlistRequestType
    let date: Date
    let partySize: Int
    let preferredWindow: String
    let createdAt: Date
    var status: String
}

struct DiningAlert: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let message: String
    let restaurantID: String?
    let date: Date
    var isRead: Bool
}

struct UserProfile: Codable, Hashable {
    let id: String
    var fullName: String
    var homeCityID: String
    var email: String
    var notificationEnabled: Bool
    var promoNotificationsEnabled: Bool
    var dietaryPreference: String
    var seatingPreference: String
    var loyaltyTier: String
    var savedCities: [String]
    var diningPreferences: [DiningPreference]
}

struct AvailabilitySnapshotMetadata: Codable, Hashable {
    let providerLabel: String
    let snapshotTimestamp: Date
    let sourceType: AvailabilitySourceType
    let version: String
}

struct AvailabilitySnapshot: Codable, Hashable {
    let metadata: AvailabilitySnapshotMetadata
    let availability: [RestaurantAvailability]
}

struct DinerReview: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    let reviewerName: String
    let date: Date
    let overallRating: Double
    let foodRating: Double
    let serviceRating: Double
    let ambianceRating: Double
    let reviewText: String
    let diningOccasion: String
}

struct PopularDish: Identifiable, Codable, Hashable {
    let id: String
    let restaurantID: String
    let name: String
    let mentionCount: Int
}

struct PersistedState: Codable {
    var reservations: [Reservation]
    var savedRestaurants: [SavedRestaurant]
    var waitlistEntries: [WaitlistEntry]
    var diningAlerts: [DiningAlert]
    var userProfile: UserProfile
    var recentSearches: [String]
    var selectedCityID: String
    var availabilityMode: AvailabilityMode
    var confirmationSequence: Int
    var waitlistSequence: Int
}
