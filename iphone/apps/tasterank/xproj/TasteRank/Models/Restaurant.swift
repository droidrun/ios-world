import Foundation

struct CuisineTag: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

struct Neighborhood: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let city: String
}

struct Dish: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

struct OpenHours: Codable, Hashable {
    let openHour: Int
    let closeHour: Int

    func isOpen(at date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        if openHour <= closeHour {
            return hour >= openHour && hour < closeHour
        }
        return hour >= openHour || hour < closeHour
    }

    var display: String {
        let open = OpenHours.format(hour: openHour)
        let close = OpenHours.format(hour: closeHour)
        return "\(open) - \(close)"
    }

    private static func format(hour: Int) -> String {
        let isPM = hour >= 12
        let adjusted = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(adjusted)\(isPM ? "PM" : "AM")"
    }
}

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let cuisine: CuisineTag
    let neighborhood: Neighborhood
    let priceLevel: Int
    let blurb: String
    let dishes: [Dish]
    let distanceMiles: Double
    let hours: OpenHours
    let seedRating: Double
    let popularity: Int
    let photoSeed: String
    let isNew: Bool
    let isTrending: Bool
    let locationLine: String
    let cuisineDetails: String
    let statusLine: String
    let beliScore: Double
    let photoAssetNames: [String]
    let searchHints: [String]
}

extension Restaurant {
    /// Formats distance for display: "2.3 mi" for local, "5,316 mi" for far away
    var formattedDistance: String {
        if distanceMiles >= 100 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            let formatted = formatter.string(from: NSNumber(value: distanceMiles)) ?? "\(Int(distanceMiles))"
            return "\(formatted) mi"
        }
        return String(format: "%.1f mi", distanceMiles)
    }

    /// Whether this restaurant is a travel destination (not local to SF Bay Area)
    var isTravel: Bool {
        distanceMiles >= 200
    }
}

struct DishRating: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let rating: Int
}

struct VisitLog: Identifiable, Codable, Hashable {
    let id: UUID
    let restaurantID: String
    let dateVisited: Date
    let rating: Int
    let dishRatings: [DishRating]
    let notes: String
    let tags: [String]
}

struct FriendProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let handle: String
    let avatarSeed: String
}

struct FriendLog: Identifiable, Codable, Hashable {
    let id: UUID
    let friendID: String
    let restaurantID: String
    let date: Date
    let rating: Int
    let note: String
}

struct ListCollection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var restaurantIDs: [String]
}

struct FeedPost: Identifiable, Codable, Hashable {
    let id: String
    let authorName: String
    let authorHandle: String
    let authorAvatarSeed: String
    let restaurantID: String
    let companionNames: [String]
    let notePreview: String
    let likeCount: Int
    let timeLabel: String
    let visitLabel: String
}

struct LeaderboardEntry: Identifiable, Codable, Hashable {
    let id: String
    let rank: Int
    let displayName: String
    let handle: String
    let score: Int
    let avatarSeed: String
}

struct GoalOption: Identifiable, Codable, Hashable {
    let id: String
    let title: String
}

struct FeedInteractionState: Codable, Hashable {
    var likedPostIDs: Set<String>
    var savedPostIDs: Set<String>
    var commentsByPostID: [String: [String]]
    var recommendationRequests: [String]

    static let `default` = FeedInteractionState(
        likedPostIDs: [],
        savedPostIDs: [],
        commentsByPostID: [:],
        recommendationRequests: []
    )
}

struct UserProfileSummary: Codable, Hashable {
    let displayName: String
    let initials: String
    let handle: String
    let memberSince: String
    let schoolName: String?
    let followers: Int
    let following: Int
    let beliRank: Int
    let beenCount: Int
    let wantToTryCount: Int
    let streakLabel: String
    let lastYearCount: Int
    let goalYear: Int
    let goalOptions: [GoalOption]
    let selectedGoalID: String
}

enum PriceDisplayMode: String, Codable, CaseIterable {
    case dollarSigns
    case numeric
}

struct SettingsState: Codable, Hashable {
    var priceDisplayMode: PriceDisplayMode
    var privateProfile: Bool

    static let `default` = SettingsState(priceDisplayMode: .dollarSigns, privateProfile: false)
}

enum VisitedFilter: String, Codable, CaseIterable {
    case all = "All"
    case visited = "Visited"
    case notVisited = "Not visited"
}

enum SortOption: String, Codable, CaseIterable {
    case recommended = "Recommended"
    case highestRated = "Highest rated"
    case mostPopular = "Most popular"
    case closest = "Closest"
}

struct FilterState: Codable, Hashable {
    var selectedCuisineIDs: Set<String>
    var selectedPriceLevels: Set<Int>
    var maxDistanceMiles: Double?
    var openNowOnly: Bool
    var visitedFilter: VisitedFilter

    static let `default` = FilterState(
        selectedCuisineIDs: [],
        selectedPriceLevels: [],
        maxDistanceMiles: nil,
        openNowOnly: false,
        visitedFilter: .all
    )
}
