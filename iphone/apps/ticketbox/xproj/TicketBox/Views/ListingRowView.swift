import SwiftUI

struct ListingRowView: View {
    let listing: TicketListing
    let showFeesUpfront: Bool

    var body: some View {
        let badge = DealBadge.badge(for: listing.dealScore)
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Section \(listing.section) • Row \(listing.row)")
                    .font(MockSeatGeekTheme.titleFont(size: 14))
                    .foregroundColor(MockSeatGeekTheme.textPrimary)
                    .accessibilityIdentifier("listing.section.\(listing.id.uuidString)")
                Text("Seats: \(listing.seatRange)")
                    .font(MockSeatGeekTheme.bodyFont(size: 12))
                    .foregroundColor(MockSeatGeekTheme.textSecondary)
                    .accessibilityIdentifier("listing.seats.\(listing.id.uuidString)")
                Text("Qty \(listing.quantityAvailable) • \(listing.deliveryType.rawValue)")
                    .font(MockSeatGeekTheme.bodyFont(size: 11))
                    .foregroundColor(MockSeatGeekTheme.textSecondary)
                    .accessibilityIdentifier("listing.delivery.\(listing.id.uuidString)")
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(Formatters.priceDisplay(
                    price: listing.price,
                    fees: listing.fees,
                    showFeesUpfront: showFeesUpfront
                ))
                .font(MockSeatGeekTheme.titleFont(size: 14))
                .foregroundColor(MockSeatGeekTheme.textPrimary)
                .accessibilityIdentifier("listing.price.\(listing.id.uuidString)")

                Text(badge.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badge.color.opacity(0.15))
                    .foregroundColor(badge.color)
                    .clipShape(Capsule())
                    .accessibilityIdentifier("listing.badge.\(listing.id.uuidString)")
            }
        }
        .padding(.vertical, 6)
    }
}
