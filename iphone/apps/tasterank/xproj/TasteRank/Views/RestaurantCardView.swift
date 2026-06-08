import SwiftUI

struct RestaurantCardView: View {
    @EnvironmentObject var store: MockTasteRankStore
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear
                .frame(height: 120)
                .overlay {
                    Image(restaurant.photoAssetNames.first ?? "tr_photo_1")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("card_photo_\(restaurant.id)")

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(MockTasteRankTheme.titleFont(size: 14))
                    .foregroundColor(MockTasteRankTheme.textPrimary)
                    .accessibilityIdentifier("card_name_\(restaurant.id)")
                Text("\(restaurant.cuisine.name) • \(restaurant.neighborhood.name)")
                    .font(MockTasteRankTheme.bodyFont(size: 11))
                    .foregroundColor(MockTasteRankTheme.textSecondary)
                    .accessibilityIdentifier("card_meta_\(restaurant.id)")

                HStack(spacing: 8) {
                    Text(store.displayPrice(level: restaurant.priceLevel))
                    Text(restaurant.formattedDistance)
                    Text("\(store.averageRating(for: restaurant.id) ?? restaurant.seedRating, specifier: "%.1f")")
                }
                .font(MockTasteRankTheme.bodyFont(size: 10))
                .foregroundColor(MockTasteRankTheme.textSecondary)
                .accessibilityIdentifier("card_stats_\(restaurant.id)")
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(CardBackground())
    }
}

#Preview {
    RestaurantCardView(restaurant: MockTasteRankStore().restaurants.first!)
        .environmentObject(MockTasteRankStore())
}
