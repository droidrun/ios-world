import Foundation

struct LockedInMessage: Identifiable, Codable, Hashable {
    var id: String
    var senderId: String
    var content: String
    var timestamp: Date
    var isFromCurrentUser: Bool
}

struct Conversation: Identifiable, Codable, Hashable {
    var id: String
    var participantName: String
    var participantInitials: String
    var participantAvatarTopHex: String
    var participantAvatarBottomHex: String
    var participantHeadline: String
    var messages: [LockedInMessage]
    var isActive: Bool
    var isInMail: Bool
    var isSponsored: Bool
    var unreadCount: Int

    var lastMessage: LockedInMessage? { messages.last }
    var lastMessagePreview: String {
        guard let msg = lastMessage else { return "" }
        if msg.isFromCurrentUser {
            return "You: \(msg.content)"
        }
        return msg.content
    }
    var lastMessageTimeAgo: String {
        guard let msg = lastMessage else { return "" }
        return msg.timestamp.linkedInMessageTime()
    }
}

enum MessageFilter: String, CaseIterable, Identifiable {
    case focused = "Focused"
    case jobs = "Jobs"
    case unread = "Unread"
    case drafts = "Drafts"
    case inMail = "InMail"

    var id: String { rawValue }
}

extension Date {
    func linkedInMessageTime() -> String {
        let cal = Calendar.current
        let now = Date()

        if cal.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: self)
        }

        if cal.isDateInYesterday(self) {
            return "Yesterday"
        }

        let days = cal.dateComponents([.day], from: self, to: now).day ?? 0
        if days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: self)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
