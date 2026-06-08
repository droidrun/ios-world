import SwiftUI

struct TeamDetailView: View {
    let team: Team

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: TeamDetailViewModel

    init(team: Team) {
        self.team = team
        _viewModel = StateObject(wrappedValue: TeamDetailViewModel(team: team))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    teamHeader

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Team Hub")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("team_detail_hub_header")

                            Text(teamMetaLine)
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .accessibilityIdentifier("team_detail_meta_line")
                        }

                        Spacer()

                        Button {
                            Task {
                                await viewModel.refresh(appState: appState)
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .tint(ScoreZoneColors.accentRed)
                        .accessibilityIdentifier("team_detail_refresh_button")
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ScoreZoneColors.cardBackgroundLighter)
                    )

                    scheduleSection
                    standingsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(team.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("screen_team_detail_\(AccessibilityID.slug(team.displayName))")
        .task {
            if case .idle = viewModel.loadState {
                await viewModel.refresh(appState: appState)
            }
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.dataAccessMode) { _, _ in
            Task {
                await viewModel.refresh(appState: appState)
            }
        }
    }

    private var teamHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TeamLogoView(team: team, size: 38, cornerRadius: 8)
                Text(team.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("team_detail_title")
            }

            HStack(spacing: 10) {
                Text(team.leagueID.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(ScoreZoneColors.cardBackgroundElevated))

                if let conference = team.conference {
                    Text(conference)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Button {
                    appState.toggleFavorite(teamID: team.id)
                } label: {
                    Label(
                        appState.isFavorite(teamID: team.id) ? "Following" : "Follow",
                        systemImage: appState.isFavorite(teamID: team.id) ? "star.fill" : "star"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("favorite_team_button_\(AccessibilityID.slug(team.nickname))")
            }
        }
    }

    private var upcomingGames: [Game] {
        viewModel.schedule.filter { $0.status.state == .upcoming || $0.status.state == .live }
    }

    private var recentGames: [Game] {
        viewModel.schedule.filter { $0.status.state == .final || $0.status.state == .postponed }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule & Results")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("team_detail_schedule_header")

            if viewModel.schedule.isEmpty {
                Text("No schedule available.")
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("team_detail_schedule_empty")
            } else {
                if !upcomingGames.isEmpty {
                    Text("Upcoming")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.gray)
                        .accessibilityIdentifier("team_detail_upcoming_header")

                    ForEach(upcomingGames.prefix(6)) { game in
                        scheduleRow(game: game)
                    }
                }

                if !recentGames.isEmpty {
                    Text("Recent Results")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.gray)
                        .padding(.top, upcomingGames.isEmpty ? 0 : 6)
                        .accessibilityIdentifier("team_detail_recent_results_header")

                    ForEach(recentGames.prefix(6)) { game in
                        scheduleRow(game: game)
                    }
                }
            }
        }
    }

    private func scheduleRow(game: Game) -> some View {
        NavigationLink(destination: GameDetailView(game: game)) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.matchupTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(DateFormatting.shortDate.string(from: game.startDate)) • \(game.status.shortText)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                if game.status.isLive {
                    Text("LIVE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ScoreZoneColors.liveRed)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(game.accessibilityRowID)
    }

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Standings")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("team_detail_standings_header")
                Spacer()
                if let league = appState.league(for: team.leagueID) {
                    NavigationLink(destination: StandingsView(league: league)) {
                        Text("View League")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ScoreZoneColors.accentRed)
                    }
                    .accessibilityIdentifier("team_detail_open_standings_button")
                }
            }

            if viewModel.standings.isEmpty {
                Text("No standings available")
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("team_detail_standings_empty")
            } else {
                ForEach(viewModel.standings.prefix(8)) { entry in
                    HStack {
                        Text("\(entry.rank)")
                            .frame(width: 22, alignment: .leading)
                            .foregroundStyle(.white)
                        Text(entry.team.abbreviation)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(entry.recordText)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("standings_row_\(AccessibilityID.slug(entry.leagueID))_\(AccessibilityID.slug(entry.conference))_\(entry.rank)")
                }
            }
        }
    }

    private var teamMetaLine: String {
        let conference = team.conference ?? team.leagueID.uppercased()
        if let division = team.division {
            return "\(conference) • \(division)"
        }
        return conference
    }
}
