import SwiftUI

struct EventRowView: View {
    @Environment(MockTicketBoxStore.self) var store
    let event: Event

    var body: some View {
        let listing = store.minListing(for: event)
        let price = listing?.price ?? store.minPrice(for: event)
        let fees = listing?.fees ?? 0

        HStack(spacing: 12) {
            EventArtworkView(event: event)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(MockSeatGeekTheme.titleFont(size: 16))
                    .foregroundColor(MockSeatGeekTheme.textPrimary)
                    .accessibilityIdentifier("event.row.title.\(event.id.uuidString)")
                Text("\(event.city) • \(Formatters.eventDate(event.date, use24Hour: store.settings.use24HourTime))")
                    .font(MockSeatGeekTheme.bodyFont(size: 12))
                    .foregroundColor(MockSeatGeekTheme.textSecondary)
                    .accessibilityIdentifier("event.row.date.\(event.id.uuidString)")
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.priceDisplay(
                    price: price,
                    fees: fees,
                    showFeesUpfront: store.settings.showFeesUpfront
                ))
                .font(MockSeatGeekTheme.titleFont(size: 14))
                .foregroundColor(MockSeatGeekTheme.textPrimary)
                .accessibilityIdentifier("event.row.price.\(event.id.uuidString)")

                Text("From")
                    .font(MockSeatGeekTheme.bodyFont(size: 11))
                    .foregroundColor(MockSeatGeekTheme.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }
}
