import MapKit
import SwiftUI

struct RequestFlowView: View {
    @ObservedObject var viewModel: RequestViewModel
    var onClose: (() -> Void)? = nil

    @StateObject private var searchService = AddressSearchService()
    @State private var pickupSearchText = ""
    @State private var destinationSearchText = ""
    @FocusState private var focusedField: RouteField?
    @State private var isResolvingAddress = false
    @State private var addressError: String?
    @State private var createdTripID = ""
    @State private var showTripStatus = false
    @State private var promoCode = ""
    @State private var showPromoInput = false

    private enum RouteField: Hashable {
        case pickup
        case destination
    }

    var body: some View {
        GeometryReader { geometry in
            let mapHeight = max(180, min(280, geometry.size.height * 0.28))
            VStack(spacing: 0) {
                routeHeader(topInset: geometry.safeAreaInsets.top)

                if focusedField != nil {
                    searchResultsList
                } else {
                    mapSection
                        .frame(height: mapHeight)

                    bottomSheet(bottomInset: geometry.safeAreaInsets.bottom)
                }
            }
            .background(CityRideTheme.background.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            pickupSearchText = viewModel.draft.pickup?.displayName ?? ""
            destinationSearchText = viewModel.draft.destination?.displayName ?? ""
            if viewModel.draft.destination == nil {
                focusedField = .destination
            }
            viewModel.store.locationManager.requestLocation()
            if let coord = viewModel.store.locationManager.currentCoordinate {
                searchService.deviceCoordinate = coord
            }
        }
        .onReceive(viewModel.store.locationManager.$currentCoordinate) { coord in
            if let coord { searchService.deviceCoordinate = coord }
        }
        .onChange(of: pickupSearchText) { _, newValue in
            if focusedField == .pickup { searchService.queryFragment = newValue }
        }
        .onChange(of: destinationSearchText) { _, newValue in
            if focusedField == .destination { searchService.queryFragment = newValue }
        }
        .onChange(of: focusedField) { _, newField in
            switch newField {
            case .pickup: searchService.queryFragment = pickupSearchText
            case .destination: searchService.queryFragment = destinationSearchText
            case nil: searchService.queryFragment = ""
            }
        }
        .fullScreenCover(isPresented: $showTripStatus) {
            NavigationStack {
                TripStatusView(store: viewModel.store, tripID: createdTripID)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") {
                                showTripStatus = false
                                onClose?()
                            }
                            .accessibilityIdentifier("trip_status_modal_close")
                        }
                    }
            }
        }
    }

    private func routeHeader(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                if let onClose {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("request_modal_close_button")
                }

                routeInputColumn
            }
            .padding(.horizontal, 16)
            .padding(.top, topInset + 8)
            .padding(.bottom, 10)

            Divider().overlay(CityRideTheme.cardBorder)
        }
        .background(CityRideTheme.panel)
    }

    private var routeInputColumn: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1.5, height: 24)
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }

            VStack(spacing: 0) {
                TextField("Pickup location", text: $pickupSearchText)
                    .font(.subheadline)
                    .focused($focusedField, equals: .pickup)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .submitLabel(.search)
                    .onSubmit { geocodeCurrentField() }
                    .accessibilityIdentifier("request_pickup_chip_button")

                Divider().overlay(Color.white.opacity(0.12))

                TextField("Where to?", text: $destinationSearchText)
                    .font(.subheadline)
                    .focused($focusedField, equals: .destination)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .submitLabel(.search)
                    .onSubmit { geocodeCurrentField() }
                    .accessibilityIdentifier("request_destination_chip_button")
            }
        }
    }

    private var searchResultsList: some View {
        let query = (focusedField == .pickup ? pickupSearchText : destinationSearchText)
            .lowercased().trimmingCharacters(in: .whitespaces)
        let predefinedPlaces = query.isEmpty
            ? viewModel.availablePlaces
            : viewModel.availablePlaces.filter {
                $0.displayName.lowercased().contains(query) || $0.address.lowercased().contains(query)
            }
        return ScrollView {
            LazyVStack(spacing: 0) {
                Button {
                    let place = viewModel.store.locationManager.currentPlace ?? LocationPlace(
                        id: "device_location",
                        displayName: "Current location",
                        address: "San Francisco, CA",
                        latitudePlaceholder: 37.7749,
                        longitudePlaceholder: -122.4194
                    )
                    selectSearchResult(place)
                } label: {
                    searchRow(
                        icon: "location.fill",
                        title: "Current location",
                        subtitle: viewModel.store.locationManager.currentPlace?.address ?? "San Francisco, CA"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("request_current_location_row")

                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.leading, 60)

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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                ForEach(predefinedPlaces) { place in
                    Button {
                        selectSearchResult(place)
                    } label: {
                        searchRow(icon: "mappin.circle.fill", title: place.displayName, subtitle: place.address)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("request_search_result_\(place.displayName.accessibilitySafe)")

                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 60)
                }

                if !searchService.completions.isEmpty && !query.isEmpty {
                    HStack {
                        Text("NEARBY")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CityRideTheme.muted)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    ForEach(Array(searchService.completions.enumerated()), id: \.offset) { _, completion in
                        Button {
                            selectMapKitResult(completion)
                        } label: {
                            searchRow(icon: "magnifyingglass", title: completion.title, subtitle: completion.subtitle)
                        }
                        .buttonStyle(.plain)
                        .disabled(isResolvingAddress)

                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 60)
                    }
                }

                if !query.isEmpty && !isResolvingAddress {
                    Button {
                        geocodeCurrentField()
                    } label: {
                        searchRow(
                            icon: "location.magnifyingglass",
                            title: "Search for \"\(focusedField == .pickup ? pickupSearchText : destinationSearchText)\"",
                            subtitle: "Find this address on the map"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, 60)
                }

                if searchService.isSearching || isResolvingAddress {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 16)
                }
            }
        }
        .background(CityRideTheme.background)
    }

    private func searchRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CityRideTheme.muted)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    private func selectSearchResult(_ place: LocationPlace) {
        if focusedField == .pickup {
            viewModel.setPickup(place)
            pickupSearchText = place.displayName
            if viewModel.draft.destination == nil {
                focusedField = .destination
            } else {
                focusedField = nil
            }
        } else {
            viewModel.setDestination(place)
            destinationSearchText = place.displayName
            focusedField = nil
        }
    }

    private func selectMapKitResult(_ completion: MKLocalSearchCompletion) {
        isResolvingAddress = true
        addressError = nil
        Task {
            if let place = await searchService.resolve(completion) {
                await MainActor.run {
                    selectSearchResult(place)
                    isResolvingAddress = false
                }
            } else {
                await MainActor.run {
                    addressError = "Could not resolve that address. Please try again."
                    isResolvingAddress = false
                }
            }
        }
    }

    private func geocodeCurrentField() {
        let field = focusedField
        let text = field == .pickup ? pickupSearchText : destinationSearchText
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isResolvingAddress = true
        addressError = nil
        Task {
            let result = await searchService.geocode(address: text)
            await MainActor.run {
                isResolvingAddress = false
                switch result {
                case .success(let place):
                    if field == .pickup {
                        pickupSearchText = place.displayName
                    } else {
                        destinationSearchText = place.displayName
                    }
                    selectSearchResult(place)
                case .failure:
                    addressError = result.errorMessage
                }
            }
        }
    }

    private var mapSection: some View {
        ZStack(alignment: .bottom) {
            RouteMapView(
                pickup: viewModel.draft.pickup,
                destination: viewModel.draft.destination
            )

            HStack {
                Text(viewModel.rideOptions.first.map { "ETA \($0.etaMinutes) min" } ?? "ETA --")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.72), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .accessibilityIdentifier("map_eta_chip")

                Spacer()

                Button {
                    viewModel.refreshRideOptions()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.72), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("map_recenter_button")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .accessibilityIdentifier("request_map_surface")
    }

    private func bottomSheet(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Capsule()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 40, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    rideTimingSection
                    rideOptionsList
                    paymentSection
                    promoSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            Divider()
                .overlay(CityRideTheme.cardBorder)

            confirmButton
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, max(10, bottomInset + 8))
                .background(CityRideTheme.panel)
        }
        .background(
            CityRideTheme.panel,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CityRideTheme.cardBorder, lineWidth: 1)
        )
        .padding(.top, -14)
    }

    private var rideTimingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Ride timing", selection: Binding(
                get: { viewModel.draft.rideTiming },
                set: { viewModel.setRideTiming($0) }
            )) {
                ForEach(RideTimingOption.allCases, id: \.self) { timing in
                    Text(timing.label).tag(timing)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("ride_timing_toggle")

            if viewModel.draft.rideTiming == .reserve {
                DatePicker(
                    "Reserve for",
                    selection: Binding(
                        get: { viewModel.draft.reservedDate ?? Date().addingTimeInterval(3600) },
                        set: { viewModel.setReservedDate($0) }
                    ),
                    in: Date().addingTimeInterval(5 * 60)...Date().addingTimeInterval(7 * 24 * 3600),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .accessibilityIdentifier("reserve_date_picker")
            }
        }
    }

    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RideFilterCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.setFilterCategory(category)
                    } label: {
                        Text(category.label)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.draft.filterCategory == category
                                    ? Color.white : Color.white.opacity(0.08),
                                in: Capsule()
                            )
                            .foregroundStyle(viewModel.draft.filterCategory == category ? .black : .white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ride_filter_\(category.rawValue)")
                }
            }
        }
    }

    private var rideOptionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Choose a ride")
                    .font(.headline)
                    .accessibilityIdentifier("request_ride_types_title")
                Spacer()
                Text("Upfront price")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("upfront_price_badge")
            }

            categoryFilterChips

            if let message = rideOptionsMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(CityRideTheme.muted)
                    .padding(12)
                    .uberCard(radius: 14)
                    .accessibilityIdentifier("request_empty_state_message")
            }

            ForEach(viewModel.rideOptions) { option in
                RideOptionCard(
                    option: option,
                    selected: option.id == viewModel.draft.selectedRideTypeId,
                    onTap: { viewModel.selectRideType(option.id) }
                )
            }
        }
    }

    private var paymentSection: some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .font(.subheadline)
                .foregroundStyle(CityRideTheme.muted)
            Picker("Payment method", selection: Binding(
                get: { viewModel.selectedPaymentMethodID },
                set: { viewModel.setPaymentMethod($0) }
            )) {
                ForEach(viewModel.paymentMethods) { method in
                    Label {
                        Text(paymentLabel(for: method))
                    } icon: {
                        Image(systemName: paymentIcon(for: method))
                    }
                    .tag(method.id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("payment_method_selector")
            Spacer()
        }
        .padding(12)
        .uberCard(radius: 14)
    }

    private func paymentLabel(for method: PaymentMethod) -> String {
        let base: String
        if let account = viewModel.store.myBankAccountForPaymentMethod(method) {
            base = "\(method.cardLabel) (MyBank \u{00B7} \(account.name))"
        } else {
            base = method.cardLabel
        }
        return method.isAvailable ? base : "\(base) (Unavailable)"
    }

    private func paymentIcon(for method: PaymentMethod) -> String {
        switch method.type {
        case .applePay:
            return "apple.logo"
        case .cash:
            return "banknote"
        case .card:
            return "creditcard.fill"
        case .business:
            return "building.2"
        }
    }

    private var promoSection: some View {
        VStack(spacing: 8) {
            if showPromoInput {
                HStack(spacing: 8) {
                    TextField("Promo code", text: $promoCode)
                        .font(.subheadline)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("promo_code_field")

                    Button {
                        viewModel.setPromoCode(promoCode)
                        showPromoInput = false
                    } label: {
                        Text("Apply")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(promoCode.isEmpty ? Color.white.opacity(0.10) : Color.white, in: Capsule())
                            .foregroundStyle(promoCode.isEmpty ? CityRideTheme.muted : .black)
                    }
                    .buttonStyle(.plain)
                    .disabled(promoCode.isEmpty)
                    .accessibilityIdentifier("promo_code_apply_button")
                }
                .padding(12)
                .uberCard(radius: 14)
            } else {
                Button {
                    showPromoInput = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tag")
                            .font(.subheadline)
                            .foregroundStyle(CityRideTheme.muted)
                        Text(viewModel.draft.promoCode.isEmpty ? "Add promo code" : "Promo: \(viewModel.draft.promoCode)")
                            .font(.subheadline)
                            .foregroundStyle(viewModel.draft.promoCode.isEmpty ? CityRideTheme.muted : .white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    .padding(12)
                    .uberCard(radius: 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("promo_code_button")
            }
        }
    }

    private var confirmButton: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if let trip = viewModel.requestRide() {
                    createdTripID = trip.id
                    showTripStatus = true
                }
            } label: {
                Text(confirmButtonLabel)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(viewModel.canConfirmRequest ? .black : CityRideTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(
                        viewModel.canConfirmRequest ? Color.white : Color.white.opacity(0.28),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canConfirmRequest)
            .accessibilityIdentifier("request_confirm_button")

            if !viewModel.canConfirmRequest {
                Text("Select pickup, destination, and ride type to continue.")
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
                    .accessibilityIdentifier("request_confirm_disabled_hint")
            }
        }
    }

    private var selectedRideOption: RideOption? {
        if let selectedId = viewModel.draft.selectedRideTypeId,
           let option = viewModel.rideOptions.first(where: { $0.id == selectedId }) {
            return option
        }
        return viewModel.rideOptions.first
    }

    private var selectedRideName: String {
        selectedRideOption?.rideTypeName ?? "CityRideX"
    }

    private var confirmButtonLabel: String {
        let verb = viewModel.draft.rideTiming == .reserve ? "Reserve" : "Request"
        if let option = selectedRideOption {
            let price = AppFormatters.price(option.estimatedPrice, currencyCode: option.currency)
            return "\(verb) \(option.rideTypeName) \u{00B7} \(price)"
        }
        return "\(verb) \(selectedRideName)"
    }

    private var rideOptionsMessage: String? {
        guard let message = viewModel.message else { return nil }
        switch message {
        case "same pickup and destination", "no ride options found", "no matching filters", "fare data unavailable", "invalid pickup/destination":
            return message
        default:
            return nil
        }
    }

}

private struct RideOptionCard: View {
    let option: RideOption
    let selected: Bool
    let onTap: () -> Void

    private var rideIcon: String {
        switch option.category {
        case .green:
            return "leaf.fill"
        case .premium:
            return "star.circle.fill"
        case .all, .standard, .comfort, .xl:
            return "car.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: rideIcon)
                    .font(.title3)
                    .foregroundStyle(option.category == .green ? .green : option.category == .premium ? .yellow : .white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(option.rideTypeName)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(AppFormatters.price(option.estimatedPrice, currencyCode: option.currency))
                            .font(.headline.weight(.semibold))
                            .accessibilityIdentifier("estimate_price_label_\(option.id)")
                    }

                    HStack(spacing: 4) {
                        Text(option.serviceLabel)
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                        Text("\u{00B7}")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(CityRideTheme.muted)
                        Text("\(option.seats)")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }

                    HStack(spacing: 8) {
                        Text("\(option.etaMinutes) min away")
                            .font(.caption.weight(.semibold))
                            .accessibilityIdentifier("estimate_eta_label_\(option.id)")

                        if !option.badges.isEmpty {
                            ForEach(option.badges, id: \.self) { badge in
                                Text(badge.label)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.10), in: Capsule())
                                    .accessibilityIdentifier("ride_badge_\(option.id)_\(badge.rawValue)")
                            }
                        }
                    }
                }
            }
            .padding(10)
            .background(selected ? Color.white.opacity(0.11) : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.78) : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ride_type_row_\(option.id)")
    }
}
