import SwiftUI

struct HomeView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var requestViewModel: RequestViewModel

    private enum HomeService: String {
        case uber
        case eats
        case courier
        case shop
    }

    @State private var showRequestFlow = false
    @State private var showPlanRide = false
    @State private var selectedService: HomeService = .uber

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    mapHero

                    VStack(alignment: .leading, spacing: 14) {
                        servicesStrip
                        recentDestinationsSection
                        suggestionsSection
                        savedPlacesSection
                        promotionsSection
                        safetySection
                    }
                    .padding(14)
                }
            }
            .background(CityRideTheme.background)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if let message = homeViewModel.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .uberCard(radius: 999)
                        .padding(.bottom, 10)
                        .accessibilityIdentifier("home_status_message")
                }
            }
            .fullScreenCover(isPresented: $showRequestFlow) {
                RequestFlowView(viewModel: requestViewModel) {
                    showRequestFlow = false
                }
            }
            .fullScreenCover(isPresented: $showPlanRide) {
                PlanRideView(
                    homeViewModel: homeViewModel,
                    requestViewModel: requestViewModel,
                    onClose: { showPlanRide = false },
                    onConfirmRoute: {
                        showPlanRide = false
                        showRequestFlow = true
                    }
                )
            }
        }
    }

    private var servicesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                serviceChipButton(service: .uber, icon: "car.fill", title: "Ride", id: "home_service_chip_uber")
                serviceChipButton(service: .eats, icon: "fork.knife", title: "Eats", id: "home_service_chip_eats")
                serviceChipButton(service: .courier, icon: "shippingbox", title: "Package", id: "home_service_chip_courier")
                serviceChipButton(service: .shop, icon: "key.fill", title: "Rental", id: "home_service_chip_shop")
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Button {
                showRequestFlow = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CityRideTheme.muted)
                    Text("Where to?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 48)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_where_to_button")

            Button {
                showPlanRide = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text("Later")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("quick_action_schedule_ride")
        }
        .padding(4)
        .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var recentDestinationsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(homeViewModel.recentDestinations.enumerated()), id: \.element.id) { index, place in
                Button {
                    homeViewModel.setDestination(place)
                    showRequestFlow = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.subheadline)
                            .foregroundStyle(CityRideTheme.muted)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.displayName)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text(place.address)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("recent_destination_row_\(place.displayName.accessibilitySafe)")

                if index < homeViewModel.recentDestinations.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 44)
                }
            }
        }
    }

    private var mapHero: some View {
        ZStack {
            RouteMapView(
                pickup: homeViewModel.requestDraft.pickup,
                destination: homeViewModel.requestDraft.destination
            )
            .frame(height: 300)
            // The home-screen map is decorative; users plan rides via the
            // overlaid `home_where_to_button` and `quick_action_schedule_ride`
            // buttons. Disabling hit-testing on the Map prevents its
            // pan/zoom gesture recognizers from swallowing taps intended
            // for the overlays — which manifested as accessibility-id
            // lookup failures on `quick_action_schedule_ride` and
            // `map_recenter_button` during UI-context verification on
            // iOS 26 simulators.
            .allowsHitTesting(false)

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, CityRideTheme.background],
                    startPoint: .init(x: 0.5, y: 0),
                    endPoint: .init(x: 0.5, y: 1)
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greetingText)
                            .font(.title2.weight(.bold))
                            .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                        Text(homeViewModel.requestDraft.pickup?.displayName ?? "San Francisco")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                    }
                    Spacer()
                    Button {
                        homeViewModel.recenterMap()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.7), in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .accessibilityIdentifier("map_recenter_button")
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                searchBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
        }
        // Expose children (recenter button, search bar) as individual
        // accessibility elements instead of collapsing the whole ZStack into
        // one element under a container identifier — otherwise WDA can't see
        // `map_recenter_button` / `home_where_to_button` / `quick_action_schedule_ride`.
        .accessibilityElement(children: .contain)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions")
                .font(.title2.weight(.bold))
                .accessibilityIdentifier("home_suggested_destinations_title")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    suggestionTile(title: "Ride", symbol: "car.fill", badge: "20%", id: "suggested_destination_row_ride") {
                        showRequestFlow = true
                    }
                    suggestionTile(title: "Reserve", symbol: "calendar", badge: "Promo", id: "suggested_destination_row_reserve") {
                        showPlanRide = true
                    }
                    suggestionTile(title: "Airport", symbol: "airplane", badge: nil, id: "suggested_destination_row_airport") {
                        if let airport = homeViewModel.availablePlaces.first(where: { $0.displayName == "Airport" }) {
                            homeViewModel.setDestination(airport)
                            showRequestFlow = true
                        }
                    }
                    suggestionTile(title: "Work", symbol: "briefcase.fill", badge: nil, id: "suggested_destination_row_work") {
                        if let work = homeViewModel.availablePlaces.first(where: { $0.displayName == "Work" }) {
                            homeViewModel.setDestination(work)
                            showRequestFlow = true
                        }
                    }
                }
            }
        }
    }

    private var savedPlacesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved places")
                .font(.title3.weight(.bold))
                .accessibilityIdentifier("home_saved_places_title")

            ForEach(homeViewModel.savedPlaces.prefix(3)) { savedPlace in
                Button {
                    homeViewModel.setDestination(from: savedPlace)
                    showRequestFlow = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: savedPlace.type))
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(savedPlace.displayName)
                                .font(.headline)
                            Text(savedPlace.address)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .uberCard(radius: 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("saved_place_row_\(savedPlace.displayName.accessibilitySafe)")
            }
        }
    }

    private var promotionsSection: some View {
        Button {
            homeViewModel.openPromotionDetails()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You have multiple promos")
                        .font(.headline)
                    Text("We'll automatically apply the one that saves you the most")
                        .font(.subheadline)
                        .foregroundStyle(CityRideTheme.muted)
                }
                Spacer()
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundStyle(CityRideTheme.accent)
            }
            .padding(14)
            .uberCard(radius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("promotion_placeholder_card")
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(homeViewModel.travelAlerts.prefix(2)) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alertIcon(for: alert.severity))
                        .font(.title3)
                        .foregroundStyle(alertColor(for: alert.severity))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.title)
                            .font(.headline)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(alertColor(for: alert.severity).opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(alertColor(for: alert.severity).opacity(0.2), lineWidth: 1)
                )
                .accessibilityIdentifier("travel_alert_row_\(alert.id)")
            }
        }
    }

    private func alertIcon(for severity: AlertSeverity) -> String {
        switch severity {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }

    private func alertColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .info:
            return .blue
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }

    private func serviceChipButton(service: HomeService, icon: String, title: String, id: String) -> some View {
        Button {
            selectedService = service
            if service != .uber {
                homeViewModel.store.postStatusMessage("Coming soon")
            }
        } label: {
            serviceChip(icon: icon, title: title, selected: selectedService == service)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func serviceChip(icon: String, title: String, selected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(selected ? .white : CityRideTheme.muted)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? Color.white.opacity(0.12) : Color.white.opacity(0.04), in: Capsule())
    }

    private func suggestionTile(title: String, symbol: String, badge: String?, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol)
                        .font(.title3)
                        .frame(width: 64, height: 50)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red, in: Capsule())
                            .offset(x: 8, y: -8)
                    }
                }
                Text(title)
                    .font(.headline)
            }
            .frame(width: 100)
            .padding(.vertical, 8)
            .uberCard(radius: 16)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func icon(for type: SavedPlaceType) -> String {
        switch type {
        case .home:
            return "house.fill"
        case .work:
            return "briefcase.fill"
        case .favorite:
            return "star.fill"
        }
    }
}

struct PlacePickerView: View {
    let title: String
    let places: [LocationPlace]
    let accessibilityPrefix: String
    let onSelect: (LocationPlace) -> Void

    @State private var searchText = ""

    private var filteredPlaces: [LocationPlace] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return places }
        return places.filter {
            $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredPlaces) { place in
                Button {
                    onSelect(place)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.displayName)
                            .font(.headline)
                        Text(place.address)
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(accessibilityPrefix)_selector_row_\(place.displayName.accessibilitySafe)")
                .listRowBackground(CityRideTheme.panel)
            }
            .searchable(text: $searchText, prompt: "Search locations")
            .scrollContentBackground(.hidden)
            .background(CityRideTheme.background)
            .navigationTitle(title)
        }
    }
}
