import MapKit
import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var store: DiningStore
    @ObservedObject var viewModel: DiscoverViewModel

    @State private var showFilterSheet = false
    @State private var showDateSheet = false
    @State private var showTimeSheet = false
    @State private var selectedMapRestaurant: Restaurant?
    @State private var bookingRequest: BookingRequest?
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    private var results: [Restaurant] {
        viewModel.filteredRestaurants(store: store)
    }

    private var selectedDateDescriptor: String {
        Calendar.current.isDateInToday(viewModel.selectedDate)
            ? "Tonight"
            : DateFormatters.weekdayDate.string(from: viewModel.selectedDate)
    }

    var body: some View {
        ZStack {
            mapLayer

            VStack(spacing: 0) {
                topControls
                Spacer(minLength: 0)
                bottomSheet
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("discover_screen")
        .sheet(isPresented: $showFilterSheet) {
            DiscoverFilterSheet(viewModel: viewModel)
                .environmentObject(store)
        }
        .sheet(isPresented: $showDateSheet) {
            dateSheet
        }
        .sheet(isPresented: $showTimeSheet) {
            timeSheet
        }
        .sheet(item: $selectedMapRestaurant) { restaurant in
            NavigationStack {
                RestaurantDetailView(
                    restaurantID: restaurant.id,
                    initialDate: viewModel.selectedDate,
                    initialTime: viewModel.selectedTime,
                    initialPartySize: viewModel.partySize
                )
            }
        }
        .sheet(item: $bookingRequest) { request in
            BookingReviewView(restaurant: request.restaurant, slot: request.slot, partySize: viewModel.partySize)
                .environmentObject(store)
        }
        .onAppear {
            recenterMap(animated: false)
        }
        .onChange(of: store.selectedCityID) { _, _ in
            recenterMap(animated: true)
        }
    }

    private var mapLayer: some View {
        ZStack {
            Map(position: $mapPosition, interactionModes: .all) {
                ForEach(results.prefix(36)) { restaurant in
                    Annotation(
                        restaurant.name,
                        coordinate: coordinate(for: restaurant),
                        anchor: .bottom
                    ) {
                        Button {
                            selectedMapRestaurant = restaurant
                        } label: {
                            Circle()
                                .fill(DiningTheme.slotRed)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("map_marker_\(restaurant.id)")
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .accessibilityIdentifier("discover_map")

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var topControls: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DiningTheme.textSecondary)

                TextField("Search \(store.city(for: store.selectedCityID)?.name ?? "restaurants")", text: $viewModel.query)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier("search_query_field")
                    .onSubmit {
                        store.addRecentSearch(viewModel.query)
                    }

                Menu {
                    ForEach(store.cities) { city in
                        Button(city.name) {
                            store.selectedCityID = city.id
                            recenterMap(animated: true)
                        }
                        .accessibilityIdentifier("city_picker_option_\(city.id)")
                    }
                } label: {
                    Image(systemName: "location")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(DiningTheme.surface)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier("search_location_field")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        showTimeSheet = true
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2")
                                .font(.system(size: 10))
                            Text("\(viewModel.partySize) \u{2022} \(DateFormatters.shortTime.string(from: viewModel.selectedTime))")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("search_time_button")

                    Button {
                        showDateSheet = true
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(DateFormatters.weekdayDate.string(from: viewModel.selectedDate))
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("search_date_button")

                    Menu {
                        ForEach(1...8, id: \.self) { size in
                            Button(AppFormat.partySizeLabel(size)) {
                                viewModel.partySize = size
                            }
                            .accessibilityIdentifier("party_size_option_\(size)")
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 10))
                            Text(AppFormat.partySizeLabel(viewModel.partySize))
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                    }
                    .accessibilityIdentifier("search_party_size_button")

                    filterChip(icon: "slider.horizontal.3", title: "Filters", identifier: "discover_filter_button") {
                        showFilterSheet = true
                    }

                    Menu {
                        ForEach(RestaurantSortOption.allCases) { option in
                            Button(option.title) {
                                viewModel.sortOption = option
                            }
                            .accessibilityIdentifier("sort_option_\(option.rawValue)")
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 10))
                            Text(viewModel.sortOption.title)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                    }
                    .accessibilityIdentifier("discover_sort_control")

                    filterChip(icon: "heart", title: "Romantic", identifier: "featured_collection_romantic") {
                        viewModel.query = "romantic"
                    }
                    filterChip(icon: "fork.knife", title: "Italian", identifier: "featured_collection_italian") {
                        viewModel.query = "italian"
                    }
                    filterChip(icon: "takeoutbag.and.cup.and.straw", title: "Brunch", identifier: "featured_collection_brunch") {
                        viewModel.filterState.selectedTimeOfDay = [.lunch]
                    }
                    filterChip(icon: "sun.max", title: "Outdoor", identifier: "featured_collection_outdoor") {
                        viewModel.filterState.outdoorSeatingOnly = true
                    }
                    filterChip(icon: "wineglass", title: "Bar", identifier: "featured_collection_bar") {
                        viewModel.filterState.barSeatingOnly = true
                    }
                }
                .padding(.vertical, 2)
            }

            if let error = store.snapshotErrorMessage, store.availabilityMode == .snapshot {
                Text(error)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.7))
                    .clipShape(Capsule())
                    .accessibilityIdentifier("snapshot_unavailable_state")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            HStack {
                Text("\(results.count) restaurants nearby")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                Spacer()
            }
            .accessibilityIdentifier("discover_results_count_label")

            if results.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(DiningTheme.muted)
                    Text("No restaurants found")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DiningTheme.textPrimary)
                    Text("Try adjusting filters or location.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .accessibilityIdentifier("discover_no_results_state")
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(results.prefix(12)) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(
                                    restaurantID: restaurant.id,
                                    initialDate: viewModel.selectedDate,
                                    initialTime: viewModel.selectedTime,
                                    initialPartySize: viewModel.partySize
                                )
                            } label: {
                                SearchResultRow(
                                    restaurant: restaurant,
                                    neighborhoodName: store.neighborhood(for: restaurant.neighborhoodID)?.name ?? "",
                                    slots: viewModel.preferredSlots(for: restaurant.id, store: store, limit: 3),
                                    onSlotTap: { slot in
                                        bookingRequest = BookingRequest(restaurant: restaurant, slot: slot)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("restaurant_row_\(restaurant.id)")
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, y: -2)
        .accessibilityIdentifier("discover_bottom_sheet")
    }

    private var dateSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Reservation Date",
                    selection: $viewModel.selectedDate,
                    in: Date()...SeedData.makeDate(daysFromNow: 30, hour: 23),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .accessibilityIdentifier("search_date_picker")

                Button("Done") {
                    showDateSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(DiningTheme.accentRed)
                .accessibilityIdentifier("search_date_done_button")
            }
            .padding()
            .navigationTitle("Select Date")
        }
        .presentationDetents([.medium, .large])
    }

    private var timeSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Reservation Time",
                    selection: $viewModel.selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .accessibilityIdentifier("search_time_picker")

                Button("Done") {
                    showTimeSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(DiningTheme.accentRed)
                .accessibilityIdentifier("search_time_done_button")
            }
            .padding()
            .navigationTitle("Select Time")
        }
        .presentationDetents([.medium])
    }

    private func filterChip(icon: String, title: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(DiningTheme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.92))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func coordinate(for restaurant: Restaurant) -> CLLocationCoordinate2D {
        let point = SeedData.coordinate(for: restaurant)
        return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    }

    private func recenterMap(animated: Bool) {
        let cityRestaurants = store.restaurants(in: store.selectedCityID)
        let reference = results.isEmpty ? cityRestaurants : results
        let visible = Array(reference.prefix(36))
        let targetRegion = regionForMap(restaurants: visible)

        if animated {
            withAnimation(.easeInOut(duration: 0.22)) {
                mapPosition = .region(targetRegion)
            }
        } else {
            mapPosition = .region(targetRegion)
        }
    }

    private func regionForMap(restaurants: [Restaurant]) -> MKCoordinateRegion {
        let fallbackCenter = SeedData.cityCoordinate(for: store.selectedCityID)

        guard !restaurants.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: fallbackCenter.latitude,
                    longitude: fallbackCenter.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.20, longitudeDelta: 0.20)
            )
        }

        let coordinates = restaurants.map(coordinate(for:))
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLat = latitudes.min() ?? fallbackCenter.latitude
        let maxLat = latitudes.max() ?? fallbackCenter.latitude
        let minLon = longitudes.min() ?? fallbackCenter.longitude
        let maxLon = longitudes.max() ?? fallbackCenter.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latitudeDelta = max(0.08, (maxLat - minLat) * 1.65)
        let longitudeDelta = max(0.08, (maxLon - minLon) * 1.65)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
}

