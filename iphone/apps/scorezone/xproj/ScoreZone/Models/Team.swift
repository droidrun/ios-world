import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let abbreviation: String
    let city: String
    let nickname: String
    let leagueID: String
    let conference: String?
    let division: String?
    let apiTeamID: String?

    var displayName: String {
        "\(city) \(nickname)"
    }

    var logoAssetName: String {
        "team_logo_\(id)"
    }

    var searchableTokens: [String] {
        [
            name,
            shortName,
            abbreviation,
            city,
            nickname,
            leagueID
        ]
    }
}
