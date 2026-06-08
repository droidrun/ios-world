import SwiftUI

struct ScoresView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ScoresViewModel()
    @State private var showSearchSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Scores")
                            .font(.caption)
                            .foregroundStyle(.clear)
                            .accessibilityIdentifier("navigation_title_scores")

                        topFilters
                        dateAndControls
                        sourceBanner
                        scoreboardSections
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen_scores")
        .task {
            viewModel.syncFromAppState(appState)
            await viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.preferredLeagueID) { _, newValue in
            viewModel.selectedLeagueID = newValue
            Task {
                await viewModel.refresh(appState: appState)
            }
        }
        .onChange(of: appState.dataAccessMode) { _, _ in
            Task {
                await viewModel.refresh(appState: appState)
            }
        }
        .onChange(of: appState.benchmarkDayOffset) { _, _ in
            viewModel.syncFromAppState(appState)
            Task {
                await viewModel.refresh(appState: appState)
            }
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                SearchView()
                    .environmentObject(appState)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scores_header_search_button")

            Button {
                viewModel.selectedFilter = .all
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scores_header_list_button")

            Spacer()

            Text("ScoreZone")
                .font(.system(size: 34, weight: .black))
                .italic()
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Spacer()

            Button {
                appState.selectedTab = .scoreZonePlus
            } label: {
                Image(systemName: appState.gameWatchlistIDs.isEmpty ? "star" : "star.fill")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scores_header_favorites_button")

            Button {
                appState.selectedTab = .menu
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scores_header_settings_button")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .background(
            Color.black
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 0.8)
                }
        )
    }

    private var topFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    viewModel.selectedSort = .liveFirst
                    viewModel.selectedFilter = .all
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                        Text("Top Events")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(ScoreZoneColors.chipBackground))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityIdentifier("scores_top_events_chip")

                ForEach(appState.leagues) { league in
                    Button {
                        viewModel.selectLeague(league.id)
                        appState.preferredLeagueID = league.id
                        Task {
                            await viewModel.refresh(appState: appState)
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: league.iconSystemName)
                            Text(league.shortName)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedLeagueID == league.id ? ScoreZoneColors.chipBackgroundSelected : ScoreZoneColors.chipBackgroundDefault)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(viewModel.selectedLeagueID == league.id ? .white : .gray)
                    .accessibilityIdentifier("scores_league_chip_\(league.accessibilitySlug)")
                }
            }
        }
    }

    private var dateAndControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    viewModel.navigateDate(by: -1)
                    Task { await viewModel.refresh(appState: appState) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scores_date_previous")

                Spacer()

                Text(DateFormatting.shortDate.string(from: viewModel.selectedDate).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("scores_selected_date_label")

                Spacer()

                Button {
                    viewModel.navigateDate(by: 1)
                    Task { await viewModel.refresh(appState: appState) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scores_date_next")
            }
            .foregroundStyle(.white)

            HStack {
                Menu {
                    ForEach(ScoresFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            viewModel.selectedFilter = filter
                        }
                    }
                } label: {
                    Label(viewModel.selectedFilter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .accessibilityIdentifier("scores_filter_control")

                Menu {
                    ForEach(ScoresSort.allCases) { sort in
                        Button(sort.rawValue) {
                            viewModel.selectedSort = sort
                        }
                    }
                } label: {
                    Label(viewModel.selectedSort.rawValue, systemImage: "arrow.up.arrow.down")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .accessibilityIdentifier("scores_sort_control")

                Spacer()

                if let league = appState.league(for: viewModel.selectedLeagueID) {
                    NavigationLink(destination: StandingsView(league: league)) {
                        Text("Standings")
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ScoreZoneColors.accentRed)
                    .accessibilityIdentifier("scores_open_standings_button")
                }
            }
            .foregroundStyle(.white)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackground)
        )
    }

    private var sourceBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scoreboard")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("scores_scoreboard_header")

                Text(scoreboardSubtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("scores_scoreboard_subtitle")
            }

            Spacer()

            Button {
                Task { await viewModel.refresh(appState: appState) }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScoreZoneColors.accentRed)
            .accessibilityIdentifier("scores_refresh_button")
        }
    }

    private var scoreboardSections: some View {
        let displayed = viewModel.displayedGames(favoriteIDs: appState.favoriteTeamIDs)
        let favoriteGames = displayed.filter { appState.favoriteTeamIDs.contains($0.homeTeam.id) || appState.favoriteTeamIDs.contains($0.awayTeam.id) }
        let remaining = displayed.filter { !favoriteGames.contains($0) }

        return VStack(alignment: .leading, spacing: 14) {
            if displayed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NO GAMES FOR THIS DATE")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Try another date or refresh to check for updates.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ScoreZoneColors.cardBackground)
                )
                .accessibilityIdentifier("scores_empty_state")
            } else {
                if !favoriteGames.isEmpty {
                    sectionContainer(title: "FAVORITES") {
                        VStack(spacing: 0) {
                            ForEach(Array(favoriteGames.enumerated()), id: \.element.id) { index, game in
                                ScoreZoneGameRow(game: game)
                                    .environmentObject(appState)
                                    .accessibilityIdentifier(game.accessibilityRowID)
                                if index < favoriteGames.count - 1 {
                                    Divider().background(Color.white.opacity(0.12))
                                }
                            }
                        }
                    }
                }

                if !remaining.isEmpty {
                    sectionContainer(title: "\((appState.league(for: viewModel.selectedLeagueID)?.name ?? "Top Events").uppercased())") {
                        VStack(spacing: 0) {
                            ForEach(Array(remaining.enumerated()), id: \.element.id) { index, game in
                                ScoreZoneGameRow(game: game)
                                    .environmentObject(appState)
                                    .accessibilityIdentifier(game.accessibilityRowID)
                                if index < remaining.count - 1 {
                                    Divider().background(Color.white.opacity(0.12))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3.weight(.black))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                Spacer()
                if title != "FAVORITES" {
                    Button {
                        viewModel.selectedFilter = .all
                        viewModel.selectedSort = .date
                    } label: {
                        Text("See All")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ScoreZoneColors.accentRed)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("scores_see_all_games_button")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScoreZoneColors.cardBackground)
        )
    }

    private var scoreboardSubtitle: String {
        let gameCount = viewModel.games.count
        let leagueName = appState.league(for: viewModel.selectedLeagueID)?.shortName ?? "Top Events"
        if gameCount == 0 {
            return "\(leagueName) • No games scheduled"
        }
        if gameCount == 1 {
            return "\(leagueName) • 1 game"
        }
        return "\(leagueName) • \(gameCount) games"
    }
}

private struct ScoreZoneGameRow: View {
    let game: Game
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Top status row
            HStack {
                Text(primaryStatus)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(game.status.isLive ? ScoreZoneColors.liveRed : .gray)
                    .accessibilityIdentifier("game_status_label_\(AccessibilityID.slug(game.status.state.rawValue))")

                if game.leagueID == "mlb", game.status.isLive {
                    HStack(spacing: 3) {
                        baseDiamond(filled: occupancy.first)
                        baseDiamond(filled: occupancy.second)
                        baseDiamond(filled: occupancy.third)
                    }
                    .padding(.leading, 4)
                }

                Spacer()

                Text(secondaryStatus)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(.bottom, 6)

            // Away team row
            teamScoreLine(team: game.awayTeam, score: game.awayScore)

            // Home team row
            teamScoreLine(team: game.homeTeam, score: game.homeScore)
                .padding(.top, 2)

            // Bottom action row
            HStack(spacing: 10) {
                NavigationLink(destination: GameDetailView(game: game)) {
                    Text("Gamecast")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ScoreZoneColors.accentRed)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scores_open_game_detail_\(AccessibilityID.slug(game.id))")

                Text(channel)
                    .font(.caption2)
                    .foregroundStyle(.gray)

                if let league = appState.league(for: game.leagueID) {
                    NavigationLink(destination: StandingsView(league: league)) {
                        Text("Standings")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("scores_open_standings_\(AccessibilityID.slug(league.id))")
                }

                Spacer()

                Button {
                    appState.toggleGameAlert(game.id)
                } label: {
                    Image(systemName: appState.isGameAlertEnabled(game.id) ? "bell.fill" : "bell")
                        .font(.caption)
                        .foregroundStyle(ScoreZoneColors.accentRed)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("game_alert_toggle_\(AccessibilityID.slug(game.id))")

                if game.status.isLive || game.status.isUpcoming {
                    Button {
                        appState.toggleGameWatchlist(game.id)
                    } label: {
                        Text(appState.isGameWatchlisted(game.id) ? "Watching" : "Watch")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(Capsule().fill(ScoreZoneColors.accentRed))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("game_watch_button_\(AccessibilityID.slug(game.id))")
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func teamScoreLine(team: Team, score: Int?) -> some View {
        HStack(spacing: 8) {
            NavigationLink(destination: TeamDetailView(team: team)) {
                HStack(spacing: 6) {
                    TeamLogoView(team: team, size: 20, cornerRadius: 5)

                    Text(team.abbreviation)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("(\(record(for: team)))")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("team_row_\(AccessibilityID.slug(team.displayName))")

            Spacer()

            Text(score.map(String.init) ?? "-")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 28, alignment: .trailing)
        }
    }

    private func record(for team: Team) -> String {
        if let standings = appState.loadedStandings.first(where: { $0.team.id == team.id }) {
            return standings.recordText
        }

        let hash = abs(team.id.hashValue)
        let wins = (hash % 24) + 8
        let losses = ((hash / 7) % 18) + 3
        return "\(wins)-\(losses)"
    }

    private var occupancy: (first: Bool, second: Bool, third: Bool) {
        let hash = abs(game.id.hashValue)
        return (
            first: hash % 2 == 0,
            second: hash % 3 == 0,
            third: hash % 5 == 0
        )
    }

    private var primaryStatus: String {
        if game.leagueID == "mlb", game.status.isLive {
            let innings = ["Top 4th", "Bot 4th", "Mid 5th", "Top 6th", "Bot 7th"]
            return innings[abs(game.id.hashValue) % innings.count]
        }
        return game.status.shortText
    }

    private var secondaryStatus: String {
        if game.leagueID == "mlb", game.status.isLive {
            let outs = abs(game.id.hashValue) % 3
            return "\(outs) Out\(outs == 1 ? "" : "s")"
        }
        return game.status.detailText
    }

    private var channel: String {
        switch game.leagueID {
        case "mlb": return "MLB.TV"
        case "nba": return "NBA TV"
        case "nfl": return "SZ"
        case "nhl": return "SZ+"
        case "ncaafb": return "ABC"
        case "ncaamb": return "SEC Network"
        case "epl": return "Peacock"
        default: return "Live"
        }
    }

    private func baseDiamond(filled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(filled ? ScoreZoneColors.accentRed : Color.white.opacity(0.2))
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(45))
    }
}
