import Foundation

enum SeedData {
    static let leagues: [League] = [
        League(id: "nba", name: "National Basketball Association", shortName: "NBA", sportSlug: "basketball", leagueSlug: "nba", iconSystemName: "basketball.fill"),
        League(id: "nfl", name: "National Football League", shortName: "NFL", sportSlug: "football", leagueSlug: "nfl", iconSystemName: "football.fill"),
        League(id: "mlb", name: "Major League Baseball", shortName: "MLB", sportSlug: "baseball", leagueSlug: "mlb", iconSystemName: "baseball.fill"),
        League(id: "nhl", name: "National Hockey League", shortName: "NHL", sportSlug: "hockey", leagueSlug: "nhl", iconSystemName: "hockey.puck.fill"),
        League(id: "ncaafb", name: "NCAA Football", shortName: "NCAAF", sportSlug: "football", leagueSlug: "college-football", iconSystemName: "football.fill"),
        League(id: "ncaamb", name: "NCAA Men's Basketball", shortName: "NCAAM", sportSlug: "basketball", leagueSlug: "mens-college-basketball", iconSystemName: "figure.basketball"),
        League(id: "epl", name: "Premier League", shortName: "EPL", sportSlug: "soccer", leagueSlug: "eng.1", iconSystemName: "soccerball"
        )
    ]

    static let teams: [Team] = [
        Team(id: "nba_lal", name: "Los Angeles Lakers", shortName: "Lakers", abbreviation: "LAL", city: "Los Angeles", nickname: "Lakers", leagueID: "nba", conference: "West", division: "Pacific", apiTeamID: "13"),
        Team(id: "nba_gsw", name: "Golden State Warriors", shortName: "Warriors", abbreviation: "GSW", city: "Golden State", nickname: "Warriors", leagueID: "nba", conference: "West", division: "Pacific", apiTeamID: "9"),
        Team(id: "nba_bos", name: "Boston Celtics", shortName: "Celtics", abbreviation: "BOS", city: "Boston", nickname: "Celtics", leagueID: "nba", conference: "East", division: "Atlantic", apiTeamID: "2"),
        Team(id: "nba_nyk", name: "New York Knicks", shortName: "Knicks", abbreviation: "NYK", city: "New York", nickname: "Knicks", leagueID: "nba", conference: "East", division: "Atlantic", apiTeamID: "18"),
        Team(id: "nba_mil", name: "Milwaukee Bucks", shortName: "Bucks", abbreviation: "MIL", city: "Milwaukee", nickname: "Bucks", leagueID: "nba", conference: "East", division: "Central", apiTeamID: "15"),
        Team(id: "nba_cle", name: "Cleveland Cavaliers", shortName: "Cavaliers", abbreviation: "CLE", city: "Cleveland", nickname: "Cavaliers", leagueID: "nba", conference: "East", division: "Central", apiTeamID: "5"),
        Team(id: "nba_mia", name: "Miami Heat", shortName: "Heat", abbreviation: "MIA", city: "Miami", nickname: "Heat", leagueID: "nba", conference: "East", division: "Southeast", apiTeamID: "14"),
        Team(id: "nba_den", name: "Denver Nuggets", shortName: "Nuggets", abbreviation: "DEN", city: "Denver", nickname: "Nuggets", leagueID: "nba", conference: "West", division: "Northwest", apiTeamID: "7"),
        Team(id: "nba_phx", name: "Phoenix Suns", shortName: "Suns", abbreviation: "PHX", city: "Phoenix", nickname: "Suns", leagueID: "nba", conference: "West", division: "Pacific", apiTeamID: "21"),
        Team(id: "nba_dal", name: "Dallas Mavericks", shortName: "Mavericks", abbreviation: "DAL", city: "Dallas", nickname: "Mavericks", leagueID: "nba", conference: "West", division: "Southwest", apiTeamID: "6"),

        Team(id: "nfl_kc", name: "Kansas City Chiefs", shortName: "Chiefs", abbreviation: "KC", city: "Kansas City", nickname: "Chiefs", leagueID: "nfl", conference: "AFC", division: "West", apiTeamID: "12"),
        Team(id: "nfl_buf", name: "Buffalo Bills", shortName: "Bills", abbreviation: "BUF", city: "Buffalo", nickname: "Bills", leagueID: "nfl", conference: "AFC", division: "East", apiTeamID: "2"),
        Team(id: "nfl_phi", name: "Philadelphia Eagles", shortName: "Eagles", abbreviation: "PHI", city: "Philadelphia", nickname: "Eagles", leagueID: "nfl", conference: "NFC", division: "East", apiTeamID: "21"),
        Team(id: "nfl_dal", name: "Dallas Cowboys", shortName: "Cowboys", abbreviation: "DAL", city: "Dallas", nickname: "Cowboys", leagueID: "nfl", conference: "NFC", division: "East", apiTeamID: "6"),
        Team(id: "nfl_sf", name: "San Francisco 49ers", shortName: "49ers", abbreviation: "SF", city: "San Francisco", nickname: "49ers", leagueID: "nfl", conference: "NFC", division: "West", apiTeamID: "25"),
        Team(id: "nfl_bal", name: "Baltimore Ravens", shortName: "Ravens", abbreviation: "BAL", city: "Baltimore", nickname: "Ravens", leagueID: "nfl", conference: "AFC", division: "North", apiTeamID: "33"),

        Team(id: "mlb_nyy", name: "New York Yankees", shortName: "Yankees", abbreviation: "NYY", city: "New York", nickname: "Yankees", leagueID: "mlb", conference: "AL", division: "East", apiTeamID: "10"),
        Team(id: "mlb_lad", name: "Los Angeles Dodgers", shortName: "Dodgers", abbreviation: "LAD", city: "Los Angeles", nickname: "Dodgers", leagueID: "mlb", conference: "NL", division: "West", apiTeamID: "19"),
        Team(id: "mlb_bos", name: "Boston Red Sox", shortName: "Red Sox", abbreviation: "BOS", city: "Boston", nickname: "Red Sox", leagueID: "mlb", conference: "AL", division: "East", apiTeamID: "2"),
        Team(id: "mlb_hou", name: "Houston Astros", shortName: "Astros", abbreviation: "HOU", city: "Houston", nickname: "Astros", leagueID: "mlb", conference: "AL", division: "West", apiTeamID: "18"),
        Team(id: "mlb_chc", name: "Chicago Cubs", shortName: "Cubs", abbreviation: "CHC", city: "Chicago", nickname: "Cubs", leagueID: "mlb", conference: "NL", division: "Central", apiTeamID: "16"),
        Team(id: "mlb_sf", name: "San Francisco Giants", shortName: "Giants", abbreviation: "SF", city: "San Francisco", nickname: "Giants", leagueID: "mlb", conference: "NL", division: "West", apiTeamID: "26"),

        Team(id: "nhl_nyr", name: "New York Rangers", shortName: "Rangers", abbreviation: "NYR", city: "New York", nickname: "Rangers", leagueID: "nhl", conference: "East", division: "Metropolitan", apiTeamID: "13"),
        Team(id: "nhl_bos", name: "Boston Bruins", shortName: "Bruins", abbreviation: "BOS", city: "Boston", nickname: "Bruins", leagueID: "nhl", conference: "East", division: "Atlantic", apiTeamID: "1"),
        Team(id: "nhl_tor", name: "Toronto Maple Leafs", shortName: "Maple Leafs", abbreviation: "TOR", city: "Toronto", nickname: "Maple Leafs", leagueID: "nhl", conference: "East", division: "Atlantic", apiTeamID: "10"),
        Team(id: "nhl_edm", name: "Edmonton Oilers", shortName: "Oilers", abbreviation: "EDM", city: "Edmonton", nickname: "Oilers", leagueID: "nhl", conference: "West", division: "Pacific", apiTeamID: "6"),

        Team(id: "ncaafb_osu", name: "Ohio State Buckeyes", shortName: "Ohio State", abbreviation: "OSU", city: "Columbus", nickname: "Buckeyes", leagueID: "ncaafb", conference: "Big Ten", division: nil, apiTeamID: "194"),
        Team(id: "ncaafb_uga", name: "Georgia Bulldogs", shortName: "Georgia", abbreviation: "UGA", city: "Athens", nickname: "Bulldogs", leagueID: "ncaafb", conference: "SEC", division: nil, apiTeamID: "61"),
        Team(id: "ncaafb_tex", name: "Texas Longhorns", shortName: "Texas", abbreviation: "TEX", city: "Austin", nickname: "Longhorns", leagueID: "ncaafb", conference: "SEC", division: nil, apiTeamID: "251"),
        Team(id: "ncaafb_ore", name: "Oregon Ducks", shortName: "Oregon", abbreviation: "ORE", city: "Eugene", nickname: "Ducks", leagueID: "ncaafb", conference: "Big Ten", division: nil, apiTeamID: "2483"),
        Team(id: "ncaafb_bama", name: "Alabama Crimson Tide", shortName: "Alabama", abbreviation: "BAMA", city: "Tuscaloosa", nickname: "Crimson Tide", leagueID: "ncaafb", conference: "SEC", division: nil, apiTeamID: "333"),
        Team(id: "ncaafb_psu", name: "Penn State Nittany Lions", shortName: "Penn State", abbreviation: "PSU", city: "State College", nickname: "Nittany Lions", leagueID: "ncaafb", conference: "Big Ten", division: nil, apiTeamID: "213"),

        Team(id: "ncaamb_duke", name: "Duke Blue Devils", shortName: "Duke", abbreviation: "DUKE", city: "Duke", nickname: "Blue Devils", leagueID: "ncaamb", conference: "ACC", division: nil, apiTeamID: "150"),
        Team(id: "ncaamb_ku", name: "Kansas Jayhawks", shortName: "Kansas", abbreviation: "KU", city: "Kansas", nickname: "Jayhawks", leagueID: "ncaamb", conference: "Big 12", division: nil, apiTeamID: "2305"),
        Team(id: "ncaamb_ucla", name: "UCLA Bruins", shortName: "UCLA", abbreviation: "UCLA", city: "UCLA", nickname: "Bruins", leagueID: "ncaamb", conference: "Big Ten", division: nil, apiTeamID: "26"),
        Team(id: "ncaamb_purdue", name: "Purdue Boilermakers", shortName: "Purdue", abbreviation: "PUR", city: "Purdue", nickname: "Boilermakers", leagueID: "ncaamb", conference: "Big Ten", division: nil, apiTeamID: "2509"),

        Team(id: "epl_ars", name: "Arsenal", shortName: "Arsenal", abbreviation: "ARS", city: "London", nickname: "Arsenal", leagueID: "epl", conference: "Premier League", division: nil, apiTeamID: "359"),
        Team(id: "epl_liv", name: "Liverpool", shortName: "Liverpool", abbreviation: "LIV", city: "Liverpool", nickname: "Liverpool", leagueID: "epl", conference: "Premier League", division: nil, apiTeamID: "364"),
        Team(id: "epl_mci", name: "Manchester City", shortName: "Man City", abbreviation: "MCI", city: "Manchester", nickname: "Manchester City", leagueID: "epl", conference: "Premier League", division: nil, apiTeamID: "382"),
        Team(id: "epl_che", name: "Chelsea", shortName: "Chelsea", abbreviation: "CHE", city: "London", nickname: "Chelsea", leagueID: "epl", conference: "Premier League", division: nil, apiTeamID: "363")
    ]

