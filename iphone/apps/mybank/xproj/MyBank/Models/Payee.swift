import Foundation

struct Payee: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: String
}
