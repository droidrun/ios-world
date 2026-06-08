import Foundation

enum SearchFilter: String, Codable, CaseIterable, Hashable {
    case all
    case messages
    case channels
    case people

    var label: String {
        switch self {
        case .all:
            return "All"
        case .messages:
            return "Messages"
        case .channels:
            return "Channels"
        case .people:
            return "People"
        }
    }
}
