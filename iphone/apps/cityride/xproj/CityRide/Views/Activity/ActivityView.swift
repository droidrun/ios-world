import SwiftUI

struct ActivityView: View {
    @ObservedObject var viewModel: ActivityViewModel
    @State private var selectedTrip: Trip?
    @State private var pastFilter: PastFilter = .all
    @State private var ratedTripIDs: Set<String> = []
    @State private var searchText = ""
    @State private var ratingTrip: Trip?
    @State private var selectedRating: Int = 5
    @State private var ratingComment: String = ""
    @State private var selectedTip: Double = 0

    private enum PastFilter: String, CaseIterable {
        case all
        case completed
        case canceled

        var label: String {
            switch self {
            case .all:
                return "All"
            case .completed:
                return "Completed"
            case .canceled:
                return "Canceled"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    activeSection
                    upcomingSection
                    pastHeader
                    pastSection
                }
                .padding(16)
            }
            .background(CityRideTheme.background)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedTrip) { trip in
                TripDetailView(viewModel: viewModel, tripID: trip.id)
            }
            .searchable(text: $searchText, prompt: "Search trips")
            .sheet(item: $ratingTrip) { trip in
                ratingSheet(for: trip)
            }
        }
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.activeTrips.isEmpty {
                ForEach(viewModel.activeTrips) { trip in
                    activeTripCard(trip)
                        .accessibilityIdentifier("activity_trip_row_\(trip.id)")
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.upcomingTrips.isEmpty {
                Text("Upcoming")
                    .font(.title3.weight(.bold))

                ForEach(viewModel.upcomingTrips) { trip in
                    simpleTripCard(trip)
                }
            }
        }
    }

    private var pastHeader: some View {
        HStack {
            Text("Past")
                .font(.title3.weight(.bold))
            Spacer()
            Menu {
                ForEach(PastFilter.allCases, id: \.self) { filter in
                    Button(filter.label) {
                        pastFilter = filter
                        viewModel.applyPastFilter(label: filter.label)
                    }
                    .accessibilityIdentifier("activity_filter_option_\(filter.rawValue)")
                }
            } label: {
                Image(systemName: pastFilter == .all ? "slider.horizontal.3" : "line.3.horizontal.decrease.circle.fill")
                    .font(.headline)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("activity_filter_button")
        }
    }

    private var pastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if filteredPastTrips.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(CityRideTheme.muted)
                    Text("No rides yet")
                        .font(.headline)
                    Text("Your ride history will appear here after your first trip.")
                        .font(.subheadline)
                        .foregroundStyle(CityRideTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .accessibilityIdentifier("empty_past_trips")
            } else {
                ForEach(filteredPastTrips) { trip in
                    pastTripCard(trip)
                }
            }
        }
    }

    private func activeTripCard(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            mapPreview(for: trip)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(trip.pickupName) to \(trip.destinationName)")
                        .font(.headline)
                    Text(trip.tripStatus.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08), in: Capsule())
                        .accessibilityIdentifier(trip.tripStatus.chipIdentifier)
                }
                Spacer()
                Button("Details") {
                    selectedTrip = trip
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityIdentifier("activity_detail_button_\(trip.id)")
            }
        }
        .padding(12)
        .uberCard(radius: 20)
    }

    private func simpleTripCard(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.pickupName) to \(trip.destinationName)")
                    .font(.headline)
                    .accessibilityIdentifier("activity_upcoming_trip_row_\(trip.id)")
                Text(trip.reservedFor.map { AppFormatters.shortDateTime.string(from: $0) } ?? AppFormatters.shortDateTime.string(from: trip.requestedAt))
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }
            Spacer()
            if trip.isCancelable {
                Button {
                    viewModel.cancelTrip(trip.id)
                } label: {
                    Text("Cancel")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("activity_cancel_upcoming_\(trip.id)")
            }
            Button {
                selectedTrip = trip
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(CityRideTheme.muted)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("activity_detail_button_\(trip.id)")
        }
        .padding(12)
        .uberCard(radius: 16)
    }

    private func pastTripCard(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: trip.tripStatus == .canceled ? "xmark.circle" : "car.fill")
                .font(.title3)
                .foregroundStyle(trip.tripStatus == .canceled ? .red : .white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destinationName)
                    .font(.headline)
                    .accessibilityIdentifier("activity_past_trip_row_\(trip.id)")
                Text("\(AppFormatters.shortDateTime.string(from: trip.dropoffTime ?? trip.requestedAt)) \u{2022} \(AppFormatters.price(trip.estimatedPrice, currencyCode: trip.currency))")
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }
            Spacer()
            VStack(spacing: 6) {
                if trip.tripStatus == .tripCompleted && !ratedTripIDs.contains(trip.id) {
                    Button {
                        selectedRating = 5
                        ratingTrip = trip
                    } label: {
                        Text("Rate")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activity_rate_button_\(trip.id)")
                }
                if trip.tripStatus == .tripCompleted {
                    Button {
                        viewModel.rebookTrip(trip)
                    } label: {
                        Text("Rebook")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("activity_rebook_button_\(trip.id)")
                }
            }
            Button {
                selectedTrip = trip
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(CityRideTheme.muted)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("activity_detail_button_\(trip.id)")
        }
        .padding(12)
        .uberCard(radius: 16)
    }

    private func mapPreview(for trip: Trip) -> some View {
        RouteMapView(
            pickupName: trip.pickupName,
            destinationName: trip.destinationName,
            places: viewModel.store.state.places,
            showsAnnotations: false,
            lineWidth: 4
        )
        .frame(height: 145)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func ratingSheet(for trip: Trip) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.white.opacity(0.9), Color.white.opacity(0.2))

                Text("How was your ride with \(trip.driver?.driverName ?? "your driver")?")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("\(trip.pickupName) to \(trip.destinationName)")
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectedRating = star
                        } label: {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= selectedRating ? .yellow : Color.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("rating_star_\(star)")
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Additional comments")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                    TextField("Add a comment (optional)", text: $ratingComment)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityIdentifier("rating_comment_field")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a tip")
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                    HStack(spacing: 8) {
                        ForEach([0, 2, 3, 5, 10], id: \.self) { amount in
                            Button { selectedTip = Double(amount) } label: {
                                Text(amount == 0 ? "None" : "$\(amount)")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTip == Double(amount) ? Color.white : Color.white.opacity(0.08), in: Capsule())
                                    .foregroundStyle(selectedTip == Double(amount) ? .black : .white)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("tip_amount_\(amount)")
                        }
                    }
                }

                Spacer()

                Button {
                    ratedTripIDs.insert(trip.id)
                    viewModel.rateTrip(trip.id, tip: selectedTip)
                    ratingComment = ""
                    selectedTip = 0
                    ratingTrip = nil
                } label: {
                    Text("Submit Rating")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("rating_submit_button")
            }
            .padding(24)
            .background(CityRideTheme.background)
            .navigationTitle("Rate your trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        ratingTrip = nil
                    }
                    .accessibilityIdentifier("rating_cancel_button")
                }
            }
        }
    }

    private var filteredPastTrips: [Trip] {
        let base: [Trip]
        switch pastFilter {
        case .all:
            base = viewModel.pastTrips
        case .completed:
            base = viewModel.pastTrips.filter { $0.tripStatus == .tripCompleted }
        case .canceled:
            base = viewModel.pastTrips.filter { $0.tripStatus == .canceled }
        }
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.pickupName.lowercased().contains(query) ||
            $0.destinationName.lowercased().contains(query) ||
            $0.rideType.lowercased().contains(query)
        }
    }
}

