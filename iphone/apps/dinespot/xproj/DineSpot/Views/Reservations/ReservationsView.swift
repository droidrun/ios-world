import SwiftUI

struct ReservationsView: View {
    enum ReservationListSection: String, CaseIterable, Identifiable {
        case upcoming
        case past
        case canceled
        case waitlist
        case notify

        var id: String { rawValue }

        var title: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .past: return "Past"
            case .canceled: return "Canceled"
            case .waitlist: return "Waitlist"
            case .notify: return "Notify"
            }
        }
    }

    @EnvironmentObject private var store: DiningStore
    @State private var selectedSection: ReservationListSection

    init(initialSection: ReservationListSection = .upcoming) {
        _selectedSection = State(initialValue: initialSection)
    }

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Reservations")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                Picker("Reservations Section", selection: $selectedSection) {
                    ForEach(ReservationListSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("reservations_segmented_control")

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        switch selectedSection {
                        case .upcoming:
                            reservationRows(store.upcomingReservations(), emptyID: "reservations_no_upcoming_state", emptyText: "No upcoming reservations")
                        case .past:
                            reservationRows(store.pastReservations(), emptyID: "reservations_no_past_state", emptyText: "No past reservations")
                        case .canceled:
                            reservationRows(store.canceledReservations(), emptyID: "reservations_no_canceled_state", emptyText: "No canceled reservations")
                        case .waitlist:
                            waitlistRows(type: .waitlist)
                        case .notify:
                            waitlistRows(type: .notify)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("reservations_screen")
    }

    @ViewBuilder
    private func reservationRows(_ reservations: [Reservation], emptyID: String, emptyText: String) -> some View {
        if reservations.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 34))
                    .foregroundStyle(DiningTheme.muted)
                Text(emptyText)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .accessibilityIdentifier(emptyID)
        } else {
            ForEach(reservations) { reservation in
                if let restaurant = store.restaurant(for: reservation.restaurantID) {
                    NavigationLink {
                        ReservationDetailView(reservationID: reservation.id)
                    } label: {
                        ReservationCardView(
                            reservation: reservation,
                            restaurant: restaurant,
                            neighborhoodName: store.neighborhood(for: restaurant.neighborhoodID)?.name ?? ""
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("reservation_card_\(reservation.reservationCode)")
                }
            }
        }
    }

    @ViewBuilder
    private func waitlistRows(type: WaitlistRequestType) -> some View {
        let entries = store.waitlistEntries.filter { $0.requestType == type }
        if entries.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: type == .waitlist ? "clock.badge.questionmark" : "bell.badge")
                    .font(.system(size: 34))
                    .foregroundStyle(DiningTheme.muted)
                Text(type == .waitlist ? "No waitlist entries" : "No notify requests")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .accessibilityIdentifier(type == .waitlist ? "reservations_no_waitlist_state" : "reservations_no_notify_state")
        } else {
            ForEach(entries) { entry in
                NavigationLink {
                    WaitlistDetailView(entryID: entry.id)
                } label: {
                    WaitlistCardView(
                        entry: entry,
                        restaurantName: store.restaurant(for: entry.restaurantID)?.name ?? "Restaurant"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("waitlist_row_\(entry.id)")
            }
        }
    }
}

private struct ReservationCardView: View {
    let reservation: Reservation
    let restaurant: Restaurant
    let neighborhoodName: String

    private var heroPhoto: RestaurantPhotoSeed {
        SeedData.photoSeeds(for: restaurant).first ?? RestaurantPhotoSeed(
            id: "photo_fallback",
            assetName: "ds_photo_01",
            title: "Dining Room",
            subtitle: "Ambience",
            paletteHex: ["#355E4F", "#1A3048", "#0A1323"]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: heroPhoto.paletteHex.map(AppFormat.colorFromHex),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(heroPhoto.assetName)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.92)
            }
            .frame(height: 150)
            .clipped()
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(restaurant.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(heroPhoto.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label(AppFormat.reservationStatusTitle(reservation.status), systemImage: "ticket")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(reservation.status == .canceled ? Color.red : DiningTheme.accentRed)
                        .accessibilityIdentifier("reservation_status_chip_\(reservation.id)")
                    Spacer()
                    Image(systemName: "bookmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(DiningTheme.accentRed)
                }

                HStack(spacing: 8) {
                    Label("\(reservation.partySize)", systemImage: "person")
                    Label(DateFormatters.monthDayYear.string(from: reservation.date), systemImage: "calendar")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DiningTheme.textSecondary)

                HStack(spacing: 4) {
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                    ForEach(0..<5) { index in
                        Image(systemName: Double(index) + 0.5 < restaurant.rating ? "star.fill" : (Double(index) < restaurant.rating ? "star.leadinghalf.filled" : "star"))
                            .font(.system(size: 13))
                            .foregroundStyle(DiningTheme.accentRed)
                    }
                    Text("(\(SeedData.reviews.filter { $0.restaurantID == restaurant.id }.count))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }

                Text("\(restaurant.cuisine) \u{2022} \(neighborhoodName)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
            }
            .padding(12)
            .background(DiningTheme.elevatedSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }
}

private struct WaitlistCardView: View {
    let entry: WaitlistEntry
    let restaurantName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurantName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            HStack(spacing: 8) {
                Text(entry.requestType == .waitlist ? "Waitlist" : "Notify")
                Text("\u{2022}")
                Text(entry.preferredWindow)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(DiningTheme.textSecondary)

            HStack(spacing: 8) {
                Text(DateFormatters.weekdayDate.string(from: entry.date))
                Text("\u{2022}")
                Text(AppFormat.partySizeLabel(entry.partySize))
                Text("\u{2022}")
                Text(entry.status)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(DiningTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
    }
}

private struct WaitlistDetailView: View {
    @EnvironmentObject private var store: DiningStore
    let entryID: String

    private var entry: WaitlistEntry? {
        store.waitlistEntries.first(where: { $0.id == entryID })
    }

    var body: some View {
        Group {
            if let entry,
               let restaurant = store.restaurant(for: entry.restaurantID) {
                Form {
                    Section("Restaurant") {
                        Text(restaurant.name)
                            .accessibilityIdentifier("waitlist_detail_restaurant")
                        Text(restaurant.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Request") {
                        Text(entry.requestType == .waitlist ? "Waitlist" : "Notify")
                            .accessibilityIdentifier("waitlist_detail_type")
                        Text(DateFormatters.weekdayDate.string(from: entry.date))
                            .accessibilityIdentifier("waitlist_detail_date")
                        Text(entry.preferredWindow)
                            .accessibilityIdentifier("waitlist_detail_window")
                        Text(AppFormat.partySizeLabel(entry.partySize))
                            .accessibilityIdentifier("waitlist_detail_party")
                        Text("Status: \(entry.status)")
                            .accessibilityIdentifier("waitlist_detail_status")
                    }
                }
                .navigationTitle("Request Detail")
            } else {
                ContentUnavailableView("Request unavailable", systemImage: "bell.slash")
                    .accessibilityIdentifier("waitlist_detail_missing_state")
            }
        }
    }
}
