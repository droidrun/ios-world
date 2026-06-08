import Foundation

enum AppTab: String, CaseIterable, Identifiable, Codable {
    case home
    case search
    case trips
    case wallet
    case more

    var id: String { rawValue }
}

enum WalletTabSection: String, CaseIterable, Identifiable, Codable {
    case skymiles
    case wallet
    case profile

    var id: String { rawValue }
}

enum FareSourceType: String, Codable, CaseIterable, Identifiable {
    case seeded
    case snapshot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seeded:
            return "Standard Data"
        case .snapshot:
            return "Snapshot Fare Data"
        }
    }
}

enum TripType: String, Codable, CaseIterable, Identifiable {
    case oneWay
    case roundTrip

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneWay:
            return "One-Way"
        case .roundTrip:
            return "Round-Trip"
        }
    }
}

enum CabinClass: String, Codable, CaseIterable, Identifiable {
    case basicEconomy
    case mainCabin
    case comfortPlus
    case firstClass
    case deltaOne

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .basicEconomy:
            return "Basic Economy"
        case .mainCabin:
            return "Main Cabin"
        case .comfortPlus:
            return "Comfort+"
        case .firstClass:
            return "First Class"
        case .deltaOne:
            return "SkyTrip One"
        }
    }
}

enum SearchSortOption: String, Codable, CaseIterable, Identifiable {
    case lowestPrice
    case highestPrice
    case shortestDuration
    case earliestDeparture

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lowestPrice:
            return "Lowest Price"
        case .highestPrice:
            return "Highest Price"
        case .shortestDuration:
            return "Shortest Duration"
        case .earliestDeparture:
            return "Earliest Departure"
        }
    }
}

enum TimeOfDayFilter: String, Codable, CaseIterable, Identifiable {
    case any
    case morning
    case afternoon
    case evening

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .any:
            return "Any Time"
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        }
    }
}

enum FlightOperationalStatus: String, Codable, CaseIterable {
    case onTime
    case boarding
    case delayed
    case departed

    var displayName: String {
        switch self {
        case .onTime:
            return "On Time"
        case .boarding:
            return "Boarding"
        case .delayed:
            return "Delayed"
        case .departed:
            return "Departed"
        }
    }
}

enum SeatAvailability: String, Codable {
    case available
    case occupied
    case blocked
    case selected
}

enum SeatTag: String, Codable {
    case standard
    case preferred
    case premium
    case exitRow
}

enum AlertSeverity: String, Codable {
    case info
    case caution
    case warning
}

enum TripCategory: String, Codable {
    case upcoming
    case past
    case canceled
}

struct Airport: Identifiable, Codable, Hashable {
    let id: String
    let code: String
    let city: String
    let name: String
    let state: String

    var displayName: String {
        "\(city) (\(code))"
    }
}

struct Passenger: Identifiable, Codable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var skyMilesNumber: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct FlightSegment: Identifiable, Codable, Hashable {
    let id: String
    let carrierCode: String
    let flightNumber: String
    let origin: Airport
    let destination: Airport
    let departureTime: Date
    let arrivalTime: Date
    let durationMinutes: Int
    let terminal: String
    let gate: String
    let stops: Int
    let status: FlightOperationalStatus

    var descriptor: String {
        "\(carrierCode)\(flightNumber)"
    }
}

struct FareOption: Codable, Hashable {
    let cabin: CabinClass
    let fareBrand: String
    let price: Double
    let currency: String
}

struct FlightItinerary: Identifiable, Codable, Hashable {
    let id: String
    let tripType: TripType
    let origin: Airport
    let destination: Airport
    let outboundSegments: [FlightSegment]
    let returnSegments: [FlightSegment]
    let fare: FareOption
    let badges: [String]
    let sourceType: FareSourceType

    var departureTime: Date {
        outboundSegments.first?.departureTime ?? Date()
    }

    var arrivalTime: Date {
        let activeSegments = tripType == .roundTrip ? returnSegments : outboundSegments
        return activeSegments.last?.arrivalTime ?? Date()
    }

    var totalDurationMinutes: Int {
        outboundSegments.reduce(0) { $0 + $1.durationMinutes } + returnSegments.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalStops: Int {
        max(0, outboundSegments.count - 1) + max(0, returnSegments.count - 1)
    }

    var outboundFlightNumber: String {
        guard let first = outboundSegments.first else { return "DL0000" }
        return "\(first.carrierCode)\(first.flightNumber)"
    }
}

struct Seat: Identifiable, Codable, Hashable {
    let id: String
    let seatNumber: String
    let row: Int
    let column: String
    var availability: SeatAvailability
    let tag: SeatTag
}

struct SeatMap: Identifiable, Codable, Hashable {
    let id: String
    let aircraftType: String
    let rows: [Int]
    let columns: [String]
    var seats: [Seat]
}

struct Trip: Identifiable, Codable, Hashable {
    let id: String
    var confirmationCode: String
    var passenger: Passenger
    var tripType: TripType
    var outboundSegments: [FlightSegment]
    var returnSegments: [FlightSegment]
    var seatAssignment: String?
    var boardingGroup: String
    var checkedIn: Bool
    var baggageStatus: String
    var category: TripCategory
    var operationalStatus: FlightOperationalStatus
    var checkInEligible: Bool
    var fareSourceType: FareSourceType
    var totalPrice: Double
    var currency: String
    var seatMap: SeatMap
    var createdAt: Date
    var passengerCount: Int

