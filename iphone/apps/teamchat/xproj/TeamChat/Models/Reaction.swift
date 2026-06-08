import Foundation

struct Reaction: Identifiable, Codable, Hashable {
    var id: String {
        reactionEmoji
    }

    var reactionEmoji: String
    var userIds: [String]
    var reactionCount: Int

    mutating func syncCount() {
        reactionCount = userIds.count
    }
}
