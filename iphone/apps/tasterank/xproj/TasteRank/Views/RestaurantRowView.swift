import SwiftUI

struct RestaurantRowView: View {
    @EnvironmentObject var store: MockTasteRankStore
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 80, height: 80)
                .overlay {
                    Image(restaurant.photoAssetNames.first ?? "tr_photo_1")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("row_photo_\(restaurant.id)")

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(restaurant.name)
                        .font(MockTasteRankTheme.titleFont(size: 16))
                        .foregroundColor(MockTasteRankTheme.textPrimary)
                        .accessibilityIdentifier("row_name_\(restaurant.id)")
                    Spacer()
                    if store.visitedRestaurantIDs.contains(restaurant.id) {
                        Text("Visited")
                            .font(MockTasteRankTheme.bodyFont(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MockTasteRankTheme.accentSoft)
                            .cornerRadius(8)
                            .accessibilityIdentifier("row_visited_\(restaurant.id)")
                    }
                }
                Text("\(restaurant.cuisine.name) • \(restaurant.neighborhood.name)")
                    .font(MockTasteRankTheme.bodyFont(size: 12))
                    .foregroundColor(MockTasteRankTheme.textSecondary)
                    .accessibilityIdentifier("row_meta_\(restaurant.id)")
                HStack(spacing: 8) {
                    Text(store.displayPrice(level: restaurant.priceLevel))
                    Text(restaurant.formattedDistance)
                    Text("\(store.averageRating(for: restaurant.id) ?? restaurant.seedRating, specifier: "%.1f")")
                }
                .font(MockTasteRankTheme.bodyFont(size: 11))
                .foregroundColor(MockTasteRankTheme.textSecondary)
                .accessibilityIdentifier("row_stats_\(restaurant.id)")
            }
            Spacer()
        }
        .padding(12)
        .background(CardBackground())
    }
}

struct RestaurantImagePlaceholder: View {
    let seed: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MockTasteRankTheme.accentSoft, MockTasteRankTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife")
                .foregroundColor(MockTasteRankTheme.accent)
        }
    }
}

#Preview {
    RestaurantRowView(restaurant: MockTasteRankStore().restaurants.first!)
        .environmentObject(MockTasteRankStore())
}
