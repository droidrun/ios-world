import SwiftUI

struct RestaurantCardView: View {
    enum CardStyle {
        case standard
        case compact
    }

    let restaurant: Restaurant
    let neighborhoodName: String
    let nextSlots: [ReservationSlot]
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    var style: CardStyle = .standard
    var onSlotTap: ((ReservationSlot) -> Void)? = nil

    private var heroHeight: CGFloat {
        style == .compact ? 120 : 160
    }

    private var photoSeeds: [RestaurantPhotoSeed] {
        SeedData.photoSeeds(for: restaurant)
    }

    private var heroPhoto: RestaurantPhotoSeed {
        photoSeeds.first ?? RestaurantPhotoSeed(
            id: "photo_fallback",
            assetName: "ds_photo_01",
            title: "Dining Room",
            subtitle: "Ambience",
            paletteHex: ["#355E4F", "#1A3048", "#0A1323"]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            hero

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(style == .compact ? .subheadline.weight(.bold) : .system(size: 18, weight: .bold))
                            .foregroundStyle(DiningTheme.textPrimary)
                            .lineLimit(1)
                            .accessibilityIdentifier("restaurant_name_\(restaurant.id)")

                        HStack(spacing: 4) {
                            Text(AppFormat.priceTierLabel(restaurant.priceTier))
                            Text("\u{2022}")
                            Text(restaurant.cuisine)
                            Text("\u{2022}")
                            Text(String(format: "%.1f", restaurant.rating))
                        }
                        .font(.system(size: style == .compact ? 13 : 14, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                        .accessibilityIdentifier("restaurant_subtitle_\(restaurant.id)")

                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                            Text("\(AppFormat.distanceLabel(miles: restaurant.distanceMiles)) \u{2022} \(neighborhoodName)")
                        }
                        .font(.system(size: style == .compact ? 13 : 14, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                        .accessibilityIdentifier("restaurant_meta_\(restaurant.id)")
                    }

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundStyle(DiningTheme.accentRed)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("favorite_toggle_\(restaurant.id)")
                }

                HStack(spacing: 6) {
                    Text(AppFormat.starSymbols(for: restaurant.rating))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DiningTheme.accentRed)

                    Text("\(AppFormat.reviewCount(for: restaurant.id)) reviews")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }
                .accessibilityIdentifier("restaurant_reviews_\(restaurant.id)")

                if nextSlots.isEmpty {
                    Text("No online times \u{2022} join waitlist")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DiningTheme.muted)
                        .accessibilityIdentifier("restaurant_no_slots_\(restaurant.id)")
                } else {
                    HStack(spacing: 8) {
                        ForEach(nextSlots.prefix(3)) { slot in
                            Button {
                                onSlotTap?(slot)
                            } label: {
                                Text(DateFormatters.shortTime.string(from: slot.date))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(Color.white)
                                    .background(DiningTheme.slotRed)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("restaurant_slot_chip_\(slot.id)")
                        }
                    }
                }
            }
            .padding(10)
            .background(DiningTheme.elevatedSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
    }

    private var hero: some View {
        ZStack {
            Rectangle().fill(heroGradient)
            Image(heroPhoto.assetName)
                .resizable()
                .scaledToFill()
                .opacity(0.92)
        }
        .frame(height: heroHeight)
        .clipped()
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 5) {
                    ForEach(0..<min(photoSeeds.count, 3), id: \.self) { _ in
                        Circle().fill(Color.white.opacity(0.9)).frame(width: 8, height: 8)
                    }
                }
                .padding(10)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(heroPhoto.title)
                        .font(.caption.weight(.bold))
                    Text(heroPhoto.subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())
                .padding(10)
                .foregroundStyle(Color.white)
            }
            .accessibilityIdentifier("restaurant_hero_\(restaurant.id)")
    }

    private var heroGradient: LinearGradient {
        let palette = heroPhoto.paletteHex.map(AppFormat.colorFromHex)
        let colors = palette.isEmpty ? [DiningTheme.surface, DiningTheme.background] : palette
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