private struct TripDetailView: View {
    @ObservedObject var viewModel: ActivityViewModel
    let tripID: String

    var body: some View {
        ScrollView {
            if let trip = currentTrip {
                VStack(alignment: .leading, spacing: 14) {
                    mapSurface

                    Text(trip.tripStatus.label)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.10), in: Capsule())
                        .accessibilityIdentifier(trip.tripStatus.chipIdentifier)

                    infoCard(title: "Route") {
                        detailRow(label: "Pickup", value: trip.pickupName, id: "trip_detail_pickup")
                        detailRow(label: "Destination", value: trip.destinationName, id: "trip_detail_destination")
                        detailRow(label: "Ride type", value: trip.rideType, id: "trip_detail_ride_type")
                        detailRow(label: "Route", value: trip.routeLabel, id: "trip_detail_route_label")
                    }

                    infoCard(title: "Timing") {
                        detailRow(label: "Requested", value: AppFormatters.shortDateTime.string(from: trip.requestedAt), id: "trip_detail_requested_at")
                        detailRow(label: "Pickup", value: trip.pickupTime.map { AppFormatters.shortDateTime.string(from: $0) } ?? "Pending", id: "trip_detail_pickup_time")
                        detailRow(label: "Dropoff", value: trip.dropoffTime.map { AppFormatters.shortDateTime.string(from: $0) } ?? "Pending", id: "trip_detail_dropoff_time")
                        detailRow(label: "ETA", value: "\(trip.etaMinutes) min", id: "trip_detail_eta")
                    }

                    infoCard(title: "Fare") {
                        detailRow(label: "Estimate", value: AppFormatters.price(trip.estimatedPrice, currencyCode: trip.currency), id: "trip_detail_fare_estimate")
                        if let receipt = viewModel.receipt(for: trip.id) {
                            detailRow(label: "Final fare", value: AppFormatters.price(receipt.receiptTotal, currencyCode: receipt.currency), id: "trip_detail_receipt_total")
                        }
                    }

                    infoCard(title: "Driver") {
                        detailRow(label: "Name", value: trip.driver?.driverName ?? "Not assigned", id: "trip_detail_driver_name")
                        detailRow(label: "Vehicle", value: vehicleText(trip.vehicle), id: "trip_detail_vehicle")
                        detailRow(label: "License plate", value: trip.vehicle?.licensePlate ?? "Pending", id: "trip_detail_license_plate")
                    }

                    actionButtons(for: trip)
                }
                .padding(16)
            } else {
                VStack(spacing: 10) {
                    Text("Trip not found")
                        .font(.headline)
                    Text("Return to Activity and select another trip.")
                        .font(.subheadline)
                        .foregroundStyle(CityRideTheme.muted)
                }
                .padding(20)
                .accessibilityIdentifier("trip_detail_not_found")
            }
        }
        .background(CityRideTheme.background)
        .navigationTitle("Trip details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentTrip: Trip? {
        viewModel.store.state.trips.first(where: { $0.id == tripID })
    }

    private var mapSurface: some View {
        RouteMapView(
            pickupName: currentTrip?.pickupName ?? "",
            destinationName: currentTrip?.destinationName ?? "",
            places: viewModel.store.state.places
        )
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func actionButtons(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let canComplete = trip.tripStatus == .driverArriving || trip.tripStatus == .driverAtPickup || trip.tripStatus == .tripInProgress
            if trip.tripStatus == .reserved {
                Button("Start reserved ride") {
                    viewModel.startReservedTrip(trip.id)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .accessibilityIdentifier("trip_detail_start_reserved_button")
            }

            Button("Advance stage") {
                viewModel.advanceTrip(trip.id)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!trip.tripStatus.canAdvance)
            .accessibilityIdentifier("trip_detail_advance_button")

            Button("Complete ride") {
                viewModel.completeTrip(trip.id)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!canComplete)
            .accessibilityIdentifier("trip_detail_complete_button")

            Button("Cancel ride") {
                viewModel.cancelTrip(trip.id)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!trip.isCancelable)
            .accessibilityIdentifier("trip_detail_cancel_button")
        }
    }

    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(12)
        .uberCard(radius: 14)
    }

    private func detailRow(label: String, value: String, id: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(CityRideTheme.muted)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(id)
        }
        .font(.subheadline)
    }

    private func vehicleText(_ vehicle: Vehicle?) -> String {
        guard let vehicle else { return "Not assigned" }
        return "\(vehicle.color) \(vehicle.make) \(vehicle.model)"
    }
}
