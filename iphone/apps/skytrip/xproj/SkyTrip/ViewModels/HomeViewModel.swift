import Foundation

enum HomeQuickAction {
    case bookFlights
    case checkIn
    case boardingPass
    case flightStatus
    case seatSelection
}

@MainActor
final class HomeViewModel: StoreBackedViewModel {
    var upcomingTrip: Trip? {
        store.upcomingTrips.first
    }

    var checkInEligibleTrip: Trip? {
        store.eligibleCheckInTrips.first
    }

    var alerts: [TravelAlert] {
        store.alerts.filter { $0.isActive }
    }

    var recentSearches: [RecentSearch] {
        store.recentSearches
    }

    var skyMiles: SkyMilesAccount {
        store.skyMilesAccount
    }

    var profileFirstName: String {
        store.userProfile.firstName
    }

    var profileName: String {
        store.userProfile.fullName
    }

    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }

    func runQuickAction(_ action: HomeQuickAction) {
        switch action {
        case .bookFlights:
            store.selectedTab = .search
        case .checkIn:
            store.selectedTab = .trips
        case .boardingPass:
            store.showWalletSection(.wallet)
        case .flightStatus:
            store.selectedTab = .trips
        case .seatSelection:
            store.selectedTab = .trips
        }
    }

    func repeatSearch(_ search: RecentSearch) {
        store.pendingSearchPreset = (
            originCode: search.originCode,
            destinationCode: search.destinationCode,
            tripType: search.tripType,
            departureDate: search.departureDate
        )
        store.selectedTab = .search
    }
}
