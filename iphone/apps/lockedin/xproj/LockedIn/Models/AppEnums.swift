import Foundation

enum AppTab: String, Hashable {
    case home
    case myNetwork
    case post
    case notifications
    case jobs
}

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case jobs = "Jobs"
    case myPosts = "My posts"
    case mentions = "Mentions"

    var id: String { rawValue }
}

enum NetworkTab: String, CaseIterable, Identifiable {
    case grow = "Grow"
    case catchUp = "Catch up"

    var id: String { rawValue }
}

enum ConnectionDegree: String, Codable, Hashable {
    case first = "1st"
    case second = "2nd"
    case third = "3rd"
}

enum PostReactionType: String, Codable, Hashable, CaseIterable {
    case like
    case celebrate
    case support
    case love
    case insightful
    case funny

    var emoji: String {
        switch self {
        case .like: return "👍"
        case .celebrate: return "🎉"
        case .support: return "🙌"
        case .love: return "❤️"
        case .insightful: return "💡"
        case .funny: return "😂"
        }
    }

    var label: String {
        switch self {
        case .like: return "Like"
        case .celebrate: return "Celebrate"
        case .support: return "Support"
        case .love: return "Love"
        case .insightful: return "Insightful"
        case .funny: return "Funny"
        }
    }

    var sfSymbol: String {
        switch self {
        case .like: return "hand.thumbsup.fill"
        case .celebrate: return "hands.clap.fill"
        case .support: return "heart.fill"
        case .love: return "heart.fill"
        case .insightful: return "lightbulb.fill"
        case .funny: return "face.smiling.inverse"
        }
    }

    var iconColor: String {
        switch self {
        case .like: return "0x0A66C2"
        case .celebrate: return "0x44712E"
        case .support: return "0x7B3B99"
        case .love: return "0xDF704D"
        case .insightful: return "0xD4A017"
        case .funny: return "0x44712E"
        }
    }
}

enum NotificationType: String, Codable, Hashable {
    case connectionAccepted
    case postReaction
    case postComment
    case profileView
    case jobAlert
    case mention
    case postShared
    case workAnniversary
    case birthday
    case connectionRequest
}

enum JobLocationType: String, Codable, Hashable {
    case onSite = "On-site"
    case remote = "Remote"
    case hybrid = "Hybrid"
}

enum JobEmploymentType: String, Codable, Hashable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case contract = "Contract"
    case internship = "Internship"
}
