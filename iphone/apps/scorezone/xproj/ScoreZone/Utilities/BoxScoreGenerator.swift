import Foundation

enum BoxScoreGenerator {

    // MARK: - Public

    static func generate(for game: Game) -> BoxScoreData {
        switch game.leagueID {
        case "nba":     return generateBasketball(for: game, periods: 4)
        case "ncaamb":  return generateBasketball(for: game, periods: 2)
        case "nfl", "ncaafb": return generateFootball(for: game)
        case "mlb":     return generateBaseball(for: game)
        case "nhl":     return generateHockey(for: game)
        case "epl":     return generateSoccer(for: game)
        default:        return generateBasketball(for: game, periods: 4)
        }
    }

    // MARK: - Seeded RNG

    private struct RNG {
        private var state: UInt64

        init(seed: Int) {
            state = UInt64(bitPattern: Int64(seed &* 2654435761 &+ 1))
            if state == 0 { state = 1 }
        }

        mutating func next() -> Int {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Int(Int64(bitPattern: state >> 33) & 0x7FFF_FFFF)
        }

        mutating func next(in range: ClosedRange<Int>) -> Int {
            let span = range.upperBound - range.lowerBound + 1
            guard span > 0 else { return range.lowerBound }
            return range.lowerBound + (next() % span)
        }
    }

    // MARK: - Name Pools

    private static let firstInitials = [
        "J", "M", "D", "C", "T", "A", "K", "B", "R", "S",
        "L", "N", "P", "E", "I", "O", "Z", "W", "G", "H",
        "F", "V", "X", "Y", "Q", "U"
    ]

    private static let lastNames = [
        "Williams", "Johnson", "Davis", "Brown", "Thompson",
        "Anderson", "Mitchell", "Harris", "Robinson", "Walker",
        "Turner", "Carter", "Allen", "Jackson", "Brooks",
        "Washington", "Powell", "Edwards", "Barnes", "Murray",
        "Grant", "Porter", "Green", "Young", "White",
        "Jones", "Butler", "Martin", "Clark", "Wright",
        "Adams", "Taylor", "King", "Scott", "Lee",
        "Hill", "Campbell", "Lewis", "Morris", "Moore",
        "Thomas", "Wilson", "Garcia", "Martinez", "Lopez",
        "Hernandez", "Gonzalez", "Rodriguez", "Perez", "Sanchez",
        "Ramirez", "Torres", "Flores", "Rivera", "Gomez",
        "Nelson", "Baker", "Hall", "Rivera", "Collins",
        "Stewart", "Murphy", "Cook", "Rogers", "Morgan",
        "Peterson", "Cooper", "Reed", "Bailey", "Bell",
        "Howard", "Ward", "Cox", "Diaz", "Richardson",
        "Wood", "Watson", "Bennett", "Gray", "James",
        "Reyes", "Cruz", "Hughes", "Price", "Myers",
        "Long", "Foster", "Sanders", "Ross", "Morales",
        "Sullivan", "Russell", "Ortiz", "Jenkins", "Gutierrez",
        "Perry", "Butler", "Simmons", "Alexander", "Hamilton"
    ]

    private static func playerName(seed: Int, index: Int) -> String {
        let s = abs(seed &+ index &* 7919)
        let initial = firstInitials[s % firstInitials.count]
        let last = lastNames[(s / 13) % lastNames.count]
        return "\(initial). \(last)"
    }

    // MARK: - Score Splitting

    private static func splitScore(total: Int, parts: Int, seed: Int) -> [Int] {
        guard parts > 0 else { return [] }
        var rng = RNG(seed: seed)
        let base = total / parts
        var scores = Array(repeating: base, count: parts)
        let remainder = total - base * parts
        for i in 0..<remainder {
            scores[i % parts] += 1
        }
        for i in 0..<(parts - 1) {
            let shift = rng.next(in: -4...4)
            let actual = min(abs(shift), max(0, scores[i] - 10), max(0, scores[i + 1] - 10))
            if shift > 0 {
                scores[i] += actual
                scores[i + 1] -= actual
            } else {
                scores[i] -= actual
                scores[i + 1] += actual
            }
        }
        let diff = total - scores.reduce(0, +)
        scores[0] += diff
        return scores
    }

