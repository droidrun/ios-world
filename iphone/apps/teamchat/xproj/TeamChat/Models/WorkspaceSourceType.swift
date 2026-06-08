import Foundation

enum WorkspaceSourceType: String, Codable, CaseIterable, Hashable {
    case seeded
    case snapshot

    var label: String {
        switch self {
        case .seeded:
            return "Default Data"
        case .snapshot:
            return "Workspace Data"
        }
    }
}
