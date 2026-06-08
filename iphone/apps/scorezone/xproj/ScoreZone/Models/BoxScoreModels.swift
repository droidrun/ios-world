import Foundation

struct PlayerBoxLine: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let jersey: String
    let position: String
    let isStarter: Bool
    let statValues: [String]
}

struct BoxScoreStatTable: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let statColumns: [String]
    let players: [PlayerBoxLine]
    let totals: [String]?
}

struct BoxScoreData: Codable, Hashable {
    let periodLabels: [String]
    let awayPeriodScores: [Int]
    let homePeriodScores: [Int]
    let awayTables: [BoxScoreStatTable]
    let homeTables: [BoxScoreStatTable]
}

struct PlayByPlayEvent: Identifiable, Codable, Hashable {
    let id: String
    let clock: String
    let period: String
    let text: String
    let isScoringPlay: Bool
    let awayScore: Int?
    let homeScore: Int?
}
