import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var headlines: [HeadlineArticle] = []
    @Published var alerts: [AlertMessage] = SeedData.alerts
    @Published var favoriteTeams: [Team] = []
    @Published var tickerGames: [Game] = []
    @Published var featuredGames: [Game] = []
    @Published var upcomingGames: [Game] = []
    @Published var standingsPreview: [StandingEntry] = []
    @Published var dataOrigin: DataOrigin = .fallback
    @Published var loadState: LoadState = .idle
    @Published var warningMessage: String?

    func refresh(appState: AppState) async {
        loadState = .loading
        favoriteTeams = appState.favoriteTeams

        let mode = appState.dataAccessMode

        // Use centrally loaded games from all leagues (populated by preWarmCache)
        let allGames = appState.loadedGames.sorted { $0.startDate < $1.startDate }

        // Score ticker: live first, then upcoming, then recent final — all leagues
        tickerGames = allGames
            .sorted { statusRank($0.status.state) < statusRank($1.status.state) }
            .prefix(15)
            .map { $0 }

        featuredGames = allGames.filter { $0.status.isLive }.prefix(4).map { $0 }
        if featuredGames.isEmpty {
            featuredGames = allGames.prefix(4).map { $0 }
        }

        upcomingGames = allGames
            .filter { $0.status.isUpcoming }
            .prefix(6)
            .map { $0 }

        // Headlines from centrally loaded data
        let headlinesResult = await appState.repository.loadHeadlines(mode: mode)
        headlines = headlinesResult.value

        // Standings preview — use first available from loaded standings
        standingsPreview = Array(appState.loadedStandings.prefix(5))

        dataOrigin = appState.loadedGames.isEmpty ? .fallback : headlinesResult.origin
        warningMessage = headlinesResult.warningMessage

        loadState = .loaded
        appState.refreshCacheMetadata()
    }

    private func statusRank(_ state: GameState) -> Int {
        switch state {
        case .live: return 0
        case .upcoming: return 1
        case .final: return 2
        case .postponed: return 3
        }
    }

}
