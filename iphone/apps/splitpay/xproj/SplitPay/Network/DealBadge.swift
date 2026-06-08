import SwiftUI

enum DealBadge: String {
    case amazing = "Amazing"
    case great = "Great"
    case good = "Good"
    case standard = "Standard"

    static func badge(for score: Int) -> DealBadge {
        switch score {
        case 90...:
            return .amazing
        case 80..<90:
            return .great
        case 70..<80:
            return .good
        default:
            return .standard
        }
    }

    var color: Color {
        switch self {
        case .amazing:
            return Color(red: 0.22, green: 0.69, blue: 0.36)
        case .great:
            return Color(red: 0.18, green: 0.58, blue: 0.90)
        case .good:
            return Color(red: 0.96, green: 0.62, blue: 0.16)
        case .standard:
            return Color.gray
        }
    }
}
