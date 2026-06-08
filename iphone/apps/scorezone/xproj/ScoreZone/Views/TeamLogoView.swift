import SwiftUI
import UIKit

struct TeamLogoView: View {
    let team: Team
    var size: CGFloat = 24
    var cornerRadius: CGFloat = 6

    var body: some View {
        Group {
            if UIImage(named: team.logoAssetName) != nil {
                Image(team.logoAssetName)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackMark
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var fallbackMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [brandColor.opacity(0.95), Color.black.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(team.abbreviation.prefix(1))
                .font(.system(size: max(10, size * 0.48), weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var brandColor: Color {
        let seed = stableSeed(team.id)
        let red = Double((seed % 120) + 90) / 255.0
        let green = Double(((seed / 7) % 120) + 70) / 255.0
        let blue = Double(((seed / 13) % 120) + 80) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    private func stableSeed(_ value: String) -> Int {
        value.unicodeScalars.reduce(0) { partial, scalar in
            ((partial * 33) + Int(scalar.value)) % 100_000
        }
    }
}
