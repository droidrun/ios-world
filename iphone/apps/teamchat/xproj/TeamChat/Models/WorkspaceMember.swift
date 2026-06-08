import Foundation

struct WorkspaceMember: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var username: String
    var title: String
    var role: String
    var presenceState: PresenceState
    var isCurrentUser: Bool
}
