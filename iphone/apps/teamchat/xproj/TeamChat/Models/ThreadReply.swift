import Foundation

struct ThreadReply: Identifiable, Codable, Hashable {
    var id: String
    var parentMessageId: String
    var senderId: String
    var messageText: String
    var timestamp: Date
    var editedAt: Date?
    var reactions: [Reaction]
    var attachments: [MessageAttachment]
}
