import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let username: String
    let displayName: String
    let avatarSeed: String
    let isYou: Bool
}

enum TransactionPrivacy: String, Codable, CaseIterable {
    case `public` = "Public"
    case friends = "Friends"
    case `private` = "Private"
}

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    let fromUserID: String
    let toUserID: String
    let amount: Double
    let memo: String
    let timestamp: Date
    let privacy: TransactionPrivacy
    let fundingSourceID: String
}

struct FundingSource: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let isBalance: Bool
}

struct PaymentDraft: Codable, Hashable {
    var recipientID: String?
    var amountText: String
    var memo: String
    var privacy: TransactionPrivacy
    var fundingSourceID: String

    static func empty(defaultPrivacy: TransactionPrivacy, fundingSourceID: String) -> PaymentDraft {
        PaymentDraft(recipientID: nil, amountText: "", memo: "", privacy: defaultPrivacy, fundingSourceID: fundingSourceID)
    }
}

enum RequestStatus: String, Codable {
    case pending
    case paid
    case declined
    case canceled
}

struct Request: Identifiable, Codable, Hashable {
    let id: UUID
    let fromUserID: String
    let toUserID: String
    let amount: Double
    let memo: String
    let timestamp: Date
    let privacy: TransactionPrivacy
    var status: RequestStatus
}

enum FeedFilter: String, CaseIterable, Codable {
    case all = "All"
    case friends = "Friends"
    case me = "Me"
}

struct SettingsState: Codable, Hashable {
    var defaultPrivacy: TransactionPrivacy
    var showSignedAmounts: Bool
    var requireConfirmation: Bool

    static let `default` = SettingsState(
        defaultPrivacy: .friends,
        showSignedAmounts: true,
        requireConfirmation: true
    )
}

struct FriendGraph: Codable, Hashable {
    var friendIDs: Set<String>
}

struct FilterState: Codable, Hashable {
    var feedFilter: FeedFilter
    var searchQuery: String
}
