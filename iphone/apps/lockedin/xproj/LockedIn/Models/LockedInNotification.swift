import Foundation

struct LockedInNotification: Identifiable, Codable, Hashable {
    var id: String
    var type: NotificationType
    var actorName: String
    var actorInitials: String
    var actorAvatarTopHex: String
    var actorAvatarBottomHex: String
    var message: String
    var timeAgo: String
    var isRead: Bool
    var isCompanyNotification: Bool
    var companyLogoInitials: String?
    var reactionCount: Int?
    var commentCount: Int?
    var actionLabel: String?
    var relatedPostId: String?
}
