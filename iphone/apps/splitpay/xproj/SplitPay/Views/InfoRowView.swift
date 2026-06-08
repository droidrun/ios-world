import SwiftUI

struct InfoRowView: View {
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(SplitPayTheme.accentLight)
                .frame(width: 44, height: 44)
                .overlay(Text(title.prefix(1)).font(SplitPayTheme.titleFont(size: 16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SplitPayTheme.titleFont(size: 14))
                    .foregroundColor(SplitPayTheme.textPrimary)
                Text(subtitle)
                    .font(SplitPayTheme.bodyFont(size: 12))
                    .foregroundColor(SplitPayTheme.textSecondary)
            }
            Spacer()
            Text(detail)
                .font(SplitPayTheme.bodyFont(size: 12))
                .foregroundColor(SplitPayTheme.textSecondary)
        }
        .padding(12)
        .background(CardSurface())
    }
}

#Preview {
    InfoRowView(title: "Mock Debit", subtitle: "•••• 1234", detail: "Linked")
}
