import Foundation

final class SportsRepository {
    private let apiClient: SportsAPIClient
    private let cacheStore: CacheStore

    init(apiClient: SportsAPIClient = SportsAPIClient(), cacheStore: CacheStore = CacheStore()) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
    }

    func loadScoreboard(league: League, date: Date, mode: DataAccessMode = .automatic) async -> FetchResult<[Game]> {
        let cacheKey = "scores_\(league.id)_\(DateFormatting.apiDate.string(from: date))"
        let fallbackGames = SeedData.fallbackGames(for: league.id, on: date)

        if mode == .fallbackOnly {
            return FetchResult(
                value: fallbackGames,
                metadata: fallbackMetadata(for: cacheKey, note: "Forced fallback scoreboard"),
                origin: .fallback,
                warningMessage: "Offline mode active — using fallback data."
            )
        }

        if mode == .cacheOnly {
            if let cached: (value: [Game], metadata: CachedResponseMetadata) = cacheStore.load([Game].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cache-only scoreboard")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: "Cache-only mode active."
                )
            }

            return FetchResult(
                value: fallbackGames,
                metadata: fallbackMetadata(for: cacheKey, note: "Cache-only fallback scoreboard"),
                origin: .fallback,
                warningMessage: "Cache unavailable — showing offline data."
            )
        }

        do {
            let liveGames = try await apiClient.fetchScoreboard(league: league, date: date)
            if !liveGames.isEmpty {
                let metadata = cacheStore.save(liveGames, key: cacheKey, origin: .live, note: "Live scoreboard")

                // If the league is off-season, the API may return games from a different date.
                // Detect this and pass the actual game date back so the UI updates.
                var adjusted: Date? = nil
                if !SeedData.isInSeason(leagueID: league.id, on: date),
                   let gameDate = liveGames.first?.startDate,
                   !Calendar.current.isDate(gameDate, inSameDayAs: date) {
                    adjusted = gameDate
                }

                return FetchResult(value: liveGames, metadata: metadata, origin: .live, warningMessage: nil, adjustedDate: adjusted)
            }

            // No games for this date – if off-season, fetch real recent games from the API
            if !SeedData.isInSeason(leagueID: league.id, on: date) {
                if let recent = await findRecentGames(league: league, from: date) {
                    let recentCacheKey = "scores_\(league.id)_\(DateFormatting.apiDate.string(from: recent.date))"
                    let note = "Off-season: showing last completed games"
                    let metadata = cacheStore.save(recent.games, key: recentCacheKey, origin: .live, note: note)
                    return FetchResult(
                        value: recent.games,
                        metadata: metadata,
                        origin: .live,
                        warningMessage: note,
                        adjustedDate: recent.date
                    )
                }

                // API unreachable – fall back to seed data
                let lastGames = SeedData.fallbackGames(for: league.id, on: date)
                let note = "Off-season: showing cached results"
                return FetchResult(
                    value: lastGames,
                    metadata: fallbackMetadata(for: cacheKey, note: note),
                    origin: .fallback,
                    warningMessage: note
                )
            }

            throw SportsAPIError.missingData("scoreboard events")
        } catch {
            if let cached: (value: [Game], metadata: CachedResponseMetadata) = cacheStore.load([Game].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cached scoreboard")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: mode == .livePreferred
                        ? "Live request failed; showing cached data. \(error.localizedDescription)"
                        : error.localizedDescription
                )
            }

            return FetchResult(
                value: fallbackGames,
                metadata: fallbackMetadata(for: cacheKey, note: "Offline fallback scoreboard"),
                origin: .fallback,
                warningMessage: mode == .livePreferred
                    ? "Could not load live data. \(error.localizedDescription)"
                    : error.localizedDescription
            )
        }
    }

    func loadStandings(league: League, mode: DataAccessMode = .automatic) async -> FetchResult<[StandingEntry]> {
        let cacheKey = "standings_\(league.id)"
        let fallback = SeedData.fallbackStandings(for: league.id)

        if mode == .fallbackOnly {
            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Forced fallback standings"),
                origin: .fallback,
                warningMessage: "Offline mode active — using fallback data."
            )
        }

        if mode == .cacheOnly {
            if let cached: (value: [StandingEntry], metadata: CachedResponseMetadata) = cacheStore.load([StandingEntry].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cache-only standings")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: "Cache-only mode active."
                )
            }

            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Cache-only fallback standings"),
                origin: .fallback,
                warningMessage: "Cache unavailable — showing offline data."
            )
        }

        do {
            let liveStandings = try await apiClient.fetchStandings(league: league)
            if !liveStandings.isEmpty {
                let metadata = cacheStore.save(liveStandings, key: cacheKey, origin: .live, note: "Live standings")
                return FetchResult(value: liveStandings, metadata: metadata, origin: .live, warningMessage: nil)
            }
            throw SportsAPIError.missingData("standings")
        } catch {
            if let cached: (value: [StandingEntry], metadata: CachedResponseMetadata) = cacheStore.load([StandingEntry].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cached standings")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: mode == .livePreferred
                        ? "Live request failed; showing cached data. \(error.localizedDescription)"
                        : error.localizedDescription
                )
            }

            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Offline fallback standings"),
                origin: .fallback,
                warningMessage: mode == .livePreferred
                    ? "Could not load live data. \(error.localizedDescription)"
                    : error.localizedDescription
            )
        }
    }

    func loadTeamSchedule(for team: Team, mode: DataAccessMode = .automatic) async -> FetchResult<[Game]> {
        let cacheKey = "schedule_\(team.id)"
        let fallback = SeedData.fallbackSchedule(for: team.id)

        if mode == .fallbackOnly {
            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Forced fallback team schedule"),
                origin: .fallback,
                warningMessage: "Offline mode active — using fallback data."
            )
        }

        if mode == .cacheOnly {
            if let cached: (value: [Game], metadata: CachedResponseMetadata) = cacheStore.load([Game].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cache-only team schedule")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: "Cache-only mode active."
                )
            }

            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Cache-only fallback team schedule"),
                origin: .fallback,
                warningMessage: "Cache unavailable — showing offline data."
            )
        }

        do {
            let live = try await apiClient.fetchTeamSchedule(team: team)
            if !live.isEmpty {
                let metadata = cacheStore.save(live, key: cacheKey, origin: .live, note: "Live team schedule")
                return FetchResult(value: live, metadata: metadata, origin: .live, warningMessage: nil)
            }
            throw SportsAPIError.missingData("team schedule")
        } catch {
            if let cached: (value: [Game], metadata: CachedResponseMetadata) = cacheStore.load([Game].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cached team schedule")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: mode == .livePreferred
                        ? "Live request failed; showing cached data. \(error.localizedDescription)"
                        : error.localizedDescription
                )
            }

            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Offline fallback team schedule"),
                origin: .fallback,
                warningMessage: mode == .livePreferred
                    ? "Could not load live data. \(error.localizedDescription)"
                    : error.localizedDescription
            )
        }
    }

    func loadGameDetail(for game: Game, mode: DataAccessMode = .automatic) async -> FetchResult<Game> {
        let cacheKey = "game_detail_\(game.id)"

        if mode == .fallbackOnly {
            return FetchResult(
                value: game,
                metadata: fallbackMetadata(for: cacheKey, note: "Forced fallback game detail"),
                origin: .fallback,
                warningMessage: "Offline mode active — using fallback data."
            )
        }

        if mode == .cacheOnly {
            if let cached: (value: Game, metadata: CachedResponseMetadata) = cacheStore.load(Game.self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cache-only game summary")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: "Cache-only mode active."
                )
            }

            return FetchResult(
                value: game,
                metadata: fallbackMetadata(for: cacheKey, note: "Cache-only fallback game detail"),
                origin: .fallback,
                warningMessage: "Cache unavailable — showing offline data."
            )
        }

        guard let league = SeedData.league(by: game.leagueID) else {
            return FetchResult(
                value: game,
                metadata: fallbackMetadata(for: cacheKey, note: "Fallback game detail"),
                origin: .fallback,
                warningMessage: "Unknown league ID \(game.leagueID)."
            )
        }

        do {
            let live = try await apiClient.fetchGameSummary(gameID: game.id, league: league, fallbackGame: game)
            let metadata = cacheStore.save(live, key: cacheKey, origin: .live, note: "Live game summary")
            return FetchResult(value: live, metadata: metadata, origin: .live, warningMessage: nil)
        } catch {
            if let cached: (value: Game, metadata: CachedResponseMetadata) = cacheStore.load(Game.self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cached game summary")
                return FetchResult(
                    value: cached.value,
                    metadata: metadata,
                    origin: .cached,
                    warningMessage: mode == .livePreferred
                        ? "Live request failed; showing cached data. \(error.localizedDescription)"
                        : error.localizedDescription
                )
            }

            return FetchResult(
                value: game,
                metadata: fallbackMetadata(for: cacheKey, note: "Offline fallback game detail"),
                origin: .fallback,
                warningMessage: mode == .livePreferred
                    ? "Could not load live data. \(error.localizedDescription)"
                    : error.localizedDescription
            )
        }
    }

    func loadHeadlines(mode: DataAccessMode = .automatic) async -> FetchResult<[HeadlineArticle]> {
        let cacheKey = "headlines_all"
        let fallback = SeedData.headlines

        if mode == .fallbackOnly {
            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Forced fallback headlines"),
                origin: .fallback,
                warningMessage: "Offline mode active — using fallback data."
            )
        }

        if mode == .cacheOnly {
            if let cached: (value: [HeadlineArticle], metadata: CachedResponseMetadata) = cacheStore.load([HeadlineArticle].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cache-only headlines")
                return FetchResult(value: cached.value, metadata: metadata, origin: .cached, warningMessage: "Cache-only mode active.")
            }
            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Cache-only fallback headlines"),
                origin: .fallback,
                warningMessage: "Cache unavailable — showing offline data."
            )
        }

        do {
            var allArticles: [HeadlineArticle] = []
            for league in SeedData.leagues {
                if let articles = try? await apiClient.fetchNews(league: league, limit: 5) {
                    allArticles.append(contentsOf: articles)
                }
            }
            guard !allArticles.isEmpty else {
                throw SportsAPIError.missingData("news articles")
            }
            let sorted = allArticles.sorted { $0.publishedAt > $1.publishedAt }
            let limited = Array(sorted.prefix(25))
            let metadata = cacheStore.save(limited, key: cacheKey, origin: .live, note: "Live headlines")
            return FetchResult(value: limited, metadata: metadata, origin: .live, warningMessage: nil)
        } catch {
            if let cached: (value: [HeadlineArticle], metadata: CachedResponseMetadata) = cacheStore.load([HeadlineArticle].self, key: cacheKey) {
                let metadata = cachedMetadata(from: cached.metadata, for: cacheKey, note: "Cached headlines")
                return FetchResult(value: cached.value, metadata: metadata, origin: .cached, warningMessage: error.localizedDescription)
            }
            return FetchResult(
                value: fallback,
                metadata: fallbackMetadata(for: cacheKey, note: "Offline fallback headlines"),
                origin: .fallback,
                warningMessage: error.localizedDescription
            )
        }
    }

    func cachedResponseMetadata() -> [CachedResponseMetadata] {
        cacheStore.latestMetadata()
    }

    func clearCachedResponses() {
        cacheStore.clearAll()
    }

    /// Searches backward from `startDate` to find the most recent date with real games from the sports API.
    /// First walks backward using date math to find the last in-season date, then queries the API
    /// day-by-day from there. Results are cached to avoid repeated searches.
    private func findRecentGames(league: League, from startDate: Date) async -> (games: [Game], date: Date)? {
        let cacheKey = "offseason_recent_\(league.id)"

        // Return cached result if available
        if let cached: (value: [Game], metadata: CachedResponseMetadata) = cacheStore.load([Game].self, key: cacheKey),
           !cached.value.isEmpty,
           let foundDate = cached.value.first?.startDate {
            return (cached.value, foundDate)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Step 1: Find the last in-season date by walking backward (pure date math, no API calls)
        var searchStart = startDate
        for _ in 0..<250 {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: searchStart) else { return nil }
            searchStart = previous
            if SeedData.isInSeason(leagueID: league.id, on: searchStart) {
                break
            }
        }

        // If we never found an in-season date, give up
        guard SeedData.isInSeason(leagueID: league.id, on: searchStart) else { return nil }

        // Step 2: From the last in-season date, search the API day-by-day going backward
        var checkDate = searchStart
        for _ in 0..<30 {
            do {
                let games = try await apiClient.fetchScoreboard(league: league, date: checkDate)
                if !games.isEmpty {
                    cacheStore.save(games, key: cacheKey, origin: .live, note: "Off-season recent \(league.id) games")
                    return (games, checkDate)
                }
            } catch {
                // API error on this date — keep searching
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }

        return nil
    }

    private func fallbackMetadata(for cacheKey: String, note: String) -> CachedResponseMetadata {
        CachedResponseMetadata(
            id: UUID().uuidString,
            cacheKey: cacheKey,
            fetchedAt: Date(),
            expiresAt: nil,
            origin: .fallback,
            note: note
        )
    }

    private func cachedMetadata(from previous: CachedResponseMetadata, for cacheKey: String, note: String) -> CachedResponseMetadata {
        CachedResponseMetadata(
            id: UUID().uuidString,
            cacheKey: cacheKey,
            fetchedAt: previous.fetchedAt,
            expiresAt: previous.expiresAt,
            origin: .cached,
            note: note
        )
    }
}
