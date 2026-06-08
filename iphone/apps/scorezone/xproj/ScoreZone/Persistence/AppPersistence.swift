import Foundation

final class AppPersistence {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let favoritesKey = "scorezone_sim_favorites"
    private let recentSearchesKey = "scorezone_sim_recent_searches"
    private let gameAlertsKey = "scorezone_sim_game_alerts"
    private let gameWatchlistKey = "scorezone_sim_game_watchlist"
    private let savedHeadlineIDsKey = "scorezone_sim_saved_headline_ids"
    private let pushAlertsEnabledKey = "scorezone_sim_push_alerts_enabled"
    private let breakingNewsEnabledKey = "scorezone_sim_breaking_news_enabled"
    private let dataAccessModeKey = "scorezone_sim_data_access_mode"
    private let benchmarkDayOffsetKey = "scorezone_sim_benchmark_day_offset"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadFavoriteTeamIDs() -> Set<String> {
        guard let saved = userDefaults.array(forKey: favoritesKey) as? [String] else {
            return Set(SeedData.defaultFavoriteTeamIDs)
        }
        return Set(saved)
    }

    func persistFavoriteTeamIDs(_ teamIDs: Set<String>) {
        userDefaults.set(Array(teamIDs).sorted(), forKey: favoritesKey)
    }

    func loadRecentSearches() -> [RecentSearch] {
        guard let data = userDefaults.data(forKey: recentSearchesKey) else {
            return SeedData.defaultRecentQueries.enumerated().map { index, query in
                RecentSearch(
                    id: "recent_seed_\(index)",
                    query: query,
                    createdAt: Date().addingTimeInterval(Double(-(index * 7200)))
                )
            }
        }

        guard let saved = try? decoder.decode([RecentSearch].self, from: data) else {
            return []
        }

        return saved
    }

    func persistRecentSearches(_ searches: [RecentSearch]) {
        if let encoded = try? encoder.encode(Array(searches.prefix(12))) {
            userDefaults.set(encoded, forKey: recentSearchesKey)
        }
    }

    func loadDataAccessMode() -> DataAccessMode {
        guard let raw = userDefaults.string(forKey: dataAccessModeKey),
              let mode = DataAccessMode(rawValue: raw) else {
            return .automatic
        }
        return mode
    }

    func persistDataAccessMode(_ mode: DataAccessMode) {
        userDefaults.set(mode.rawValue, forKey: dataAccessModeKey)
    }

    func loadBenchmarkDayOffset() -> Int {
        guard let value = userDefaults.object(forKey: benchmarkDayOffsetKey) as? Int else {
            return 0
        }
        return value
    }

    func persistBenchmarkDayOffset(_ value: Int) {
        userDefaults.set(value, forKey: benchmarkDayOffsetKey)
    }

    func loadGameAlertIDs() -> Set<String> {
        guard let saved = userDefaults.array(forKey: gameAlertsKey) as? [String] else {
            return Set(SeedData.defaultGameAlertIDs)
        }
        return Set(saved)
    }

    func persistGameAlertIDs(_ ids: Set<String>) {
        userDefaults.set(Array(ids).sorted(), forKey: gameAlertsKey)
    }

    func loadGameWatchlistIDs() -> Set<String> {
        guard let saved = userDefaults.array(forKey: gameWatchlistKey) as? [String] else {
            return Set(SeedData.defaultWatchlistGameIDs)
        }
        return Set(saved)
    }

    func persistGameWatchlistIDs(_ ids: Set<String>) {
        userDefaults.set(Array(ids).sorted(), forKey: gameWatchlistKey)
    }

    func loadSavedHeadlineIDs() -> Set<String> {
        guard let saved = userDefaults.array(forKey: savedHeadlineIDsKey) as? [String] else {
            return Set(SeedData.defaultSavedHeadlineIDs)
        }
        return Set(saved)
    }

    func persistSavedHeadlineIDs(_ ids: Set<String>) {
        userDefaults.set(Array(ids).sorted(), forKey: savedHeadlineIDsKey)
    }

    func loadPushAlertsEnabled() -> Bool {
        guard userDefaults.object(forKey: pushAlertsEnabledKey) != nil else {
            return true
        }
        return userDefaults.bool(forKey: pushAlertsEnabledKey)
    }

    func persistPushAlertsEnabled(_ value: Bool) {
        userDefaults.set(value, forKey: pushAlertsEnabledKey)
    }

    func loadBreakingNewsEnabled() -> Bool {
        guard userDefaults.object(forKey: breakingNewsEnabledKey) != nil else {
            return true
        }
        return userDefaults.bool(forKey: breakingNewsEnabledKey)
    }

    func persistBreakingNewsEnabled(_ value: Bool) {
        userDefaults.set(value, forKey: breakingNewsEnabledKey)
    }

    func resetUserState() {
        userDefaults.removeObject(forKey: favoritesKey)
        userDefaults.removeObject(forKey: recentSearchesKey)
        userDefaults.removeObject(forKey: gameAlertsKey)
        userDefaults.removeObject(forKey: gameWatchlistKey)
        userDefaults.removeObject(forKey: savedHeadlineIDsKey)
        userDefaults.removeObject(forKey: pushAlertsEnabledKey)
        userDefaults.removeObject(forKey: breakingNewsEnabledKey)
        userDefaults.removeObject(forKey: dataAccessModeKey)
        userDefaults.removeObject(forKey: benchmarkDayOffsetKey)

        persistFavoriteTeamIDs(Set(SeedData.defaultFavoriteTeamIDs))
        persistGameAlertIDs(Set(SeedData.defaultGameAlertIDs))
        persistGameWatchlistIDs(Set(SeedData.defaultWatchlistGameIDs))
        persistSavedHeadlineIDs(Set(SeedData.defaultSavedHeadlineIDs))
        persistPushAlertsEnabled(true)
        persistBreakingNewsEnabled(true)
        persistDataAccessMode(.automatic)
        persistBenchmarkDayOffset(0)
        let defaultRecents = SeedData.defaultRecentQueries.enumerated().map { index, query in
            RecentSearch(
                id: "recent_default_\(index)",
                query: query,
                createdAt: Date().addingTimeInterval(Double(-(index * 3600)))
            )
        }
        persistRecentSearches(defaultRecents)
    }
}
