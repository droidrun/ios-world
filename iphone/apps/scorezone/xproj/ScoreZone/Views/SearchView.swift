import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search")
                        .font(.caption)
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("navigation_title_search")

                    searchControls

                    if !appState.recentSearches.isEmpty {
                        recentSearchesSection
                    }

                    if viewModel.hasQuery && !viewModel.hasResults {
                        emptyState
                    }

                    if !viewModel.teamResults.isEmpty {
                        teamResultsSection
                    }

                    if !viewModel.leagueResults.isEmpty {
                        leagueResultsSection
                    }

                    if !viewModel.gameResults.isEmpty {
                        gameResultsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("screen_search")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("search_done_button")
            }
        }
        .task {
            applyPendingSearchIfNeeded()
        }
        .onChange(of: appState.pendingSearchQuery) { _, _ in
            applyPendingSearchIfNeeded()
        }
    }

    private var searchControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search teams, leagues, games", text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ScoreZoneColors.cardBackground)
                    )
                    .accessibilityIdentifier("search_query_field")
                    .onSubmit {
                        viewModel.commitCurrentSearch(appState: appState)
                        viewModel.search(appState: appState)
                    }

                Button {
                    viewModel.commitCurrentSearch(appState: appState)
                    viewModel.search(appState: appState)
                } label: {
                    Text("Search")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("search_submit_button")
            }

            HStack(spacing: 12) {
                Menu {
                    Button("All Leagues") {
                        viewModel.selectedLeagueFilter = "all"
                        viewModel.search(appState: appState)
                    }
                    ForEach(appState.leagues) { league in
                        Button(league.shortName) {
                            viewModel.selectedLeagueFilter = league.id
                            viewModel.search(appState: appState)
                        }
                    }
                } label: {
                    Label(
                        viewModel.selectedLeagueFilter == "all"
                            ? "League: All"
                            : "League: \((appState.league(for: viewModel.selectedLeagueFilter)?.shortName) ?? "All")",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                    .foregroundStyle(.white)
                }
                .accessibilityIdentifier("search_filter_control")

                Menu {
                    ForEach([ScoresSort.alphabetical, .favoritesFirst]) { sort in
                        Button(sort.rawValue) {
                            viewModel.selectedSort = sort
                            viewModel.search(appState: appState)
                        }
                    }
                } label: {
                    Label("Sort: \(viewModel.selectedSort.rawValue)", systemImage: "arrow.up.arrow.down")
                        .foregroundStyle(.white)
                }
                .accessibilityIdentifier("search_sort_control")

                Spacer()
            }
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button("Clear") {
                    appState.clearRecentSearches()
                }
                .font(.subheadline)
                .foregroundStyle(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("search_clear_recent_button")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(appState.recentSearches.enumerated()), id: \.element.id) { index, item in
                        Button {
                            viewModel.query = item.query
                            viewModel.search(appState: appState)
                        } label: {
                            Text(item.query)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(ScoreZoneColors.cardBackgroundElevated))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("search_recent_query_\(String(format: "%03d", index + 1))")
                    }
                }
            }
        }
    }

    private var teamResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Teams")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("search_team_results_header")

            ForEach(viewModel.teamResults) { team in
                HStack {
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        HStack(spacing: 8) {
                            TeamLogoView(team: team, size: 24, cornerRadius: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(team.abbreviation)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("team_row_\(AccessibilityID.slug(team.displayName))")

                    Spacer()

                    Button {
                        appState.toggleFavorite(teamID: team.id)
                    } label: {
                        Image(systemName: appState.isFavorite(teamID: team.id) ? "star.fill" : "star")
                            .foregroundStyle(appState.isFavorite(teamID: team.id) ? ScoreZoneColors.accentRed : .gray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("favorite_team_button_\(AccessibilityID.slug(team.nickname))")
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var leagueResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leagues")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("search_league_results_header")

            ForEach(viewModel.leagueResults) { league in
                Button {
                    appState.preferredLeagueID = league.id
                    appState.selectedTab = .scores
                } label: {
                    HStack {
                        Text(league.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Open Scores")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("search_league_row_\(league.accessibilitySlug)")
            }
        }
    }

    private var gameResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Games")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("search_game_results_header")

            ForEach(viewModel.gameResults) { game in
                NavigationLink(destination: GameDetailView(game: game)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.matchupTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(DateFormatting.shortDate.string(from: game.startDate)) • \(game.status.shortText)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(game.accessibilityRowID)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No results")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Try searching by team name, city, abbreviation, or league.")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackground)
        )
        .accessibilityIdentifier("search_empty_state")
    }

    private func applyPendingSearchIfNeeded() {
        guard let pending = appState.consumePendingSearchQuery() else { return }
        viewModel.query = pending
        viewModel.search(appState: appState)
    }
}