    // MARK: - Dynamic Anchor (today in UTC)

    private static let anchor: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.startOfDay(for: Date())
    }()

    private static func makeDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: anchor) else { return anchor }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    // MARK: - Season Awareness

    static func isInSeason(leagueID: String, on date: Date? = nil) -> Bool {
        let checkDate = date ?? anchor
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let month = cal.component(.month, from: checkDate)
        let day = cal.component(.day, from: checkDate)
        let md = month * 100 + day

        switch leagueID {
        case "nba":     return md >= 1020 || md <= 620   // Oct 20 – Jun 20
        case "nfl":     return md >= 905  || md <= 215    // Sep 5 – Feb 15
        case "mlb":     return md >= 301  && md <= 1105   // Mar 1 – Nov 5
        case "nhl":     return md >= 1005 || md <= 625    // Oct 5 – Jun 25
        case "ncaafb":  return md >= 825  || md <= 115     // Aug 25 – Jan 15
        case "ncaamb":  return md >= 1101 || md <= 410    // Nov 1 – Apr 10
        case "epl":     return md >= 810  || md <= 525    // Aug 10 – May 25
        default:        return true
        }
    }

    // MARK: - Sport-Specific Data Generators

    private static func sportSpecificLeaders(leagueID: String, seed: Int, isHome: Bool) -> [String] {
        let s = abs(isHome ? seed : seed &+ 500)
        switch leagueID {
        case "nba":
            return ["PTS: \(20 + s % 15)", "REB: \(5 + s % 8)", "AST: \(3 + s % 9)"]
        case "nfl":
            return ["Pass YDS: \(180 + s % 160)", "Rush YDS: \(40 + s % 80)", "REC YDS: \(50 + s % 90)"]
        case "mlb":
            return ["\(1 + s % 3)-\(3 + s % 2), \(s % 3) RBI", "IP: \(4 + s % 4).0, K: \(3 + s % 7)"]
        case "nhl":
            return ["G: \(s % 3), A: \(s % 2)", "SV: \(20 + s % 15)"]
        case "ncaafb":
            return ["Pass YDS: \(150 + s % 180)", "Rush YDS: \(50 + s % 100)", "REC YDS: \(40 + s % 100)"]
        case "ncaamb":
            return ["PTS: \(14 + s % 14)", "REB: \(3 + s % 7)", "AST: \(2 + s % 6)"]
        case "epl":
            return ["G: \(s % 2), A: \(s % 2)", "Shots: \(1 + s % 4)"]
        default:
            return ["PTS: \(18 + s % 17)"]
        }
    }

    private static func sportSpecificStats(leagueID: String, seed: Int, isHome: Bool) -> [String] {
        let s = abs(isHome ? seed &+ 100 : seed &+ 600)
        switch leagueID {
        case "nba":
            return [
                "FG% \(String(format: "%.1f", 42.0 + Double(s % 12)))",
                "3PT% \(String(format: "%.1f", 30.0 + Double(s % 12)))",
                "REB \(35 + s % 15)",
                "TO \(8 + s % 8)"
            ]
        case "nfl":
            return [
                "Total YDS \(250 + s % 150)",
                "Pass YDS \(150 + s % 150)",
                "Rush YDS \(60 + s % 100)",
                "TOP \(26 + s % 8):\(String(format: "%02d", 10 + s % 50))"
            ]
        case "mlb":
            return [
                "H \(4 + s % 8)",
                "HR \(s % 4)",
                "LOB \(3 + s % 7)",
                "K \(4 + s % 8)"
            ]
        case "nhl":
            return [
                "SOG \(22 + s % 16)",
                "PP \(s % 3)/\(2 + s % 4)",
                "FO% \(String(format: "%.1f", 45.0 + Double(s % 10)))",
                "Hits \(15 + s % 20)"
            ]
        case "ncaafb":
            return [
                "Total YDS \(280 + s % 180)",
                "Pass YDS \(150 + s % 180)",
                "Rush YDS \(80 + s % 120)",
                "TOP \(25 + s % 10):\(String(format: "%02d", 10 + s % 50))"
            ]
        case "ncaamb":
            return [
                "FG% \(String(format: "%.1f", 38.0 + Double(s % 15)))",
                "3PT% \(String(format: "%.1f", 28.0 + Double(s % 14)))",
                "REB \(28 + s % 12)",
                "TO \(8 + s % 8)"
            ]
        case "epl":
            return [
                "Poss \(42 + s % 16)%",
                "Shots \(6 + s % 12)",
                "SOT \(2 + s % 6)",
                "Corners \(2 + s % 8)"
            ]
        default:
            return ["FG% \(String(format: "%.1f", 42.0 + Double(s % 12)))"]
        }
    }

    private static func scoreRange(for leagueID: String) -> (low: Int, high: Int) {
        switch leagueID {
        case "nba":     return (95, 130)
        case "nfl":     return (10, 42)
        case "mlb":     return (0, 12)
        case "nhl":     return (0, 7)
        case "ncaafb":  return (7, 45)
        case "ncaamb":  return (55, 92)
        case "epl":     return (0, 5)
        default:        return (70, 120)
        }
    }

    static let profile = UserProfile(id: "profile_default", displayName: "Jordan Avery", favoriteSport: "Basketball", homeMarket: "United States")

    static let defaultFavoriteTeamIDs: [String] = ["nba_lal", "nfl_kc", "mlb_nyy"]
    static let defaultGameAlertIDs: [String] = ["g_mlb_001", "g_nba_001"]
    static let defaultWatchlistGameIDs: [String] = ["g_mlb_001", "g_epl_001"]
    static let defaultSavedHeadlineIDs: [String] = ["headline_001", "headline_008", "headline_015"]
    static let defaultRecentQueries: [String] = [
        "Lakers",
        "NBA standings",
        "Chiefs",
        "Yankees",
        "Premier League table",
        "Duke",
        "Bruins",
        "Warriors vs Celtics"
    ]

    static let alerts: [AlertMessage] = [
        AlertMessage(id: "alert_001", title: "Trade Deadline Tracker", message: "Deadline coverage is live with team-by-team updates.", severity: "info", createdAt: makeDate(dayOffset: -1, hour: 14)),
        AlertMessage(id: "alert_002", title: "Game Delay", message: "Yankees vs Red Sox is delayed due to weather.", severity: "warning", createdAt: makeDate(dayOffset: 0, hour: 0, minute: 15)),
        AlertMessage(id: "alert_003", title: "Breaking News", message: "Top seed race tightens in both NBA conferences.", severity: "high", createdAt: makeDate(dayOffset: 0, hour: 1, minute: 25)),
        AlertMessage(id: "alert_004", title: "Injury Report", message: "Chiefs list two starters as questionable for Sunday.", severity: "warning", createdAt: makeDate(dayOffset: 0, hour: 3, minute: 5)),
        AlertMessage(id: "alert_005", title: "Lineup Note", message: "Dodgers shuffle batting order ahead of weekend series.", severity: "info", createdAt: makeDate(dayOffset: 0, hour: 4, minute: 5)),
        AlertMessage(id: "alert_006", title: "Title Race Update", message: "Arsenal draw keeps race within two points at the top.", severity: "high", createdAt: makeDate(dayOffset: 0, hour: 5, minute: 25))
    ]

    static let headlines: [HeadlineArticle] = [
        HeadlineArticle(id: "headline_001", headline: "Lakers Hold Off Warriors in Instant Classic", summary: "Late-game defense and clutch shotmaking decide a back-and-forth showdown.", imageURL: "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 1, minute: 10), leagueID: "nba", sectionTag: "Top Story"),
        HeadlineArticle(id: "headline_002", headline: "Chiefs Clinch AFC Top Seed Path", summary: "Kansas City leans on red-zone efficiency in a key conference win.", imageURL: "https://images.unsplash.com/photo-1566577739112-5180d4bf9390?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 23), leagueID: "nfl", sectionTag: "NFL"),
        HeadlineArticle(id: "headline_003", headline: "Red Sox Bullpen Survives Late Yankees Push", summary: "Boston preserves a one-run lead with two scoreless innings.", imageURL: "https://images.unsplash.com/photo-1471295253337-3ceaaedca402?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 0, minute: 50), leagueID: "mlb", sectionTag: "MLB"),
        HeadlineArticle(id: "headline_004", headline: "Bruins and Rangers Battle for Metro Control", summary: "A critical divisional matchup heads to overtime territory.", imageURL: "https://images.unsplash.com/photo-1515703407324-5f753afd8be8?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 22, minute: 20), leagueID: "nhl", sectionTag: "NHL"),
        HeadlineArticle(id: "headline_005", headline: "Purdue's Defense Sets Tone in Top-25 Clash", summary: "Second-chance points and rebounding margin shape the result.", imageURL: "https://images.unsplash.com/photo-1518989229647-6377f907a0b2?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 2), leagueID: "ncaamb", sectionTag: "NCAAM"),
        HeadlineArticle(id: "headline_006", headline: "Arsenal and Liverpool Split Points", summary: "Two first-half goals and tactical adjustments produce a draw.", imageURL: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 21, minute: 15), leagueID: "epl", sectionTag: "EPL"),
        HeadlineArticle(id: "headline_007", headline: "Standings Watch: East Race Tightens", summary: "Three teams remain within one game in the NBA East.", imageURL: "https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 20, minute: 10), leagueID: "nba", sectionTag: "Trending"),
        HeadlineArticle(id: "headline_008", headline: "Weekend Watch Guide: Must-See Matchups", summary: "Key games across football, basketball, hockey, and soccer.", imageURL: "https://images.unsplash.com/photo-1508697371770-529139794f8b?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 19, minute: 5), leagueID: nil, sectionTag: "Latest"),
        HeadlineArticle(id: "headline_009", headline: "Celtics Extend Win Streak With Late Defensive Stops", summary: "Boston closes with a 13-4 run and improves seeding outlook.", imageURL: "https://images.unsplash.com/photo-1515523110800-9415d13b84a8?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 3, minute: 20), leagueID: "nba", sectionTag: "NBA"),
        HeadlineArticle(id: "headline_010", headline: "Bills Red-Zone Woes Loom Large in Narrow Loss", summary: "Buffalo moves the ball well but stalls in key fourth-quarter drives.", imageURL: "https://images.unsplash.com/photo-1757587936273-0b32ffea9103?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 2, minute: 42), leagueID: "nfl", sectionTag: "NFL"),
        HeadlineArticle(id: "headline_011", headline: "Dodgers Rotation Finds Rhythm in Spring Tune-Up", summary: "Two starters combine for nine strikeouts over six innings.", imageURL: "https://images.unsplash.com/photo-1475440197469-e367ec8eeb19?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 1, minute: 55), leagueID: "mlb", sectionTag: "MLB"),
        HeadlineArticle(id: "headline_012", headline: "Oilers Top Line Drives Another Multi-Goal Night", summary: "Transition speed and power-play execution tilt the game early.", imageURL: "https://images.unsplash.com/photo-1517339763538-9bb6c388613a?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 1, minute: 30), leagueID: "nhl", sectionTag: "NHL"),
        HeadlineArticle(id: "headline_013", headline: "Jayhawks Hold Paint Advantage Against Duke", summary: "Kansas wins second-chance battle and limits transition points.", imageURL: "https://images.unsplash.com/photo-1521055170349-25f955971658?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: 0, hour: 0, minute: 35), leagueID: "ncaamb", sectionTag: "NCAAM"),
        HeadlineArticle(id: "headline_014", headline: "Manchester City Keep Pressure on League Leaders", summary: "City control possession and secure another clean sheet.", imageURL: "https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 23, minute: 45), leagueID: "epl", sectionTag: "EPL"),
        HeadlineArticle(id: "headline_015", headline: "Film Room: Why Late-Switch Defense Is Trending", summary: "Teams across leagues are changing end-game coverages.", imageURL: "https://images.unsplash.com/photo-1574907060871-4555aa8aca75?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 22, minute: 55), leagueID: nil, sectionTag: "Analysis"),
        HeadlineArticle(id: "headline_016", headline: "Power Rankings: Postseason Picture Update", summary: "Big movers emerge after a packed night of games.", imageURL: "https://images.unsplash.com/photo-1577416412292-747c6607f055?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 22, minute: 15), leagueID: nil, sectionTag: "Rankings"),
        HeadlineArticle(id: "headline_017", headline: "Preview: Knicks vs Bucks Could Swing East Seeding", summary: "Matchup features elite half-court offense versus rim pressure.", imageURL: "https://images.unsplash.com/photo-1519766304817-4f37bda74a26?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 21, minute: 44), leagueID: "nba", sectionTag: "Preview"),
        HeadlineArticle(id: "headline_018", headline: "Sunday Slate: Best Games to Watch Across Leagues", summary: "From prime-time NFL to marquee EPL fixtures, here is the guide.", imageURL: "https://images.unsplash.com/photo-1581852549708-72910bd52cff?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 21, minute: 2), leagueID: nil, sectionTag: "Guide"),
        HeadlineArticle(id: "headline_019", headline: "Inside the Numbers: MLB Exit Velocity Leaders", summary: "Early data points to several breakout bats this spring.", imageURL: "https://images.unsplash.com/photo-1512631737701-737916001362?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 20, minute: 25), leagueID: "mlb", sectionTag: "Stats"),
        HeadlineArticle(id: "headline_020", headline: "Rivalry Week Brings Packed Arena Atmosphere", summary: "College crowds and conference implications headline the weekend.", imageURL: "https://images.unsplash.com/photo-1523142096306-cca37b5aa001?w=1600&h=900&q=85&fm=jpg&fit=crop&auto=format", publishedAt: makeDate(dayOffset: -1, hour: 19, minute: 48), leagueID: "ncaamb", sectionTag: "Campus")
    ]

    static var teamsByID: [String: Team] {
        Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })
    }

    static let allSeededGames: [Game] = {
        let teamMap = teamsByID

        func team(_ id: String) -> Team {
            guard let value = teamMap[id] else {
                fatalError("Missing seeded team: \(id)")
            }
            return value
        }

        func st(_ state: GameState, short: String, detail: String, period: String?) -> GameStatus {
            GameStatus(state: state, shortText: short, detailText: detail, periodDescription: period)
        }

        func game(
            _ id: String,
            league: String,
            dayOffset: Int,
            hour: Int,
            minute: Int = 0,
            away: String,
            home: String,
            awayScore: Int?,
            homeScore: Int?,
            liveStatus: GameStatus?,
            venue: String,
            headline: String
        ) -> Game {
            let startDate = makeDate(dayOffset: dayOffset, hour: hour, minute: minute)
            let resolvedStatus: GameStatus
            if dayOffset < 0 {
                resolvedStatus = league == "epl"
                    ? st(.final, short: "FT", detail: "Full Time", period: "Full Time")
                    : st(.final, short: "Final", detail: "Final", period: "Final")
            } else if dayOffset > 0 {
                resolvedStatus = st(.upcoming, short: DateFormatting.gameTime.string(from: startDate), detail: "Scheduled", period: nil)
            } else if let live = liveStatus {
                resolvedStatus = live
            } else {
                resolvedStatus = st(.upcoming, short: DateFormatting.gameTime.string(from: startDate), detail: "Scheduled", period: nil)
            }
            let range = scoreRange(for: league)
            let defaultAway = range.low + (stableSeed(id) % (range.high - range.low + 1))
            let defaultHome = range.low + (stableSeed(id + "h") % (range.high - range.low + 1))
            let resolvedAwayScore = dayOffset < 0 ? (awayScore ?? defaultAway) : (resolvedStatus.state == .final || resolvedStatus.state == .live ? awayScore : nil)
            let resolvedHomeScore = dayOffset < 0 ? (homeScore ?? defaultHome) : (resolvedStatus.state == .final || resolvedStatus.state == .live ? homeScore : nil)
            let gameSeed = stableSeed(id)
            return Game(
                id: id,
                leagueID: league,
                startDate: startDate,
                homeTeam: team(home),
                awayTeam: team(away),
                homeScore: resolvedHomeScore,
                awayScore: resolvedAwayScore,
                status: resolvedStatus,
                venue: venue,
                headline: headline,
                homeLeaders: sportSpecificLeaders(leagueID: league, seed: gameSeed, isHome: true),
                awayLeaders: sportSpecificLeaders(leagueID: league, seed: gameSeed, isHome: false),
                homeTeamStats: sportSpecificStats(leagueID: league, seed: gameSeed, isHome: true),
                awayTeamStats: sportSpecificStats(leagueID: league, seed: gameSeed, isHome: false)
            )
        }

        let baseGames: [Game] = [
            // NBA – Day 0 (today)
            game("g_nba_001", league: "nba", dayOffset: 0, hour: 3, minute: 30, away: "nba_lal", home: "nba_gsw", awayScore: 102, homeScore: 109, liveStatus: st(.live, short: "Q4", detail: "Q4 4:12", period: "4th Quarter"), venue: "Chase Center", headline: "Warriors and Lakers trading late runs"),
            game("g_nba_002", league: "nba", dayOffset: 0, hour: 0, away: "nba_bos", home: "nba_nyk", awayScore: 118, homeScore: 110, liveStatus: st(.final, short: "Final", detail: "Final", period: "Final"), venue: "Madison Square Garden", headline: "Celtics close out road win"),
            game("g_nba_003", league: "nba", dayOffset: 0, hour: 2, away: "nba_mil", home: "nba_den", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Ball Arena", headline: "MVP candidates face off"),
            // NBA – Day -1 (yesterday)
            game("g_nba_004", league: "nba", dayOffset: -1, hour: 2, away: "nba_phx", home: "nba_dal", awayScore: 97, homeScore: 103, liveStatus: nil, venue: "American Airlines Center", headline: "Mavericks defend home floor"),
            // NBA – Day +3
            game("g_nba_005", league: "nba", dayOffset: 3, hour: 3, minute: 30, away: "nba_gsw", home: "nba_lal", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Crypto.com Arena", headline: "Rematch in Los Angeles"),
            // NBA – Day +2
            game("g_nba_006", league: "nba", dayOffset: 2, hour: 0, away: "nba_nyk", home: "nba_mil", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Fiserv Forum", headline: "Playoff seeding implications"),

            // NFL – Off-season: most recent games from prior season
            game("g_nfl_001", league: "nfl", dayOffset: -30, hour: 22, minute: 30, away: "nfl_kc", home: "nfl_phi", awayScore: 28, homeScore: 25, liveStatus: nil, venue: "Allegiant Stadium", headline: "Championship Sunday concludes the season"),
            game("g_nfl_002", league: "nfl", dayOffset: -31, hour: 20, minute: 15, away: "nfl_buf", home: "nfl_kc", awayScore: 24, homeScore: 27, liveStatus: nil, venue: "GEHA Field at Arrowhead", headline: "Chiefs advance past Bills in AFC title game"),
            game("g_nfl_003", league: "nfl", dayOffset: -31, hour: 15, minute: 5, away: "nfl_phi", home: "nfl_sf", awayScore: 31, homeScore: 27, liveStatus: nil, venue: "Levi's Stadium", headline: "Eagles rally late in NFC Championship"),
            game("g_nfl_004", league: "nfl", dayOffset: -37, hour: 18, away: "nfl_dal", home: "nfl_bal", awayScore: 17, homeScore: 34, liveStatus: nil, venue: "M&T Bank Stadium", headline: "Ravens dominate divisional round"),

            // MLB – Spring Training
            game("g_mlb_001", league: "mlb", dayOffset: 0, hour: 18, minute: 10, away: "mlb_nyy", home: "mlb_bos", awayScore: 4, homeScore: 5, liveStatus: st(.live, short: "7th", detail: "Top 7th", period: "Top 7th"), venue: "JetBlue Park", headline: "Spring training AL East preview"),
            game("g_mlb_002", league: "mlb", dayOffset: -1, hour: 18, minute: 5, away: "mlb_lad", home: "mlb_hou", awayScore: 6, homeScore: 2, liveStatus: nil, venue: "FITTEAM Ballpark", headline: "Dodgers lineup shines in Grapefruit League"),
            game("g_mlb_003", league: "mlb", dayOffset: 1, hour: 18, minute: 5, away: "mlb_chc", home: "mlb_nyy", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Steinbrenner Field", headline: "Cactus meets Grapefruit matchup"),
            game("g_mlb_004", league: "mlb", dayOffset: 2, hour: 21, minute: 5, away: "mlb_bos", home: "mlb_lad", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Camelback Ranch", headline: "West coast spring tune-up"),
            game("g_mlb_005", league: "mlb", dayOffset: 5, hour: 1, minute: 15, away: "mlb_nyy", home: "mlb_sf", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Oracle Park", headline: "Yankees visit Oracle Park for interleague clash"),

            // NHL
            game("g_nhl_001", league: "nhl", dayOffset: 0, hour: 0, away: "nhl_nyr", home: "nhl_bos", awayScore: 2, homeScore: 2, liveStatus: st(.live, short: "3rd", detail: "3rd 11:03", period: "3rd Period"), venue: "TD Garden", headline: "Goalies under pressure in Boston"),
            game("g_nhl_002", league: "nhl", dayOffset: -1, hour: 2, away: "nhl_tor", home: "nhl_edm", awayScore: 1, homeScore: 4, liveStatus: nil, venue: "Rogers Place", headline: "Oilers score three in the second"),
            game("g_nhl_003", league: "nhl", dayOffset: 1, hour: 0, away: "nhl_bos", home: "nhl_nyr", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Madison Square Garden", headline: "Bruins visit Rangers"),
            game("g_nhl_004", league: "nhl", dayOffset: 2, hour: 1, away: "nhl_edm", home: "nhl_tor", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Scotiabank Arena", headline: "High-powered offenses collide"),

            // NCAAMB
            game("g_ncaamb_001", league: "ncaamb", dayOffset: -1, hour: 23, minute: 30, away: "ncaamb_duke", home: "ncaamb_ku", awayScore: 68, homeScore: 74, liveStatus: nil, venue: "Allen Fieldhouse", headline: "Jayhawks protect home court"),
            game("g_ncaamb_002", league: "ncaamb", dayOffset: 0, hour: 2, away: "ncaamb_ucla", home: "ncaamb_purdue", awayScore: 52, homeScore: 55, liveStatus: st(.live, short: "2nd", detail: "2nd 09:13", period: "2nd Half"), venue: "Mackey Arena", headline: "Defense-heavy top-25 battle"),
            game("g_ncaamb_003", league: "ncaamb", dayOffset: 1, hour: 19, away: "ncaamb_ku", home: "ncaamb_ucla", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Pauley Pavilion", headline: "Kansas heads west"),
            game("g_ncaamb_004", league: "ncaamb", dayOffset: 2, hour: 22, away: "ncaamb_purdue", home: "ncaamb_duke", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Cameron Indoor Stadium", headline: "Statement-game opportunity"),

            // EPL
            game("g_epl_001", league: "epl", dayOffset: -1, hour: 19, minute: 45, away: "epl_ars", home: "epl_liv", awayScore: 1, homeScore: 1, liveStatus: nil, venue: "Anfield", headline: "Title race intensity on display"),
            game("g_epl_002", league: "epl", dayOffset: -1, hour: 16, away: "epl_mci", home: "epl_che", awayScore: 3, homeScore: 0, liveStatus: nil, venue: "Stamford Bridge", headline: "City dominate away from home"),
            game("g_epl_003", league: "epl", dayOffset: 1, hour: 15, minute: 30, away: "epl_che", home: "epl_ars", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Emirates Stadium", headline: "London derby with big stakes"),
            game("g_epl_004", league: "epl", dayOffset: 2, hour: 16, minute: 30, away: "epl_liv", home: "epl_mci", awayScore: nil, homeScore: nil, liveStatus: nil, venue: "Etihad Stadium", headline: "Heavyweight matchup at the Etihad")
        ]

        let supplementalGames = generateSupplementalGames(from: baseGames)
        return (baseGames + supplementalGames).sorted { $0.startDate < $1.startDate }
    }()

    static let standings: [StandingEntry] = {
        func entry(
            id: String,
            league: String,
            conference: String,
            rank: Int,
            teamID: String,
            wins: Int,
            losses: Int,
            draws: Int = 0,
            gamesBack: Double?
        ) -> StandingEntry {
            guard let team = teamsByID[teamID] else {
                fatalError("Missing standings team: \(teamID)")
            }
            return StandingEntry(
                id: id,
                leagueID: league,
                conference: conference,
                division: team.division,
                rank: rank,
                team: team,
                wins: wins,
                losses: losses,
                draws: draws,
                gamesBack: gamesBack
            )
        }

        let baseStandings: [StandingEntry] = [
            // NBA – mid-season (~60 games played by March)
            entry(id: "st_nba_e_1", league: "nba", conference: "East", rank: 1, teamID: "nba_cle", wins: 48, losses: 14, gamesBack: 0.0),
            entry(id: "st_nba_e_2", league: "nba", conference: "East", rank: 2, teamID: "nba_bos", wins: 45, losses: 17, gamesBack: 3.0),
            entry(id: "st_nba_e_3", league: "nba", conference: "East", rank: 3, teamID: "nba_nyk", wins: 42, losses: 21, gamesBack: 6.5),
            entry(id: "st_nba_e_4", league: "nba", conference: "East", rank: 4, teamID: "nba_mil", wins: 37, losses: 25, gamesBack: 11.0),
            entry(id: "st_nba_e_5", league: "nba", conference: "East", rank: 5, teamID: "nba_mia", wins: 32, losses: 30, gamesBack: 16.0),

            entry(id: "st_nba_w_1", league: "nba", conference: "West", rank: 1, teamID: "nba_den", wins: 44, losses: 18, gamesBack: 0.0),
            entry(id: "st_nba_w_2", league: "nba", conference: "West", rank: 2, teamID: "nba_gsw", wins: 39, losses: 23, gamesBack: 5.0),
            entry(id: "st_nba_w_3", league: "nba", conference: "West", rank: 3, teamID: "nba_lal", wins: 37, losses: 25, gamesBack: 7.0),
            entry(id: "st_nba_w_4", league: "nba", conference: "West", rank: 4, teamID: "nba_dal", wins: 36, losses: 26, gamesBack: 8.0),
            entry(id: "st_nba_w_5", league: "nba", conference: "West", rank: 5, teamID: "nba_phx", wins: 34, losses: 28, gamesBack: 10.0),

            // NFL – final regular-season standings (season over)
            entry(id: "st_nfl_afc_1", league: "nfl", conference: "AFC", rank: 1, teamID: "nfl_kc", wins: 14, losses: 3, gamesBack: 0.0),
            entry(id: "st_nfl_afc_2", league: "nfl", conference: "AFC", rank: 2, teamID: "nfl_buf", wins: 13, losses: 4, gamesBack: 1.0),
            entry(id: "st_nfl_afc_3", league: "nfl", conference: "AFC", rank: 3, teamID: "nfl_bal", wins: 12, losses: 5, gamesBack: 2.0),
            entry(id: "st_nfl_nfc_1", league: "nfl", conference: "NFC", rank: 1, teamID: "nfl_phi", wins: 14, losses: 3, gamesBack: 0.0),
            entry(id: "st_nfl_nfc_2", league: "nfl", conference: "NFC", rank: 2, teamID: "nfl_sf", wins: 12, losses: 5, gamesBack: 2.0),
            entry(id: "st_nfl_nfc_3", league: "nfl", conference: "NFC", rank: 3, teamID: "nfl_dal", wins: 10, losses: 7, gamesBack: 4.0),

            // MLB – previous season final standings (spring training underway)
            entry(id: "st_mlb_al_1", league: "mlb", conference: "AL", rank: 1, teamID: "mlb_nyy", wins: 94, losses: 68, gamesBack: 0.0),
            entry(id: "st_mlb_al_2", league: "mlb", conference: "AL", rank: 2, teamID: "mlb_hou", wins: 90, losses: 72, gamesBack: 4.0),
            entry(id: "st_mlb_al_3", league: "mlb", conference: "AL", rank: 3, teamID: "mlb_bos", wins: 86, losses: 76, gamesBack: 8.0),
            entry(id: "st_mlb_nl_1", league: "mlb", conference: "NL", rank: 1, teamID: "mlb_lad", wins: 98, losses: 64, gamesBack: 0.0),
            entry(id: "st_mlb_nl_2", league: "mlb", conference: "NL", rank: 2, teamID: "mlb_chc", wins: 83, losses: 79, gamesBack: 15.0),
            entry(id: "st_mlb_nl_3", league: "mlb", conference: "NL", rank: 3, teamID: "mlb_sf", wins: 80, losses: 82, gamesBack: 18.0),

            // NHL – mid-season (~65 games played by March)
            entry(id: "st_nhl_e_1", league: "nhl", conference: "East", rank: 1, teamID: "nhl_nyr", wins: 38, losses: 20, gamesBack: 0.0),
            entry(id: "st_nhl_e_2", league: "nhl", conference: "East", rank: 2, teamID: "nhl_bos", wins: 36, losses: 21, gamesBack: 2.0),
            entry(id: "st_nhl_e_3", league: "nhl", conference: "East", rank: 3, teamID: "nhl_tor", wins: 34, losses: 24, gamesBack: 5.0),
            entry(id: "st_nhl_w_1", league: "nhl", conference: "West", rank: 1, teamID: "nhl_edm", wins: 40, losses: 18, gamesBack: 0.0),

            // NCAAMB – conference record by March
            entry(id: "st_ncaamb_1", league: "ncaamb", conference: "Top 25", rank: 1, teamID: "ncaamb_duke", wins: 27, losses: 4, gamesBack: 0.0),
            entry(id: "st_ncaamb_2", league: "ncaamb", conference: "Top 25", rank: 2, teamID: "ncaamb_ku", wins: 25, losses: 6, gamesBack: 2.0),
            entry(id: "st_ncaamb_3", league: "ncaamb", conference: "Top 25", rank: 3, teamID: "ncaamb_ucla", wins: 23, losses: 7, gamesBack: 3.5),
            entry(id: "st_ncaamb_4", league: "ncaamb", conference: "Top 25", rank: 4, teamID: "ncaamb_purdue", wins: 22, losses: 9, gamesBack: 5.5),

            // EPL – mid-season (~28 matches played by March)
            entry(id: "st_epl_1", league: "epl", conference: "Premier League", rank: 1, teamID: "epl_ars", wins: 19, losses: 4, draws: 5, gamesBack: 0.0),
            entry(id: "st_epl_2", league: "epl", conference: "Premier League", rank: 2, teamID: "epl_liv", wins: 18, losses: 4, draws: 6, gamesBack: 1.0),
            entry(id: "st_epl_3", league: "epl", conference: "Premier League", rank: 3, teamID: "epl_mci", wins: 17, losses: 5, draws: 6, gamesBack: 3.0),
            entry(id: "st_epl_4", league: "epl", conference: "Premier League", rank: 4, teamID: "epl_che", wins: 14, losses: 7, draws: 7, gamesBack: 8.0)
        ]

        let supplementalStandings = generateSupplementalStandings(from: baseStandings)
        return (baseStandings + supplementalStandings).sorted { lhs, rhs in
            if lhs.leagueID != rhs.leagueID {
                return lhs.leagueID < rhs.leagueID
            }
            if lhs.conference != rhs.conference {
                return lhs.conference < rhs.conference
            }
            return lhs.rank < rhs.rank
        }
    }()

    private static func generateSupplementalGames(from baseGames: [Game]) -> [Game] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var generated: [Game] = []

        // Track which teams already play on which day (from base games)
        var busyTeamsByDay: [Int: Set<String>] = [:]
        for game in baseGames {
            let dayOff = calendar.dateComponents([.day], from: anchor, to: game.startDate).day ?? 0
            busyTeamsByDay[dayOff, default: []].insert(game.homeTeam.id)
            busyTeamsByDay[dayOff, default: []].insert(game.awayTeam.id)
        }

        let leagueIDs = Set(teams.map(\.leagueID)).sorted()

        for leagueID in leagueIDs {
            // Skip off-season leagues – no supplemental games when not in season
            guard isInSeason(leagueID: leagueID) else { continue }

            let leagueTeams = teams.filter { $0.leagueID == leagueID }.sorted { $0.id < $1.id }
            let slotsPerDay = min(4, max(2, leagueTeams.count / 2))
            let range = scoreRange(for: leagueID)

            for dayOffset in -5...5 {
                let busyOnDay = busyTeamsByDay[dayOffset] ?? []

                // Filter to teams in this league that aren't already playing today
                let available = leagueTeams.filter { !busyOnDay.contains($0.id) }
                guard available.count >= 2 else { continue }

                // Deterministically shuffle teams for varied matchups each day
                let shuffled = available.sorted { lhs, rhs in
                    stableSeed("\(leagueID)_day\(dayOffset)_\(lhs.id)") < stableSeed("\(leagueID)_day\(dayOffset)_\(rhs.id)")
                }

                let pairCount = min(slotsPerDay, shuffled.count / 2)
                for slot in 0..<pairCount {
                    let away = shuffled[slot * 2]
                    let home = shuffled[slot * 2 + 1]

                    // Use realistic game times per league
                    let hour: Int
                    let minute: Int
                    if leagueID == "epl" {
                        // UK afternoon/evening: 3-6 PM UK = 15-18 UTC
                        hour = 15 + slot
                        minute = slot % 2 == 0 ? 0 : 30
                    } else {
                        // US evening games: 7-10:30 PM ET = 0-3:30 AM UTC (next calendar day)
                        hour = slot + 1
                        minute = slot % 2 == 0 ? 0 : 30
                    }
                    let startDate = makeDate(dayOffset: dayOffset, hour: hour, minute: minute)

                    let seededID = "g_\(leagueID)_supp_\(dayOffset + 6)_\(slot + 1)"
                    let status = supplementalStatus(for: leagueID, dayOffset: dayOffset, slot: slot, startDate: startDate)
                    let isUpcoming = status.state == .upcoming
                    let span = max(1, range.high - range.low + 1)
                    let awayScore = isUpcoming ? nil : range.low + (stableSeed("\(seededID)_away") % span)
                    let homeScore = isUpcoming ? nil : range.low + (stableSeed("\(seededID)_home") % span)
                    let gameSeed = stableSeed(seededID)

                    generated.append(
                        Game(
                            id: seededID,
                            leagueID: leagueID,
                            startDate: startDate,
                            homeTeam: home,
                            awayTeam: away,
                            homeScore: homeScore,
                            awayScore: awayScore,
                            status: status,
                            venue: supplementalVenue(for: leagueID, home: home),
                            headline: "\(away.shortName) at \(home.shortName)",
                            homeLeaders: sportSpecificLeaders(leagueID: leagueID, seed: gameSeed, isHome: true),
                            awayLeaders: sportSpecificLeaders(leagueID: leagueID, seed: gameSeed, isHome: false),
                            homeTeamStats: sportSpecificStats(leagueID: leagueID, seed: gameSeed, isHome: true),
                            awayTeamStats: sportSpecificStats(leagueID: leagueID, seed: gameSeed, isHome: false)
                        )
                    )

                    // Mark these teams as busy on this day
                    busyTeamsByDay[dayOffset, default: []].insert(away.id)
                    busyTeamsByDay[dayOffset, default: []].insert(home.id)
                }
            }
        }

        return generated
    }

    private static func supplementalVenue(for leagueID: String, home: Team) -> String {
        switch leagueID {
        case "nba":     return "\(home.city) Arena"
        case "nfl":     return "\(home.city) Stadium"
        case "mlb":     return "\(home.city) Ballpark"
        case "nhl":     return "\(home.city) Arena"
        case "ncaafb":  return "\(home.city) Stadium"
        case "ncaamb":  return "\(home.city) Fieldhouse"
        case "epl":     return "\(home.city) Stadium"
        default:        return "\(home.city) Arena"
        }
    }

    private static func supplementalStatus(for leagueID: String, dayOffset: Int, slot: Int, startDate: Date) -> GameStatus {
        let state: GameState
        if dayOffset < 0 {
            state = .final
        } else if dayOffset >= 2 {
            state = .upcoming
        } else {
            state = slot == 0 ? .live : .upcoming
        }

        switch state {
        case .live:
            if leagueID == "mlb" {
                let inningOptions = ["Top 3rd", "Bot 5th", "Top 7th", "Bot 8th"]
                let inning = inningOptions[slot % inningOptions.count]
                return GameStatus(state: .live, shortText: inning, detailText: inning, periodDescription: inning)
            }
            if leagueID == "nfl" || leagueID == "ncaafb" {
                return GameStatus(state: .live, shortText: "3rd", detailText: "3rd 08:14", periodDescription: "3rd Quarter")
            }
            if leagueID == "epl" {
                return GameStatus(state: .live, shortText: "58'", detailText: "58th Minute", periodDescription: "2nd Half")
            }
            return GameStatus(state: .live, shortText: "Live", detailText: "In Progress", periodDescription: "Live")
        case .upcoming:
            return GameStatus(
                state: .upcoming,
                shortText: DateFormatting.gameTime.string(from: startDate),
                detailText: "Scheduled",
                periodDescription: nil
            )
        case .final:
            if leagueID == "epl" {
                return GameStatus(state: .final, shortText: "FT", detailText: "Full Time", periodDescription: "Full Time")
            }
            return GameStatus(state: .final, shortText: "Final", detailText: "Final", periodDescription: "Final")
        case .postponed:
            return GameStatus(state: .postponed, shortText: "Postponed", detailText: "Postponed", periodDescription: nil)
        }
    }

    private static func generateSupplementalStandings(from base: [StandingEntry]) -> [StandingEntry] {
        let existingTeamIDs = Set(base.map { $0.team.id })
        let existingMaxRankByGroup = Dictionary(grouping: base) { "\($0.leagueID)|\($0.conference)" }
            .mapValues { entries in
                entries.map(\.rank).max() ?? 0
            }

        var supplemental: [StandingEntry] = []
        let missingTeams = teams.filter { !existingTeamIDs.contains($0.id) }
        let groupedTeams = Dictionary(grouping: missingTeams) { team in
            "\(team.leagueID)|\(conferenceLabel(for: team))"
        }

        for key in groupedTeams.keys.sorted() {
            guard let grouped = groupedTeams[key] else { continue }
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            guard let leagueID = parts.first else { continue }
            let conference = parts.count > 1 ? parts[1] : "Overall"
            let rankStart = (existingMaxRankByGroup[key] ?? 0) + 1

            for (index, team) in grouped.sorted(by: { $0.displayName < $1.displayName }).enumerated() {
                let rank = rankStart + index
                let record = syntheticRecord(leagueID: leagueID, rank: rank, teamID: team.id)

                supplemental.append(
                    StandingEntry(
                        id: "st_\(leagueID)_supp_\(rank)_\(team.id)",
                        leagueID: leagueID,
                        conference: conference,
                        division: team.division,
                        rank: rank,
                        team: team,
                        wins: record.wins,
                        losses: record.losses,
                        draws: record.draws,
                        gamesBack: record.gamesBack
                    )
                )
            }
        }

        return supplemental
    }

    private static func conferenceLabel(for team: Team) -> String {
        if let conference = team.conference, !conference.isEmpty {
            return conference
        }

        switch team.leagueID {
        case "ncaafb": return "CFP Rankings"
        case "ncaamb": return "Top 25"
        case "epl": return "Premier League"
        default: return "Overall"
        }
    }

    private static func syntheticRecord(leagueID: String, rank: Int, teamID: String) -> (wins: Int, losses: Int, draws: Int, gamesBack: Double?) {
        let seed = stableSeed(teamID)

        switch leagueID {
        case "nba":
            let wins = max(30, 57 - (rank * 2) - (seed % 2))
            return (wins, 82 - wins, 0, rank == 1 ? 0.0 : Double(rank - 1) * 1.8)
        case "nfl":
            let wins = max(6, 14 - rank - (seed % 2))
            return (wins, 17 - wins, 0, rank == 1 ? 0.0 : Double(rank - 1))
        case "mlb":
            let wins = max(68, 102 - (rank * 2) - (seed % 3))
            return (wins, 162 - wins, 0, rank == 1 ? 0.0 : Double(rank - 1) * 2.0)
        case "nhl":
            let wins = max(30, 52 - rank - (seed % 3))
            let losses = max(20, 30 + rank + (seed % 3))
            return (wins, losses, 0, rank == 1 ? 0.0 : Double(rank - 1) * 1.5)
        case "ncaafb":
            let wins = max(6, 14 - rank - (seed % 2))
            let losses = max(1, 2 + (rank / 2))
            return (wins, losses, 0, rank == 1 ? 0.0 : Double(rank - 1))
        case "ncaamb":
            let wins = max(18, 30 - rank - (seed % 2))
            let losses = max(3, 6 + (rank / 2))
            return (wins, losses, 0, rank == 1 ? 0.0 : Double(rank - 1))
        case "epl":
            let wins = max(9, 24 - rank - (seed % 2))
            let draws = max(4, 10 - (rank / 2))
            let losses = max(2, 38 - wins - draws)
            return (wins, losses, draws, rank == 1 ? 0.0 : Double(rank - 1) * 2.0)
        default:
            let wins = max(10, 20 - rank)
            let losses = max(4, 10 + rank)
            return (wins, losses, 0, rank == 1 ? 0.0 : Double(rank - 1))
        }
    }

    private static func stableSeed(_ value: String) -> Int {
        value.unicodeScalars.reduce(0) { partial, scalar in
            ((partial * 33) + Int(scalar.value)) % 100_000
        }
    }

    static func league(by id: String) -> League? {
        leagues.first(where: { $0.id == id })
    }

    static func team(by id: String) -> Team? {
        teamsByID[id]
    }

    static func teams(in leagueID: String) -> [Team] {
        teams.filter { $0.leagueID == leagueID }
    }

    static func fallbackStandings(for leagueID: String) -> [StandingEntry] {
        standings
            .filter { $0.leagueID == leagueID }
            .sorted { lhs, rhs in
                if lhs.conference != rhs.conference {
                    return lhs.conference < rhs.conference
                }
                return lhs.rank < rhs.rank
            }
    }

    static func fallbackSchedule(for teamID: String) -> [Game] {
        allSeededGames
            .filter { $0.homeTeam.id == teamID || $0.awayTeam.id == teamID }
            .sorted { $0.startDate < $1.startDate }
    }

    static func fallbackGames(for leagueID: String, on date: Date) -> [Game] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sameDay = allSeededGames
            .filter { $0.leagueID == leagueID && calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }

        if !sameDay.isEmpty {
            return sameDay
        }

        // Off-season: return the most recent completed games for this league
        if !isInSeason(leagueID: leagueID, on: date) {
            let recentGames = allSeededGames
                .filter { $0.leagueID == leagueID && $0.startDate <= date }
                .sorted { $0.startDate > $1.startDate }
            return Array(recentGames.prefix(4))
        }

        // In-season: generate fallback games for dates outside the seeded ±5 day window
        let leagueTeams = teams.filter { $0.leagueID == leagueID }.sorted { $0.id < $1.id }
        guard leagueTeams.count >= 2 else { return [] }

        let dayOffset = calendar.dateComponents([.day], from: anchor, to: date).day ?? 0
        let maxCount = min(4, leagueTeams.count / 2)
        let range = scoreRange(for: leagueID)
        let span = max(1, range.high - range.low + 1)

        // Deterministically shuffle teams for this date
        let shuffled = leagueTeams.sorted { lhs, rhs in
            stableSeed("\(leagueID)_fallback\(dayOffset)_\(lhs.id)") < stableSeed("\(leagueID)_fallback\(dayOffset)_\(rhs.id)")
        }

        let isPast = date < anchor

        return (0..<maxCount).map { index in
            let away = shuffled[index * 2]
            let home = shuffled[index * 2 + 1]
            let normalizedDate = calendar.date(bySettingHour: 12 + (index * 2), minute: 0, second: 0, of: date) ?? date
            let status: GameStatus
            let homeScore: Int?
            let awayScore: Int?
            let seededID = "g_\(leagueID)_fb_\(DateFormatting.apiDate.string(from: date))_\(index)"
            let gameSeed = stableSeed(seededID)

            if isPast {
                status = leagueID == "epl"
                    ? GameStatus(state: .final, shortText: "FT", detailText: "Full Time", periodDescription: "Full Time")
                    : GameStatus(state: .final, shortText: "Final", detailText: "Final", periodDescription: "Final")
                awayScore = range.low + (stableSeed("\(seededID)_away") % span)
                homeScore = range.low + (stableSeed("\(seededID)_home") % span)
            } else {
                status = GameStatus(state: .upcoming, shortText: DateFormatting.gameTime.string(from: normalizedDate), detailText: "Scheduled", periodDescription: nil)
                awayScore = nil
                homeScore = nil
            }

            return Game(
                id: seededID,
                leagueID: leagueID,
                startDate: normalizedDate,
                homeTeam: home,
                awayTeam: away,
                homeScore: homeScore,
                awayScore: awayScore,
                status: status,
                venue: supplementalVenue(for: leagueID, home: home),
                headline: "\(away.shortName) at \(home.shortName)",
                homeLeaders: sportSpecificLeaders(leagueID: leagueID, seed: gameSeed, isHome: true),
                awayLeaders: sportSpecificLeaders(leagueID: leagueID, seed: gameSeed, isHome: false),
                homeTeamStats: sportSpecificStats(leagueID: leagueID, seed: gameSeed, isHome: true),
                awayTeamStats: sportSpecificStats(leagueID: leagueID, seed: gameSeed, isHome: false)
            )
        }
        .sorted { $0.startDate < $1.startDate }
    }
}
