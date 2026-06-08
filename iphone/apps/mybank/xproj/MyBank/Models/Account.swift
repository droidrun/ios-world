import Foundation

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking
    case savings
    case credit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .credit: return "Credit"
        }
    }
}

struct Account: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var availableBalance: Double
    var currency: String
    var lastUpdated: Date
    var creditLimit: Double?
}
