import Foundation

struct League: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let sportSlug: String
    let leagueSlug: String
    let iconSystemName: String

    var accessibilitySlug: String {
        AccessibilityID.slug(id)
    }
}
