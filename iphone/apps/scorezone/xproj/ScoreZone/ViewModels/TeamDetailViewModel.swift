import Foundation

@MainActor
final class TeamDetailViewModel: ObservableObject {
    @Published var schedule: [Game] = []
    @Published var standings: [StandingEntry] = []
    @Published var dataOrigin: DataOrigin = .fallback
    @Published var loadState: LoadState = .idle
    @Published var warningMessage: String?

    let team: Team

    init(team: Team) {
        self.team = team
    }

    func refresh(appState: AppState) async {
        guard let league = appState.league(for: team.leagueID) else {
            loadState = .failed("League unavailable for \(team.displayName).")
            return
        }

        loadState = .loading

        let mode = appState.dataAccessMode
        async let scheduleResult = appState.repository.loadTeamSchedule(for: team, mode: mode)
        async let standingsResult = appState.repository.loadStandings(league: league, mode: mode)

        let scheduleValue = await scheduleResult
        let standingsValue = await standingsResult

        // Sort upcoming/live games first (soonest first), then past games (most recent first).
        // This ensures the "next game" is always visible without scrolling through old results.
        schedule = scheduleValue.value.sorted { lhs, rhs in
            let lhsUpcoming = lhs.status.state == .upcoming || lhs.status.state == .live
            let rhsUpcoming = rhs.status.state == .upcoming || rhs.status.state == .live
            if lhsUpcoming != rhsUpcoming {
                return lhsUpcoming
            }
            if lhsUpcoming {
                return lhs.startDate < rhs.startDate
            }
            return lhs.startDate > rhs.startDate
        }
        standings = standingsValue.value.filter { $0.team.leagueID == team.leagueID }

        dataOrigin = [scheduleValue.origin, standingsValue.origin].contains(.live)
            ? .live
            : ([scheduleValue.origin, standingsValue.origin].contains(.cached) ? .cached : .fallback)

        warningMessage = scheduleValue.warningMessage ?? standingsValue.warningMessage
        loadState = .loaded

        appState.refreshCacheMetadata()
    }
}
