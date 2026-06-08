import Foundation

enum SportsAPIError: LocalizedError {
    case disabled
    case invalidURL
    case badStatus(Int)
    case rateLimited
    case parsingFailed
    case missingData(String)

    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Live API calls are disabled in APIConfig.plist."
        case .invalidURL:
            return "Unable to construct API request URL."
        case .badStatus(let code):
            return "API request failed with HTTP status \(code)."
        case .rateLimited:
            return "API rate limited."
        case .parsingFailed:
            return "Failed to parse API response."
        case .missingData(let detail):
            return "API data missing expected field: \(detail)."
        }
    }
}

final class SportsAPIClient {
    private let config: APIConfig
    private let session: URLSession

    init(config: APIConfig = .shared) {
        self.config = config
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.requestTimeout
        sessionConfig.timeoutIntervalForResource = config.requestTimeout
        self.session = URLSession(configuration: sessionConfig)
    }

    func fetchScoreboard(league: League, date: Date) async throws -> [Game] {
        let json = try await requestJSON(
            path: "\(league.sportSlug)/\(league.leagueSlug)/scoreboard",
            query: [URLQueryItem(name: "dates", value: DateFormatting.apiDate.string(from: date))]
        )
        return parseEvents(from: json, leagueID: league.id)
    }

    func fetchStandings(league: League) async throws -> [StandingEntry] {
        let json = try await requestJSON(path: "\(league.sportSlug)/\(league.leagueSlug)/standings", query: [])
        let entries = parseStandings(from: json, leagueID: league.id)
        if entries.isEmpty {
            throw SportsAPIError.missingData("standings entries")
        }
        return entries
    }

    func fetchTeamSchedule(team: Team) async throws -> [Game] {
        guard let league = SeedData.league(by: team.leagueID) else {
            throw SportsAPIError.missingData("league for team \(team.id)")
        }
        guard let apiTeamID = team.apiTeamID else {
            throw SportsAPIError.missingData("apiTeamID for \(team.id)")
        }

        let json = try await requestJSON(
            path: "\(league.sportSlug)/\(league.leagueSlug)/teams/\(apiTeamID)/schedule",
            query: []
        )

        let games = parseEvents(from: json, leagueID: league.id)
        if games.isEmpty {
            throw SportsAPIError.missingData("team schedule events")
        }
        return games
    }

    func fetchNews(league: League, limit: Int = 20) async throws -> [HeadlineArticle] {
        let json = try await requestJSON(
            path: "\(league.sportSlug)/\(league.leagueSlug)/news",
            query: [URLQueryItem(name: "limit", value: "\(limit)")]
        )
        let articles = parseNews(from: json, leagueID: league.id)
        if articles.isEmpty {
            throw SportsAPIError.missingData("news articles")
        }
        return articles
    }

    func fetchGameSummary(gameID: String, league: League, fallbackGame: Game) async throws -> Game {
        let json = try await requestJSON(
            path: "\(league.sportSlug)/\(league.leagueSlug)/summary",
            query: [URLQueryItem(name: "event", value: gameID)]
        )

        guard let parsed = parseSummaryGame(from: json, fallbackGame: fallbackGame, leagueID: league.id) else {
            throw SportsAPIError.parsingFailed
        }

        return parsed
    }

    private func requestJSON(path: String, query: [URLQueryItem]) async throws -> [String: Any] {
        guard config.enableLiveAPI else {
            throw SportsAPIError.disabled
        }

        let endpoint = config.baseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw SportsAPIError.invalidURL
        }

        var queryItems = query
        if let apiKey = config.apiKey {
            queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SportsAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SportsAPIError.parsingFailed
        }

        if http.statusCode == 429 {
            throw SportsAPIError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SportsAPIError.badStatus(http.statusCode)
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        guard let dictionary = object as? [String: Any] else {
            throw SportsAPIError.parsingFailed
        }

        return dictionary
    }

