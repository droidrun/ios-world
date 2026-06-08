import Foundation

struct NotificationPreference: Codable, Hashable {
    var pushEnabled: Bool
    var mentionOnly: Bool
    var threadRepliesEnabled: Bool
    var huddleInvitesEnabled: Bool
}