    private static func stableSeed(_ value: String) -> Int {
        value.unicodeScalars.reduce(0) { partial, scalar in
            ((partial &* 33) &+ Int(scalar.value)) % 100_000
        }
    }

    // MARK: - Basketball (NBA / NCAAM)

    private static let basketballPositions = ["PG", "SG", "SF", "PF", "C"]
    private static let basketballColumns = ["MIN", "FG", "3PT", "FT", "OREB", "DREB", "REB", "AST", "STL", "BLK", "TO", "PF", "PTS"]

    private static func generateBasketball(for game: Game, periods: Int) -> BoxScoreData {
        let seed = stableSeed(game.id)
        let awayTotal = game.awayScore ?? 100
        let homeTotal = game.homeScore ?? 102

        let periodLabels: [String]
        if periods == 2 {
            periodLabels = ["1", "2", "T"]
        } else {
            periodLabels = ["1", "2", "3", "4", "T"]
        }

        let awayQ = splitScore(total: awayTotal, parts: periods, seed: seed)
        let homeQ = splitScore(total: homeTotal, parts: periods, seed: seed + 100)

        let starterCount = 5
        let benchCount = periods == 2 ? 5 : 8

        let awayPlayers = generateBasketballTeam(
            teamSeed: seed + 200,
            totalScore: awayTotal,
            starterCount: starterCount,
            benchCount: benchCount
        )
        let homePlayers = generateBasketballTeam(
            teamSeed: seed + 700,
            totalScore: homeTotal,
            starterCount: starterCount,
            benchCount: benchCount
        )

        let awayTotals = computeBasketballTotals(players: awayPlayers, totalScore: awayTotal)
        let homeTotals = computeBasketballTotals(players: homePlayers, totalScore: homeTotal)

        let awayTable = BoxScoreStatTable(
            id: "away_bb",
            title: "",
            statColumns: basketballColumns,
            players: awayPlayers,
            totals: awayTotals
        )
        let homeTable = BoxScoreStatTable(
            id: "home_bb",
            title: "",
            statColumns: basketballColumns,
            players: homePlayers,
            totals: homeTotals
        )

        return BoxScoreData(
            periodLabels: periodLabels,
            awayPeriodScores: awayQ + [awayTotal],
            homePeriodScores: homeQ + [homeTotal],
            awayTables: [awayTable],
            homeTables: [homeTable]
        )
    }

    private static func generateBasketballTeam(
        teamSeed: Int,
        totalScore: Int,
        starterCount: Int,
        benchCount: Int
    ) -> [PlayerBoxLine] {
        var rng = RNG(seed: teamSeed)
        let count = starterCount + benchCount

        // Distribute points
        let shares: [Double] = [0.25, 0.19, 0.16, 0.13, 0.10, 0.05, 0.04, 0.03, 0.02, 0.01, 0.01, 0.005, 0.005]
        var points = [Int](repeating: 0, count: count)
        var assigned = 0
        for i in 0..<count {
            let share = i < shares.count ? shares[i] : 0.005
            points[i] = max(0, Int(Double(totalScore) * share) + rng.next(in: -2...2))
            assigned += points[i]
        }
        points[0] += totalScore - assigned

        // Distribute minutes
        let totalMin = 240
        let minTemplates = [36, 34, 32, 30, 28, 22, 18, 14, 10, 8, 6, 5, 4]
        var minutes = [Int](repeating: 0, count: count)
        for i in 0..<count {
            minutes[i] = (i < minTemplates.count ? minTemplates[i] : 4) + rng.next(in: -2...2)
            minutes[i] = max(0, minutes[i])
        }
        let minSum = minutes.reduce(0, +)
        if minSum > 0 {
            let scale = Double(totalMin) / Double(minSum)
            for i in 0..<count {
                minutes[i] = Int(Double(minutes[i]) * scale)
            }
            minutes[0] += totalMin - minutes.reduce(0, +)
        }

        var players: [PlayerBoxLine] = []
        for i in 0..<count {
            let pos = basketballPositions[i % basketballPositions.count]
            let stats = basketballStatLine(points: points[i], minutes: minutes[i], position: pos, rng: &rng)
            players.append(PlayerBoxLine(
                id: "\(teamSeed)_\(i)",
                name: playerName(seed: teamSeed, index: i),
                jersey: "\(rng.next(in: 0...55))",
                position: pos,
                isStarter: i < starterCount,
                statValues: stats
            ))
        }
        return players
    }

