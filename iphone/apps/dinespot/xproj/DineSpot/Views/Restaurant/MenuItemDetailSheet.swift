import SwiftUI

/// Full-screen detail sheet that appears when a user taps a menu item card.
struct MenuItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let itemName: String

    var body: some View {
        let appearance = MenuItemAppearance.lookup(name: itemName)
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero band ──────────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(appearance.tint.opacity(0.15))
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)

                        ZStack {
                            Circle()
                                .fill(appearance.tint.opacity(0.22))
                                .frame(width: 90, height: 90)
                            Image(systemName: appearance.symbol)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(appearance.tint)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .accessibilityIdentifier("menu_item_detail_hero_\(AppFormat.accessibilitySlug(itemName))")

                    // ── Name & price row ───────────────────────────────────────
                    HStack(alignment: .firstTextBaseline) {
                        Text(itemName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(DiningTheme.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)
                        Spacer()
                        Text(appearance.estimatedPrice)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(DiningTheme.accentRed)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .accessibilityIdentifier("menu_item_detail_name_price_\(AppFormat.accessibilitySlug(itemName))")

                    // ── Course badge ───────────────────────────────────────────
                    Text(appearance.courseLabel)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(appearance.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(appearance.tint.opacity(0.14))
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .accessibilityIdentifier("menu_item_detail_badge_\(AppFormat.accessibilitySlug(itemName))")

                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // ── Description ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this dish")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DiningTheme.textSecondary)

                        Text("\(itemName) is a signature highlight at \(restaurant.name), prepared with seasonal ingredients sourced from local purveyors. Our kitchen team crafts each portion to order.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DiningTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .accessibilityIdentifier("menu_item_detail_description_\(AppFormat.accessibilitySlug(itemName))")

                    // ── Dietary callouts ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dietary notes")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DiningTheme.textSecondary)

                        HStack(spacing: 8) {
                            dietaryBadge(
                                label: "Chef's Pick",
                                systemImage: "star.fill",
                                color: DiningTheme.accentRed
                            )
                            dietaryBadge(
                                label: "Seasonal",
                                systemImage: "leaf.fill",
                                color: Color(red: 0.28, green: 0.62, blue: 0.35)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .accessibilityIdentifier("menu_item_detail_dietary_\(AppFormat.accessibilitySlug(itemName))")

                    Spacer(minLength: 32)

                    // ── Reserve CTA ────────────────────────────────────────────
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Reserve a table to enjoy this")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(DiningTheme.accentRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("menu_item_detail_reserve_button_\(AppFormat.accessibilitySlug(itemName))")
                }
            }
            .background(DiningTheme.background)
            .navigationTitle(itemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("menu_item_detail_done_button")
                }
            }
        }
        .presentationDetents([.large])
    }

    private func dietaryBadge(label: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
