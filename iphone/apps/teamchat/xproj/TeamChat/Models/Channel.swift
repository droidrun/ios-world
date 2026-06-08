import Foundation

struct ChannelBookmark: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let type: String // "canvas", "link", "workflow"
}

struct Channel: Identifiable, Codable, Hashable {
    var id: String
    var channelName: String
    var descriptionTopic: String
    var isPrivate: Bool
    var notifyOnAllMessages: Bool
    var isMuted: Bool
    var isStarred: Bool
    var unreadCount: Int
    var mentionCount: Int
    var memberIds: [String]
    var messages: [Message]
    var pinnedItemsPlaceholderCount: Int
    var filesPlaceholderCount: Int
    var linksPlaceholderCount: Int
    var lastMessagePreview: String
    var lastMessageAt: Date
    var bookmarks: [ChannelBookmark]

    var displayName: String {
        "#\(channelName)"
    }
}
