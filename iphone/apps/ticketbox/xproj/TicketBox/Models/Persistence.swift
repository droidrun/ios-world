import Foundation

enum PersistenceKey: String {
    case favoriteEvents
    case favoritePerformers
    case favoriteVenues
    case listedOrders
    case saleListings
    case cartItems
    case orders
    case promoCodes
    case settings
    case recentSearches
    case recentlyViewedEvents
}

enum Persistence {
    static func contains(_ key: PersistenceKey) -> Bool {
        UserDefaults.standard.data(forKey: key.rawValue) != nil
    }

    static func load<T: Codable>(_ type: T.Type, key: PersistenceKey, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return fallback
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(type, from: data)) ?? fallback
    }

    static func save<T: Codable>(_ value: T, key: PersistenceKey) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }

    static func clearAll() {
        for key in [
            PersistenceKey.favoriteEvents,
            .favoritePerformers,
            .favoriteVenues,
            .listedOrders,
            .saleListings,
            .cartItems,
            .orders,
            .promoCodes,
            .settings,
            .recentSearches,
            .recentlyViewedEvents
        ] {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
