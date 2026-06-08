import Foundation

enum DataOrigin: String, Codable, CaseIterable {
    case live
    case cached
    case fallback

    var displayName: String {
        switch self {
        case .live: return "Live API"
        case .cached: return "Cached"
        case .fallback: return "Offline Data"
        }
    }
}

enum DataAccessMode: String, Codable, CaseIterable, Identifiable {
    case automatic
    case livePreferred
    case cacheOnly
    case fallbackOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .livePreferred: return "Live Preferred"
        case .cacheOnly: return "Cache Only"
        case .fallbackOnly: return "Fallback Only"
        }
    }

    var benchmarkNote: String {
        switch self {
        case .automatic:
            return "Uses live data first, then cache, then offline fallback."
        case .livePreferred:
            return "Tries live on every request before cache/fallback."
        case .cacheOnly:
            return "Never hits network; uses cache, then fallback on cache miss."
        case .fallbackOnly:
            return "Uses built-in offline data only, with no network or cache reads."
        }
    }
}

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

enum ScoresFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case live = "Live"
    case final = "Final"
    case upcoming = "Upcoming"

    var id: String { rawValue }
}

enum ScoresSort: String, CaseIterable, Identifiable {
    case date = "Date"
    case alphabetical = "Alphabetical"
    case liveFirst = "Live First"
    case favoritesFirst = "Favorites First"

    var id: String { rawValue }
}

enum AppTab: String, Hashable {
    case home
    case scores
    case watch
    case scoreZonePlus
    case menu
}
