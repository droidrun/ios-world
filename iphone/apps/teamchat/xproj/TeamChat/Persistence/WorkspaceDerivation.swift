import Foundation

extension Workspace {
    mutating func recalculateDerivedFields() {
        channels = channels.map { channel in
            var updated = channel
            updated.unreadCount = channel.messages.filter(\.isUnread).count
            updated.mentionCount = channel.messages.filter { $0.isUnread && $0.mentionUserIds.contains(currentUserId) }.count
            if let latest = channel.messages.max(by: { $0.timestamp < $1.timestamp }) {
                updated.lastMessageAt = latest.timestamp
                updated.lastMessagePreview = latest.previewText
            }
            return updated
        }

        dmConversations = dmConversations.map { dm in
            var updated = dm
            updated.unreadCount = dm.messages.filter(\.isUnread).count
            updated.mentionCount = dm.messages.filter { $0.isUnread && $0.mentionUserIds.contains(currentUserId) }.count
            if let latest = dm.messages.max(by: { $0.timestamp < $1.timestamp }) {
                updated.lastMessageAt = latest.timestamp
                updated.lastMessagePreview = latest.previewText
            }
            return updated
        }

        let latestTimestamp = (channels.flatMap(\.messages) + dmConversations.flatMap(\.messages))
            .map(\.timestamp)
            .max()
        lastUpdated = latestTimestamp ?? lastUpdated
    }

    mutating func ensureNextSequence() {
        let maxMessage = (channels.flatMap(\.messages) + dmConversations.flatMap(\.messages))
            .compactMap { message in
                Int(message.id.replacingOccurrences(of: "msg_", with: ""))
            }
            .max() ?? 0
        if nextMessageSequence <= maxMessage {
            nextMessageSequence = maxMessage + 1
        }
    }

    mutating func nextMessageId() -> String {
        ensureNextSequence()
        defer { nextMessageSequence += 1 }
        return String(format: "msg_%03d", nextMessageSequence)
    }
}
