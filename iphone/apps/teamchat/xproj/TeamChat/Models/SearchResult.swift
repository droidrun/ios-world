import Foundation

enum SearchResultType: String, Codable, CaseIterable, Hashable {
    case messages
    case channels
    case people
}

struct SearchResult: Identifiable, Codable, Hashable {
    var id: String
    var type: SearchResultType
    var title: String
    var searchSnippet: String
    var sender: String
    var contextName: String
    var timestamp: Date?
    var isUnread: Bool
    var channelId: String?
    var dmId: String?
    var messageId: String?
    var memberId: String?
}
