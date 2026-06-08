import SwiftUI
import UIKit

struct HeadlineThumbnailView: View {
    let article: HeadlineArticle
    var height: CGFloat = 138

    var body: some View {
        Group {
            if UIImage(named: article.imageAssetName) != nil {
                Image(article.imageAssetName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }
        // SwiftUI clip trick: force the view to accept the parent's width first
        // (.frame(width: 0) proposes a zero width which an oversized scaledToFill
        // image must respect), then expand to the parent's max width so the
        // clipped() below actually constrains the rendered overflow.
        .frame(width: 0)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fallbackImage: some View {
        Group {
            if let name = fallbackAssetName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
    }

    private var fallbackAssetName: String? {
        let leagueBuckets: [String: [Int]] = [
            "nba": [1, 7, 9, 12, 14],
            "nfl": [2, 10, 15, 17],
            "mlb": [3, 11, 18],
            "nhl": [4, 13, 20],
            "ncaamb": [5, 16],
            "ncaafb": [19],
            "epl": [6, 8]
        ]
        let pool = article.leagueID.flatMap { leagueBuckets[$0] } ?? Array(1...20)
        guard !pool.isEmpty else { return nil }
        var hash: UInt64 = 14695981039346656037
        for byte in article.id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let idx = Int(hash % UInt64(pool.count))
        return String(format: "headline_image_headline_%03d", pool[idx])
    }

    private var placeholder: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.18, blue: 0.30), Color(red: 0.07, green: 0.08, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(article.sectionTag.uppercased())
                .font(.caption.weight(.black))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.9))
                .padding(10)
        }
    }
}
