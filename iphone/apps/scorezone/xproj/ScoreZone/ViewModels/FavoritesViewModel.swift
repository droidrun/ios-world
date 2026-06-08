import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favoriteTeams: [Team] = []
    @Published var upcomingGames: [Game] = []
    @Published var recentResults: [Game] = []
    @Published var standingsByLeague: [String: [StandingEntry]] = [:]
    @Published var dataOrigin: DataOrigin = .fallback
    @Published var loadState: LoadState = .idle
    @Published var warningMessage: String?

    func refresh(appState: AppState) async {
        favoriteTeams = appState.favoriteTeams

        // Saved stories on the Favorites screen resolve against
        // appState.loadedHeadlines. That collection is only populated by the
        // Home/Watch tabs, so reaching Favorites directly (e.g. via the More
        // tab "Saved Stories" shortcut) would show an empty saved-stories
        // section. Load headlines here so the saved-stories list always renders.
        if appState.loadedHeadlines.isEmpty {
            let headlinesResult = await appState.repository.loadHeadlines(mode: appState.dataAccessMode)
            appState.loadedHeadlines = headlinesResult.value
        }

        guard !favoriteTeams.isEmpty else {
            upcomingGames = []
            recentResults = []
            standingsByLeague = [:]
            dataOrigin = .fallback
            loadState = .loaded
            warningMessage = nil
            return
        }

        loadState = .loading

        let mode = appState.dataAccessMode
        var allOrigins: [DataOrigin] = []
        var warnings: [String] = []
        var collectedGames: [Game] = []

        await withTaskGroup(of: FetchResult<[Game]>.self) { group in
            for team in favoriteTeams {
                group.addTask {
                    await appState.repository.loadTeamSchedule(for: team, mode: mode)
                }
            }

            for await result in group {
                allOrigins.append(result.origin)
                if let warning = result.warningMessage {
                    warnings.append(warning)
                }
                collectedGames.append(contentsOf: result.value)
            }
        }

        let dedupedGames = Dictionary(grouping: collectedGames, by: \.id).compactMap { $0.value.first }
        upcomingGames = dedupedGames
            .filter { $0.status.isUpcoming || $0.status.isLive }
            .sorted { $0.startDate < $1.startDate }
        recentResults = dedupedGames
            .filter { $0.status.isFinal }
            .sorted { $0.startDate > $1.startDate }

        let leagueIDs = Set(favoriteTeams.map { $0.leagueID })
        standingsByLeague = [:]

        await withTaskGroup(of: (String, FetchResult<[StandingEntry]>).self) { group in
            for leagueID in leagueIDs {
                guard let league = appState.league(for: leagueID) else { continue }
                group.addTask {
                    (leagueID, await appState.repository.loadStandings(league: league, mode: mode))
                }
            }

            for await tuple in group {
                allOrigins.append(tuple.1.origin)
                standingsByLeague[tuple.0] = tuple.1.value
                if let warning = tuple.1.warningMessage {
                    warnings.append(warning)
                }
            }
        }

        dataOrigin = aggregateOrigin(allOrigins)
        warningMessage = warnings.first
        loadState = .loaded

        appState.refreshCacheMetadata()
    }

    private func aggregateOrigin(_ origins: [DataOrigin]) -> DataOrigin {
        if origins.contains(.live) {
            return .live
        }
        if origins.contains(.cached) {
            return .cached
        }
        return .fallback
    }
}