private struct SearchResultRow: View {
    let restaurant: Restaurant
    let neighborhoodName: String
    let slots: [ReservationSlot]
    var onSlotTap: ((ReservationSlot) -> Void)? = nil

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
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 3) {
                    Text(AppFormat.priceTierLabel(restaurant.priceTier))
                    Text("\u{2022}")
                    Text(restaurant.cuisine)
                    Text("\u{2022}")
                    Text(String(format: "%.1f", restaurant.rating))
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)

                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text("\(AppFormat.distanceLabel(miles: restaurant.distanceMiles)) \u{2022} \(neighborhoodName)")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)

                HStack(spacing: 4) {
                    Text(AppFormat.starSymbols(for: restaurant.rating))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DiningTheme.accentRed)
                    Text("\(AppFormat.reviewCount(for: restaurant.id)) reviews")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DiningTheme.textSecondary)
                }

                if slots.isEmpty {
                    Text("No online times \u{2022} Join waitlist")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DiningTheme.muted)
                } else {
                    HStack(spacing: 6) {
                        ForEach(slots.prefix(3)) { slot in
                            Button {
                                onSlotTap?(slot)
                            } label: {
                                Text(DateFormatters.shortTime.string(from: slot.date))
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(DiningTheme.slotRed)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                    .opacity(0.93)
            }
            .frame(width: 82, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(heroPhoto.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.94))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(4)
            }
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

private struct DiscoverFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DiningStore
    @ObservedObject var viewModel: DiscoverViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Cuisine") {
                    ForEach(viewModel.availableCuisines(store: store), id: \.self) { cuisine in
                        Button {
                            toggleCuisine(cuisine)
                        } label: {
                            filterRow(title: cuisine, selected: viewModel.filterState.selectedCuisines.contains(cuisine))
                        }
                        .accessibilityIdentifier("filter_cuisine_\(AppFormat.accessibilitySlug(cuisine))")
                    }
                }

                Section("Neighborhood") {
                    ForEach(viewModel.availableNeighborhoods(store: store)) { neighborhood in
                        Button {
                            toggleNeighborhood(neighborhood.id)
                        } label: {
                            filterRow(title: neighborhood.name, selected: viewModel.filterState.selectedNeighborhoodIDs.contains(neighborhood.id))
                        }
                        .accessibilityIdentifier("filter_neighborhood_\(neighborhood.id)")
                    }
                }

                Section("Price Tier") {
                    HStack {
                        ForEach(1...4, id: \.self) { tier in
                            Button {
                                togglePriceTier(tier)
                            } label: {
                                Text(AppFormat.priceTierLabel(tier))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.filterState.selectedPriceTiers.contains(tier) ? DiningTheme.accentRed.opacity(0.25) : Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("filter_price_tier_\(tier)")
                        }
                    }
                }

                Section("Time of Day") {
                    ForEach(TimeOfDayFilter.allCases) { filter in
                        Button {
                            toggleTimeOfDay(filter)
                        } label: {
                            filterRow(title: filter.title, selected: viewModel.filterState.selectedTimeOfDay.contains(filter))
                        }
                        .accessibilityIdentifier("filter_time_of_day_\(filter.rawValue)")
                    }
                }

                Section("Other") {
                    Toggle("Available Now", isOn: $viewModel.filterState.availableNowOnly)
                        .accessibilityIdentifier("filter_available_now")
                    Toggle("Outdoor Seating", isOn: $viewModel.filterState.outdoorSeatingOnly)
                        .accessibilityIdentifier("filter_outdoor")
                    Toggle("Bar Seating", isOn: $viewModel.filterState.barSeatingOnly)
                        .accessibilityIdentifier("filter_bar_seating")
                    Toggle("Bookable Online", isOn: $viewModel.filterState.bookableOnlineOnly)
                        .accessibilityIdentifier("filter_bookable_online")
                    Toggle("Party Size Support", isOn: $viewModel.filterState.requirePartySizeSupport)
                        .accessibilityIdentifier("filter_party_size_support")
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        viewModel.filterState = .default
                    }
                    .accessibilityIdentifier("filter_reset_button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("filter_done_button")
                }
            }
        }
        .presentationDetents([.large])
    }

    private func filterRow(title: String, selected: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundStyle(DiningTheme.accentRed)
            }
        }
    }

    private func toggleCuisine(_ cuisine: String) {
        if viewModel.filterState.selectedCuisines.contains(cuisine) {
            viewModel.filterState.selectedCuisines.remove(cuisine)
        } else {
            viewModel.filterState.selectedCuisines.insert(cuisine)
        }
    }

    private func toggleNeighborhood(_ neighborhoodID: String) {
        if viewModel.filterState.selectedNeighborhoodIDs.contains(neighborhoodID) {
            viewModel.filterState.selectedNeighborhoodIDs.remove(neighborhoodID)
        } else {
            viewModel.filterState.selectedNeighborhoodIDs.insert(neighborhoodID)
        }
    }

    private func togglePriceTier(_ tier: Int) {
        if viewModel.filterState.selectedPriceTiers.contains(tier) {
            viewModel.filterState.selectedPriceTiers.remove(tier)
        } else {
            viewModel.filterState.selectedPriceTiers.insert(tier)
        }
    }

    private func toggleTimeOfDay(_ filter: TimeOfDayFilter) {
        if viewModel.filterState.selectedTimeOfDay.contains(filter) {
            viewModel.filterState.selectedTimeOfDay.remove(filter)
        } else {
            viewModel.filterState.selectedTimeOfDay.insert(filter)
        }
    }
}
