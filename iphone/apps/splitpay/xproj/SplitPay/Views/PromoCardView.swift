import SwiftUI

struct PromoCardView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(SplitPayTheme.accentLight)
                .frame(height: 100)
                .overlay(
                    Text(title.prefix(2))
                        .font(SplitPayTheme.titleFont(size: 20))
                        .foregroundColor(SplitPayTheme.accent)
                )

            Text(title)
                .font(SplitPayTheme.titleFont(size: 14))
                .foregroundColor(SplitPayTheme.textPrimary)
            Text(subtitle)
                .font(SplitPayTheme.bodyFont(size: 11))
                .foregroundColor(SplitPayTheme.textSecondary)
        }
        .padding(12)
        .frame(width: 220)
        .background(CardSurface())
    }
}

#Preview {
    PromoCardView(title: "Split Dinner", subtitle: "Try pay/request flows")
}