    private func parseEvents(from json: [String: Any], leagueID: String) -> [Game] {
        guard let events = json["events"] as? [[String: Any]] else {
            return []
        }

        return events.compactMap { parseEvent($0, leagueID: leagueID) }
            .sorted { $0.startDate < $1.startDate }
    }

    private func parseEvent(_ event: [String: Any], leagueID: String) -> Game? {
        guard
            let competition = (event["competitions"] as? [[String: Any]])?.first,
            let competitors = competition["competitors"] as? [[String: Any]],
            let homeCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "home" }),
            let awayCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "away" })
        else {
            return nil
        }

        let id = (event["id"] as? String) ?? UUID().uuidString
        let startDate = ((event["date"] as? String).flatMap(DateFormatting.parseISO)) ?? Date()
        let homeTeam = parseTeam(fromCompetitor: homeCompetitor, leagueID: leagueID)
        let awayTeam = parseTeam(fromCompetitor: awayCompetitor, leagueID: leagueID)

        let statusDictionary = (competition["status"] as? [String: Any]) ?? (event["status"] as? [String: Any]) ?? [:]
        let status = parseStatus(from: statusDictionary, startDate: startDate)

        let venue = ((competition["venue"] as? [String: Any])?["fullName"] as? String)
        let headline = (event["shortName"] as? String) ?? "\(awayTeam.abbreviation) @ \(homeTeam.abbreviation)"

        return Game(
            id: id,
            leagueID: leagueID,
            startDate: startDate,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: parseScore(from: homeCompetitor["score"]),
            awayScore: parseScore(from: awayCompetitor["score"]),
            status: status,
            venue: venue,
            headline: headline,
            homeLeaders: parseLeaders(from: homeCompetitor),
            awayLeaders: parseLeaders(from: awayCompetitor),
            homeTeamStats: parseStatistics(from: homeCompetitor),
            awayTeamStats: parseStatistics(from: awayCompetitor)
        )
    }

    private func parseSummaryGame(from json: [String: Any], fallbackGame: Game, leagueID: String) -> Game? {
        guard
            let header = json["header"] as? [String: Any],
            let competition = (header["competitions"] as? [[String: Any]])?.first,
            let competitors = competition["competitors"] as? [[String: Any]],
            let homeCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "home" }),
            let awayCompetitor = competitors.first(where: { ($0["homeAway"] as? String) == "away" })
        else {
            return nil
        }

        let startDate = ((competition["date"] as? String).flatMap(DateFormatting.parseISO)) ?? fallbackGame.startDate
        let status = parseStatus(from: (competition["status"] as? [String: Any]) ?? [:], startDate: startDate)
        let venue = ((competition["venue"] as? [String: Any])?["fullName"] as? String) ?? fallbackGame.venue

        let home = parseTeam(fromCompetitor: homeCompetitor, leagueID: leagueID)
        let away = parseTeam(fromCompetitor: awayCompetitor, leagueID: leagueID)

        let homeStats = parseBoxscoreStats(from: json, homeAway: "home")
        let awayStats = parseBoxscoreStats(from: json, homeAway: "away")

        let homeScoreVal = parseScore(from: homeCompetitor["score"])
        let awayScoreVal = parseScore(from: awayCompetitor["score"])

        let apiBoxScore = parsePlayerBoxScore(
            from: json,
            competition: competition,
            leagueID: leagueID,
            homeAbbr: home.abbreviation,
            awayAbbr: away.abbreviation,
            homeScore: homeScoreVal,
            awayScore: awayScoreVal
        )
        let apiPlays = parsePlayByPlay(from: json)

        var game = Game(
            id: (header["id"] as? String) ?? fallbackGame.id,
            leagueID: leagueID,
            startDate: startDate,
            homeTeam: home,
            awayTeam: away,
            homeScore: homeScoreVal,
            awayScore: awayScoreVal,
            status: status,
            venue: venue,
            headline: (header["shortName"] as? String) ?? fallbackGame.headline,
            homeLeaders: parseLeaders(from: homeCompetitor).isEmpty ? fallbackGame.homeLeaders : parseLeaders(from: homeCompetitor),
            awayLeaders: parseLeaders(from: awayCompetitor).isEmpty ? fallbackGame.awayLeaders : parseLeaders(from: awayCompetitor),
            homeTeamStats: homeStats.isEmpty ? fallbackGame.homeTeamStats : homeStats,
            awayTeamStats: awayStats.isEmpty ? fallbackGame.awayTeamStats : awayStats
        )
        game.apiBoxScore = apiBoxScore
        game.apiPlays = apiPlays
        return game
    }

    private func parseTeam(fromCompetitor competitor: [String: Any], leagueID: String) -> Team {
        let teamDictionary = competitor["team"] as? [String: Any] ?? [:]
        let displayName = (teamDictionary["displayName"] as? String) ?? "Unknown Team"
        let abbreviation = (teamDictionary["abbreviation"] as? String) ?? "UNK"
        let apiID = teamDictionary["id"] as? String

        if let seeded = SeedData.teams.first(where: {
            $0.leagueID == leagueID && (
                $0.abbreviation.caseInsensitiveCompare(abbreviation) == .orderedSame ||
                $0.name.caseInsensitiveCompare(displayName) == .orderedSame
            )
        }) {
            return seeded
        }

        let location = (teamDictionary["location"] as? String) ?? ""
        let nickname = (teamDictionary["name"] as? String) ?? displayName

        return Team(
            id: "\(leagueID)_api_\(apiID ?? abbreviation.lowercased())",
            name: displayName,
            shortName: (teamDictionary["shortDisplayName"] as? String) ?? displayName,
            abbreviation: abbreviation,
            city: location.isEmpty ? displayName : location,
            nickname: nickname,
            leagueID: leagueID,
            conference: nil,
            division: nil,
            apiTeamID: apiID
        )
    }

    private func parseStatus(from statusDictionary: [String: Any], startDate: Date) -> GameStatus {
        let type = statusDictionary["type"] as? [String: Any] ?? [:]
        let stateToken = ((type["state"] as? String) ?? "pre").lowercased()
        let completed = (type["completed"] as? Bool) ?? false

        let state: GameState
        switch (stateToken, completed) {
        case (_, true), ("post", _):
            state = .final
        case ("in", _):
            state = .live
        case ("postponed", _):
            state = .postponed
        default:
            state = .upcoming
        }

        let shortText =
            (type["shortDetail"] as? String) ??
            (type["shortDescription"] as? String) ??
            (type["description"] as? String) ??
            DateFormatting.gameTime.string(from: startDate)

        let detailText =
            (type["detail"] as? String) ??
            (statusDictionary["displayClock"] as? String) ??
            shortText

        let period: String?
        if let numericPeriod = statusDictionary["period"] as? Int, state == .live {
            let clock = (statusDictionary["displayClock"] as? String) ?? ""
            period = "P\(numericPeriod) \(clock)".trimmingCharacters(in: .whitespaces)
        } else {
            period = nil
        }

        return GameStatus(state: state, shortText: shortText, detailText: detailText, periodDescription: period)
    }

    private func parseScore(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let stringValue = value as? String {
            return Int(stringValue)
        }
        return nil
    }

    private func parseLeaders(from competitor: [String: Any]) -> [String] {
        guard let leaders = competitor["leaders"] as? [[String: Any]] else {
            return []
        }

        return leaders.compactMap { leader in
            let title = (leader["name"] as? String) ?? (leader["displayName"] as? String) ?? "Leader"
            let details = (leader["displayValue"] as? String) ?? ""
            let text = "\(title): \(details)".trimmingCharacters(in: .whitespaces)
            return text.isEmpty ? nil : text
        }
    }

    private func parseStatistics(from competitor: [String: Any]) -> [String] {
        guard let stats = competitor["statistics"] as? [[String: Any]] else {
            return []
        }

        return stats.prefix(6).compactMap { stat in
            let name = (stat["name"] as? String) ?? "Stat"
            let value = (stat["displayValue"] as? String) ?? (stat["value"] as? String) ?? "--"
            return "\(name): \(value)"
        }
    }

    private func parseBoxscoreStats(from json: [String: Any], homeAway: String) -> [String] {
        guard
            let boxscore = json["boxscore"] as? [String: Any],
            let teams = boxscore["teams"] as? [[String: Any]],
            let row = teams.first(where: { ($0["homeAway"] as? String) == homeAway }),
            let statistics = row["statistics"] as? [[String: Any]]
        else {
            return []
        }

        return statistics.prefix(6).compactMap { stat in
            let name = (stat["label"] as? String) ?? (stat["name"] as? String) ?? "Stat"
            let value = (stat["displayValue"] as? String) ?? (stat["value"] as? String) ?? "--"
            return "\(name): \(value)"
        }
    }

    // MARK: - Player Box Score Parsing

    private func parsePlayerBoxScore(
        from json: [String: Any],
        competition: [String: Any],
        leagueID: String,
        homeAbbr: String,
        awayAbbr: String,
        homeScore: Int?,
        awayScore: Int?
    ) -> BoxScoreData? {
        guard let boxscore = json["boxscore"] as? [String: Any],
              let players = boxscore["players"] as? [[String: Any]]
        else { return nil }

        // Parse linescores from header competitors
        let competitors = competition["competitors"] as? [[String: Any]] ?? []
        let homeCompetitor = competitors.first { ($0["homeAway"] as? String) == "home" }
        let awayCompetitor = competitors.first { ($0["homeAway"] as? String) == "away" }

        let homeLinescores = (homeCompetitor?["linescores"] as? [[String: Any]])?.compactMap { entry -> Int? in
            if let val = entry["value"] as? Double { return Int(val) }
            if let val = entry["value"] as? Int { return val }
            return nil
        } ?? []
        let awayLinescores = (awayCompetitor?["linescores"] as? [[String: Any]])?.compactMap { entry -> Int? in
            if let val = entry["value"] as? Double { return Int(val) }
            if let val = entry["value"] as? Int { return val }
            return nil
        } ?? []

        let periodLabels = derivePeriodLabels(count: max(homeLinescores.count, awayLinescores.count), leagueID: leagueID)
        let awayPeriodScores = awayLinescores + [awayScore ?? awayLinescores.reduce(0, +)]
        let homePeriodScores = homeLinescores + [homeScore ?? homeLinescores.reduce(0, +)]

        // Parse player stats per team
        var homeTables: [BoxScoreStatTable] = []
        var awayTables: [BoxScoreStatTable] = []

        for playerGroup in players {
            let teamDict = playerGroup["team"] as? [String: Any] ?? [:]
            let teamAbbr = (teamDict["abbreviation"] as? String) ?? ""
            let homeAway = (playerGroup["homeAway"] as? String) ??
                (teamAbbr.caseInsensitiveCompare(homeAbbr) == .orderedSame ? "home" : "away")

            let statistics = playerGroup["statistics"] as? [[String: Any]] ?? []

            for (groupIndex, statGroup) in statistics.enumerated() {
                let labels = statGroup["labels"] as? [String] ?? statGroup["keys"] as? [String] ?? []
                guard !labels.isEmpty else { continue }

                let groupName = (statGroup["name"] as? String) ?? (statGroup["type"] as? String) ?? ""
                let athletes = statGroup["athletes"] as? [[String: Any]] ?? []
                let totals = statGroup["totals"] as? [String]

                var playerLines: [PlayerBoxLine] = []
                for (athleteIndex, athleteEntry) in athletes.enumerated() {
                    let athleteDict = athleteEntry["athlete"] as? [String: Any] ?? [:]
                    let displayName = (athleteDict["displayName"] as? String) ?? "Unknown"
                    let jersey = (athleteDict["jersey"] as? String) ?? ""
                    let posDict = athleteDict["position"] as? [String: Any] ?? [:]
                    let position = (posDict["abbreviation"] as? String) ?? ""
                    let isStarter = (athleteEntry["starter"] as? Bool) ?? (groupName.lowercased().contains("starter"))
                    let stats = athleteEntry["stats"] as? [String] ?? []
                    let didNotPlay = (athleteEntry["didNotPlay"] as? Bool) ?? false

                    if didNotPlay { continue }

                    playerLines.append(PlayerBoxLine(
                        id: "api_\(homeAway)_\(groupIndex)_\(athleteIndex)",
                        name: displayName,
                        jersey: jersey,
                        position: position,
                        isStarter: isStarter,
                        statValues: stats
                    ))
                }

                guard !playerLines.isEmpty else { continue }

                let tableTitle = groupName.uppercased().replacingOccurrences(of: "STARTERS", with: "").replacingOccurrences(of: "BENCH", with: "").trimmingCharacters(in: .whitespaces)

                let table = BoxScoreStatTable(
                    id: "api_\(homeAway)_\(groupIndex)",
                    title: tableTitle,
                    statColumns: labels,
                    players: playerLines,
                    totals: totals
                )

                if homeAway == "home" {
                    homeTables.append(table)
                } else {
                    awayTables.append(table)
                }
            }
        }

        // If we got no tables, some sports merge starters+bench into one group.
        // Try to split them by the starter flag.
        if homeTables.count == 1, let table = homeTables.first {
            let starters = table.players.filter(\.isStarter)
            let bench = table.players.filter { !$0.isStarter }
            if !starters.isEmpty && !bench.isEmpty {
                homeTables = [BoxScoreStatTable(
                    id: table.id,
                    title: table.title,
                    statColumns: table.statColumns,
                    players: starters + bench,
                    totals: table.totals
                )]
            }
        }
        if awayTables.count == 1, let table = awayTables.first {
            let starters = table.players.filter(\.isStarter)
            let bench = table.players.filter { !$0.isStarter }
            if !starters.isEmpty && !bench.isEmpty {
                awayTables = [BoxScoreStatTable(
                    id: table.id,
                    title: table.title,
                    statColumns: table.statColumns,
                    players: starters + bench,
                    totals: table.totals
                )]
            }
        }

        guard !homeTables.isEmpty || !awayTables.isEmpty else { return nil }

        return BoxScoreData(
            periodLabels: periodLabels,
            awayPeriodScores: awayPeriodScores,
            homePeriodScores: homePeriodScores,
            awayTables: awayTables,
            homeTables: homeTables
        )
    }

    private func derivePeriodLabels(count: Int, leagueID: String) -> [String] {
        guard count > 0 else { return ["T"] }

        switch leagueID {
        case "mlb":
            let innings = (1...count).map { "\($0)" }
            return innings + ["R", "H", "E"]
        case "epl":
            return ["1H", "2H", "T"]
        case "nhl":
            if count <= 3 {
                return (1...count).map { "\($0)" } + ["T"]
            }
            return (1...3).map { "\($0)" } + ["OT", "T"]
        default:
            return (1...count).map { "\($0)" } + ["T"]
        }
    }

    // MARK: - Play-by-Play Parsing

    private func parsePlayByPlay(from json: [String: Any]) -> [PlayByPlayEvent]? {
        guard let plays = json["plays"] as? [[String: Any]], !plays.isEmpty else {
            return nil
        }

        let events: [PlayByPlayEvent] = plays.compactMap { play in
            let text = (play["text"] as? String) ?? ""
            guard !text.isEmpty else { return nil }

            let playID = (play["id"] as? String)
                ?? (play["id"] as? Int).map(String.init)
                ?? UUID().uuidString

            let clockDict = play["clock"] as? [String: Any] ?? [:]
            let clock = (clockDict["displayValue"] as? String) ?? ""

            let periodDict = play["period"] as? [String: Any] ?? [:]
            let period = (periodDict["displayValue"] as? String)
                ?? (periodDict["number"] as? Int).map { "Period \($0)" }
                ?? ""

            let isScoringPlay = (play["scoringPlay"] as? Bool) ?? false
            let awayScore = play["awayScore"] as? Int
            let homeScore = play["homeScore"] as? Int

            return PlayByPlayEvent(
                id: playID,
                clock: clock,
                period: period,
                text: text,
                isScoringPlay: isScoringPlay,
                awayScore: awayScore,
                homeScore: homeScore
            )
        }

        return events.isEmpty ? nil : events
    }

    private func parseStandings(from json: [String: Any], leagueID: String) -> [StandingEntry] {
        let harvested = harvestStandingEntries(from: json, conferenceHint: nil)

        var seen = Set<String>()
        let results: [StandingEntry] = harvested.compactMap { tuple in
            let entry = tuple.entry
            let conference = tuple.conference

            let teamDictionary = entry["team"] as? [String: Any] ?? [:]
            let apiTeamID = teamDictionary["id"] as? String
            let abbreviation = (teamDictionary["abbreviation"] as? String) ?? ""

            guard let team = resolveTeam(leagueID: leagueID, apiTeamID: apiTeamID, abbreviation: abbreviation, teamDictionary: teamDictionary) else {
                return nil
            }

            let stats = entry["stats"] as? [[String: Any]] ?? entry["statistics"] as? [[String: Any]] ?? []
            let rank = intStat(named: ["rank", "playoffSeed"], in: stats) ?? ((entry["rank"] as? Int) ?? 0)
            let wins = intStat(named: ["wins", "W"], in: stats) ?? 0
            let losses = intStat(named: ["losses", "L"], in: stats) ?? 0
            let draws = intStat(named: ["ties", "draws", "D"], in: stats) ?? 0
            let gamesBack = doubleStat(named: ["gamesBack", "GB"], in: stats)

            let key = "\(leagueID)_\(team.id)_\(conference)_\(rank)"
            guard !seen.contains(key) else { return nil }
            seen.insert(key)

            return StandingEntry(
                id: "api_\(key)",
                leagueID: leagueID,
                conference: conference,
                division: team.division,
                rank: max(rank, 1),
                team: team,
                wins: wins,
                losses: losses,
                draws: draws,
                gamesBack: gamesBack
            )
        }

        return results.sorted {
            if $0.conference != $1.conference {
                return $0.conference < $1.conference
            }
            return $0.rank < $1.rank
        }
    }

    private func harvestStandingEntries(from node: Any, conferenceHint: String?) -> [(entry: [String: Any], conference: String)] {
        var results: [(entry: [String: Any], conference: String)] = []

        if let dictionary = node as? [String: Any] {
            let derivedConference =
                (dictionary["name"] as? String) ??
                (dictionary["header"] as? String) ??
                conferenceHint ??
                "Overall"

            if
                let standings = dictionary["standings"] as? [String: Any],
                let entries = standings["entries"] as? [[String: Any]]
            {
                results.append(contentsOf: entries.map { ($0, derivedConference) })
            }

            if let entries = dictionary["entries"] as? [[String: Any]], entries.first?["team"] != nil {
                results.append(contentsOf: entries.map { ($0, derivedConference) })
            }

            for value in dictionary.values {
                results.append(contentsOf: harvestStandingEntries(from: value, conferenceHint: derivedConference))
            }
        } else if let array = node as? [Any] {
            for item in array {
                results.append(contentsOf: harvestStandingEntries(from: item, conferenceHint: conferenceHint))
            }
        }

        return results
    }

    private func resolveTeam(leagueID: String, apiTeamID: String?, abbreviation: String, teamDictionary: [String: Any]) -> Team? {
        if let apiTeamID,
           let seededByApiID = SeedData.teams.first(where: { $0.leagueID == leagueID && $0.apiTeamID == apiTeamID }) {
            return seededByApiID
        }

        if let seededByAbbreviation = SeedData.teams.first(where: {
            $0.leagueID == leagueID && $0.abbreviation.caseInsensitiveCompare(abbreviation) == .orderedSame
        }) {
            return seededByAbbreviation
        }

        let displayName = (teamDictionary["displayName"] as? String) ?? "Unknown"
        let nickname = (teamDictionary["name"] as? String) ?? displayName
        let city = (teamDictionary["location"] as? String) ?? ""

        return Team(
            id: "\(leagueID)_standings_\(apiTeamID ?? abbreviation.lowercased())",
            name: displayName,
            shortName: (teamDictionary["shortDisplayName"] as? String) ?? displayName,
            abbreviation: abbreviation.isEmpty ? "UNK" : abbreviation,
            city: city.isEmpty ? displayName : city,
            nickname: nickname,
            leagueID: leagueID,
            conference: nil,
            division: nil,
            apiTeamID: apiTeamID
        )
    }

    private func intStat(named names: [String], in stats: [[String: Any]]) -> Int? {
        for stat in stats {
            let key = ((stat["name"] as? String) ?? (stat["abbreviation"] as? String) ?? "").lowercased()
            if names.contains(where: { $0.lowercased() == key }) {
                if let value = stat["value"] as? Int {
                    return value
                }
                if let doubleValue = stat["value"] as? Double {
                    return Int(doubleValue)
                }
                if let stringValue = stat["displayValue"] as? String ?? stat["value"] as? String {
                    return Int(stringValue.replacingOccurrences(of: ",", with: ""))
                }
            }
        }
        return nil
    }

    private func doubleStat(named names: [String], in stats: [[String: Any]]) -> Double? {
        for stat in stats {
            let key = ((stat["name"] as? String) ?? (stat["abbreviation"] as? String) ?? "").lowercased()
            if names.contains(where: { $0.lowercased() == key }) {
                if let value = stat["value"] as? Double {
                    return value
                }
                if let intValue = stat["value"] as? Int {
                    return Double(intValue)
                }
                if let stringValue = stat["displayValue"] as? String ?? stat["value"] as? String {
                    return Double(stringValue)
                }
            }
        }
        return nil
    }

    // MARK: - News Parsing

    private func parseNews(from json: [String: Any], leagueID: String) -> [HeadlineArticle] {
        guard let articles = json["articles"] as? [[String: Any]] else {
            return []
        }

        return articles.compactMap { article -> HeadlineArticle? in
            let headline = (article["headline"] as? String) ?? ""
            guard !headline.isEmpty else { return nil }

            let description = (article["description"] as? String) ?? ""
            let published = (article["published"] as? String).flatMap(DateFormatting.parseISO) ?? Date()

            // Extract image URL from images array
            let images = article["images"] as? [[String: Any]] ?? []
            let imageURL = images.first.flatMap { $0["url"] as? String }

            // Determine section tag from categories or type
            let categories = article["categories"] as? [[String: Any]] ?? []
            let sectionTag = categories.first.flatMap { $0["description"] as? String }
                ?? (article["type"] as? String)
                ?? leagueID.uppercased()

            let articleID = (article["id"] as? Int).map { "api_news_\($0)" }
                ?? "api_news_\(abs(headline.hashValue))"

            return HeadlineArticle(
                id: articleID,
                headline: headline,
                summary: description,
                imageURL: imageURL,
                publishedAt: published,
                leagueID: leagueID,
                sectionTag: sectionTag
            )
        }
    }
}