    private static func basketballStatLine(points: Int, minutes: Int, position: String, rng: inout RNG) -> [String] {
        guard minutes > 0 else {
            return ["0", "0-0", "0-0", "0-0", "0", "0", "0", "0", "0", "0", "0", "0", "0"]
        }

        var remaining = points
        let ftMade = rng.next(in: 0...min(8, remaining))
        remaining -= ftMade
        let maxThrees = remaining / 3
        let threeMade = maxThrees > 0 ? rng.next(in: 0...min(6, maxThrees)) : 0
        remaining -= threeMade * 3
        let twoMade = remaining / 2
        let leftover = remaining % 2
        let finalFT = ftMade + leftover
        let ftAtt = finalFT + rng.next(in: 0...min(3, max(0, 10 - finalFT)))

        let fgMade = twoMade + threeMade
        let fgAtt = fgMade + rng.next(in: max(1, fgMade / 3)...max(3, fgMade + 3))
        let threeAtt = threeMade + rng.next(in: max(1, threeMade / 2)...max(2, threeMade + 3))

        let isCenter = position == "C" || position == "PF"
        let isPG = position == "PG"
        let oreb = rng.next(in: 0...(isCenter ? 4 : 2))
        let dreb = rng.next(in: 1...(isCenter ? 10 : 5))
        let ast = rng.next(in: 0...(isPG ? 10 : 4))
        let stl = rng.next(in: 0...3)
        let blk = rng.next(in: 0...(isCenter ? 4 : 2))
        let to = rng.next(in: 0...4)
        let pf = rng.next(in: 0...5)

        return [
            "\(minutes)",
            "\(fgMade)-\(fgAtt)",
            "\(threeMade)-\(threeAtt)",
            "\(finalFT)-\(ftAtt)",
            "\(oreb)", "\(dreb)", "\(oreb + dreb)",
            "\(ast)", "\(stl)", "\(blk)", "\(to)", "\(pf)",
            "\(points)"
        ]
    }

    private static func computeBasketballTotals(players: [PlayerBoxLine], totalScore: Int) -> [String] {
        var tm = 0, fgM = 0, fgA = 0, tM = 0, tA = 0, ftM = 0, ftA = 0
        var or_ = 0, dr = 0, rb = 0, ast = 0, stl = 0, blk = 0, to = 0, pf = 0
        for p in players {
            let v = p.statValues
            tm += Int(v[0]) ?? 0
            let fg = v[1].split(separator: "-").compactMap { Int($0) }
            fgM += fg.first ?? 0; fgA += fg.last ?? 0
            let t3 = v[2].split(separator: "-").compactMap { Int($0) }
            tM += t3.first ?? 0; tA += t3.last ?? 0
            let ft = v[3].split(separator: "-").compactMap { Int($0) }
            ftM += ft.first ?? 0; ftA += ft.last ?? 0
            or_ += Int(v[4]) ?? 0; dr += Int(v[5]) ?? 0; rb += Int(v[6]) ?? 0
            ast += Int(v[7]) ?? 0; stl += Int(v[8]) ?? 0; blk += Int(v[9]) ?? 0
            to += Int(v[10]) ?? 0; pf += Int(v[11]) ?? 0
        }
        return [
            "\(tm)", "\(fgM)-\(fgA)", "\(tM)-\(tA)", "\(ftM)-\(ftA)",
            "\(or_)", "\(dr)", "\(rb)",
            "\(ast)", "\(stl)", "\(blk)", "\(to)", "\(pf)",
            "\(totalScore)"
        ]
    }

