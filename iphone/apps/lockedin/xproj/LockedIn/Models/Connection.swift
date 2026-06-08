import Foundation

struct Connection: Identifiable, Codable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var headline: String
    var avatarInitials: String
    var avatarTopHex: String
    var avatarBottomHex: String
    var degree: ConnectionDegree
    var mutualConnections: Int
    var isFollowing: Bool
    var company: String
    var location: String

    var fullName: String { "\(firstName) \(lastName)" }
}

struct ConnectionInvitation: Identifiable, Codable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var headline: String
    var avatarInitials: String
    var avatarTopHex: String
    var avatarBottomHex: String
    var mutualConnections: Int
    var timeAgo: String
    var isFollower: Bool
    var note: String?

    var fullName: String { "\(firstName) \(lastName)" }
}
