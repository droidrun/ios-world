import SwiftUI

struct InfoBannerView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 16))
                .foregroundColor(SplitPayTheme.textPrimary)
            Text(subtitle)
                .font(SplitPayTheme.bodyFont(size: 12))
                .foregroundColor(SplitPayTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(CardSurface())
    }
}
