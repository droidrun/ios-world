import Foundation

enum PresenceState: String, Codable, CaseIterable, Hashable {
    case active
    case away
    case doNotDisturb
    case offline

    var label: String {
        switch self {
        case .active:
            return "Active"
        case .away:
            return "Away"
        case .doNotDisturb:
            return "Do Not Disturb"
        case .offline:
            return "Offline"
        }
    }
}