    // MARK: - Football (NFL)

    private static func generateFootball(for game: Game) -> BoxScoreData {
        let seed = stableSeed(game.id)
        let awayTotal = game.awayScore ?? 21
        let homeTotal = game.homeScore ?? 24

        let awayQ = splitScore(total: awayTotal, parts: 4, seed: seed)
        let homeQ = splitScore(total: homeTotal, parts: 4, seed: seed + 100)

        func teamTables(tSeed: Int, total: Int, prefix: String) -> [BoxScoreStatTable] {
            var rng = RNG(seed: tSeed)
            let passYds = rng.next(in: 180...340)
            let comp = rng.next(in: 18...30)
            let att = comp + rng.next(in: 5...16)
            let passTD = rng.next(in: 0...4)
            let intc = rng.next(in: 0...2)
            let rating = Double(rng.next(in: 700...1580)) / 10.0

            let qb = PlayerBoxLine(
                id: "\(prefix)_qb", name: playerName(seed: tSeed, index: 0),
                jersey: "\(rng.next(in: 1...19))", position: "QB", isStarter: true,
                statValues: ["\(comp)/\(att)", "\(passYds)", "\(passTD)", "\(intc)", String(format: "%.1f", rating)]
            )

            let rb1Yds = rng.next(in: 40...120)
            let rb1Car = rng.next(in: 10...22)
            let rb1TD = rng.next(in: 0...2)
            let rb1 = PlayerBoxLine(
                id: "\(prefix)_rb1", name: playerName(seed: tSeed, index: 1),
                jersey: "\(rng.next(in: 20...35))", position: "RB", isStarter: true,
                statValues: ["\(rb1Car)", "\(rb1Yds)", String(format: "%.1f", Double(rb1Yds) / max(1.0, Double(rb1Car))), "\(rb1TD)", "\(rng.next(in: 8...35))"]
            )
            let rb2Yds = rng.next(in: 10...50)
            let rb2Car = rng.next(in: 3...10)
            let rb2 = PlayerBoxLine(
                id: "\(prefix)_rb2", name: playerName(seed: tSeed, index: 2),
                jersey: "\(rng.next(in: 25...40))", position: "RB", isStarter: false,
                statValues: ["\(rb2Car)", "\(rb2Yds)", String(format: "%.1f", Double(rb2Yds) / max(1.0, Double(rb2Car))), "\(rng.next(in: 0...1))", "\(rng.next(in: 4...20))"]
            )

            var receivers: [PlayerBoxLine] = []
            for i in 0..<4 {
                let pos = i < 3 ? "WR" : "TE"
                let rec = rng.next(in: 2...8)
                let yds = rng.next(in: 15...110)
                let td = rng.next(in: 0...1)
                receivers.append(PlayerBoxLine(
                    id: "\(prefix)_wr\(i)", name: playerName(seed: tSeed, index: 3 + i),
                    jersey: "\(rng.next(in: 10...89))", position: pos, isStarter: i < 3,
                    statValues: ["\(rec)", "\(yds)", String(format: "%.1f", Double(yds) / max(1.0, Double(rec))), "\(td)", "\(rng.next(in: 8...45))"]
                ))
            }

            return [
                BoxScoreStatTable(id: "\(prefix)_pass", title: "PASSING", statColumns: ["C/ATT", "YDS", "TD", "INT", "RTG"], players: [qb], totals: nil),
                BoxScoreStatTable(id: "\(prefix)_rush", title: "RUSHING", statColumns: ["CAR", "YDS", "AVG", "TD", "LNG"], players: [rb1, rb2], totals: nil),
                BoxScoreStatTable(id: "\(prefix)_rec", title: "RECEIVING", statColumns: ["REC", "YDS", "AVG", "TD", "LNG"], players: receivers, totals: nil)
            ]
        }

        return BoxScoreData(
            periodLabels: ["1", "2", "3", "4", "T"],
            awayPeriodScores: awayQ + [awayTotal],
            homePeriodScores: homeQ + [homeTotal],
            awayTables: teamTables(tSeed: seed + 200, total: awayTotal, prefix: "a"),
            homeTables: teamTables(tSeed: seed + 700, total: homeTotal, prefix: "h")
        )
    }

