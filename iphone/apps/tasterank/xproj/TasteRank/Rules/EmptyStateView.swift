import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(MockTasteRankTheme.titleFont(size: 18))
                .foregroundColor(MockTasteRankTheme.textPrimary)
            Text(subtitle)
                .font(MockTasteRankTheme.bodyFont(size: 13))
                .foregroundColor(MockTasteRankTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CardBackground())
    }
}
