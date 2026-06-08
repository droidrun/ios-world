import Foundation

enum TransactionStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case posted
    case disputed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .posted: return "Posted"
        case .disputed: return "Disputed"
        }
    }
}

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID
    var externalId: String
    var accountId: UUID
    var vendor: String
    var amount: Double
    var currency: String
    var category: String
    var note: String?
    var timestamp: Date
    var status: TransactionStatus
    var sourceApp: String
    var rawSource: String

    enum CodingKeys: String, CodingKey {
        case id
        case externalId = "external_id"
        case accountId = "account_id"
        case vendor
        case amount
        case currency
        case category
        case note
        case timestamp
        case status
        case sourceApp = "source_app"
        case rawSource = "raw_source"
    }
}
