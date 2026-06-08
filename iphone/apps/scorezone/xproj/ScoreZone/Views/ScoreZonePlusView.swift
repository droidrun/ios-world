import SwiftUI

struct ScoreZonePlusView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var selectedHeadline: HeadlineArticle?
    @State private var showSearchSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Favorites")
                        .font(.caption)
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("navigation_title_favorites")

                    scoreZonePlusHeroSection
                    sportCategoriesSection

                    // Favorites integration
                    favoritesHeader
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
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen_favorites")
        .safeAreaInset(edge: .top) {
            scoreZonePlusTopBar
        }
        .task {
            await viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.favoriteTeamIDs) { _, _ in
            Task { await viewModel.refresh(appState: appState) }
        }
        .onChange(of: appState.dataAccessMode) { _, _ in
            Task { await viewModel.refresh(appState: appState) }
        }
        .refreshable {
            await viewModel.refresh(appState: appState)
        }
        .sheet(item: $selectedHeadline) { article in
            FavoritesHeadlineDetailSheet(article: article)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                SearchView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Top Bar

    private var scoreZonePlusTopBar: some View {
        HStack(spacing: 18) {
            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("espn_plus_header_search_button")

            Spacer()

            HStack(spacing: 0) {
                Text("ScoreZone")
                    .font(.system(size: 28, weight: .black))
                    .italic()
                Text("+")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(ScoreZoneColors.accentRed)
            }

            Spacer()

            Button {
                appState.selectedTab = .menu
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("espn_plus_header_profile_button")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Color.black
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 0.8)
                }
        )
    }

    // MARK: - Plus Content

    private var scoreZonePlusHeroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [ScoreZoneColors.accentRed.opacity(0.8), Color(red: 0.15, green: 0.05, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Text("ScoreZone")
                                    .font(.system(size: 48, weight: .black))
                                    .italic()
                                Text("+")
                                    .font(.system(size: 36, weight: .black))
                                    .foregroundStyle(ScoreZoneColors.accentRed)
                            }
                            .foregroundStyle(.white)

                            Text("Stream exclusive live sports & originals")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
            }
        }
    }

    private var sportCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BROWSE")
                .font(.title3.weight(.black))
                .tracking(1)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(appState.leagues) { league in
                        Button {
                            appState.preferredLeagueID = league.id
                            appState.selectedTab = .scores
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: league.iconSystemName)
                                    .font(.headline)
                                Text(league.shortName)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(ScoreZoneColors.cardBackgroundElevated)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("espn_plus_league_shortcut_\(league.accessibilitySlug)")
                    }
                }
            }
        }
    }

    // MARK: - Favorites (preserved identifiers)

    private var favoritesHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My ScoreZone")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("favorites_page_header")

                    Text(favoritesSubtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .accessibilityIdentifier("favorites_page_subtitle")
                }

                Spacer()

                Button {
                    Task { await viewModel.refresh(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(ScoreZoneColors.accentRed)
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
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
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
                            Text("\(DateFormatting.shortDate.string(from: game.startDate)) \u{2022} \(game.status.shortText)")
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
                                    .foregroundStyle(ScoreZoneColors.accentRed)
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
                            .tint(ScoreZoneColors.accentRed)
                            .accessibilityIdentifier("favorites_open_saved_story_\(String(format: "%03d", index + 1))")

                            Spacer()

                            Button {
                                appState.toggleSavedHeadline(article.id)
                            } label: {
                                Image(systemName: "bookmark.slash")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
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
            Text("Follow teams from Scores or Team pages to personalize this section.")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Button {
                showSearchSheet = true
            } label: {
                Text("Find Teams")
            }
            .buttonStyle(.borderedProminent)
            .tint(ScoreZoneColors.accentRed)
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
        return "\(followedTeams) teams followed \u{2022} \(savedStories) saved stories"
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
