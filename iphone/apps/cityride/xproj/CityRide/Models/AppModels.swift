import Foundation

enum FareSourceType: String, Codable, CaseIterable {
    case seeded
    case snapshot

    var label: String {
        switch self {
        case .seeded:
            return "Standard Pricing"
        case .snapshot:
            return "Regional Pricing"
        }
    }
}

enum SnapshotLocation: String, Codable, CaseIterable {
    case bundled
    case sandbox

    var label: String {
        switch self {
        case .bundled:
            return "Default"
        case .sandbox:
            return "Custom"
        }
    }
}

enum TripStatus: String, Codable, CaseIterable {
    case requesting
    case driverAssigned
    case driverArriving
    case driverAtPickup
    case tripInProgress
    case tripCompleted
    case canceled
    case reserved

    var label: String {
        switch self {
        case .requesting:
            return "Requesting"
        case .driverAssigned:
            return "Driver assigned"
        case .driverArriving:
            return "Driver arriving"
        case .driverAtPickup:
            return "Driver at pickup"
        case .tripInProgress:
            return "In progress"
        case .tripCompleted:
            return "Completed"
        case .canceled:
            return "Canceled"
        case .reserved:
            return "Reserved"
        }
    }

    var chipIdentifier: String {
        switch self {
        case .requesting:
            return "trip_status_chip_requesting"
        case .driverAssigned:
            return "trip_status_chip_driver_assigned"
        case .driverArriving:
            return "trip_status_chip_driver_arriving"
        case .driverAtPickup:
            return "trip_status_chip_driver_at_pickup"
        case .tripInProgress:
            return "trip_status_chip_trip_in_progress"
        case .tripCompleted:
            return "trip_status_chip_trip_completed"
        case .canceled:
            return "trip_status_chip_canceled"
        case .reserved:
            return "trip_status_chip_reserved"
        }
    }

    var canAdvance: Bool {
        switch self {
        case .requesting, .driverAssigned, .driverArriving, .driverAtPickup, .tripInProgress, .reserved:
            return true
        case .tripCompleted, .canceled:
            return false
        }
    }

    func next() -> TripStatus {
        switch self {
        case .reserved:
            return .requesting
        case .requesting:
            return .driverAssigned
        case .driverAssigned:
            return .driverArriving
        case .driverArriving:
            return .driverAtPickup
        case .driverAtPickup:
            return .tripInProgress
        case .tripInProgress:
            return .tripCompleted
        case .tripCompleted:
            return .tripCompleted
        case .canceled:
            return .canceled
        }
    }
}

enum RideTimingOption: String, Codable, CaseIterable {
    case now
    case reserve

    var label: String {
        switch self {
        case .now:
            return "Ride now"
        case .reserve:
            return "Reserve"
        }
    }
}

enum RideSortOption: String, Codable, CaseIterable {
    case lowestPrice
    case highestPrice
    case fastestETA

    var label: String {
        switch self {
        case .lowestPrice:
            return "Lowest price"
        case .highestPrice:
            return "Highest price"
        case .fastestETA:
            return "Fastest ETA"
        }
    }
}

enum RideFilterCategory: String, Codable, CaseIterable {
    case all
    case standard
    case comfort
    case xl
    case green
    case premium

    var label: String {
        switch self {
        case .all:
            return "All"
        case .standard:
            return "Standard"
        case .comfort:
            return "Comfort"
        case .xl:
            return "XL"
        case .green:
            return "Green"
        case .premium:
            return "Premium"
        }
    }
}

enum RideBadge: String, Codable, CaseIterable {
    case fastest
    case cheapest
    case popular

    var label: String {
        switch self {
        case .fastest:
            return "Fastest"
        case .cheapest:
            return "Cheapest"
        case .popular:
            return "Popular"
        }
    }
}

enum SavedPlaceType: String, Codable, CaseIterable {
    case home
    case work
    case favorite

    var label: String {
        switch self {
        case .home:
            return "Home"
        case .work:
            return "Work"
        case .favorite:
            return "Favorite"
        }
    }
}

enum PaymentMethodType: String, Codable, CaseIterable {
    case card
    case applePay
    case cash
    case business

    var label: String {
        switch self {
        case .card:
            return "Card"
        case .applePay:
            return "Apple Pay"
        case .cash:
            return "Cash"
        case .business:
            return "Business"
        }
    }
}

enum AlertSeverity: String, Codable, CaseIterable {
    case info
    case warning
    case critical
}

struct LocationPlace: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var address: String
    var latitudePlaceholder: Double
    var longitudePlaceholder: Double
}

struct RouteEstimate: Identifiable, Codable, Hashable {
    var id: String
    var pickupName: String
    var destinationName: String
    var rideType: String
    var rideTypeId: String
    var etaMinutes: Int
    var estimatedPrice: Double
    var currency: String
    var seats: Int
    var serviceLabel: String
    var badges: [RideBadge]
    var category: RideFilterCategory
    var routeLabel: String
    var sourceType: FareSourceType
    var lastUpdated: Date
}

