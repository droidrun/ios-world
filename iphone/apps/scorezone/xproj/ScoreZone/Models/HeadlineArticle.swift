import Foundation

struct HeadlineArticle: Identifiable, Codable, Hashable {
    let id: String
    let headline: String
    let summary: String
    let imageURL: String?
    let publishedAt: Date
    let leagueID: String?
    let sectionTag: String

    var imageAssetName: String {
        "headline_image_\(id)"
    }
}
