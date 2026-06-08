import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var selectedHeadline: HeadlineArticle?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Favorites")
                    .font(.caption)
                    .foregroundStyle(.clear)
                    .accessibilityIdentifier("navigation_title_favorites")

                header

                if viewModel.favoriteTeams.isEmpty {
                    emptyState
                } else {
                    favoriteTeamsSection

                    if !viewModel.upcomingGames.isEmpty {
                        gameSection(title: "Upcoming Games", games: viewModel.upcomingGames)
                    }

                    if !viewModel.recentResults.isEmpty {
                        gameSection(title: "Recent Results", games: viewModel.recentResults)
                    }

                    standingsSection
                }

                if !appState.savedHeadlines.isEmpty {
                    savedStoriesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.black)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("screen_favorites")
        .task {
            await viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.favoriteTeamIDs) { _, _ in
            Task {
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
        .sheet(item: $selectedHeadline) { article in
            FavoritesHeadlineDetailSheet(article: article)
                .environmentObject(appState)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My ScoreZone")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("favorites_page_header")

                    Text(favoritesSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("favorites_page_subtitle")
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.refresh(appState: appState)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("favorites_refresh_button")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var favoriteTeamsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Teams")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("favorites_saved_teams_header")

            ForEach(viewModel.favoriteTeams) { team in
                HStack {
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        HStack(spacing: 8) {
                            TeamLogoView(team: team, size: 26, cornerRadius: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(team.leagueID.uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("team_row_\(AccessibilityID.slug(team.displayName))")

                    Spacer()

                    Button {
                        appState.setFavorite(teamID: team.id, isFavorite: false)
                    } label: {
                        Label("Unfavorite", systemImage: "star.slash")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("favorite_team_button_\(AccessibilityID.slug(team.nickname))")
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func gameSection(title: String, games: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("favorites_\(AccessibilityID.slug(title))_header")

            ForEach(games.prefix(8)) { game in
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
        }
    }

    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Standings Snippets")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("favorites_standings_header")

            ForEach(Array(viewModel.standingsByLeague.keys.sorted()), id: \.self) { leagueID in
                if let league = appState.league(for: leagueID) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(league.shortName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            NavigationLink(destination: StandingsView(league: league)) {
                                Text("View")
                                    .font(.caption.weight(.semibold))
                            }
                            .accessibilityIdentifier("favorites_open_standings_\(AccessibilityID.slug(league.id))")
                        }

                        ForEach(viewModel.standingsByLeague[leagueID, default: []].prefix(3)) { entry in
                            HStack {
                                Text("\(entry.rank). \(entry.team.abbreviation)")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(entry.recordText)
                                    .foregroundStyle(.gray)
                            }
                            .font(.caption)
                            .accessibilityIdentifier("standings_row_\(AccessibilityID.slug(entry.leagueID))_\(AccessibilityID.slug(entry.conference))_\(entry.rank)")
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ScoreZoneColors.cardBackgroundLighter)
                    )
                }
            }
        }
    }

    private var savedStoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Stories")
                .font(.headline)
                .foregroundStyle(.white)
                .accessibilityIdentifier("favorites_saved_stories_header")

            ForEach(Array(appState.savedHeadlines.prefix(10).enumerated()), id: \.element.id) { index, article in
                HStack(alignment: .top, spacing: 10) {
                    HeadlineThumbnailView(article: article, height: 60)
                        .frame(width: 96)
                        .accessibilityIdentifier("favorites_saved_story_image_\(String(format: "%03d", index + 1))")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.sectionTag.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.gray)
                        Text(article.headline)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        HStack {
                            Button("Open") {
                                selectedHeadline = article
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("favorites_open_saved_story_\(String(format: "%03d", index + 1))")

                            Spacer()

                            Button {
                                appState.toggleSavedHeadline(article.id)
                            } label: {
                                Image(systemName: "bookmark.slash")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.gray)
                            .accessibilityIdentifier("favorites_remove_saved_story_\(String(format: "%03d", index + 1))")
                        }
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ScoreZoneColors.cardBackgroundLighter)
                )
                .accessibilityIdentifier("favorites_saved_story_row_\(String(format: "%03d", index + 1))")
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No Favorite Teams")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Follow teams from Search, Scores, or Team pages to personalize this tab.")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Button {
                appState.selectedTab = .menu
            } label: {
                Text("Find Teams")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("favorites_open_search_button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
        .accessibilityIdentifier("favorites_empty_state")
    }

    private var favoritesSubtitle: String {
        let followedTeams = viewModel.favoriteTeams.count
        let savedStories = appState.savedHeadlines.count
        return "\(followedTeams) teams followed • \(savedStories) saved stories"
    }
}

private struct FavoritesHeadlineDetailSheet: View {
    let article: HeadlineArticle

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HeadlineThumbnailView(article: article, height: 210)
                        .accessibilityIdentifier("favorites_headline_detail_image")

                    Text(article.sectionTag.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("favorites_headline_detail_section")

                    Text(article.headline)
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("favorites_headline_detail_title")

                    Text(article.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("favorites_headline_detail_summary")

                    HStack(spacing: 10) {
                        Button {
                            appState.toggleSavedHeadline(article.id)
                        } label: {
                            Label(
                                appState.isHeadlineSaved(article.id) ? "Saved" : "Save Story",
                                systemImage: appState.isHeadlineSaved(article.id) ? "bookmark.fill" : "bookmark"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("favorites_headline_detail_save_button")

                        if let leagueID = article.leagueID,
                           let league = appState.league(for: leagueID) {
                            Button {
                                appState.preferredLeagueID = league.id
                                appState.selectedTab = .scores
                                dismiss()
                            } label: {
                                Text("Open \(league.shortName)")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("favorites_headline_detail_open_league_button")
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Story")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("screen_favorites_headline_detail")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("favorites_headline_detail_done_button")
                }
            }
        }
    }
}
