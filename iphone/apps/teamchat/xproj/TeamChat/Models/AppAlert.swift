import Foundation

struct AppAlert: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var message: String
    var confirmButtonTitle: String
}