    var routeText: String {
        guard let first = outboundSegments.first,
              let last = outboundSegments.last else {
            return "Unknown Route"
        }
        return "\(first.origin.code) → \(last.destination.code)"
    }

    var departureTime: Date {
        outboundSegments.first?.departureTime ?? Date()
    }

    var primaryFlightNumber: String {
        guard let first = outboundSegments.first else { return "DL0000" }
        return "\(first.carrierCode)\(first.flightNumber)"
    }

    var selectedSeats: [String] {
        seatMap.seats.filter { $0.availability == .selected }.map(\.seatNumber)
    }

    var selectedSeatCount: Int {
        selectedSeats.count
    }

    static func seatUpcharge(for tag: SeatTag) -> Double {
        switch tag {
        case .premium: return 89
        case .preferred: return 29
        case .exitRow: return 39
        case .standard: return 0
        }
    }
}

struct BoardingPass: Identifiable, Codable, Hashable {
    let id: String
    let tripId: String
    let confirmationCode: String
    let passengerName: String
    let route: String
    let flightNumber: String
    let date: Date
    var boardingTime: Date
    var gate: String
    var seat: String
    var boardingGroup: String
    let qrPayload: String
}

struct TravelAlert: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let message: String
    let severity: AlertSeverity
    let publishedAt: Date
    let isActive: Bool
}

struct UserProfile: Codable, Hashable {
    var firstName: String
    var lastName: String
    var email: String
    var homeAirportCode: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct SkyMilesAccount: Codable, Hashable {
    var memberNumber: String
    var medallionLevel: String
    var redeemableMiles: Int
    var mqds: Int
}

struct FareSnapshotMetadata: Codable, Hashable {
    let providerLabel: String
    let snapshotTimestamp: String
    let sourceDescription: String
    let lastUpdated: String
}

struct FareSnapshotFile: Codable {
    let metadata: FareSnapshotMetadata
    let itineraries: [FlightItinerary]
}

struct RecentSearch: Identifiable, Codable, Hashable {
    let id: String
    let originCode: String
    let destinationCode: String
    let tripType: TripType
    let departureDate: Date
    let returnDate: Date?
    let passengers: Int
}

struct FlightSearchCriteria: Codable, Hashable {
    var tripType: TripType
    var originCode: String
    var destinationCode: String
    var departureDate: Date
    var returnDate: Date?
    var passengers: Int
    var cabin: CabinClass
    var nonstopOnly: Bool
}

struct SearchFilters: Codable, Hashable {
    var nonstopOnly: Bool = false
    var cabin: CabinClass?
    var timeOfDay: TimeOfDayFilter = .any
    var maxStops: Int = 2
}

struct PersistedAppState: Codable {
    var fareSourceType: FareSourceType
    var trips: [Trip]
    var boardingPasses: [BoardingPass]
    var alerts: [TravelAlert]
    var recentSearches: [RecentSearch]
    var userProfile: UserProfile
    var skyMilesAccount: SkyMilesAccount
}

struct BaggageEvent: Identifiable, Hashable {
    let id: String
    let status: String
    let location: String
    let timestamp: Date
    let isCompleted: Bool
}

struct FareClassBenefit: Identifiable {
    let id = UUID()
    let cabin: CabinClass
    let benefits: [String]

    static let allClasses: [FareClassBenefit] = [
        FareClassBenefit(cabin: .basicEconomy, benefits: [
            "Seat assigned at check-in",
            "No changes or refunds",
            "Personal item included",
            "Carry-on bag not included",
            "No upgrades",
            "Earn miles"
        ]),
        FareClassBenefit(cabin: .mainCabin, benefits: [
            "Seat selection at booking",
            "Changes allowed (fee may apply)",
            "Personal item + carry-on",
            "First checked bag fee applies",
            "Eligible for upgrades",
            "Earn miles"
        ]),
        FareClassBenefit(cabin: .comfortPlus, benefits: [
            "Extra legroom seating",
            "Priority boarding",
            "Dedicated overhead bin",
            "Premium snacks & drinks",
            "Free changes",
            "Earn 2x miles"
        ]),
        FareClassBenefit(cabin: .firstClass, benefits: [
            "Wide seats, extra legroom",
            "Priority boarding & check-in",
            "Complimentary meals & drinks",
            "2 free checked bags",
            "Free changes & cancellation",
            "Earn 2x miles"
        ]),
        FareClassBenefit(cabin: .deltaOne, benefits: [
            "Lie-flat seats",
            "SkyTrip One Lounge access",
            "Premium dining experience",
            "2 free checked bags",
            "Free changes & cancellation",
            "Earn 3x miles"
        ])
    ]
}
