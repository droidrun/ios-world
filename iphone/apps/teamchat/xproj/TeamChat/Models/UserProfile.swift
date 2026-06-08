import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var username: String
    var title: String
    var role: String
    var statusText: String
    var presenceState: PresenceState
    var notificationPreference: NotificationPreference
}
