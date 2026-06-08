import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = MenuViewModel()

    @State private var showResetConfirmation = false
    @State private var showDeveloperTools = false
    @State private var showSearchSheet = false
    @State private var showSavedStories = false
    @State private var scrollTarget: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        topBar
                        favoritesCard
                        sportsSections
                        preferencesCard
                            .id("menu_preferences_section")
                        appInfoCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
                .onChange(of: scrollTarget) { _, value in
                    guard let value else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(value, anchor: .top)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen_menu")
        .task {
            viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.cacheMetadata) { _, _ in
            viewModel.refresh(appState: appState)
        }
        .onChange(of: appState.pendingSearchQuery) { _, newValue in
            if newValue != nil {
                showSearchSheet = true
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                SearchView()
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showSavedStories) {
            SavedStoriesSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showDeveloperTools) {
            developerToolsSheet
        }
        .alert("Reset App State", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("menu_reset_cancel")
            Button("Reset", role: .destructive) {
                viewModel.reset(appState: appState)
            }
            .accessibilityIdentifier("menu_reset_confirm_button")
        } message: {
            Text("This clears followed teams, saved stories, recent searches, and stored app data, then restores defaults.")
                .accessibilityIdentifier("menu_reset_confirmation_message")
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
            .accessibilityIdentifier("menu_header_search_button")

            Button {
                appState.selectedTab = .scores
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu_header_scores_button")

            Spacer()

            VStack(spacing: 0) {
                Text("ScoreZone")
                    .font(.system(size: 28, weight: .black))
                    .italic()
                    .foregroundStyle(.white)
                Text("More")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.gray)
            }
            .accessibilityIdentifier("navigation_title_menu")

            Spacer()

            Button {
                appState.selectedTab = .scoreZonePlus
            } label: {
                Image(systemName: "star")
                    .font(.system(size: 22, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu_header_favorites_button")

            Button {
                scrollTarget = "menu_preferences_section"
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu_header_settings_button")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .background(
            Color.black
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(ScoreZoneColors.hairlineOpacity))
                        .frame(height: 0.8)
                }
        )
    }

    private var favoritesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FAVORITES")
                    .font(.title3.weight(.black))
                    .tracking(1)
                Spacer()
                Button("Edit") {
                    appState.selectedTab = .scoreZonePlus
                }
                    .foregroundStyle(ScoreZoneColors.accentRed)
                    .accessibilityIdentifier("menu_open_favorites_edit")
            }
            .foregroundStyle(.white)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [ScoreZoneColors.accentRed.opacity(0.7), ScoreZoneColors.accentRed, ScoreZoneColors.accentRed.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if appState.favoriteTeams.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No saved teams yet.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)

                            Button("Find Teams") {
                                showSearchSheet = true
                            }
                            .buttonStyle(.bordered)
                            .tint(ScoreZoneColors.accentRed)
                            .accessibilityIdentifier("menu_favorites_empty_find_teams")
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(appState.favoriteTeams) { team in
                            VStack(spacing: 6) {
                                NavigationLink(destination: TeamDetailView(team: team)) {
                                    TeamLogoView(team: team, size: 68, cornerRadius: 34)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("team_row_\(AccessibilityID.slug(team.displayName))")

                                Text(team.abbreviation)
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var benchmarkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATA CONTROLS")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("menu_benchmark_controls_header")

            HStack {
                Text("Data Access")
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(DataAccessMode.allCases) { mode in
                        Button(mode.displayName) {
                            appState.setDataAccessMode(mode)
                        }
                    }
                } label: {
                    Label(appState.dataAccessMode.displayName, systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.white.opacity(ScoreZoneColors.pillBackgroundOpacity)))
                }
                .accessibilityIdentifier("menu_data_mode_picker")
            }

            Text(appState.dataAccessMode.benchmarkNote)
                .font(.caption)
                .foregroundStyle(.gray)
                .accessibilityIdentifier("menu_data_mode_note")

            HStack {
                Text("Reference Date")
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    appState.shiftBenchmarkDay(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("menu_benchmark_day_minus")

                Text("\(DateFormatting.shortDate.string(from: appState.benchmarkDate)) (\(signedOffsetText))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 4)
                    .accessibilityIdentifier("menu_benchmark_day_label")

                Button {
                    appState.shiftBenchmarkDay(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(ScoreZoneColors.accentRed)
                .accessibilityIdentifier("menu_benchmark_day_plus")
            }

            HStack(spacing: 8) {
                Button("Live Scores") {
                    appState.setDataAccessMode(.livePreferred)
                    appState.setBenchmarkDayOffset(0)
                    appState.preferredLeagueID = "mlb"
                    appState.selectedTab = .scores
                }
                .accessibilityIdentifier("menu_shortcut_live_scores")

                Button("Cache Replay") {
                    appState.setDataAccessMode(.cacheOnly)
                    appState.selectedTab = .home
                }
                .accessibilityIdentifier("menu_shortcut_cache_replay")

                Button("Offline Data") {
                    appState.setDataAccessMode(.fallbackOnly)
                    appState.setBenchmarkDayOffset(0)
                    appState.preferredLeagueID = "nba"
                    appState.selectedTab = .scores
                }
                .accessibilityIdentifier("menu_shortcut_seeded_fallback")
            }
            .buttonStyle(.bordered)
            .tint(ScoreZoneColors.accentRed)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP INFO")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("menu_app_info_header")

            Button {
                showSavedStories = true
            } label: {
                infoRow(
                    title: "Saved Stories",
                    detail: "\(appState.savedHeadlines.count) bookmarked",
                    icon: "bookmark",
                    showsChevron: true
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu_saved_stories_row")

            Button {
                showSearchSheet = true
            } label: {
                infoRow(
                    title: "Search Sports",
                    detail: "Teams, leagues, and games",
                    icon: "magnifyingglass",
                    showsChevron: true
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("menu_search_sports_row")

            infoRow(
                title: "Version",
                detail: appVersionText,
                icon: "info.circle",
                showsChevron: false
            )
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1.25) {
                showDeveloperTools = true
            }
            .accessibilityIdentifier("menu_app_version_row")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var sportsSections: some View {
        VStack(spacing: 12) {
            sportSection(title: "FAVORITE SPORTS", sports: favoriteSportRows)
            sportSection(title: "ALL SPORTS", sports: allSportRows)
        }
    }

    private func sportSection(title: String, sports: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title3.weight(.black))
                .tracking(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            ForEach(Array(sports.enumerated()), id: \.offset) { index, sport in
                Button {
                    if let league = appState.leagues.first(where: {
                        $0.name.localizedCaseInsensitiveContains(sport) ||
                        $0.shortName.localizedCaseInsensitiveContains(sport)
                    }) {
                        appState.preferredLeagueID = league.id
                        appState.selectedTab = .scores
                    } else {
                        appState.openSearch(with: sport)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.white.opacity(ScoreZoneColors.hairlineOpacity))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: iconForSport(sport))
                                    .foregroundStyle(.white)
                            )

                        Text(sport)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("menu_sport_row_\(AccessibilityID.slug(sport))")

                if index < sports.count - 1 {
                    Divider().background(Color.white.opacity(ScoreZoneColors.dividerOpacity)).padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTIFICATIONS & PREFERENCES")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .accessibilityIdentifier("menu_preferences_section_title")

            Toggle(
                "Push Alerts",
                isOn: Binding(
                    get: { appState.pushAlertsEnabled },
                    set: { appState.setPushAlertsEnabled($0) }
                )
            )
                .toggleStyle(.switch)
                .foregroundStyle(.white)
                .accessibilityIdentifier("menu_toggle_push_alerts")

            Toggle(
                "Breaking News Alerts",
                isOn: Binding(
                    get: { appState.breakingNewsEnabled },
                    set: { appState.setBreakingNewsEnabled($0) }
                )
            )
                .toggleStyle(.switch)
                .foregroundStyle(.white)
                .accessibilityIdentifier("menu_toggle_breaking_news")

            Text("Profile: \(appState.userProfile.displayName) • Market: \(appState.userProfile.homeMarket)")
                .font(.caption)
                .foregroundStyle(.gray)
                .accessibilityIdentifier("menu_profile_summary")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONNECTION STATUS")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)

            HStack {
                Text("Live Connection")
                Spacer()
                Text(APIConfig.shared.enableLiveAPI ? "Enabled" : "Disabled")
                    .foregroundStyle(APIConfig.shared.enableLiveAPI ? .green : .orange)
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("menu_api_status")

            HStack {
                Text("Data Mode")
                Spacer()
                Text(appState.dataAccessMode.displayName)
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("menu_data_mode_status")

            HStack {
                Text("Reference Date")
                Spacer()
                Text(DateFormatting.shortDate.string(from: appState.benchmarkDate))
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("menu_benchmark_day_status")

            HStack {
                Text("Cached Responses")
                Spacer()
                Text("\(viewModel.cacheMetadata.count)")
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.white)
            .accessibilityIdentifier("menu_cache_count")

            if let latest = viewModel.cacheMetadata.first {
                Text("Latest: \(latest.cacheKey) • \(latest.origin.displayName)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("menu_cache_status_row_001")
            } else {
                Text("No cached responses yet")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibilityIdentifier("menu_cache_status_empty")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ScoreZoneColors.cardBackgroundLighter)
        )
    }

    private var resetCard: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack {
                Text("Reset App State")
                    .font(.headline.weight(.bold))
                Spacer()
                Image(systemName: "arrow.counterclockwise")
            }
            .foregroundStyle(Color(red: 0.98, green: 0.42, blue: 0.41))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.16, green: 0.09, blue: 0.10))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("menu_reset_app_state")
    }

    private var developerToolsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    benchmarkCard
                    cacheCard
                    resetCard
                }
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showDeveloperTools = false
                    }
                    .accessibilityIdentifier("menu_developer_tools_done")
                }
            }
            .accessibilityIdentifier("screen_menu_developer_tools")
        }
    }

    private var favoriteSportRows: [String] {
        let leagueSports = appState.favoriteTeams.compactMap { team in
            appState.league(for: team.leagueID)?.name
        }
        let defaultSports = ["NCAA Men's Basketball", "NCAA Football", "NFL", "MLB", "NBA"]
        let merged = leagueSports + defaultSports
        return Array(NSOrderedSet(array: merged)).compactMap { $0 as? String }
    }

    private var allSportRows: [String] {
        appState.leagues.map { $0.shortName }
    }

    private func iconForSport(_ sport: String) -> String {
        let lowered = sport.lowercased()
        if lowered.contains("basket") { return "basketball.fill" }
        if lowered.contains("football") || lowered.contains("nfl") { return "football.fill" }
        if lowered.contains("baseball") || lowered.contains("mlb") { return "baseball.fill" }
        if lowered.contains("hockey") || lowered.contains("nhl") { return "hockey.puck.fill" }
        if lowered.contains("soccer") || lowered.contains("epl") { return "soccerball" }
        if lowered.contains("golf") { return "figure.golf" }
        return "sportscourt.fill"
    }

    private var signedOffsetText: String {
        let value = appState.benchmarkDayOffset
        if value >= 0 {
            return "+\(value)"
        }
        return "\(value)"
    }

    private func infoRow(title: String, detail: String, icon: String, showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 2)
    }

    private var appVersionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(shortVersion) (\(buildNumber))"
    }
}

/// Saved Stories list, presented from the More tab. Previously the "Saved
/// Stories" row routed to the ScoreZone+ (Favorites) tab, which rests at the
/// top showing "Saved Teams" first — so users landed on saved teams, not
/// saved stories. This sheet opens the saved-stories list directly and reuses
/// the existing `favorites_saved_story_*` accessibility identifiers.
private struct SavedStoriesSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHeadline: HeadlineArticle?

    /// Resolve saved stories against loaded headlines, falling back to seed
    /// data so seeded saved IDs (e.g. "headline_001") always render even when
    /// the live feed returns a different headline set.
    private var savedStories: [HeadlineArticle] {
        var byID: [String: HeadlineArticle] = [:]
        for article in SeedData.headlines { byID[article.id] = article }
        for article in appState.loadedHeadlines { byID[article.id] = article }
        return appState.savedHeadlineIDs
            .sorted()
            .compactMap { byID[$0] }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saved Stories")
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("favorites_saved_stories_header")

                        if savedStories.isEmpty {
                            Text("No saved stories yet. Bookmark a headline from Watch to see it here.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .accessibilityIdentifier("menu_saved_stories_empty")
                        } else {
                            ForEach(Array(savedStories.prefix(10).enumerated()), id: \.element.id) { index, article in
                                storyRow(index: index, article: article)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Saved Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .accessibilityIdentifier("screen_saved_stories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("menu_saved_stories_done")
                }
            }
            .task {
                // Ensure loaded headlines exist so live-saved stories resolve.
                if appState.loadedHeadlines.isEmpty {
                    let result = await appState.repository.loadHeadlines(mode: appState.dataAccessMode)
                    appState.loadedHeadlines = result.value
                }
            }
            .sheet(item: $selectedHeadline) { article in
                SavedStoryDetailSheet(article: article)
                    .environmentObject(appState)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func storyRow(index: Int, article: HeadlineArticle) -> some View {
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
        // Keep the per-story Open / Remove buttons individually addressable
        // while still exposing the row's own identifier.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("favorites_saved_story_row_\(String(format: "%03d", index + 1))")
    }
}

/// Headline detail opened from the Saved Stories sheet. Mirrors the Favorites
/// headline detail and reuses the same `favorites_headline_detail_*`
/// identifiers so existing tooling continues to resolve.
private struct SavedStoryDetailSheet: View {
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
