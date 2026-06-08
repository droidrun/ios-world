import Foundation

struct StandingEntry: Identifiable, Codable, Hashable {
    let id: String
    let leagueID: String
    let conference: String
    let division: String?
    let rank: Int
    let team: Team
    let wins: Int
    let losses: Int
    let draws: Int
    let gamesBack: Double?

    var recordText: String {
        if draws > 0 {
            return "\(wins)-\(losses)-\(draws)"
        }
        return "\(wins)-\(losses)"
    }
}
