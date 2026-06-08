import MapKit
import SwiftUI

struct PlanRideView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var requestViewModel: RequestViewModel
    var onClose: () -> Void
    var onConfirmRoute: () -> Void

    @StateObject private var searchService = AddressSearchService()
    @State private var destinationSearch = ""
    @State private var stopSearch = ""
    @State private var showStopField = false
    @State private var pickupTiming = "Pickup now"
    @State private var rideFor = "For me"
    @State private var isResolvingAddress = false
    @State private var addressError: String?
    @FocusState private var destinationFocused: Bool
    @FocusState private var stopFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.08))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    optionChips
                    routeInputCard
                    recentLocationsList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(CityRideTheme.background)
        .onAppear {
            requestViewModel.setRideTiming(.reserve)
            destinationFocused = true
            homeViewModel.store.locationManager.requestLocation()
            if let coord = homeViewModel.store.locationManager.currentCoordinate {
                searchService.deviceCoordinate = coord
            }
        }
        .onReceive(homeViewModel.store.locationManager.$currentCoordinate) { coord in
            if let coord {
                searchService.deviceCoordinate = coord
            }
        }
        .onChange(of: destinationSearch) { _, newValue in
            if destinationFocused { searchService.queryFragment = newValue }
        }
        .onChange(of: destinationFocused) { _, focused in
            searchService.queryFragment = focused ? destinationSearch : ""
        }
    }

    private var header: some View {
        HStack {
            Button {
                onClose()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.medium))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plan_ride_back_button")

            Spacer()

            Text("Plan your ride")
                .font(.title3.weight(.semibold))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var optionChips: some View {
        HStack(spacing: 10) {
            Menu {
                Button("Pickup now") {
                    pickupTiming = "Pickup now"
                    requestViewModel.setRideTiming(.now)
                }
                Button("Schedule pickup") {
                    pickupTiming = "Schedule pickup"
                    requestViewModel.setRideTiming(.reserve)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(pickupTiming)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.10), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plan_ride_pickup_timing")

            Menu {
                Button("For me") {
                    rideFor = "For me"
                }
                Button("For someone else") {
                    rideFor = "For someone else"
                    homeViewModel.store.postStatusMessage("Ride will be requested for someone else.")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person")
                        .font(.caption)
                    Text(rideFor)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.10), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("plan_ride_for_whom")

            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var routeInputCard: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1.5, height: 28)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 8, height: 8)
                    }

                    VStack(spacing: 0) {
                        Button {
                            let place = homeViewModel.store.locationManager.currentPlace ?? LocationPlace(
                                id: "device_location",
                                displayName: "Current location",
                                address: "San Francisco, CA",
                                latitudePlaceholder: 37.7749,
                                longitudePlaceholder: -122.4194
                            )
                            homeViewModel.setPickup(place)
                        } label: {
                            HStack {
                                Text(homeViewModel.requestDraft.pickup?.displayName ?? "Current location")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                if homeViewModel.requestDraft.pickup == nil || homeViewModel.requestDraft.pickup?.id == "device_location" {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("plan_ride_pickup_current_location")

                        Divider().overlay(Color.white.opacity(0.12))

                        HStack {
                            TextField("Where to?", text: $destinationSearch)
                                .font(.subheadline)
                                .focused($destinationFocused)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit { geocodeDestination() }
                                .accessibilityIdentifier("plan_ride_destination_field")
                            Spacer()
                        }
                        .padding(.vertical, 12)

                        if showStopField {
                            Divider().overlay(Color.white.opacity(0.12))

                            HStack {
                                TextField("Add a stop", text: $stopSearch)
                                    .font(.subheadline)
                                    .focused($stopFocused)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .accessibilityIdentifier("plan_ride_stop_field")
                                Button {
                                    showStopField = false
                                    stopSearch = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(CityRideTheme.muted)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            )

            Button {
                showStopField = true
                stopFocused = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(showStopField)
            .opacity(showStopField ? 0.4 : 1.0)
            .accessibilityIdentifier("plan_ride_add_stop")
        }
        .padding(.bottom, 16)
    }

    private var recentLocationsList: some View {
        VStack(spacing: 0) {
            if let error = addressError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        addressError = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.vertical, 8)
            }

            ForEach(Array(filteredLocations.enumerated()), id: \.element.id) { index, place in
                Button {
                    selectPlace(place)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: iconForPlace(place))
                            .font(.subheadline)
                            .foregroundStyle(CityRideTheme.muted)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 3) {
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
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("plan_ride_location_\(place.displayName.accessibilitySafe)")

                if index < filteredLocations.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 46)
                }
            }

            if !searchService.completions.isEmpty && !destinationSearch.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack {
                    Text("NEARBY")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CityRideTheme.muted)
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.bottom, 4)

                ForEach(Array(searchService.completions.enumerated()), id: \.offset) { _, completion in
                    Button {
                        selectMapKitResult(completion)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "magnifyingglass")
                                .font(.subheadline)
                                .foregroundStyle(CityRideTheme.muted)
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(completion.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(CityRideTheme.muted)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolvingAddress)

                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 46)
                }
            }

            if !destinationSearch.trimmingCharacters(in: .whitespaces).isEmpty && !isResolvingAddress {
                Button {
                    geocodeDestination()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(CityRideTheme.muted)
                            .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Search for \"\(destinationSearch)\"")
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            Text("Find this address on the map")
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.leading, 46)
            }

            if searchService.isSearching || isResolvingAddress {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical, 16)
            }
        }
    }

    private func selectPlace(_ place: LocationPlace) {
        homeViewModel.setDestination(place)
        if pickupTiming == "Pickup now" {
            requestViewModel.setRideTiming(.now)
        } else {
            requestViewModel.setRideTiming(.reserve)
        }
        onConfirmRoute()
    }

    private func selectMapKitResult(_ completion: MKLocalSearchCompletion) {
        isResolvingAddress = true
        addressError = nil
        Task {
            if let place = await searchService.resolve(completion) {
                await MainActor.run {
                    isResolvingAddress = false
                    selectPlace(place)
                }
            } else {
                await MainActor.run {
                    addressError = "Could not resolve that address. Please try again."
                    isResolvingAddress = false
                }
            }
        }
    }

    private func geocodeDestination() {
        let text = destinationSearch
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isResolvingAddress = true
        addressError = nil
        Task {
            let result = await searchService.geocode(address: text)
            await MainActor.run {
                isResolvingAddress = false
                switch result {
                case .success(let place):
                    destinationSearch = place.displayName
                    selectPlace(place)
                case .failure:
                    addressError = result.errorMessage
                }
            }
        }
    }

    private var filteredLocations: [LocationPlace] {
        let allLocations = homeViewModel.recentDestinations + homeViewModel.suggestedDestinations.filter { suggested in
            !homeViewModel.recentDestinations.contains(where: { $0.id == suggested.id })
        }

        if destinationSearch.trimmingCharacters(in: .whitespaces).isEmpty {
            return allLocations
        }

        let query = destinationSearch.lowercased()
        return homeViewModel.availablePlaces.filter {
            $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query)
        }
    }

    private func iconForPlace(_ place: LocationPlace) -> String {
        if homeViewModel.recentDestinations.contains(where: { $0.id == place.id }) {
            return "clock"
        }
        return "mappin"
    }
}
