import Foundation

struct Message: Identifiable, Codable, Hashable {
    var id: String
    var senderId: String
    var messageText: String
    var timestamp: Date
    var editedAt: Date?
    var senderDisplayName: String
    var replyCount: Int
    var reactions: [Reaction]
    var attachments: [MessageAttachment]
    var threadReplies: [ThreadReply]
    var mentionUserIds: [String]
    var isUnread: Bool
}

extension Message {
    var previewText: String {
        if messageText.isEmpty == false {
            return messageText
        }
        if attachments.count == 1, let attachment = attachments.first {
            return "Shared \(attachment.title)"
        }
        if attachments.isEmpty == false {
            return "Shared \(attachments.count) attachments"
        }
        return "No message text"
    }
}