    // MARK: - Baseball (MLB)

    private static let battingPositions = ["C", "1B", "2B", "SS", "3B", "LF", "CF", "RF", "DH"]

    private static func generateBaseball(for game: Game) -> BoxScoreData {
        let seed = stableSeed(game.id)
        let awayTotal = game.awayScore ?? 4
        let homeTotal = game.homeScore ?? 5

        let awayInnings = splitScore(total: awayTotal, parts: 9, seed: seed)
        let homeInnings = splitScore(total: homeTotal, parts: 9, seed: seed + 100)

        func teamTables(tSeed: Int, totalRuns: Int, prefix: String) -> [BoxScoreStatTable] {
            var rng = RNG(seed: tSeed)
            var totalH = 0
            var batters: [PlayerBoxLine] = []
            for i in 0..<9 {
                let pos = battingPositions[i]
                let ab = rng.next(in: 3...5)
                let h = rng.next(in: 0...min(ab, 3))
                let r = rng.next(in: 0...min(2, h))
                let rbi = rng.next(in: 0...min(3, h))
                let bb = rng.next(in: 0...2)
                let so = rng.next(in: 0...min(ab, 3))
                let avg = ab > 0 ? String(format: ".%03d", min(999, rng.next(in: 180...340))) : ".000"
                totalH += h
                batters.append(PlayerBoxLine(
                    id: "\(prefix)_b\(i)", name: playerName(seed: tSeed, index: i),
                    jersey: "\(rng.next(in: 1...55))", position: pos, isStarter: true,
                    statValues: ["\(ab)", "\(r)", "\(h)", "\(rbi)", "\(bb)", "\(so)", avg]
                ))
            }

            let sp = PlayerBoxLine(
                id: "\(prefix)_sp", name: playerName(seed: tSeed, index: 10),
                jersey: "\(rng.next(in: 30...65))", position: "SP", isStarter: true,
                statValues: [
                    "\(rng.next(in: 5...7)).\(rng.next(in: 0...2))",
                    "\(rng.next(in: 3...8))", "\(rng.next(in: 1...4))", "\(rng.next(in: 1...3))",
                    "\(rng.next(in: 1...4))", "\(rng.next(in: 4...10))",
                    String(format: "%.2f", Double(rng.next(in: 250...450)) / 100.0)
                ]
            )
            var relievers: [PlayerBoxLine] = []
            for i in 0..<2 {
                relievers.append(PlayerBoxLine(
                    id: "\(prefix)_rp\(i)", name: playerName(seed: tSeed, index: 11 + i),
                    jersey: "\(rng.next(in: 40...75))", position: "RP", isStarter: false,
                    statValues: [
                        "\(rng.next(in: 1...2)).\(rng.next(in: 0...2))",
                        "\(rng.next(in: 0...3))", "\(rng.next(in: 0...2))", "\(rng.next(in: 0...2))",
                        "\(rng.next(in: 0...2))", "\(rng.next(in: 1...4))",
                        String(format: "%.2f", Double(rng.next(in: 0...500)) / 100.0)
                    ]
                ))
            }

            let battingTotals = ["\(batters.reduce(0) { $0 + (Int($1.statValues[0]) ?? 0) })", "\(totalRuns)", "\(totalH)", "", "", "", ""]

            return [
                BoxScoreStatTable(id: "\(prefix)_bat", title: "BATTING", statColumns: ["AB", "R", "H", "RBI", "BB", "SO", "AVG"], players: batters, totals: battingTotals),
                BoxScoreStatTable(id: "\(prefix)_pit", title: "PITCHING", statColumns: ["IP", "H", "R", "ER", "BB", "SO", "ERA"], players: [sp] + relievers, totals: nil)
            ]
        }

        var awayRHE = awayInnings
        let awayH = 4 + (seed % 8)
        let awayE = seed % 3
        awayRHE += [awayTotal, awayH, awayE]

        var homeRHE = homeInnings
        let homeH = 5 + ((seed + 7) % 7)
        let homeE = (seed + 3) % 3
        homeRHE += [homeTotal, homeH, homeE]

        return BoxScoreData(
            periodLabels: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "R", "H", "E"],
            awayPeriodScores: awayRHE,
            homePeriodScores: homeRHE,
            awayTables: teamTables(tSeed: seed + 200, totalRuns: awayTotal, prefix: "a"),
            homeTables: teamTables(tSeed: seed + 700, totalRuns: homeTotal, prefix: "h")
        )
    }

    // MARK: - Hockey (NHL)

    private static let hockeyPositions = ["C", "LW", "RW", "D", "D", "C", "LW", "RW", "D", "D", "C", "LW", "RW", "D", "G"]
    private static let hockeyColumns = ["G", "A", "+/-", "SOG", "PIM", "HIT", "BLK", "TOI"]

    private static func generateHockey(for game: Game) -> BoxScoreData {
        let seed = stableSeed(game.id)
        let awayTotal = game.awayScore ?? 2
        let homeTotal = game.homeScore ?? 3

        let awayP = splitScore(total: awayTotal, parts: 3, seed: seed)
        let homeP = splitScore(total: homeTotal, parts: 3, seed: seed + 100)

        func teamTable(tSeed: Int, totalGoals: Int, prefix: String) -> [BoxScoreStatTable] {
            var rng = RNG(seed: tSeed)
            var goalsLeft = totalGoals
            var players: [PlayerBoxLine] = []
            let count = 15

            for i in 0..<count {
                let pos = hockeyPositions[i % hockeyPositions.count]
                let isGoalie = pos == "G"
                let g: Int
                if isGoalie {
                    g = 0
                } else if goalsLeft > 0 && rng.next(in: 0...3) == 0 {
                    g = 1; goalsLeft -= 1
                } else {
                    g = 0
                }
                let a = isGoalie ? 0 : rng.next(in: 0...1)
                let pm = isGoalie ? 0 : rng.next(in: -2...3)
                let sog = isGoalie ? 0 : rng.next(in: 0...5)
                let pim = rng.next(in: 0...4) == 0 ? 2 : 0
                let hit = isGoalie ? 0 : rng.next(in: 0...4)
                let blk = isGoalie ? 0 : rng.next(in: 0...3)
                let toiMin = isGoalie ? rng.next(in: 55...60) : (i < 6 ? rng.next(in: 16...22) : rng.next(in: 10...16))
                let toiSec = rng.next(in: 0...59)

                players.append(PlayerBoxLine(
                    id: "\(prefix)_\(i)", name: playerName(seed: tSeed, index: i),
                    jersey: "\(rng.next(in: 1...91))", position: pos, isStarter: i < 6,
                    statValues: [
                        "\(g)", "\(a)", pm >= 0 ? "+\(pm)" : "\(pm)",
                        "\(sog)", "\(pim)", "\(hit)", "\(blk)",
                        "\(toiMin):\(String(format: "%02d", toiSec))"
                    ]
                ))
            }

            // ensure all goals assigned
            if goalsLeft > 0 {
                for i in 0..<min(goalsLeft, players.count) where players[i].position != "G" {
                    var vals = players[i].statValues
                    vals[0] = "\((Int(vals[0]) ?? 0) + 1)"
                    players[i] = PlayerBoxLine(
                        id: players[i].id, name: players[i].name,
                        jersey: players[i].jersey, position: players[i].position,
                        isStarter: players[i].isStarter, statValues: vals
                    )
                }
            }

            return [BoxScoreStatTable(
                id: "\(prefix)_hockey", title: "",
                statColumns: hockeyColumns, players: players, totals: nil
            )]
        }

        return BoxScoreData(
            periodLabels: ["1", "2", "3", "T"],
            awayPeriodScores: awayP + [awayTotal],
            homePeriodScores: homeP + [homeTotal],
            awayTables: teamTable(tSeed: seed + 200, totalGoals: awayTotal, prefix: "a"),
            homeTables: teamTable(tSeed: seed + 700, totalGoals: homeTotal, prefix: "h")
        )
    }

    // MARK: - Soccer (EPL)

    private static let soccerPositions = ["GK", "DEF", "DEF", "DEF", "DEF", "MID", "MID", "MID", "FWD", "FWD", "FWD"]
    private static let soccerColumns = ["G", "A", "SH", "SOG", "FK", "OF", "CK"]

    private static func generateSoccer(for game: Game) -> BoxScoreData {
        let seed = stableSeed(game.id)
        let awayTotal = game.awayScore ?? 1
        let homeTotal = game.homeScore ?? 1

        let awayH = splitScore(total: awayTotal, parts: 2, seed: seed)
        let homeH = splitScore(total: homeTotal, parts: 2, seed: seed + 100)

        func teamTable(tSeed: Int, totalGoals: Int, prefix: String) -> [BoxScoreStatTable] {
            var rng = RNG(seed: tSeed)
            var goalsLeft = totalGoals
            var players: [PlayerBoxLine] = []

            for i in 0..<11 {
                let pos = soccerPositions[i]
                let isKeeper = pos == "GK"
                let isFwd = pos == "FWD"
                let g: Int
                if isKeeper {
                    g = 0
                } else if goalsLeft > 0 && (isFwd ? rng.next(in: 0...2) == 0 : rng.next(in: 0...5) == 0) {
                    g = 1; goalsLeft -= 1
                } else {
                    g = 0
                }
                let a = isKeeper ? 0 : rng.next(in: 0...1)
                let sh = isKeeper ? 0 : rng.next(in: 0...(isFwd ? 5 : 2))
                let sog = min(sh, rng.next(in: 0...max(1, sh)))
                let fk = rng.next(in: 0...3)
                let of = isKeeper ? 0 : rng.next(in: 0...1)
                let ck = rng.next(in: 0...2)

                players.append(PlayerBoxLine(
                    id: "\(prefix)_\(i)", name: playerName(seed: tSeed, index: i),
                    jersey: "\(rng.next(in: 1...30))", position: pos, isStarter: true,
                    statValues: ["\(g)", "\(a)", "\(sh)", "\(sog)", "\(fk)", "\(of)", "\(ck)"]
                ))
            }

            if goalsLeft > 0 {
                for i in (8..<11) where goalsLeft > 0 {
                    var vals = players[i].statValues
                    vals[0] = "\((Int(vals[0]) ?? 0) + 1)"
                    vals[2] = "\((Int(vals[2]) ?? 0) + 1)"
                    vals[3] = "\((Int(vals[3]) ?? 0) + 1)"
                    players[i] = PlayerBoxLine(
                        id: players[i].id, name: players[i].name,
                        jersey: players[i].jersey, position: players[i].position,
                        isStarter: true, statValues: vals
                    )
                    goalsLeft -= 1
                }
            }

            return [BoxScoreStatTable(
                id: "\(prefix)_soc", title: "",
                statColumns: soccerColumns, players: players, totals: nil
            )]
        }

        return BoxScoreData(
            periodLabels: ["1H", "2H", "T"],
            awayPeriodScores: awayH + [awayTotal],
            homePeriodScores: homeH + [homeTotal],
            awayTables: teamTable(tSeed: seed + 200, totalGoals: awayTotal, prefix: "a"),
            homeTables: teamTable(tSeed: seed + 700, totalGoals: homeTotal, prefix: "h")
        )
    }
}
