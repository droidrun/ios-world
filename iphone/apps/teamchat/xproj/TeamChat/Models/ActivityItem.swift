import Foundation

enum ActivityType: String, Codable, CaseIterable, Hashable {
    case all
    case mentions
    case threads
    case reactions
    case unreads
    case saved

    var label: String {
        switch self {
        case .all:
            return "All"
        case .mentions:
            return "Mentions"
        case .threads:
            return "Threads"
        case .reactions:
            return "Reactions"
        case .unreads:
            return "Unreads"
        case .saved:
            return "Saved"
        }
    }
}

struct ActivityItem: Identifiable, Codable, Hashable {
    var id: String
    var type: ActivityType
    var title: String
    var subtitle: String
    var channelOrDMName: String
    var timestamp: Date
    var channelId: String?
    var dmId: String?
    var messageId: String?
    var isUnread: Bool
}
