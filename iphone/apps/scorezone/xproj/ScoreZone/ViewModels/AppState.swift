import Foundation

@MainActor
final class AppState: ObservableObject {
    let repository: SportsRepository
    private let persistence: AppPersistence

    @Published var selectedTab: AppTab = .home
    @Published var preferredLeagueID: String = "nba"
    @Published var dataAccessMode: DataAccessMode
    @Published var benchmarkDayOffset: Int

    @Published var favoriteTeamIDs: Set<String>
    @Published var gameAlertIDs: Set<String>
    @Published var gameWatchlistIDs: Set<String>
    @Published var savedHeadlineIDs: Set<String>
    @Published var recentSearches: [RecentSearch]
    @Published var pushAlertsEnabled: Bool
    @Published var breakingNewsEnabled: Bool
    @Published var userProfile: UserProfile
    @Published var loadedGames: [Game] = []
    @Published var loadedHeadlines: [HeadlineArticle] = []
    @Published var loadedStandings: [StandingEntry] = []
    @Published var cacheMetadata: [CachedResponseMetadata]
    @Published var pendingSearchQuery: String?

    init(repository: SportsRepository = SportsRepository(), persistence: AppPersistence = AppPersistence()) {
        self.repository = repository
        self.persistence = persistence
        self.dataAccessMode = persistence.loadDataAccessMode()
        self.benchmarkDayOffset = persistence.loadBenchmarkDayOffset()
        self.favoriteTeamIDs = persistence.loadFavoriteTeamIDs()
        self.gameAlertIDs = persistence.loadGameAlertIDs()
        self.gameWatchlistIDs = persistence.loadGameWatchlistIDs()
        self.savedHeadlineIDs = persistence.loadSavedHeadlineIDs()
        self.recentSearches = persistence.loadRecentSearches()
        self.pushAlertsEnabled = persistence.loadPushAlertsEnabled()
        self.breakingNewsEnabled = persistence.loadBreakingNewsEnabled()
        self.userProfile = SeedData.profile
        self.cacheMetadata = repository.cachedResponseMetadata()
        self.pendingSearchQuery = nil
    }

    var leagues: [League] {
        SeedData.leagues
    }

    var teams: [Team] {
        SeedData.teams
    }

    var favoriteTeams: [Team] {
        SeedData.teams
            .filter { favoriteTeamIDs.contains($0.id) }
            .sorted { $0.displayName < $1.displayName }
    }

    var savedHeadlines: [HeadlineArticle] {
        loadedHeadlines
            .filter { savedHeadlineIDs.contains($0.id) }
            .sorted { $0.publishedAt > $1.publishedAt }
    }

    func team(for id: String) -> Team? {
        SeedData.team(by: id)
    }

    func league(for id: String) -> League? {
        SeedData.league(by: id)
    }

    func isFavorite(teamID: String) -> Bool {
        favoriteTeamIDs.contains(teamID)
    }

    func toggleFavorite(teamID: String) {
        if favoriteTeamIDs.contains(teamID) {
            favoriteTeamIDs.remove(teamID)
        } else {
            favoriteTeamIDs.insert(teamID)
        }
        persistence.persistFavoriteTeamIDs(favoriteTeamIDs)
    }

    func setFavorite(teamID: String, isFavorite: Bool) {
        if isFavorite {
            favoriteTeamIDs.insert(teamID)
        } else {
            favoriteTeamIDs.remove(teamID)
        }
        persistence.persistFavoriteTeamIDs(favoriteTeamIDs)
    }

    var benchmarkDate: Date {
        Calendar.current.date(byAdding: .day, value: benchmarkDayOffset, to: Date()) ?? Date()
    }

    func setDataAccessMode(_ mode: DataAccessMode) {
        dataAccessMode = mode
        persistence.persistDataAccessMode(mode)
    }

    func setBenchmarkDayOffset(_ value: Int) {
        benchmarkDayOffset = min(max(value, -7), 7)
        persistence.persistBenchmarkDayOffset(benchmarkDayOffset)
    }

    func shiftBenchmarkDay(by delta: Int) {
        setBenchmarkDayOffset(benchmarkDayOffset + delta)
    }

    func isGameAlertEnabled(_ gameID: String) -> Bool {
        gameAlertIDs.contains(gameID)
    }

