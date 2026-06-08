import Foundation

enum GameState: String, Codable {
    case live
    case upcoming
    case final
    case postponed
}

struct GameStatus: Codable, Hashable {
    let state: GameState
    let shortText: String
    let detailText: String
    let periodDescription: String?

    var isLive: Bool { state == .live }
    var isFinal: Bool { state == .final }
    var isUpcoming: Bool { state == .upcoming }
}

struct Game: Identifiable, Codable, Hashable {
    let id: String
    let leagueID: String
    let startDate: Date
    let homeTeam: Team
    let awayTeam: Team
    let homeScore: Int?
    let awayScore: Int?
    let status: GameStatus
    let venue: String?
    let headline: String?
    let homeLeaders: [String]
    let awayLeaders: [String]
    let homeTeamStats: [String]
    let awayTeamStats: [String]
    var apiBoxScore: BoxScoreData?
    var apiPlays: [PlayByPlayEvent]?

    var sortDate: Date { startDate }

    var matchupTitle: String {
        "\(awayTeam.abbreviation) @ \(homeTeam.abbreviation)"
    }

    var accessibilityRowID: String {
        let away = AccessibilityID.slug(awayTeam.nickname)
        let home = AccessibilityID.slug(homeTeam.nickname)
        return "scores_game_row_\(AccessibilityID.slug(leagueID))_\(away)_\(home)"
    }
}
