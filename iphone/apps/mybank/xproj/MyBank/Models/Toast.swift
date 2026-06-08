import Foundation

struct Toast: Identifiable, Equatable {
    enum Style {
        case success
        case error
        case info
    }

    var id = UUID()
    var message: String
    var style: Style
}