struct RideOption: Identifiable, Codable, Hashable {
    var id: String
    var rideTypeName: String
    var seats: Int
    var etaMinutes: Int
    var estimatedPrice: Double
    var currency: String
    var serviceLabel: String
    var badges: [RideBadge]
    var category: RideFilterCategory
    var sourceType: FareSourceType

    var rideTypeIdentifier: String {
        id
    }
}

struct Driver: Identifiable, Codable, Hashable {
    var id: String
    var driverName: String
    var rating: Double
    var phoneMask: String
}

struct Vehicle: Identifiable, Codable, Hashable {
    var id: String
    var make: String
    var model: String
    var color: String
    var licensePlate: String
}

struct Trip: Identifiable, Codable, Hashable {
    var id: String
    var pickupName: String
    var destinationName: String
    var rideType: String
    var rideTypeId: String
    var etaMinutes: Int
    var estimatedPrice: Double
    var currency: String
    var routeLabel: String
    var tripStatus: TripStatus
    var requestedAt: Date
    var reservedFor: Date?
    var pickupTime: Date?
    var dropoffTime: Date?
    var paymentMethodId: String
    var sourceType: FareSourceType
    var driver: Driver?
    var vehicle: Vehicle?
    var pickupNotes: String?
    var dropoffNotes: String?

    var isCompleted: Bool {
        tripStatus == .tripCompleted
    }

    var isCancelable: Bool {
        switch tripStatus {
        case .requesting, .driverAssigned, .driverArriving, .reserved:
            return true
        case .driverAtPickup, .tripInProgress, .tripCompleted, .canceled:
            return false
        }
    }

    var isActive: Bool {
        switch tripStatus {
        case .requesting, .driverAssigned, .driverArriving, .driverAtPickup, .tripInProgress:
            return true
        case .tripCompleted, .canceled, .reserved:
            return false
        }
    }

    var isUpcoming: Bool {
        tripStatus == .reserved || (reservedFor ?? .distantPast) > Date()
    }
}

struct PassengerProfile: Identifiable, Codable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var riderRating: Double
    var preferredLanguage: String
}

struct PaymentMethod: Identifiable, Codable, Hashable {
    var id: String
    var providerName: String
    var type: PaymentMethodType
    var last4: String
    var cardLabel: String
    var isDefault: Bool
    var isAvailable: Bool
}

struct RideReceipt: Identifiable, Codable, Hashable {
    var id: String
    var tripId: String
    var receiptTotal: Double
    var baseFare: Double
    var fees: Double
    var taxes: Double
    var tip: Double = 0
    var currency: String
    var paymentMethodId: String
    var generatedAt: Date
}

struct SavedPlace: Identifiable, Codable, Hashable {
    var id: String
    var type: SavedPlaceType
    var displayName: String
    var address: String
    var latitudePlaceholder: Double
    var longitudePlaceholder: Double
}

struct Promotion: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var detail: String
    var valueLabel: String
    var isActive: Bool
}

struct TravelAlert: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var message: String
    var severity: AlertSeverity
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: String
    var fullName: String
    var email: String
    var phoneNumberMasked: String
    var homeCity: String
    var safetyToolkitEnabled: Bool
}

struct WalletState: Codable, Hashable {
    var paymentMethods: [PaymentMethod]
    var promotions: [Promotion]
    var rideCredits: Double
    var businessProfileEnabled: Bool
    var giftCardBalance: Double
}

struct FareSnapshotMetadata: Codable, Hashable {
    var providerLabel: String
    var snapshotTimestamp: Date
    var sourceType: FareSourceType
    var lastUpdated: Date
    var sourceNote: String
}

struct RequestDraft: Codable, Hashable {
    var pickup: LocationPlace?
    var destination: LocationPlace?
    var rideTiming: RideTimingOption
    var reservedDate: Date?
    var selectedRideTypeId: String?
    var sortOption: RideSortOption
    var filterCategory: RideFilterCategory
    var maxETAMinutes: Int
    var lowerPriceOnly: Bool
    var promoCode: String

    static let empty = RequestDraft(
        pickup: nil,
        destination: nil,
        rideTiming: .now,
        reservedDate: nil,
        selectedRideTypeId: nil,
        sortOption: .lowestPrice,
        filterCategory: .all,
        maxETAMinutes: 45,
        lowerPriceOnly: false,
        promoCode: ""
    )
}

struct RideTypeDefinition: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var category: RideFilterCategory
    var seats: Int
    var serviceLabel: String
    var priceMultiplier: Double
    var etaAdjustment: Int
}

struct CityRideSimState: Codable {
    var userProfile: UserProfile
    var passengerProfile: PassengerProfile
    var places: [LocationPlace]
    var suggestedDestinations: [LocationPlace]
    var recentDestinations: [LocationPlace]
    var savedPlaces: [SavedPlace]
    var travelAlerts: [TravelAlert]
    var walletState: WalletState
    var trips: [Trip]
    var receipts: [RideReceipt]
    var requestDraft: RequestDraft
    var fareMode: FareSourceType
    var snapshotLocation: SnapshotLocation
    var currentSnapshotMetadata: FareSnapshotMetadata?
    var selectedPaymentMethodId: String
    var nextDriverIndex: Int
    var seedVersion: Int?
}
