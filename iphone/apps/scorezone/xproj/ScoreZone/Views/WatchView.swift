import SwiftUI

struct WatchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSearchSheet = false
    @State private var selectedHeadline: HeadlineArticle?

    private var liveGames: [Game] {
        appState.loadedGames
            .filter { $0.status.isLive }
            .sorted { $0.startDate < $1.startDate }
    }

    private var replayGames: [Game] {
        appState.loadedGames
            .filter { $0.status.isFinal }
            .sorted { $0.startDate > $1.startDate }
            .prefix(8)
            .map { $0 }
    }

    private var upcomingGames: [Game] {
        appState.loadedGames
            .filter { $0.status.isUpcoming }
            .sorted { $0.startDate < $1.startDate }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Watch")
                        .font(.caption)
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("navigation_title_watch")

                    if !liveGames.isEmpty {
                        liveNowSection
                    }

                    if !appState.loadedHeadlines.isEmpty {
                        featuredContentSection
                    }

                    if !upcomingGames.isEmpty {
                        upcomingSection
                    }

                    if !replayGames.isEmpty {
                        replaySection
                    }

                    browseBySportSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("screen_watch")
        .safeAreaInset(edge: .top) {
            watchTopBar
        }
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                SearchView()
                    .environmentObject(appState)
            }
        }
        .sheet(item: $selectedHeadline) { article in
            WatchHeadlineDetailSheet(article: article)
                .environmentObject(appState)
        }
    }

    private var watchTopBar: some View {
        HStack(spacing: 18) {
            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("watch_header_search_button")

            Spacer()

            Text("ScoreZone")
                .font(.system(size: 34, weight: .black))
                .italic()

            Spacer()

            Button {
                appState.selectedTab = .scoreZonePlus
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 24, weight: .regular))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("watch_header_profile_button")
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

    private var liveNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(ScoreZoneColors.liveRed)
                    .frame(width: 8, height: 8)
                Text("LIVE NOW")
                    .font(.title3.weight(.black))
                    .tracking(1)
                    .foregroundStyle(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(liveGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            watchGameCard(game: game, isLive: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(game.accessibilityRowID)
                    }
                }
            }
        }
    }

    private var featuredContentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FEATURED")
                .font(.title3.weight(.black))
                .tracking(1)
                .foregroundStyle(.white)

            ForEach(Array(appState.loadedHeadlines.prefix(3).enumerated()), id: \.element.id) { index, article in
                Button {
                    selectedHeadline = article
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        HeadlineThumbnailView(article: article, height: 180)

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.85)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                Text("ScoreZone+")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(ScoreZoneColors.accentRed)

                            Text(article.headline)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        .padding(14)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("watch_featured_headline_\(String(format: "%03d", index + 1))")
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UPCOMING")
                .font(.title3.weight(.black))
                .tracking(1)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upcomingGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            watchGameCard(game: game, isLive: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(game.accessibilityRowID)
                    }
                }
            }
        }
    }

    private var replaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REPLAYS")
                .font(.title3.weight(.black))
                .tracking(1)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(replayGames) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            watchGameCard(game: game, isLive: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(game.accessibilityRowID)
                    }
                }
            }
        }
    }

    private var browseBySportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BROWSE BY SPORT")
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
                            VStack(spacing: 8) {
                                Image(systemName: league.iconSystemName)
                                    .font(.title2)
                                    .frame(width: 52, height: 52)
                                    .background(
                                        Circle()
                                            .fill(ScoreZoneColors.cardBackgroundElevated)
                                    )
                                Text(league.shortName)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(width: 80)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("watch_league_shortcut_\(league.accessibilitySlug)")
                    }
                }
            }
        }
    }

    private func watchGameCard(game: Game, isLive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [ScoreZoneColors.cardBackgroundElevated, ScoreZoneColors.cardBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 90)
                    .overlay {
                        HStack(spacing: 16) {
                            TeamLogoView(team: game.awayTeam, size: 36, cornerRadius: 8)
                            Text("vs")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.gray)
                            TeamLogoView(team: game.homeTeam, size: 36, cornerRadius: 8)
                        }
                    }

                if isLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ScoreZoneColors.liveRed)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ScoreZoneColors.liveRed.opacity(0.9)))
                    .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(game.matchupTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(game.leagueID.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: 160)
    }
}

private struct WatchHeadlineDetailSheet: View {
    let article: HeadlineArticle

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HeadlineThumbnailView(article: article, height: 210)
                        .accessibilityIdentifier("watch_headline_detail_image")

                    Text(article.sectionTag.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watch_headline_detail_section")

                    Text(article.headline)
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("watch_headline_detail_title")

                    Text(article.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watch_headline_detail_summary")

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
                        .accessibilityIdentifier("watch_headline_detail_save_button")

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
                            .accessibilityIdentifier("watch_headline_detail_open_league_button")
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Story")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("screen_watch_headline_detail")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("watch_headline_detail_done_button")
                }
            }
        }
    }
}
