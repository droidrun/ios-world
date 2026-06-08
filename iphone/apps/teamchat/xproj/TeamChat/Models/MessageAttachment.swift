import Foundation

enum AttachmentType: String, Codable, CaseIterable, Hashable {
    case image
    case pdf
    case link
}

struct MessageAttachment: Identifiable, Codable, Hashable {
    var id: String
    var attachmentType: AttachmentType
    var title: String
    var subtitle: String
    var localPath: String
}