    func toggleGameAlert(_ gameID: String) {
        if gameAlertIDs.contains(gameID) {
            gameAlertIDs.remove(gameID)
        } else {
            gameAlertIDs.insert(gameID)
        }
        persistence.persistGameAlertIDs(gameAlertIDs)
    }

    func isGameWatchlisted(_ gameID: String) -> Bool {
        gameWatchlistIDs.contains(gameID)
    }

    func toggleGameWatchlist(_ gameID: String) {
        if gameWatchlistIDs.contains(gameID) {
            gameWatchlistIDs.remove(gameID)
        } else {
            gameWatchlistIDs.insert(gameID)
        }
        persistence.persistGameWatchlistIDs(gameWatchlistIDs)
    }

    func isHeadlineSaved(_ headlineID: String) -> Bool {
        savedHeadlineIDs.contains(headlineID)
    }

    func toggleSavedHeadline(_ headlineID: String) {
        if savedHeadlineIDs.contains(headlineID) {
            savedHeadlineIDs.remove(headlineID)
        } else {
            savedHeadlineIDs.insert(headlineID)
        }
        persistence.persistSavedHeadlineIDs(savedHeadlineIDs)
    }

    func setPushAlertsEnabled(_ value: Bool) {
        pushAlertsEnabled = value
        persistence.persistPushAlertsEnabled(value)
    }

    func setBreakingNewsEnabled(_ value: Bool) {
        breakingNewsEnabled = value
        persistence.persistBreakingNewsEnabled(value)
    }

    func openSearch(with query: String) {
        pendingSearchQuery = query
        addRecentSearch(query)
        selectedTab = .menu
    }

    func consumePendingSearchQuery() -> String? {
        defer { pendingSearchQuery = nil }
        return pendingSearchQuery
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recentSearches.removeAll { $0.query.caseInsensitiveCompare(trimmed) == .orderedSame }
        let newSearch = RecentSearch(id: UUID().uuidString, query: trimmed, createdAt: Date())
        recentSearches.insert(newSearch, at: 0)
        recentSearches = Array(recentSearches.prefix(12))
        persistence.persistRecentSearches(recentSearches)
    }

    func clearRecentSearches() {
        recentSearches = []
        persistence.persistRecentSearches([])
    }

    func removeRecentSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        persistence.persistRecentSearches(recentSearches)
    }

    func refreshCacheMetadata() {
        cacheMetadata = repository.cachedResponseMetadata()
    }

    /// Fetches scoreboards, standings, and headlines for all leagues and populates loaded data properties.
    func preWarmCache() async {
        let date = benchmarkDate
        let mode = dataAccessMode

        let leagueResults = await withTaskGroup(of: ([Game], [StandingEntry]).self) { group -> [([Game], [StandingEntry])] in
            for league in SeedData.leagues {
                group.addTask { [repository] in
                    let scoreResult = await repository.loadScoreboard(league: league, date: date, mode: mode)
                    let standingsResult = await repository.loadStandings(league: league, mode: mode)
                    return (scoreResult.value, standingsResult.value)
                }
            }
            var results: [([Game], [StandingEntry])] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        let headlinesResult = await repository.loadHeadlines(mode: mode)

        loadedGames = leagueResults.flatMap { $0.0 }
        loadedStandings = leagueResults.flatMap { $0.1 }
        loadedHeadlines = headlinesResult.value

        refreshCacheMetadata()
    }

    func resetAppState() {
        repository.clearCachedResponses()
        persistence.resetUserState()

        favoriteTeamIDs = persistence.loadFavoriteTeamIDs()
        gameAlertIDs = persistence.loadGameAlertIDs()
        gameWatchlistIDs = persistence.loadGameWatchlistIDs()
        savedHeadlineIDs = persistence.loadSavedHeadlineIDs()
        dataAccessMode = persistence.loadDataAccessMode()
        benchmarkDayOffset = persistence.loadBenchmarkDayOffset()
        recentSearches = persistence.loadRecentSearches()
        pushAlertsEnabled = persistence.loadPushAlertsEnabled()
        breakingNewsEnabled = persistence.loadBreakingNewsEnabled()
        userProfile = SeedData.profile
        loadedGames = []
        loadedHeadlines = []
        loadedStandings = []
        cacheMetadata = repository.cachedResponseMetadata()
        preferredLeagueID = "nba"
        pendingSearchQuery = nil
        selectedTab = .home
    }
}
