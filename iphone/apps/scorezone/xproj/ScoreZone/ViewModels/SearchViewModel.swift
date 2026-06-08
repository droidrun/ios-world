import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var teamResults: [Team] = []
    @Published var leagueResults: [League] = []
    @Published var gameResults: [Game] = []
    @Published var selectedSort: ScoresSort = .alphabetical
    @Published var selectedLeagueFilter: String = "all"

    func search(appState: AppState) {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            teamResults = []
            leagueResults = []
            gameResults = []
            return
        }

        let needle = normalized.lowercased()

        let filteredTeams = SeedData.teams.filter { team in
            if selectedLeagueFilter != "all" && team.leagueID != selectedLeagueFilter {
                return false
            }
            return team.searchableTokens.contains(where: { token in
                token.lowercased().contains(needle)
            })
        }

        let sortedTeams: [Team]
        switch selectedSort {
        case .favoritesFirst:
            sortedTeams = filteredTeams.sorted { lhs, rhs in
                let lhsFavorite = appState.favoriteTeamIDs.contains(lhs.id)
                let rhsFavorite = appState.favoriteTeamIDs.contains(rhs.id)
                if lhsFavorite != rhsFavorite {
                    return lhsFavorite && !rhsFavorite
                }
                return lhs.displayName < rhs.displayName
            }
        default:
            sortedTeams = filteredTeams.sorted { $0.displayName < $1.displayName }
        }

        teamResults = Array(sortedTeams.prefix(30))

        leagueResults = SeedData.leagues.filter { league in
            league.name.lowercased().contains(needle) ||
            league.shortName.lowercased().contains(needle)
        }

        let searchableGames = appState.loadedGames.filter { game in
            if selectedLeagueFilter != "all" && game.leagueID != selectedLeagueFilter {
                return false
            }

            let haystacks = [
                game.homeTeam.displayName,
                game.awayTeam.displayName,
                game.homeTeam.abbreviation,
                game.awayTeam.abbreviation,
                game.homeTeam.shortName,
                game.awayTeam.shortName,
                game.homeTeam.nickname,
                game.awayTeam.nickname,
                game.leagueID,
                game.headline ?? ""
            ]
            return haystacks.contains(where: { $0.lowercased().contains(needle) })
        }

        gameResults = Array(searchableGames.sorted { $0.startDate > $1.startDate }.prefix(20))
    }

    var hasResults: Bool {
        !teamResults.isEmpty || !leagueResults.isEmpty || !gameResults.isEmpty
    }

    var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func commitCurrentSearch(appState: AppState) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.addRecentSearch(trimmed)
    }
}
