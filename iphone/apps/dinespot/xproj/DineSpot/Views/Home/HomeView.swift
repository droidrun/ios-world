import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DiningStore
    @State private var bookingRequest: BookingRequest?

    private var dinnerTonight: [Restaurant] {
        store.restaurants(in: store.selectedCityID)
            .sorted {
                if $0.rating == $1.rating {
                    return $0.distanceMiles < $1.distanceMiles
                }
                return $0.rating > $1.rating
            }
            .prefix(8)
            .map { $0 }
    }

    private var recentlyViewed: [Restaurant] {
        let favorites = store.favoriteRestaurants()
        if !favorites.isEmpty {
            return Array(favorites.prefix(8))
        }
        return store.restaurants(in: store.selectedCityID)
            .sorted(by: { $0.distanceMiles < $1.distanceMiles })
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    contextPills
                    upcomingCard
                    restaurantCarousel(title: "Book for dinner tonight", restaurants: dinnerTonight, identifierPrefix: "home_dinner")
                    restaurantCarousel(title: "Recently viewed", restaurants: recentlyViewed, identifierPrefix: "home_recent")
                    quickActions
                    policyMessage
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 22)
            }
        }
        .navigationBarHidden(true)
        .accessibilityIdentifier("home_screen")
        .sheet(item: $bookingRequest) { request in
            BookingReviewView(restaurant: request.restaurant, slot: request.slot, partySize: 2)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting()), \(firstName())")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("home_greeting_label")

                Text(store.city(for: store.selectedCityID)?.name ?? "City")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)
                    .accessibilityIdentifier("home_city_label")
            }

            Spacer()

            NavigationLink {
                ProfileView()
            } label: {
                Text(initials())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DiningTheme.accentRed))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_profile_button")
        }
    }

    private var contextPills: some View {
        HStack(spacing: 10) {
            NavigationLink {
                DiscoverView(viewModel: discoverViewModel(partySize: 2))
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "person.2")
                    Text("2 \u{2022} 7:00 PM Tonight")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DiningTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .overlay(
                    Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.4)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_context_party_time_button")

            NavigationLink {
                DiscoverView(viewModel: DiscoverViewModel())
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "location")
                    Text("Nearby")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DiningTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .overlay(
                    Capsule().stroke(DiningTheme.chipBorder, lineWidth: 1.4)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_context_nearby_button")

            Spacer()
        }
    }

    @ViewBuilder
    private var upcomingCard: some View {
        if let reservation = store.upcomingReservations().first,
           let restaurant = store.restaurant(for: reservation.restaurantID) {
            NavigationLink {
                ReservationDetailView(reservationID: reservation.id)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming reservation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)

                    Text(restaurant.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .lineLimit(1)

                    HStack {
                        Label(DateFormatters.weekdayDate.string(from: reservation.date), systemImage: "calendar")
                        Text("\u{2022}")
                        Label(DateFormatters.shortTime.string(from: reservation.date), systemImage: "clock")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DiningTheme.textSecondary)

                    Text("\(AppFormat.partySizeLabel(reservation.partySize)) \u{2022} \(reservation.reservationCode)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .background(DiningTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DiningTheme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_upcoming_card")
        }
    }

    private func restaurantCarousel(title: String, restaurants: [Restaurant], identifierPrefix: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .accessibilityIdentifier("\(identifierPrefix)_title")
                Spacer()

                NavigationLink {
                    DiscoverView(viewModel: DiscoverViewModel())
                } label: {
                    Text("View all")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DiningTheme.accentRed)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(identifierPrefix)_view_all")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(restaurants) { restaurant in
                        NavigationLink {
                            RestaurantDetailView(restaurantID: restaurant.id)
                        } label: {
                            RestaurantCardView(
                                restaurant: restaurant,
                                neighborhoodName: store.neighborhood(for: restaurant.neighborhoodID)?.name ?? "",
                                nextSlots: store.nextAvailableSlots(for: restaurant.id, partySize: 2, limit: 3),
                                isFavorite: store.isFavorite(restaurantID: restaurant.id),
                                onToggleFavorite: { store.toggleFavorite(restaurantID: restaurant.id) },
                                style: .compact,
                                onSlotTap: { slot in
                                    bookingRequest = BookingRequest(restaurant: restaurant, slot: slot)
                                }
                            )
                            .frame(width: 290)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("\(identifierPrefix)_row_\(restaurant.id)")
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick actions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .accessibilityIdentifier("home_quick_actions_label")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    NavigationLink {
                        DiscoverView(viewModel: DiscoverViewModel())
                    } label: {
                        actionChip(title: "Book a table")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_action_book")

                    NavigationLink {
                        ReservationsView()
                    } label: {
                        actionChip(title: "View reservations")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_action_reservations")

                    NavigationLink {
                        ReservationsView(initialSection: .waitlist)
                    } label: {
                        actionChip(title: "Join waitlist")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_action_waitlist")

                    NavigationLink {
                        ProfileView()
                    } label: {
                        actionChip(title: "Saved restaurants")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_action_saved_restaurants")

                    NavigationLink {
                        UpdatesView()
                    } label: {
                        actionChip(title: "Updates")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_action_updates")
                }
            }
        }
    }

    private func actionChip(title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(DiningTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DiningTheme.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(DiningTheme.border, lineWidth: 1)
            )
    }

    private var policyMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dining policies")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            Text("Credit card holds and cancellation windows vary by restaurant and time. Tables may be released after 15 minutes.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)
        }
        .padding(14)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
        .accessibilityIdentifier("home_policy_notice")
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private func firstName() -> String {
        store.userProfile.fullName.split(separator: " ").first.map(String.init) ?? store.userProfile.fullName
    }

    private func initials() -> String {
        let words = store.userProfile.fullName.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))"
        }
        return words.first?.prefix(2).uppercased() ?? "OT"
    }

    private func discoverViewModel(partySize: Int) -> DiscoverViewModel {
        let model = DiscoverViewModel()
        model.partySize = partySize
        model.selectedDate = Date()
        model.selectedTime = SeedData.makeDate(daysFromNow: 0, hour: 19)
        return model
    }
}
