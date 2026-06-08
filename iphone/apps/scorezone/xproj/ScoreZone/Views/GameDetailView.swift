import SwiftUI

struct GameDetailView: View {
    private enum ActiveSheet: String, Identifiable {
        case boxScore
        case gamecast

        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: GameDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var activeSheet: ActiveSheet?
    @State private var showSearchSheet = false

    init(game: Game) {
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(game: game))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    topBar
                    scoreStrip
                    if viewModel.game.leagueID == "mlb" {
                        atBatCard
                    }
                    actionRow
                    promoBanner
                    relatedLeagueGames
                    detailsStack
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen_game_detail_\(AccessibilityID.slug(viewModel.game.id))")
        .task {
            if case .idle = viewModel.loadState {
                await viewModel.refresh(appState: appState)
            }
        }
        .onChange(of: appState.dataAccessMode) { _, _ in
            Task {
                await viewModel.refresh(appState: appState)
            }
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .boxScore:
                BoxScoreSheet(game: viewModel.game)
            case .gamecast:
                GamecastSheet(game: viewModel.game)
            }
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
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_header_back_button")

            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_header_search_button")

            Spacer()

            Text("ScoreZone")
                .font(.system(size: 34, weight: .black))
                .italic()

            Spacer()

            Button {
                appState.toggleGameWatchlist(viewModel.game.id)
            } label: {
                Image(systemName: appState.isGameWatchlisted(viewModel.game.id) ? "play.rectangle.fill" : "play.rectangle")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_header_watch_button")

            Button {
                appState.toggleGameAlert(viewModel.game.id)
            } label: {
                Image(systemName: appState.isGameAlertEnabled(viewModel.game.id) ? "bell.fill" : "bell")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_header_alert_button")
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

    private var scoreStrip: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.game.awayTeam.shortName.uppercased())
                    .frame(maxWidth: .infinity)
                Text(viewModel.game.homeTeam.shortName.uppercased())
                    .frame(maxWidth: .infinity)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [ScoreZoneColors.accentRed, Color(red: 0.28, green: 0.03, blue: 0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            HStack(alignment: .center) {
                teamScoreColumn(team: viewModel.game.awayTeam, score: viewModel.game.awayScore)
                Spacer()
                VStack(spacing: 2) {
                    Text(primaryStatus)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(viewModel.game.status.isLive ? ScoreZoneColors.liveRed : .white)
                        .accessibilityIdentifier("game_status_label_\(AccessibilityID.slug(viewModel.game.status.state.rawValue))")
                    Text(secondaryStatus)
                        .font(.headline)
                        .foregroundStyle(.gray)
                    if viewModel.game.leagueID == "mlb" {
                        HStack(spacing: 8) {
                            baseDiamond(filled: occupancy.first)
                            baseDiamond(filled: occupancy.second)
                            baseDiamond(filled: occupancy.third)
                        }
                    }
                }
                Spacer()
                teamScoreColumn(team: viewModel.game.homeTeam, score: viewModel.game.homeScore)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(ScoreZoneColors.cardBackground)
        }
    }

    private var atBatCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AT BAT")
                .font(.title3.weight(.black))
                .foregroundStyle(.gray)
                .accessibilityIdentifier("game_detail_at_bat_header")

            Divider().background(Color.white.opacity(0.25))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pitcher")
                        .foregroundStyle(.gray)
                    Text(viewModel.game.homeLeaders.first ?? "Starter")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Batter")
                        .foregroundStyle(.gray)
                    Text(viewModel.game.awayLeaders.first ?? "Lead Off")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text("B \(balls)")
                    Text("S \(strikes)")
                }
                .foregroundStyle(.gray)
                .font(.title3.weight(.semibold))
            }
            .font(.headline)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScoreZoneColors.cardBackgroundElevated)
        )
        .padding(.horizontal, 12)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                activeSheet = .gamecast
            } label: {
                Text("Gamecast")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(ScoreZoneColors.accentRed, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScoreZoneColors.accentRed)
            .accessibilityIdentifier("game_detail_gamecast_button")

            Button {
                activeSheet = .boxScore
            } label: {
                Text("Box Score")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(ScoreZoneColors.accentRed, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScoreZoneColors.accentRed)
            .accessibilityIdentifier("game_detail_box_score_button")
        }
        .padding(.horizontal, 12)
    }

    private var promoBanner: some View {
        Button {
            appState.preferredLeagueID = "ncaamb"
            appState.selectedTab = .scores
        } label: {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.24, blue: 0.49), Color(red: 0.52, green: 0.38, blue: 0.11)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 72)
                .overlay {
                    HStack {
                        Text("ScoreZone")
                            .font(.title.weight(.black))
                            .italic()
                        Spacer()
                        Text("MARCH MADNESS")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text("LEARN MORE")
                            .font(.headline.weight(.bold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Color.white))
                            .foregroundStyle(.black)
                    }
                    .padding(.horizontal, 16)
                    .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .accessibilityIdentifier("game_detail_promo_banner")
    }

    private var relatedLeagueGames: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(viewModel.game.leagueID.uppercased()) GAMES")
                    .font(.title3.weight(.black))
                    .tracking(1)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    appState.preferredLeagueID = viewModel.game.leagueID
                    appState.selectedTab = .scores
                } label: {
                    Text("See All")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ScoreZoneColors.accentRed)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("game_detail_see_all_games_button")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            ForEach(Array(relatedGames.enumerated()), id: \.element.id) { index, game in
                NavigationLink(destination: GameDetailView(game: game)) {
                    miniRow(game: game)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(game.accessibilityRowID)

                if index < relatedGames.count - 1 {
                    Divider().background(Color.white.opacity(0.12))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScoreZoneColors.cardBackground)
        )
        .padding(.horizontal, 12)
    }

    private var detailsStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            sourceAndRefresh
            leadersSection
            teamStatsSection
            summarySection
        }
        .padding(.horizontal, 12)
    }

    private var sourceAndRefresh: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Center")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("game_detail_center_header")

                Text(detailSubtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("game_detail_center_subtitle")
            }

            Spacer()

            Button {
                appState.toggleGameAlert(viewModel.game.id)
            } label: {
                Image(systemName: appState.isGameAlertEnabled(viewModel.game.id) ? "bell.fill" : "bell")
                    .foregroundStyle(ScoreZoneColors.accentRed)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_alert_toggle_\(AccessibilityID.slug(viewModel.game.id))")

            Button {
                Task { await viewModel.refresh(appState: appState) }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ScoreZoneColors.accentRed)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_refresh_button")
        }
    }

    private var leadersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GAME LEADERS")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("game_detail_leaders_header")

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.game.awayTeam.abbreviation)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                    ForEach(viewModel.game.awayLeaders.prefix(3), id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.game.homeTeam.abbreviation)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                    ForEach(viewModel.game.homeLeaders.prefix(3), id: \.self) { line in
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var teamStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TEAM STATS")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("game_detail_team_stats_header")

            statList(title: viewModel.game.awayTeam.abbreviation, stats: viewModel.game.awayTeamStats)
            statList(title: viewModel.game.homeTeam.abbreviation, stats: viewModel.game.homeTeamStats)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECENT PLAY / SUMMARY")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("game_detail_summary_header")
            Text(viewModel.game.headline ?? "Recap details will appear here as the game develops.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .accessibilityIdentifier("game_detail_summary_text")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private func teamScoreColumn(team: Team, score: Int?) -> some View {
        VStack(spacing: 5) {
            TeamLogoView(team: team, size: 56, cornerRadius: 12)
            Text(score.map(String.init) ?? "-")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(team.abbreviation)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
    }

    private func miniRow(game: Game) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(game.awayTeam.abbreviation)
                    Spacer()
                    Text(game.awayScore.map(String.init) ?? "-")
                }
                HStack {
                    Text(game.homeTeam.abbreviation)
                    Spacer()
                    Text(game.homeScore.map(String.init) ?? "-")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(game.status.shortText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(game.status.isLive ? ScoreZoneColors.liveRed : .gray)
                Text(channel(for: game))
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .frame(width: 80, alignment: .leading)

            Button {
                appState.toggleGameAlert(game.id)
            } label: {
                Image(systemName: appState.isGameAlertEnabled(game.id) ? "bell.fill" : "bell")
                    .font(.caption)
                    .foregroundStyle(ScoreZoneColors.accentRed)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_alert_toggle_\(AccessibilityID.slug(game.id))")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func statList(title: String, stats: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
            ForEach(stats.prefix(6), id: \.self) { stat in
                Text(stat)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(ScoreZoneColors.cardBackgroundElevated)
        )
    }

    private var occupancy: (first: Bool, second: Bool, third: Bool) {
        let hash = abs(viewModel.game.id.hashValue)
        return (
            first: hash % 2 == 0,
            second: hash % 3 == 0,
            third: hash % 5 == 0
        )
    }

    private var primaryStatus: String {
        if viewModel.game.leagueID == "mlb", viewModel.game.status.isLive {
            let innings = ["Top 4th", "Bot 4th", "Mid 5th", "Top 6th", "Bot 7th"]
            return innings[abs(viewModel.game.id.hashValue) % innings.count]
        }
        return viewModel.game.status.shortText
    }

    private var secondaryStatus: String {
        if viewModel.game.leagueID == "mlb", viewModel.game.status.isLive {
            let outs = abs(viewModel.game.id.hashValue) % 3
            return "\(outs) Out\(outs == 1 ? "" : "s")"
        }
        return viewModel.game.status.detailText
    }

    private var balls: String {
        String(abs(viewModel.game.id.hashValue) % 4)
    }

    private var strikes: String {
        String(abs(viewModel.game.id.hashValue / 7) % 3)
    }

    private var relatedGames: [Game] {
        appState.loadedGames
            .filter { $0.leagueID == viewModel.game.leagueID && $0.id != viewModel.game.id }
            .sorted { $0.startDate > $1.startDate }
            .prefix(4)
            .map { $0 }
    }

    private func channel(for game: Game) -> String {
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
            .frame(width: 11, height: 11)
            .rotationEffect(.degrees(45))
    }

    private var detailSubtitle: String {
        if let venue = viewModel.game.venue {
            return venue
        }
        return viewModel.game.status.detailText
    }
}

private struct BoxScoreSheet: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeam = 0 // 0 = away, 1 = home

    private var boxScore: BoxScoreData {
        game.apiBoxScore ?? BoxScoreGenerator.generate(for: game)
    }

    private let nameColumnWidth: CGFloat = 130
    private let statColumnWidth: CGFloat = 48
    private let rowHeight: CGFloat = 40
    private let headerRowHeight: CGFloat = 30
    private let sectionHeaderHeight: CGFloat = 28

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if game.status.isUpcoming {
                upcomingState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        sheetHeader
                        scoreHeader
                        linescoreCard
                        teamPicker
                        statsContent
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("screen_box_score_sheet")
    }

    // MARK: - Upcoming Empty State

    private var upcomingState: some View {
        VStack(spacing: 16) {
            sheetHeader
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text("Box score will be available\nonce the game begins.")
                .font(.headline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack {
            Text("Box Score")
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("game_detail_box_score_done")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        HStack(spacing: 0) {
            // Away team
            VStack(spacing: 4) {
                TeamLogoView(team: game.awayTeam, size: 36, cornerRadius: 8)
                Text(game.awayTeam.abbreviation)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            // Away score
            Text(game.awayScore.map(String.init) ?? "-")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 60)

            // Status
            VStack(spacing: 2) {
                Text(game.status.shortText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(game.status.isLive ? ScoreZoneColors.liveRed : .gray)
                if game.status.isFinal {
                    Text(game.status.detailText)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 60)

            // Home score
            Text(game.homeScore.map(String.init) ?? "-")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 60)

            // Home team
            VStack(spacing: 4) {
                TeamLogoView(team: game.homeTeam, size: 36, cornerRadius: 8)
                Text(game.homeTeam.abbreviation)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }

    // MARK: - Linescore

    private var linescoreCard: some View {
        let data = boxScore
        let isMLB = game.leagueID == "mlb"

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 52, alignment: .leading)
                ForEach(Array(data.periodLabels.enumerated()), id: \.offset) { idx, label in
                    let isTotal = idx == data.periodLabels.count - 1
                    let isRHE = isMLB && idx >= data.periodLabels.count - 3
                    Text(label)
                        .font(.caption2.weight(isTotal || isRHE ? .black : .semibold))
                        .foregroundStyle(isTotal || isRHE ? .white : .gray)
                        .frame(width: isMLB ? 26 : 32)
                }
            }
            .padding(.vertical, 6)

            Divider().background(Color.white.opacity(0.15))

            // Away row
            linescoreRow(
                team: game.awayTeam,
                scores: data.awayPeriodScores,
                labels: data.periodLabels
            )

            Divider().background(Color.white.opacity(0.08))

            // Home row
            linescoreRow(
                team: game.homeTeam,
                scores: data.homePeriodScores,
                labels: data.periodLabels
            )
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackground)
        )
        .padding(.horizontal, 12)
    }

    private func linescoreRow(team: Team, scores: [Int], labels: [String]) -> some View {
        let isMLB = game.leagueID == "mlb"
        return HStack(spacing: 0) {
            HStack(spacing: 5) {
                TeamLogoView(team: team, size: 18, cornerRadius: 4)
                Text(team.abbreviation)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, alignment: .leading)

            ForEach(Array(scores.enumerated()), id: \.offset) { idx, score in
                let isTotal = idx == scores.count - 1
                let isRHE = isMLB && idx >= scores.count - 3
                Text("\(score)")
                    .font(.caption.weight(isTotal || isRHE ? .black : .regular))
                    .foregroundStyle(isTotal || isRHE ? .white : .gray)
                    .frame(width: isMLB ? 26 : 32)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Team Picker

    private var teamPicker: some View {
        HStack(spacing: 0) {
            teamTab(team: game.awayTeam, index: 0)
            teamTab(team: game.homeTeam, index: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func teamTab(team: Team, index: Int) -> some View {
        let isSelected = selectedTeam == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTeam = index
            }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    TeamLogoView(team: team, size: 20, cornerRadius: 5)
                    Text(team.abbreviation)
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(isSelected ? .white : .gray)

                Rectangle()
                    .fill(isSelected ? ScoreZoneColors.accentRed : Color.clear)
                    .frame(height: 3)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("box_score_team_tab_\(AccessibilityID.slug(team.abbreviation))")
    }

    // MARK: - Stats Content

    private var statsContent: some View {
        let tables = selectedTeam == 0 ? boxScore.awayTables : boxScore.homeTables
        return ForEach(tables) { table in
            statsSection(table: table)
                .padding(.top, 8)
        }
    }

    private func statsSection(table: BoxScoreStatTable) -> some View {
        let allPlayers = table.players
        let starters = allPlayers.filter(\.isStarter)
        let bench = allPlayers.filter { !$0.isStarter }
        let hasSections = !starters.isEmpty && !bench.isEmpty

        return VStack(spacing: 0) {
            // Optional section title for NFL categories
            if !table.title.isEmpty {
                HStack {
                    Text(table.title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            HStack(alignment: .top, spacing: 0) {
                // Fixed player name column
                VStack(alignment: .leading, spacing: 0) {
                    // Column header
                    Text(hasSections ? "STARTERS" : "PLAYER")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.gray)
                        .frame(width: nameColumnWidth, height: headerRowHeight, alignment: .leading)
                        .padding(.leading, 12)
                        .background(ScoreZoneColors.cardBackground)

                    // Starters or all players
                    ForEach(hasSections ? starters : allPlayers) { player in
                        playerNameCell(player)
                    }

                    // Bench
                    if hasSections {
                        Text("BENCH")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.gray)
                            .frame(width: nameColumnWidth, height: sectionHeaderHeight, alignment: .leading)
                            .padding(.leading, 12)
                            .background(ScoreZoneColors.cardBackgroundElevated)

                        ForEach(bench) { player in
                            playerNameCell(player)
                        }
                    }

                    // Team totals
                    if table.totals != nil {
                        Text("TEAM")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: nameColumnWidth, height: rowHeight, alignment: .leading)
                            .padding(.leading, 12)
                            .background(ScoreZoneColors.cardBackgroundElevated)
                    }
                }
                .frame(width: nameColumnWidth)
                .zIndex(1)

                // Thin divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 0.5)
                    .zIndex(1)

                // Scrollable stat columns
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Column headers
                        HStack(spacing: 0) {
                            ForEach(Array(table.statColumns.enumerated()), id: \.offset) { _, col in
                                Text(col)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.gray)
                                    .frame(width: statColumnWidth, height: headerRowHeight)
                            }
                        }
                        .background(ScoreZoneColors.cardBackground)

                        // Starters or all players
                        ForEach(hasSections ? starters : allPlayers) { player in
                            statValueRow(values: player.statValues, columns: table.statColumns)
                        }

                        // Bench spacer + rows
                        if hasSections {
                            Color.clear
                                .frame(height: sectionHeaderHeight)
                                .background(ScoreZoneColors.cardBackgroundElevated)

                            ForEach(bench) { player in
                                statValueRow(values: player.statValues, columns: table.statColumns)
                            }
                        }

                        // Totals
                        if let totals = table.totals {
                            HStack(spacing: 0) {
                                ForEach(Array(totals.enumerated()), id: \.offset) { _, val in
                                    Text(val)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: statColumnWidth, height: rowHeight)
                                }
                            }
                            .background(ScoreZoneColors.cardBackgroundElevated)
                        }
                    }
                }
            }
            .background(ScoreZoneColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)
        }
    }

    private func playerNameCell(_ player: PlayerBoxLine) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(player.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(player.position)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(width: nameColumnWidth, height: rowHeight, alignment: .leading)
        .padding(.leading, 12)
        .background(ScoreZoneColors.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 0.5)
        }
    }

    private func statValueRow(values: [String], columns: [String]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { i, val in
                let isLast = i == values.count - 1
                Text(val)
                    .font(.caption.weight(isLast ? .bold : .regular))
                    .foregroundStyle(isLast ? .white : .gray)
                    .frame(width: statColumnWidth, height: rowHeight)
            }
        }
        .background(ScoreZoneColors.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 0.5)
        }
    }
}

private struct GamecastSheet: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Gamecast")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.gray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("gamecast_done_button")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Game status card
                    VStack(spacing: 0) {
                        HStack {
                            Text("Status")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(game.status.shortText)
                                .foregroundStyle(game.status.isLive ? ScoreZoneColors.liveRed : .gray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .accessibilityIdentifier("gamecast_status_row")

                        Divider().background(Color.white.opacity(0.1))

                        HStack {
                            Text("Venue")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(game.venue ?? "TBD")
                                .foregroundStyle(.gray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .accessibilityIdentifier("gamecast_venue_row")
                    }
                    .font(.subheadline)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ScoreZoneColors.cardBackground)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)

                    // Plays section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("RECENT PLAYS")
                            .font(.caption.weight(.black))
                            .tracking(1)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                        if let apiPlays = game.apiPlays {
                            ForEach(Array(apiPlays.suffix(30).reversed().enumerated()), id: \.element.id) { index, event in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(event.period)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.gray)
                                        if !event.clock.isEmpty {
                                            Text(event.clock)
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.gray)
                                        }
                                        Spacer()
                                        if event.isScoringPlay {
                                            if let away = event.awayScore, let home = event.homeScore {
                                                Text("\(away) - \(home)")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(ScoreZoneColors.accentRed)
                                            }
                                        }
                                    }
                                    Text(event.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(event.isScoringPlay ? ScoreZoneColors.cardBackgroundElevated : Color.clear)
                                .accessibilityIdentifier("gamecast_event_row_\(String(format: "%03d", index + 1))")

                                if index < min(apiPlays.count, 30) - 1 {
                                    Divider().background(Color.white.opacity(0.08)).padding(.leading, 14)
                                }
                            }
                        } else {
                            ForEach(Array(syntheticEvents.enumerated()), id: \.offset) { index, event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.time)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.gray)
                                    Text(event.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .accessibilityIdentifier("gamecast_event_row_\(String(format: "%03d", index + 1))")

                                if index < syntheticEvents.count - 1 {
                                    Divider().background(Color.white.opacity(0.08)).padding(.leading, 14)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ScoreZoneColors.cardBackground)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("screen_gamecast_sheet")
    }

    private var syntheticEvents: [(time: String, text: String)] {
        let base = [
            ("12:00", "\(game.awayTeam.abbreviation) opening possession."),
            ("10:34", "\(game.homeTeam.abbreviation) scores in transition."),
            ("08:21", "\(game.awayTeam.abbreviation) answers with a quick run."),
            ("05:02", "Timeout on floor. Coaches adjust matchups."),
            ("02:11", "Lead changes as defenses tighten."),
            ("00:34", "Key late-game sequence shifts momentum.")
        ]

        if game.status.isFinal {
            return base + [("00:00", "Final horn. \(game.matchupTitle) is complete.")]
        }
        if game.status.isUpcoming {
            return [
                ("Pregame", "Lineups posted for \(game.matchupTitle)."),
                ("Pregame", "Tip/kick/first pitch scheduled at \(DateFormatting.gameTime.string(from: game.startDate))."),
                ("Pregame", "Injury and availability report loaded.")
            ]
        }
        return base
    }
}
