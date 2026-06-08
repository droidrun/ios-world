import Foundation

struct DMConversation: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var participantIds: [String]
    var isGroup: Bool
    var isMuted: Bool
    var unreadCount: Int
    var mentionCount: Int
    var messages: [Message]
    var lastMessagePreview: String
    var lastMessageAt: Date
}
