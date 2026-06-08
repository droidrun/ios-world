import Foundation

enum RestaurantSortOption: String, CaseIterable, Codable, Identifiable {
    case earliestAvailability
    case bestMatch
    case highestRated
    case nearest
    case lowestPriceTier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .earliestAvailability:
            return "Earliest Availability"
        case .bestMatch:
            return "Best Match"
        case .highestRated:
            return "Highest Rated"
        case .nearest:
            return "Nearest"
        case .lowestPriceTier:
            return "Lowest Price Tier"
        }
    }
}

enum TimeOfDayFilter: String, CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case lateNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .lateNight:
            return "Late Night"
        }
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        switch self {
        case .breakfast:
            return hour >= 7 && hour < 11
        case .lunch:
            return hour >= 11 && hour < 15
        case .dinner:
            return hour >= 17 && hour < 22
        case .lateNight:
            return hour >= 22 || hour < 2
        }
    }
}

struct RestaurantFilterState: Codable, Hashable {
    var selectedCuisines: Set<String> = []
    var selectedNeighborhoodIDs: Set<String> = []
    var selectedPriceTiers: Set<Int> = []
    var availableNowOnly: Bool = false
    var outdoorSeatingOnly: Bool = false
    var barSeatingOnly: Bool = false
    var bookableOnlineOnly: Bool = false
    var requirePartySizeSupport: Bool = false
    var selectedTimeOfDay: Set<TimeOfDayFilter> = []

    static let `default` = RestaurantFilterState()
}
